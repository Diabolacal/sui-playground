#!/bin/bash
# Step 3: ACL & Server Registration
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
GOVERNOR_CAP=0xf8e599b2dfa05df8235bb13da150ccaea28e24b3b80504c7d2774a513b164bfd
ADMIN_ACL=0x1e83339450703266605be88b25e16421fde63c25adc370bd3169ee673fdf4429
SERVER_REGISTRY=0x7df06997b37c8d2393d75090c8c5b1fcf122bc6d8d72690a9684341cb03d2168
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe

echo "Step 3a: Add ADMIN as sponsor"
sui client call \
  --package "$WORLD_PKG" --module access --function add_sponsor_to_acl \
  --args "$ADMIN_ACL" "$GOVERNOR_CAP" "$ADMIN_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3a.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step3a.json

echo ""
echo "Step 3b: Register server address"
# Derive server address from deterministic key
SERVER_PRIVKEY_HEX="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
cp /workspace/sandbox/derive_server_address.mjs /tmp/derive_server_address.mjs
SERVER_ADDR=$(cd /tmp && node derive_server_address.mjs "$SERVER_PRIVKEY_HEX")
echo "SERVER_ADDR=$SERVER_ADDR"

sui client call \
  --package "$WORLD_PKG" --module access --function register_server_address \
  --args "$SERVER_REGISTRY" "$GOVERNOR_CAP" "$SERVER_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3b.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step3b.json
