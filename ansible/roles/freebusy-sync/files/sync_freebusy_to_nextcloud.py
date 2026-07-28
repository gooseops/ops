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


def fetch_busy_blocks(creds: service_account.Credentials, calendar_ids: List[str], lookahead_days: int) -> List[dict]:
    """
    Queries the freebusy.query endpoint for each configured calendar ID.
    This only ever returns opaque busy/free time ranges -- Google's API
    does not include event titles or details in this response, regardless
    of the access level (owner, reader, or freeBusyReader) granted on the
    source calendar. That makes it a good fit for privacy-scoped syncing.
    """
    service = build("calendar", "v3", credentials=creds)
    now = datetime.now(timezone.utc)
    time_min = now.isoformat()
    time_max = (now + timedelta(days=lookahead_days)).isoformat()

    body = {
        "timeMin": time_min,
        "timeMax": time_max,
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


def sync_busy_blocks(calendar: caldav.Calendar, busy_blocks: List[dict], uid_prefix: str, state_path: Path, dry_run: bool) -> None:
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

    to_create = desired_fps - existing_fps
    to_delete = existing_fps - desired_fps
    unchanged = desired_fps & existing_fps

    for fp in to_delete:
        uid = state[fp]["uid"]
        if dry_run:
            logging.info("[dry-run] would delete stale block (uid=%s)", uid)
        else:
            try:
                event = calendar.event_by_uid(uid)
                event.delete()
            except Exception as exc:
                logging.warning("Could not delete uid=%s (may already be gone): %s", uid, exc)
            del state[fp]

    for fp in to_create:
        # Never derived from content, never reused -- see module-level
        # comment above on why that matters for Nextcloud's trash bin.
        uid = f"{uid_prefix}{uuid.uuid4().hex[:16]}"
        start = desired[fp]["start"]
        end = desired[fp]["end"]
        if dry_run:
            logging.info("[dry-run] would create uid=%s: %s -> %s", uid, start, end)
        else:
            calendar.save_event(_build_ical(uid, start, end))
            state[fp] = {"uid": uid}

    logging.info(
        "Reconcile complete: %d created, %d deleted, %d unchanged",
        len(to_create), len(to_delete), len(unchanged),
    )

    if not dry_run:
        _save_state(state_path, state)


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

    logging.info("Querying free/busy for: %s", ", ".join(cfg.google_calendar_ids))
    busy_blocks = fetch_busy_blocks(creds, cfg.google_calendar_ids, cfg.lookahead_days)

    logging.info("Connecting to Nextcloud calendar at %s", cfg.nextcloud_calendar_url)
    calendar = connect_nextcloud_calendar(cfg)

    sync_busy_blocks(calendar, busy_blocks, cfg.sync_uid_prefix, cfg.sync_state_path, args.dry_run)

    logging.info("Sync complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
