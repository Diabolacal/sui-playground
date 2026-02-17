#!/bin/bash
# Step 6: Create and share NetworkNode via PTB
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
ADMIN_CAP=0x5f72ed01230a904bf76497ae97a5ea58b2411a7e7ba84b5552990c8e12954559
OBJECT_REGISTRY=0x56a5c94eb14c9187fc47d0ee70261c6802fea7e8f8e6d13ebb4be23755b9bad3
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9

LOCATION_HASH_HEX="16217de8ec7330ec3eac32831df5c9cd9b21a255756a5fd5762dd7f49f6cc049"
LOCATION_VEC=$(echo "$LOCATION_HASH_HEX" | sed 's/\(..\)/0x\1,/g' | sed 's/,$//')
NWN_TYPE_ID=111000

echo "Step 6: Create + share NetworkNode via PTB"
echo "Location vector bytes: ${#LOCATION_HASH_HEX} hex chars -> $(( ${#LOCATION_HASH_HEX} / 2 )) bytes"

# NetworkNode only has 'key' ability, so must use PTB
sui client ptb \
  --move-call "${WORLD_PKG}::network_node::anchor" \
    "@${OBJECT_REGISTRY}" "@${CHARACTER_ID}" "@${ADMIN_CAP}" \
    100u64 ${NWN_TYPE_ID}u64 "vector[$LOCATION_VEC]" \
    1000000u64 60000u64 1000u64 \
  --assign nwn \
  --move-call "${WORLD_PKG}::network_node::share_network_node" \
    nwn "@${ADMIN_CAP}" \
  --gas-budget 100000000 \
  --json > /tmp/step6.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step6.json
