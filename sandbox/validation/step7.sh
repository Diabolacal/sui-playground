#!/bin/bash
# Step 7: Bring NetworkNode online (PTB with OwnerCap borrow/return)
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
NWN_ID=0xb045ce813b60f21ccc97efda39668b8b00315aa0b7f500adbab191e771dfc19c
NWN_OWNER_CAP=0x1a5e8ff78244f0586dac24075b914fe6b90a7ffd0f8b5476a1b1d8ba2eac20c7

echo "Step 7: NWN online via PTB (borrow_owner_cap -> online -> return_owner_cap)"

# OwnerCap<NWN> lives inside the Character object.
# Borrow it, use it, return it.
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
