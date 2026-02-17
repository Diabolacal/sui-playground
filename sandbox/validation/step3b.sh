#!/bin/bash
# Step 3b only: Register server address
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
GOVERNOR_CAP=0xf8e599b2dfa05df8235bb13da150ccaea28e24b3b80504c7d2774a513b164bfd
SERVER_REGISTRY=0x7df06997b37c8d2393d75090c8c5b1fcf122bc6d8d72690a9684341cb03d2168

SERVER_PRIVKEY_HEX="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
cp /workspace/sandbox/derive_server_address.mjs /tmp/derive_server_address.mjs
SERVER_ADDR=$(cd /tmp && node derive_server_address.mjs "$SERVER_PRIVKEY_HEX")
echo "SERVER_ADDR=$SERVER_ADDR"

echo "Step 3b: Register server address"
sui client call \
  --package "$WORLD_PKG" --module access --function register_server_address \
  --args "$SERVER_REGISTRY" "$GOVERNOR_CAP" "$SERVER_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3b.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step3b.json
