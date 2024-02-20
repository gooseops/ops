## Ansible
This will be the root of all ansible playbooks, roles, scripts, templates, etc.  All things ansible will live here.

### Directory Structure
The structure of this `ansible` directory will align with Ansible best practices and be as follows
    - Inventory files will be at the root of this directory
    - `group_vars` will be a directory at the root of this directory containt group variable files
    - `host_vars` will be a directory at the root of this directory containt host variable files
    - `library` will be a directory at the root of this directory for any custom modules
    - `module_utils` will be a directory at the root of this directory for any custom module_utils
    - `filter_plugins` will be a directory for any custom filter plugins
    - Master Playbooks will be at the root of this directory
    - `roles` will be directory in this directory and each role will have its own directory in the `ansible/roles` directory

