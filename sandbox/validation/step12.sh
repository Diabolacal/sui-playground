#!/bin/bash
# Step 12: Issue a jump permit via test extension
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
EXT_PKG=0x71edd82b91e4256472987b853cfab3ccf6c97a01d9e000a5abc0744984e7aa81

CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
EXT_ADMIN_CAP=0x3ae6e6bf6e327c006ebaf4b03e94d2659d23647ccc57639ef334308edb5cb6d4

# Clock is always 0x6 on Sui
CLOCK=0x6

echo "Step 12: Issue jump permit (Gate A -> Gate B)"
# The extension's issue_permit calls gate::issue_jump_permit internally
# The permit is transferred directly to the character's address
sui client ptb \
  --move-call "${EXT_PKG}::test_gate_ext::issue_permit" \
    "@${GATE_A}" "@${GATE_B}" "@${CHARACTER_ID}" "@${EXT_ADMIN_CAP}" "@${CLOCK}" \
  --gas-budget 100000000 \
  --json 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
idx = raw.index('{')
data = json.loads(raw[idx:])
json.dump(data, open('/tmp/step12.json','w'))
"
python3 /workspace/sandbox/extract_objects.py /tmp/step12.json

# Extract the JumpPermit object ID
PERMIT_ID=$(python3 -c "
import json
data = json.load(open('/tmp/step12.json'))
changes = data.get('objectChanges', [])
for c in changes:
    if c.get('type') == 'created' and 'JumpPermit' in c.get('objectType',''):
        print(c['objectId'])
        break
")
echo ""
echo "PERMIT_ID=${PERMIT_ID}"
