#!/bin/bash
# Step 2: Create AdminCap
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
GOVERNOR_CAP=0xf8e599b2dfa05df8235bb13da150ccaea28e24b3b80504c7d2774a513b164bfd
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe

echo "Step 2: Create AdminCap"
sui client call \
  --package "$WORLD_PKG" --module access --function create_admin_cap \
  --args "$GOVERNOR_CAP" "$ADMIN_ADDR" \
  --gas-budget 50000000 --json > /tmp/step2.json 2>&1

python3 /workspace/sandbox/parse_step.py /tmp/step2.json AdminCap
