## Ansible
Ansible is a software tool that provides simple but powerful automation for cross-platform computer support. It is primarily intended for IT professionals, who use it for application deployment, updates on workstations and servers, cloud provisioning, configuration management, intra-service orchestration, and nearly anything a systems administrator does on a weekly or daily basis. Ansible doesn't depend on agent software and has no additional security infrastructure, so it's easy to deploy. See official [docs](docs.ansible.com) for more information regarding Ansible.

### Purpose
This directory will be the root of all things ansible - playbooks, roles, scripts, templates, etc.

### Directory Structure
The structure of this `ansible` directory will align with Ansible best practices and be as follows
- `inventory` would normally be a directory at the root of this directory and contain configurations for group_vars and host_vars and dynamic inventories. These files typically contains sensitive information and so will not be pushed to public source control.
  - `group_vars` will be a directory under this directory containt group variable files
  - `host_vars` will be a directory under this this directory containt host variable files
- `roles` will be directory in this directory and each role will have its own directory in the `ansible/roles` directory
- Master Playbooks will be at the root of this directory
