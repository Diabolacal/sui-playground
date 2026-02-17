#!/bin/bash
# Step 10: Bring both gates online
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
NWN_ID=0xb045ce813b60f21ccc97efda39668b8b00315aa0b7f500adbab191e771dfc19c
ENERGY_CONFIG=0x4b889dc5dac92e1b2b8fba4451d589782de914d040138e7728d08fcfab6661b0

GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
GATE_A_CAP=0xb3cd16e364d22249096858b44dc8009ca7c4379d763b3d615f6d744eca8b4a00
GATE_B_CAP=0x89183fcb02c940b2eac1a94aa099602d00882e11fa44ae31c82042b0d95b9a41

echo "Step 10a: Gate A online"
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
  --assign ba \
  --move-call "${WORLD_PKG}::gate::online" \
    "@${GATE_A}" "@${NWN_ID}" "@${ENERGY_CONFIG}" ba.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" ba.0 ba.1 \
  --gas-budget 100000000 \
  --json > /tmp/step10a.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step10a.json

echo ""
echo "Step 10b: Gate B online"
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
  --assign bb \
  --move-call "${WORLD_PKG}::gate::online" \
    "@${GATE_B}" "@${NWN_ID}" "@${ENERGY_CONFIG}" bb.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" bb.0 bb.1 \
  --gas-budget 100000000 \
  --json > /tmp/step10b.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step10b.json
