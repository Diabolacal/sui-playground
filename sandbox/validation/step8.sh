#!/bin/bash
# Step 8: Anchor and share two gates via PTB
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
ADMIN_CAP=0x5f72ed01230a904bf76497ae97a5ea58b2411a7e7ba84b5552990c8e12954559
OBJECT_REGISTRY=0x56a5c94eb14c9187fc47d0ee70261c6802fea7e8f8e6d13ebb4be23755b9bad3
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
NWN_ID=0xb045ce813b60f21ccc97efda39668b8b00315aa0b7f500adbab191e771dfc19c

LOCATION_HASH_HEX="16217de8ec7330ec3eac32831df5c9cd9b21a255756a5fd5762dd7f49f6cc049"
LOCATION_VEC=$(echo "$LOCATION_HASH_HEX" | sed 's/\(..\)/0x\1,/g' | sed 's/,$//')
GATE_TYPE_ID=8888

echo "Step 8a: Anchor + share Gate A (item_id=1001)"
sui client ptb \
  --move-call "${WORLD_PKG}::gate::anchor" \
    "@${OBJECT_REGISTRY}" "@${NWN_ID}" "@${CHARACTER_ID}" "@${ADMIN_CAP}" \
    1001u64 ${GATE_TYPE_ID}u64 "vector[$LOCATION_VEC]" \
  --assign gate_a \
  --move-call "${WORLD_PKG}::gate::share_gate" \
    gate_a "@${ADMIN_CAP}" \
  --gas-budget 100000000 \
  --json > /tmp/step8a.json 2>&1

echo "Gate A result:"
python3 /workspace/sandbox/extract_objects.py /tmp/step8a.json

echo ""
echo "Step 8b: Anchor + share Gate B (item_id=1002)"
sui client ptb \
  --move-call "${WORLD_PKG}::gate::anchor" \
    "@${OBJECT_REGISTRY}" "@${NWN_ID}" "@${CHARACTER_ID}" "@${ADMIN_CAP}" \
    1002u64 ${GATE_TYPE_ID}u64 "vector[$LOCATION_VEC]" \
  --assign gate_b \
  --move-call "${WORLD_PKG}::gate::share_gate" \
    gate_b "@${ADMIN_CAP}" \
  --gas-budget 100000000 \
  --json > /tmp/step8b.json 2>&1

echo "Gate B result:"
python3 /workspace/sandbox/extract_objects.py /tmp/step8b.json
