lint:
  #!/usr/bin/env bash
  set -euo pipefail
  tflint --chdir=terraform/ --recursive
  ansible-lint ansible/
