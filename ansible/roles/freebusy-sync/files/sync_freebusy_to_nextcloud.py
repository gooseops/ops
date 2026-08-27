#!/usr/bin/env python3
"""
sync_freebusy_to_nextcloud.py

Pulls free/busy data from one or more Google Calendars (including calendars
shared *into* the authenticated account, e.g. client calendars shared as
free/busy-only) and writes generic "Busy" blocks into a Nextcloud calendar
over CalDAV. No event titles, descriptions, or attendees are ever read or
written -- only start/end times.

Authenticates as a Google service account impersonating a specific user via
domain-wide delegation (Workspace Admin console -> Security -> API Controls
-> Domain-wide Delegation). This requires no browser interaction, ever --
no OAuth consent screen, no refresh-token expiry, nothing to re-authenticate
periodically. It only works for a user within a Workspace domain you
administer; it cannot be used to access a calendar in someone else's domain.

Designed to run on a schedule (cron or systemd timer) on headless/remote
infrastructure with zero manual intervention after initial setup.

All configuration is via environment variables so secrets can be rotated
and endpoints changed without touching code. See .env.example.

Usage:
    python3 sync_freebusy_to_nextcloud.py [--dry-run] [--verbose]
"""

import argparse
import hashlib
import json
import logging
import os
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List
from zoneinfo import ZoneInfo

from dateutil import parser as dateutil_parser
from dotenv import load_dotenv
from google.auth.transport.requests import Request
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import caldav
from icalendar import Calendar as ICalendar
from icalendar import Event as IEvent

load_dotenv()

# Read-only scope -- this script never needs to modify or delete anything
# in Google Calendar, only query free/busy status.
GOOGLE_SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]


# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

@dataclass
class Config:
    # Google service account + domain-wide delegation
    google_service_account_key_path: Path
    google_impersonate_subject: str
    google_calendar_ids: List[str]

    # Sync window
    lookahead_days: int
    timezone: str

    # Nextcloud CalDAV target
    nextcloud_base_url: str
    nextcloud_calendar_url: str
    nextcloud_username: str
    nextcloud_app_password: str

    # Bookkeeping
    sync_uid_prefix: str
    sync_state_path: Path
    log_level: str

    @staticmethod
    def _require(name: str) -> str:
        value = os.environ.get(name)
        if not value:
            raise SystemExit(
                f"Missing required environment variable: {name}\n"
                f"See .env.example for the full list of required settings."
            )
        return value

    @classmethod
    def from_env(cls) -> "Config":
        calendar_ids_raw = cls._require("GOOGLE_CALENDAR_IDS")
        calendar_ids = [c.strip() for c in calendar_ids_raw.split(",") if c.strip()]
        if not calendar_ids:
            raise SystemExit("GOOGLE_CALENDAR_IDS is set but contains no valid calendar IDs.")

        key_path = Path(cls._require("GOOGLE_SERVICE_ACCOUNT_KEY_PATH")).expanduser()

        tz_name = os.environ.get("SYNC_TIMEZONE", "UTC")
        try:
            ZoneInfo(tz_name)
        except Exception as exc:
            raise SystemExit(
                f"SYNC_TIMEZONE={tz_name!r} is not a valid IANA zone name "
                f"(e.g. 'America/New_York', 'UTC'): {exc}"
            )

        state_path = Path(
            os.environ.get(
                "SYNC_STATE_PATH",
                str(Path.home() / ".config" / "freebusy-sync" / "sync_state.json"),
            )
        ).expanduser()

        return cls(
            google_service_account_key_path=key_path,
            google_impersonate_subject=cls._require("GOOGLE_IMPERSONATE_SUBJECT"),
            google_calendar_ids=calendar_ids,
            lookahead_days=int(os.environ.get("SYNC_LOOKAHEAD_DAYS", "90")),
            timezone=tz_name,
            nextcloud_base_url=cls._require("NEXTCLOUD_BASE_URL"),
            nextcloud_calendar_url=cls._require("NEXTCLOUD_CALENDAR_URL"),
            nextcloud_username=cls._require("NEXTCLOUD_USERNAME"),
            nextcloud_app_password=cls._require("NEXTCLOUD_APP_PASSWORD"),
            sync_uid_prefix=os.environ.get("SYNC_UID_PREFIX", "freebusy-sync-"),
            sync_state_path=state_path,
            log_level=os.environ.get("LOG_LEVEL", "INFO").upper(),
        )


# --------------------------------------------------------------------------
# Google service account auth + free/busy fetch
# --------------------------------------------------------------------------

def get_google_credentials(cfg: Config) -> service_account.Credentials:
    """
    Loads the service account's private key and impersonates
    cfg.google_impersonate_subject via domain-wide delegation.

    No browser, no consent screen, no cached/expiring token -- this
    authenticates fresh from the key file on every run. Requires:

    1. This service account's numeric Client ID (found on the service
       account's details page in Google Cloud Console -- NOT its email
       address) authorized for domain-wide delegation in the Workspace
       Admin console: Security -> Access and data control -> API
       Controls -> Domain-wide Delegation, scoped to GOOGLE_SCOPES.
    2. cfg.google_impersonate_subject to be a real mailbox in that same
       Workspace domain. Impersonating that user means this script sees
       everything their own calendarList shows -- their own calendar
       plus anything already shared into it -- without any calendar
       needing to be separately shared with the service account itself.
    """
    if not cfg.google_service_account_key_path.exists():
        raise SystemExit(
            f"Service account key file not found: {cfg.google_service_account_key_path}\n"
            f"Download it from Google Cloud Console -> IAM & Admin -> Service Accounts "
            f"-> (your account) -> Keys -> Add Key -> JSON."
        )

    base_creds = service_account.Credentials.from_service_account_file(
        str(cfg.google_service_account_key_path), scopes=GOOGLE_SCOPES
    )
    creds = base_creds.with_subject(cfg.google_impersonate_subject)
    creds.refresh(Request())
    return creds


def floor_to_local_day(moment_utc: datetime, tz_name: str) -> datetime:
    """
    Floors a UTC datetime to local midnight of the same day in tz_name,
    expressed back in UTC.

    Used as the freebusy query's timeMin instead of the raw current
    instant -- see fetch_busy_blocks for why that matters. The boundary
    only needs to be stable for much longer than the sync interval, so
    plain UTC midnight would satisfy that too -- this floors to tz_name's
    midnight instead so the boundary actually lines up with what "today"
    means to a person in that zone, rather than shifting at whatever
    local hour UTC midnight happens to fall on. zoneinfo resolves DST
    transitions automatically (e.g. US Eastern midnight is UTC-4 in
    summer, UTC-5 in winter) -- never hardcode a fixed UTC offset here,
    it'll be wrong for half the year.
    """
    local_midnight = moment_utc.astimezone(ZoneInfo(tz_name)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    return local_midnight.astimezone(timezone.utc)


def fetch_busy_blocks(
    creds: service_account.Credentials, calendar_ids: List[str], time_min: datetime, lookahead_days: int
) -> List[dict]:
    """
    Queries the freebusy.query endpoint for each configured calendar ID.
    This only ever returns opaque busy/free time ranges -- Google's API
    does not include event titles or details in this response, regardless
    of the access level (owner, reader, or freeBusyReader) granted on the
    source calendar. That makes it a good fit for privacy-scoped syncing.

    time_min is expected to be floor_to_local_day(now, tz_name), not now
    itself. Google's freebusy API clips returned busy intervals to the
    query window -- an event already in progress at timeMin gets its
    reported start clipped to timeMin, not its real start. This script's
    content fingerprint (see _content_fingerprint) is derived from that
    reported start, so if time_min were the raw current instant -- which
    this timer re-samples every minute -- an in-progress event's
    fingerprint would change on every single run, and reconcile would
    read that as "old block gone, new block appeared", needlessly
    deleting and recreating the same event every minute for its entire
    duration. Flooring to local midnight keeps an in-progress event's
    fingerprint stable all day; it only shifts once, at the next local
    midnight rollover.
    """
    service = build("calendar", "v3", credentials=creds)
    time_max = time_min + timedelta(days=lookahead_days)

    body = {
        "timeMin": time_min.isoformat(),
        "timeMax": time_max.isoformat(),
        "items": [{"id": cid} for cid in calendar_ids],
    }

    try:
        response = service.freebusy().query(body=body).execute()
    except HttpError as exc:
        raise SystemExit(f"Google freebusy query failed: {exc}")

    busy_blocks = []
    for cal_id, data in response.get("calendars", {}).items():
        errors = data.get("errors")
        if errors:
            logging.warning("Calendar %s returned errors, skipping: %s", cal_id, errors)
            continue
        busy_list = data.get("busy", [])
        logging.info("Calendar %s: %d busy block(s)", cal_id, len(busy_list))
        for block in busy_list:
            busy_blocks.append(
                {
                    "source_calendar": cal_id,
                    "start": block["start"],
                    "end": block["end"],
                }
            )
    return busy_blocks


# --------------------------------------------------------------------------
# Local sync-state bookkeeping
# --------------------------------------------------------------------------
#
# Nextcloud keeps a trash bin for deleted calendar events, and its UID
# uniqueness constraint applies even to trashed items -- a UID stays
# reserved server-side until the trash is emptied, so deleting an event
# and immediately recreating one with the *same* UID reliably 500s.
#
# Rather than fight that, UIDs here are never derived from content and
# never reused. A local state file maps a content fingerprint (used only
# to detect create/delete/unchanged locally) to the actual opaque UID
# written to the server, so each logical busy block gets exactly one UID
# for its entire lifetime.
#
# Each entry also stores the block's end time. Google's freebusy.query
# only ever returns blocks at or after timeMin -- once a block's end
# passes below the query window, it silently stops appearing in the
# fetch, which would otherwise look identical to the source event having
# been cancelled. Recording end lets reconcile tell those apart: a block
# still due to be in the window (end >= this run's time_min) that
# vanished from the fetch really was removed/changed upstream and gets
# deleted; a block that's simply aged out of the window is left alone
# permanently, so already-happened events stay on the Nextcloud calendar
# as a durable record instead of being swept the next time the window
# rolls forward. Entries written before this field existed have no "end"
# -- treated as not-deletable (see _is_deletable) rather than guessed at.

def _load_state(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except (json.JSONDecodeError, OSError) as exc:
        logging.warning("Could not read sync state file (%s), treating as empty: %s", path, exc)
        return {}


def _save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True))
    os.chmod(path, 0o600)


def _content_fingerprint(block: dict) -> str:
    raw = f"{block['source_calendar']}|{block['start']}|{block['end']}"
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:16]


def _is_deletable(entry: dict, time_min: datetime) -> bool:
    """
    Whether a state entry that fell out of this run's fetch is safe to
    delete -- see the module-level comment above _load_state for why
    that's not the same question as "is it missing from desired".
    """
    end_raw = entry.get("end")
    if not end_raw:
        # No recorded end -- either a legacy entry from before this
        # field existed, or bookkeeping got confused somewhere. Either
        # way, there's no way to tell already-happened history apart
        # from a genuine cancellation, so leave it alone rather than
        # risk deleting a historical record.
        return False
    return dateutil_parser.isoparse(end_raw) >= time_min


# --------------------------------------------------------------------------
# Nextcloud CalDAV write
# --------------------------------------------------------------------------

def connect_nextcloud_calendar(cfg: Config) -> caldav.Calendar:
    client = caldav.DAVClient(
        url=cfg.nextcloud_base_url,
        username=cfg.nextcloud_username,
        password=cfg.nextcloud_app_password,
    )
    return caldav.Calendar(client=client, url=cfg.nextcloud_calendar_url)


def _build_ical(uid: str, start: datetime, end: datetime) -> str:
    ical = ICalendar()
    ical.add("prodid", "-//freebusy-sync//EN")
    ical.add("version", "2.0")

    event = IEvent()
    event.add("uid", uid)
    # Deliberately generic -- no source calendar name, no details.
    event.add("summary", "Busy")
    event.add("dtstart", start)
    event.add("dtend", end)
    # RFC 5545 requires DTSTAMP on every VEVENT. Without it, the caldav
    # client silently patches it in before every write (logged as "Ical
    # data was modified to avoid compatibility issues") -- setting it
    # here makes the payload spec-compliant outright instead of relying
    # on that undocumented client-side workaround on every single sync.
    event.add("dtstamp", datetime.now(timezone.utc))
    event.add("transp", "OPAQUE")
    ical.add_component(event)
    return ical.to_ical().decode("utf-8")


def sync_busy_blocks(
    calendar: caldav.Calendar, busy_blocks: List[dict], uid_prefix: str, state_path: Path, time_min: datetime, dry_run: bool
) -> None:
    state = _load_state(state_path)

    desired: dict = {}
    for block in busy_blocks:
        fp = _content_fingerprint(block)
        desired[fp] = {
            "start": dateutil_parser.isoparse(block["start"]),
            "end": dateutil_parser.isoparse(block["end"]),
        }

    existing_fps = set(state.keys())
    desired_fps = set(desired.keys())

    missing = existing_fps - desired_fps
    to_delete = {fp for fp in missing if _is_deletable(state[fp], time_min)}
    kept_as_history = missing - to_delete
    to_create = desired_fps - existing_fps
    unchanged = desired_fps & existing_fps

    # Backfills "end" onto entries written before that field existed,
    # while they're still confirmed matching a fetched block -- so
    # legacy entries age into the _is_deletable logic above instead of
    # being permanently exempt from it for lacking data this run can
    # supply for free.
    for fp in unchanged:
        state[fp].setdefault("end", desired[fp]["end"].isoformat())

    # Everything below is wrapped so a failure partway through still
    # persists whatever succeeded before it -- previously an unguarded
    # exception here (most likely from calendar.save_event, a plain
    # network call that can fail transiently) would propagate straight
    # out of this function, skipping _save_state entirely and leaving
    # the state file out of sync with deletes/creates that had already
    # actually happened against the live server.
    try:
        for fp in to_delete:
            uid = state[fp]["uid"]
            if dry_run:
                logging.info("[dry-run] would delete stale block (uid=%s)", uid)
                continue
            try:
                event = calendar.event_by_uid(uid)
                event.delete()
            except Exception as exc:
                logging.warning("Could not delete uid=%s (may already be gone): %s", uid, exc)
            del state[fp]

        for fp in to_create:
            # Never derived from content, never reused -- see
            # module-level comment above on why that matters for
            # Nextcloud's trash bin.
            uid = f"{uid_prefix}{uuid.uuid4().hex[:16]}"
            start = desired[fp]["start"]
            end = desired[fp]["end"]
            if dry_run:
                logging.info("[dry-run] would create uid=%s: %s -> %s", uid, start, end)
                continue
            try:
                calendar.save_event(_build_ical(uid, start, end))
            except Exception as exc:
                logging.warning("Could not create block (fp=%s, %s -> %s): %s", fp, start, end, exc)
                continue
            state[fp] = {"uid": uid, "end": end.isoformat()}
    finally:
        if not dry_run:
            _save_state(state_path, state)

    logging.info(
        "Reconcile complete: %d created, %d deleted, %d unchanged, %d kept as history",
        len(to_create), len(to_delete), len(unchanged), len(kept_as_history),
    )


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Don't write or delete anything, just log what would happen.")
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging.")
    args = parser.parse_args()

    cfg = Config.from_env()
    log_level = "DEBUG" if args.verbose else cfg.log_level
    logging.basicConfig(level=log_level, format="%(asctime)s [%(levelname)s] %(message)s")

    logging.info("Loading Google service account credentials (impersonating %s).", cfg.google_impersonate_subject)
    creds = get_google_credentials(cfg)

    time_min = floor_to_local_day(datetime.now(timezone.utc), cfg.timezone)

    logging.info("Querying free/busy for: %s", ", ".join(cfg.google_calendar_ids))
    busy_blocks = fetch_busy_blocks(creds, cfg.google_calendar_ids, time_min, cfg.lookahead_days)

    logging.info("Connecting to Nextcloud calendar at %s", cfg.nextcloud_calendar_url)
    calendar = connect_nextcloud_calendar(cfg)

    sync_busy_blocks(calendar, busy_blocks, cfg.sync_uid_prefix, cfg.sync_state_path, time_min, args.dry_run)

    logging.info("Sync complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
