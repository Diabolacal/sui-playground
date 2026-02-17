#!/bin/bash
# Step 11: Create, publish test extension & authorize on both gates
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9

GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
GATE_A_CAP=0xb3cd16e364d22249096858b44dc8009ca7c4379d763b3d615f6d744eca8b4a00
GATE_B_CAP=0x89183fcb02c940b2eac1a94aa099602d00882e11fa44ae31c82042b0d95b9a41

# --- 11a: Create test extension package ---
echo "Step 11a: Creating test extension package..."

mkdir -p /tmp/test_extension/sources

# Get chain-id from world package's Pub.local.toml
CHAIN_ID=$(grep 'chain-id' /workspace/world-contracts/world/Pub.local.toml | head -1 | tr -d '"' | awk '{print $NF}')

cat > /tmp/test_extension/Move.toml <<MOVETOML
[package]
name = "test_extension"
edition = "2024"

[dependencies]
world = { local = "/workspace/world-contracts/world" }

[environments]
local = "${CHAIN_ID}"
MOVETOML

cat > /tmp/test_extension/sources/test_gate_ext.move <<'MOVESRC'
module test_extension::test_gate_ext;

use sui::clock::Clock;
use world::{
    character::Character,
    gate::{Self, Gate},
};

/// Witness type — only this module can instantiate it
public struct TestAuth has drop {}

/// Shared rules object (minimal — no custom rules)
public struct TestGateRules has key {
    id: UID,
}

/// Admin cap for this extension
public struct ExtAdminCap has key, store {
    id: UID,
}

/// Issue a jump permit with 1-hour expiry (no custom checks)
public fun issue_permit(
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    _admin: &ExtAdminCap,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let expires_at_timestamp_ms = clock.timestamp_ms() + 60 * 60 * 1000;
    gate::issue_jump_permit<TestAuth>(
        source_gate,
        destination_gate,
        character,
        TestAuth {},
        expires_at_timestamp_ms,
        ctx,
    );
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(ExtAdminCap { id: object::new(ctx) }, ctx.sender());
    transfer::share_object(TestGateRules { id: object::new(ctx) });
}
MOVESRC

echo "Test extension package created."

# --- 11b: Publish test extension ---
echo ""
echo "Step 11b: Publishing test extension..."
cd /tmp/test_extension

# Clean any stale files
rm -f Pub.local.toml Move.lock

# Create Pub.local.toml that tells publish about already-published World dependency
cat > /tmp/test_extension/Pub.local.toml <<PUBTOML
build-env = "local"
chain-id = "${CHAIN_ID}"

[[published]]
source = { local = "/workspace/world-contracts/world" }
published-at = "${WORLD_PKG}"
original-id = "${WORLD_PKG}"
version = 1
toolchain-version = "1.65.2"
build-config = { flavor = "sui", edition = "2024" }
upgrade-capability = "0x6060eeb6159d064d4576143e32d513e5506054b08127fea14986c3ce40c1630b"
PUBTOML

sui client test-publish --build-env local --gas-budget 500000000 --json 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
# Find first '{' to skip build output lines
idx = raw.index('{')
data = json.loads(raw[idx:])
json.dump(data, open('/tmp/step11b.json','w'))
"
python3 /workspace/sandbox/extract_objects.py /tmp/step11b.json

# Extract extension package ID
EXT_PKG=$(python3 -c "
import json
data = json.load(open('/tmp/step11b.json'))
changes = data.get('objectChanges', data.get('effects',{}).get('changed_objects',[]))
for c in changes:
    if c.get('type') == 'published':
        print(c['packageId'])
        break
")

# Extract ExtAdminCap ID
EXT_ADMIN_CAP=$(python3 -c "
import json
data = json.load(open('/tmp/step11b.json'))
changes = data.get('objectChanges', data.get('effects',{}).get('changed_objects',[]))
for c in changes:
    if c.get('type') == 'created' and 'ExtAdminCap' in c.get('objectType',''):
        print(c['objectId'])
        break
")

echo "EXT_PKG=${EXT_PKG}"
echo "EXT_ADMIN_CAP=${EXT_ADMIN_CAP}"

# --- 11c: Authorize extension on Gate A ---
echo ""
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
  --json > /tmp/step11c.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step11c.json

# --- 11d: Authorize extension on Gate B ---
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
  --json > /tmp/step11d.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step11d.json

echo ""
echo "=== Extension authorized on both gates ==="
echo "EXT_PKG=${EXT_PKG}"
echo "EXT_ADMIN_CAP=${EXT_ADMIN_CAP}"
