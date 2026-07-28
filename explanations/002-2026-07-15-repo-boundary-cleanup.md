# Public Repo Boundary: Boilerplate Here, Homelab Specifics Elsewhere

## Overview

This session started as an infrastructure strategy planning exercise and ended up establishing a firmer rule for what belongs in this repository at all. A hypervisor migration decision, a network segmentation decision, a network design document, and a step by step migration runbook were all drafted here first, then relocated to the maintainer's separate private repository once the maintainer pointed out that this repository is meant to be a public, reusable boilerplate showcase, and none of that content, tied as it is to specific host names, specific hardware constraints, and one particular homelab's topology, belongs in a repository meant for strangers to read and reuse.

## Why This Exists

This repository's whole reason for existing, stated plainly in its own read me file, is to be boilerplate. Terraform modules and Ansible roles here are meant to be generic enough that someone unrelated to the maintainer could look at them and understand a reusable pattern, or even adapt them for their own infrastructure. Mixing that reusable code with a narrative about exactly which physical machines the maintainer owns, how many solid state drives they have on hand, and the exact sequence they plan to reimage those two specific machines in, undermines that goal in two ways: it clutters the reusable material with irrelevant specifics, and it puts information about the maintainer's actual home network into a public, indexed repository that anyone can read.

The maintainer already had a mechanism in place for exactly this kind of separation, two directories in this repository that are actually symbolic links pointing into a separate, private repository, keeping real inventory data and real Terraform state out of git history here. What hadn't happened yet was extending that same discipline to planning documents and decision records, which is easy to overlook since writing a document doesn't feel like committing a secret the way pasting a real IP address into a committed file does.

## Technical Decisions

The dividing line settled on is straightforward: if a stranger could pick up a piece of content without knowing anything about this specific homelab and still get value from it, meaning a reusable role, a reusable module, or genuinely generic design reasoning about how that role or module is built, it stays here. If a piece of content only makes sense with knowledge of this particular homelab, meaning specific host names, specific hardware and storage constraints, or the specific order operations happen in against two particular machines, it moves to the private repository.

Applying that line to what had been drafted this session: the decision to migrate from one virtualization platform to another, the network segmentation model, the network design document, and the migration runbook all moved out entirely, since every one of them named specific hosts or specific hardware limitations. What stayed here, reframed, is the underlying engineering work still owed to this repository itself: porting three pieces of configuration management automation and one infrastructure provisioning module from the maintainer's other, fully private production repository, written generically enough that they don't assume any particular hostname, address range, or storage layout. That's legitimately boilerplate work, distinct from the maintainer's own plan to actually run it against real hardware.

## Dependencies

The private repository previously held only raw configuration data, meaning host inventory and live infrastructure state, with no planning documents of its own. This session gave it a first formal plan document, a first decisions folder, a first network design document, a first runbooks folder, and a first session changelog folder, mirroring the structure already used here, so that future work in that repository follows the same discipline this repository already follows.

## How It Fits Together

Going forward, this repository's own plan document tracks only the roadmap for the reusable roles and modules themselves, not any particular consumer's use of them. The private repository's plan document tracks the maintainer's actual homelab topology, its migration timeline, and its open hardware questions. A short note was added to this repository's own guidance file describing the boundary explicitly, so future work defaults to asking which repository a given piece of content belongs in before writing it, rather than writing everything in whichever repository happens to be open at the time.

## Gotchas

The two repositories sit right next to each other on the same machine, which makes it easy, out of habit, to keep drafting homelab-specific narrative content into this public repository without noticing, especially mid-session when both repositories already feel present in the working context. Worth a deliberate check, every time new planning content gets written, about which repository it actually belongs in.

## What's Next

The immediate next step for this repository specifically is the role and module porting work itself: bringing over the virtualization host role, the pinned image refresh role, and the host firewall role, along with the equivalent provisioning module, all written generically. Once that lands here, the maintainer's actual migration execution, tracked entirely in the private repository now, can begin.
