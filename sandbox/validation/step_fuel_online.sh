#!/bin/bash
# Step 3c: Add PLAYER_A as sponsor
# Step 6b: Deposit fuel into NWN (sponsored tx with PLAYER_A as gas-sponsor)
# Step 7: Bring NWN online
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
GOVERNOR_CAP=0xf8e599b2dfa05df8235bb13da150ccaea28e24b3b80504c7d2774a513b164bfd
ADMIN_ACL=0x1e83339450703266605be88b25e16421fde63c25adc370bd3169ee673fdf4429
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
NWN_ID=0xb045ce813b60f21ccc97efda39668b8b00315aa0b7f500adbab191e771dfc19c
NWN_OWNER_CAP=0x1a5e8ff78244f0586dac24075b914fe6b90a7ffd0f8b5476a1b1d8ba2eac20c7
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe
PLAYER_A_ADDR=0x075c99b3eedd7ae54e41b2e8ed61a5069c28742c381bf313b9a254c5ad07ee1c

echo "Step 3c: PLAYER_A already added as sponsor — skipping"

echo ""
echo "Step 6b: Deposit fuel (PLAYER_A as gas-sponsor)"
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" "@${NWN_OWNER_CAP}" \
  --assign borrow_result \
  --move-call "${WORLD_PKG}::network_node::deposit_fuel" \
    "@${NWN_ID}" "@${ADMIN_ACL}" borrow_result.0 \
    1u64 1u64 100000u64 @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::network_node::NetworkNode>" \
    "@${CHARACTER_ID}" borrow_result.0 borrow_result.1 \
  --gas-sponsor "@${PLAYER_A_ADDR}" \
  --gas-budget 100000000 \
  --json > /tmp/step6b.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step6b.json

echo ""
echo "Step 7: NWN online (no sponsor needed for online)"
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
