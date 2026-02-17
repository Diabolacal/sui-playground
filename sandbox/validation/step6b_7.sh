#!/bin/bash
# Step 6b: Deposit fuel into NWN, then Step 7: bring NWN online
# Both require sponsored tx
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
NWN_ID=0xb045ce813b60f21ccc97efda39668b8b00315aa0b7f500adbab191e771dfc19c
NWN_OWNER_CAP=0x1a5e8ff78244f0586dac24075b914fe6b90a7ffd0f8b5476a1b1d8ba2eac20c7
ADMIN_ACL=0x1e83339450703266605be88b25e16421fde63c25adc370bd3169ee673fdf4429
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe

echo "Step 6b: Deposit fuel (sponsored tx)"
# deposit_fuel requires sponsor because it calls verify_sponsor
# Use --gas-sponsor to self-sponsor
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" "@${NWN_OWNER_CAP}" \
  --assign borrow_result \
  --move-call "${WORLD_PKG}::network_node::deposit_fuel" \
    "@${NWN_ID}" "@${ADMIN_ACL}" borrow_result.0 \
    1u64 100u64 500000u64 @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" borrow_result.0 borrow_result.1 \
  --gas-sponsor "@${ADMIN_ADDR}" \
  --gas-budget 100000000 \
  --json > /tmp/step6b.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step6b.json

echo ""
echo "Step 7: NWN online (sponsored tx)"
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" "@${NWN_OWNER_CAP}" \
  --assign borrow_result \
  --move-call "${WORLD_PKG}::network_node::online" \
    "@${NWN_ID}" borrow_result.0 @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" borrow_result.0 borrow_result.1 \
  --gas-budget 100000000 \
  --json > /tmp/step7.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step7.json
