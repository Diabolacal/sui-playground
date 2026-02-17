#!/bin/bash
# Step 11c/d: Authorize extension on both gates
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9

GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
GATE_A_CAP=0xb3cd16e364d22249096858b44dc8009ca7c4379d763b3d615f6d744eca8b4a00
GATE_B_CAP=0x89183fcb02c940b2eac1a94aa099602d00882e11fa44ae31c82042b0d95b9a41

EXT_PKG=0x71edd82b91e4256472987b853cfab3ccf6c97a01d9e000a5abc0744984e7aa81

echo "Step 11c: Authorize extension on Gate A..."
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
  --assign ba \
  --move-call "${WORLD_PKG}::gate::authorize_extension<${EXT_PKG}::test_gate_ext::TestAuth>" \
    "@${GATE_A}" ba.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" ba.0 ba.1 \
  --gas-budget 100000000 \
  --json 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
idx = raw.index('{')
data = json.loads(raw[idx:])
json.dump(data, open('/tmp/step11c.json','w'))
"
python3 /workspace/sandbox/extract_objects.py /tmp/step11c.json

echo ""
echo "Step 11d: Authorize extension on Gate B..."
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
  --assign bb \
  --move-call "${WORLD_PKG}::gate::authorize_extension<${EXT_PKG}::test_gate_ext::TestAuth>" \
    "@${GATE_B}" bb.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" bb.0 bb.1 \
  --gas-budget 100000000 \
  --json 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
idx = raw.index('{')
data = json.loads(raw[idx:])
json.dump(data, open('/tmp/step11d.json','w'))
"
python3 /workspace/sandbox/extract_objects.py /tmp/step11d.json

echo ""
echo "=== Extension authorized on both gates ==="
