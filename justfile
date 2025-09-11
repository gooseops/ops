# Run code quality checks on Terraform and Ansible configurations
lint:
  #!/usr/bin/env bash
  set -euo pipefail
  tflint --chdir=terraform/ --recursive
  ansible-lint ansible/
  ansible-lint ansible/

# Format Terraform and Ansible configurations to follow style guidelines
fmt:
  #!/usr/bin/env bash
  set -euo pipefail
  ansible-lint ansible/ --fix
  terraform -chdir=terraform/ fmt -recursive
