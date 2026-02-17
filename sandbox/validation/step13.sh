#!/bin/bash
# Step 13: Jump with permit (sponsored transaction)
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1

CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
ADMIN_ACL=0x1e83339450703266605be88b25e16421fde63c25adc370bd3169ee673fdf4429
PERMIT_ID=0xc473eefcf5d30e222cdac1913f2e68c34fdb33ca56a750b049cb5120cef8c012

# PLAYER_A as sponsor (already in ACL)
PLAYER_A_ADDR=0x075c99b3eedd7ae54e41b2e8ed61a5069c28742c381bf313b9a254c5ad07ee1c

CLOCK=0x6

echo "Step 13: Jump with permit (Gate A -> Gate B, sponsored)"
# jump_with_permit requires sponsored tx (verify_sponsor)
# JumpPermit is consumed (single-use)
sui client ptb \
  --move-call "${WORLD_PKG}::gate::jump_with_permit" \
    "@${GATE_A}" "@${GATE_B}" "@${CHARACTER_ID}" "@${PERMIT_ID}" "@${ADMIN_ACL}" "@${CLOCK}" \
  --gas-budget 100000000 \
  --gas-sponsor "@${PLAYER_A_ADDR}" \
  --json 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
idx = raw.index('{')
data = json.loads(raw[idx:])
json.dump(data, open('/tmp/step13.json','w'))
"
python3 /workspace/sandbox/extract_objects.py /tmp/step13.json

echo ""
echo "=== FULL GATE LIFECYCLE COMPLETE ==="
