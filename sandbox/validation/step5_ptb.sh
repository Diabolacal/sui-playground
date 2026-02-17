#!/bin/bash
# Step 5: Create and share character using PTB
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
ADMIN_CAP=0x5f72ed01230a904bf76497ae97a5ea58b2411a7e7ba84b5552990c8e12954559
OBJECT_REGISTRY=0x56a5c94eb14c9187fc47d0ee70261c6802fea7e8f8e6d13ebb4be23755b9bad3
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe

echo "Step 5: Create + share character via PTB"
sui client ptb \
  --move-call "${WORLD_PKG}::character::create_character" \
    "@${OBJECT_REGISTRY}" "@${ADMIN_CAP}" 1 '"EVE"' 1 "@${ADMIN_ADDR}" '"TestPilot"' \
  --assign character \
  --move-call "${WORLD_PKG}::character::share_character" \
    character "@${ADMIN_CAP}" \
  --gas-budget 100000000 \
  --json > /tmp/step5.json 2>&1

python3 /workspace/sandbox/parse_step.py /tmp/step5.json Character OwnerCap
