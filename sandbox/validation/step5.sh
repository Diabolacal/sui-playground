#!/bin/bash
# Step 5: Create and share character
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
ADMIN_CAP=0x5f72ed01230a904bf76497ae97a5ea58b2411a7e7ba84b5552990c8e12954559
OBJECT_REGISTRY=0x56a5c94eb14c9187fc47d0ee70261c6802fea7e8f8e6d13ebb4be23755b9bad3
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe

echo "Step 5a: Create character (game_id=1, tenant=EVE, tribe=1)"
sui client call \
  --package "$WORLD_PKG" --module character --function create_character \
  --args "$OBJECT_REGISTRY" "$ADMIN_CAP" 1 "EVE" 1 "$ADMIN_ADDR" "TestPilot" \
  --gas-budget 100000000 --json > /tmp/step5a.json 2>&1

python3 /workspace/sandbox/parse_step.py /tmp/step5a.json Character OwnerCap

# Extract CHARACTER_ID for next steps
CHARACTER_ID=$(python3 -c "
import json
data = json.load(open('/tmp/step5a.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    op = c.get('idOperation', '')
    if op == 'CREATED' and '::character::Character' in ot and 'OwnerCap' not in ot:
        print(c['objectId'])
        break
")
echo "CHARACTER_ID=$CHARACTER_ID"

echo ""
echo "Step 5b: Share character"
sui client call \
  --package "$WORLD_PKG" --module character --function share_character \
  --args "$CHARACTER_ID" "$ADMIN_CAP" \
  --gas-budget 50000000 --json > /tmp/step5b.json 2>&1

python3 /workspace/sandbox/parse_step.py /tmp/step5b.json
echo "Character shared."
