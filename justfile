# Run code quality checks on Terraform and Ansible configurations
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    tflint --chdir=terraform/ --recursive
    ansible-lint ansible/

# Format Terraform and Ansible configurations to follow style guidelines
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    ansible-lint ansible/ --fix
    terraform -chdir=terraform/ fmt -recursive

# Generate and list the inventory of Ansible hosts for the specified environment
inventory:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible/
    ansible-inventory --list

# Generate a graph representation of the Ansible inventory for the specified environment
inventory-graph:
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible/
    ansible-inventory --graph

# Deploy an Ansible playbook by playbook name
deploy playbook="noop":
    #!/usr/bin/env bash
    set -euo pipefail
    cd ansible/
    doppler run --command 'ansible-playbook {{playbook}}.playbook.yml'
