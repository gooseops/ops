# incus-image-pin role

Refreshes a locally-pinned Incus VM image, deliberately decoupled from
whatever the upstream image alias currently points at.

## Why pin at all

Incus image aliases like `images:debian/13/cloud` track a moving upstream
target — the fingerprint behind that alias changes over time as the
distro publishes new cloud images. Provisioning VMs directly against the
live alias means a `terraform apply` today and one next month can
silently pull different underlying images, with no record of what
changed. Pinning a local copy (`incus image copy ... --auto-update=false`)
freezes the fingerprint until this role runs again — image refreshes
become a deliberate, auditable action instead of an invisible side effect
of the next apply.

## Usage

Run against exactly one cluster member (a dedicated `[image_builders]`
inventory group is a reasonable pattern, but not required by the role
itself). Incus replicates the pinned image to other cluster members
lazily on first use — no need to run this per-host.

`incus_image_pin_alias` (default: `debian-13`, see `defaults/main.yml`) is
the name the Incus Terraform module's `image` variable should reference —
that variable has no default on purpose, so whatever alias you pin here
is the value a consumer passes in.

## Gotcha

`--vm` is required on the `incus image copy` call. Without it, the
command defaults to the *container* variant of the same alias — same
name, different image, silently useless for VM instances.
