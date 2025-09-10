lint:
  #!/usr/bin/env bash
  set -euo pipefail
  ansible-lint ansible/
  cd ../terraform/
  tflint

apply:
  #!/usr/bin/env bash
  set -euo pipefail
  cd terraform/worlds/${WORLDS_DIR}/world-00/
  terraform apply

init-upgrade:
  #!/usr/bin/env bash
  set -euo pipefail
  cd terraform/worlds/${WORLDS_DIR}/world-00/
  terraform init -upgrade

output:
  #!/usr/bin/env bash
  set -euo pipefail
  cd terraform/worlds/${WORLDS_DIR}/world-00/
  terraform output

init:
  #!/usr/bin/env bash
  set -euo pipefail
  for world in $(ls -d terraform/worlds/*/); do
    cd $world && terraform init || true
  done

plan:
  #!/usr/bin/env bash
  set -euxo pipefail
  cd terraform/worlds/local/world-00/
  terraform plan
