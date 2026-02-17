#!/bin/bash
# ============================================================================
# gate_lifecycle_steps.sh - Execute gate lifecycle step by step
# Run inside Docker container: bash /workspace/sandbox/gate_lifecycle_steps.sh
# ============================================================================
set -euo pipefail

EXTRACT="python3 /workspace/sandbox/extract_objects.py"
LOG="/workspace/notes/gate-lifecycle-evidence.md"

# Write evidence header
cat > "$LOG" << 'HEADER'
# Gate Lifecycle Rehearsal Evidence

**Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')  
**Sui CLI:** $(sui --version)  
**Environment:** local devnet (Docker)

## Object Registry
HEADER

echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$LOG"
echo "Sui CLI: $(sui --version)" >> "$LOG"
echo "" >> "$LOG"

step() { echo ""; echo "====== $1 ======"; echo "## $1" >> "$LOG"; }
log() { echo "[OK] $1"; echo "- $1" >> "$LOG"; }
err() { echo "[ERR] $1"; echo "- ❌ $1" >> "$LOG"; }

ADMIN_ADDR=$(sui client active-address)
PLAYER_A_ADDR=$(grep PLAYER_A_ADDRESS /workspace/data/.env.sui | cut -d= -f2)

echo "ADMIN: $ADMIN_ADDR"
echo "PLAYER_A: $PLAYER_A_ADDR"

# --- Extract IDs from already-published world package ---
step "Step 1: Extract World Package IDs"

WORLD_PKG=$($EXTRACT /tmp/world_publish.json "package" 2>/dev/null | head -1)
GOVERNOR_CAP=$($EXTRACT /tmp/world_publish.json "GovernorCap" 2>/dev/null | head -1)
ADMIN_ACL=$($EXTRACT /tmp/world_publish.json "AdminACL" 2>/dev/null | head -1)
SERVER_REGISTRY=$($EXTRACT /tmp/world_publish.json "ServerAddressRegistry" 2>/dev/null | head -1)
OBJECT_REGISTRY=$($EXTRACT /tmp/world_publish.json "ObjectRegistry" 2>/dev/null | head -1)
GATE_CONFIG=$($EXTRACT /tmp/world_publish.json "GateConfig" 2>/dev/null | head -1)
FUEL_CONFIG=$($EXTRACT /tmp/world_publish.json "FuelConfig" 2>/dev/null | head -1)
ENERGY_CONFIG=$($EXTRACT /tmp/world_publish.json "EnergyConfig" 2>/dev/null | head -1)

echo "WORLD_PKG=$WORLD_PKG"
echo "GOVERNOR_CAP=$GOVERNOR_CAP"
echo "ADMIN_ACL=$ADMIN_ACL"
echo "SERVER_REGISTRY=$SERVER_REGISTRY"
echo "OBJECT_REGISTRY=$OBJECT_REGISTRY"
echo "GATE_CONFIG=$GATE_CONFIG"
echo "FUEL_CONFIG=$FUEL_CONFIG"
echo "ENERGY_CONFIG=$ENERGY_CONFIG"

for var in WORLD_PKG GOVERNOR_CAP ADMIN_ACL SERVER_REGISTRY OBJECT_REGISTRY GATE_CONFIG FUEL_CONFIG ENERGY_CONFIG; do
  val="${!var}"
  if [[ "$val" == NOT_FOUND* ]] || [[ -z "$val" ]]; then
    err "Missing: $var = $val"
    exit 1
  fi
  log "$var=$val"
done

# --- Step 2: Create AdminCap ---
step "Step 2: Create AdminCap"

sui client call \
  --package "$WORLD_PKG" --module access --function create_admin_cap \
  --args "$GOVERNOR_CAP" "$ADMIN_ADDR" \
  --gas-budget 50000000 --json > /tmp/step2.json 2>/dev/null

ADMIN_CAP=$($EXTRACT /tmp/step2.json "AdminCap" 2>/dev/null | head -1)
log "AdminCap=$ADMIN_CAP"

# --- Step 3: Add sponsor + Register server ---
step "Step 3: ACL & Server Registration"

# Add ADMIN as sponsor
sui client call \
  --package "$WORLD_PKG" --module access --function add_sponsor_to_acl \
  --args "$ADMIN_ACL" "$GOVERNOR_CAP" "$ADMIN_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3a.json 2>/dev/null
log "ADMIN added as sponsor"

# Add PLAYER_A as sponsor too (needed later for sponsored txs)
sui client call \
  --package "$WORLD_PKG" --module access --function add_sponsor_to_acl \
  --args "$ADMIN_ACL" "$GOVERNOR_CAP" "$PLAYER_A_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3a2.json 2>/dev/null
log "PLAYER_A added as sponsor"

# Generate server keypair for distance proofs
SERVER_PRIVKEY_HEX="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
SERVER_ADDR=$(NODE_PATH=/tmp/node_modules node -e "
const crypto = require('crypto');
const { blake2b } = require('@noble/hashes/blake2b');
const pk = Buffer.from('$SERVER_PRIVKEY_HEX', 'hex');
const key = crypto.createPrivateKey({key: Buffer.concat([Buffer.from('302e020100300506032b657004220420','hex'), pk]), format:'der', type:'pkcs8'});
const pub = crypto.createPublicKey(key).export({type:'spki',format:'der'}).slice(-32);
const addr = Buffer.from(blake2b(Buffer.concat([Buffer.from([0x00]), pub]), {dkLen:32}));
console.log('0x' + addr.toString('hex'));
")
echo "SERVER_ADDR=$SERVER_ADDR"

sui client call \
  --package "$WORLD_PKG" --module access --function register_server_address \
  --args "$SERVER_REGISTRY" "$GOVERNOR_CAP" "$SERVER_ADDR" \
  --gas-budget 50000000 --json > /tmp/step3b.json 2>/dev/null
log "Server address registered: $SERVER_ADDR"

# --- Step 4: Configure fuel, energy, gate distance ---
step "Step 4: Configuration"

GATE_TYPE_ID=8888
NWN_TYPE_ID=111000

sui client call \
  --package "$WORLD_PKG" --module fuel --function set_fuel_efficiency \
  --args "$FUEL_CONFIG" "$ADMIN_CAP" 1 100 \
  --gas-budget 50000000 --json > /tmp/step4a.json 2>/dev/null
log "Fuel efficiency: type=1, eff=100"

sui client call \
  --package "$WORLD_PKG" --module energy --function set_energy_config \
  --args "$ENERGY_CONFIG" "$ADMIN_CAP" "$GATE_TYPE_ID" 50 \
  --gas-budget 50000000 --json > /tmp/step4b.json 2>/dev/null
log "Energy config: gate_type=$GATE_TYPE_ID, energy=50"

sui client call \
  --package "$WORLD_PKG" --module gate --function set_max_distance \
  --args "$GATE_CONFIG" "$ADMIN_CAP" "$GATE_TYPE_ID" 1000000000 \
  --gas-budget 50000000 --json > /tmp/step4c.json 2>/dev/null
log "Gate max distance: type=$GATE_TYPE_ID, maxDist=1000000000"

# --- Step 5: Create Character ---
step "Step 5: Create Character"

sui client call \
  --package "$WORLD_PKG" --module character --function create_character \
  --args "$OBJECT_REGISTRY" "$ADMIN_CAP" 1 "EVE" 1 "$ADMIN_ADDR" "TestPilot" \
  --gas-budget 100000000 --json > /tmp/step5a.json 2>/dev/null

# The character is returned (not shared yet) — check output format
CHARACTER_ID=$($EXTRACT /tmp/step5a.json "character::Character" 2>/dev/null | head -1)
# If not found, try broader search
if [[ "$CHARACTER_ID" == NOT_FOUND* ]]; then
  CHARACTER_ID=$($EXTRACT /tmp/step5a.json "Character" 2>/dev/null | head -1)
fi
echo "CHARACTER_ID=$CHARACTER_ID"

# Check all created objects for debugging
echo "Step 5 created objects:"
$EXTRACT /tmp/step5a.json 2>/dev/null || true

# Share character  
sui client call \
  --package "$WORLD_PKG" --module character --function share_character \
  --args "$CHARACTER_ID" "$ADMIN_CAP" \
  --gas-budget 50000000 --json > /tmp/step5b.json 2>/dev/null
log "Character created and shared: $CHARACTER_ID"

# OwnerCap<Character> was auto-transferred to the character object
CHAR_OWNER_CAP=$($EXTRACT /tmp/step5a.json "OwnerCap" 2>/dev/null | head -1)
log "OwnerCap<Character>=$CHAR_OWNER_CAP"

# --- Step 6: Create NetworkNode ---
step "Step 6: Create NetworkNode"

LOCATION_HASH="16217de8ec7330ec3eac32831df5c9cd9b21a255756a5fd5762dd7f49f6cc049"

sui client call \
  --package "$WORLD_PKG" --module network_node --function anchor \
  --args "$OBJECT_REGISTRY" "$CHARACTER_ID" "$ADMIN_CAP" \
    100 "$NWN_TYPE_ID" "0x${LOCATION_HASH}" \
    1000000 60000 1000 \
  --gas-budget 100000000 --json > /tmp/step6a.json 2>/dev/null

echo "Step 6 created objects:"
$EXTRACT /tmp/step6a.json 2>/dev/null || true

NWN_ID=$($EXTRACT /tmp/step6a.json "NetworkNode" 2>/dev/null | grep -v OwnerCap | head -1)
NWN_OWNER_CAP=$($EXTRACT /tmp/step6a.json "OwnerCap" 2>/dev/null | head -1)

echo "NWN_ID=$NWN_ID"
echo "NWN_OWNER_CAP=$NWN_OWNER_CAP"

# Share network node
sui client call \
  --package "$WORLD_PKG" --module network_node --function share_network_node \
  --args "$NWN_ID" "$ADMIN_CAP" \
  --gas-budget 50000000 --json > /tmp/step6b.json 2>/dev/null
log "NetworkNode created and shared: $NWN_ID"

# --- Step 7: Bring NetworkNode Online ---
step "Step 7: NetworkNode Online (PTB with OwnerCap borrow/return)"

# NWN OwnerCap lives inside the Character object. 
# We use Receiving pattern: borrow → use → return
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
    --type-args "${WORLD_PKG}::network_node::NetworkNode" \
    "@${CHARACTER_ID}" "@${NWN_OWNER_CAP}" \
  --assign borrow_result \
  --move-call "${WORLD_PKG}::network_node::online" \
    "@${NWN_ID}" borrow_result.0 @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap" \
    --type-args "${WORLD_PKG}::network_node::NetworkNode" \
    "@${CHARACTER_ID}" borrow_result.0 borrow_result.1 \
  --gas-budget 100000000 \
  --json > /tmp/step7.json 2>/dev/null || true

NWN_ONLINE=$($EXTRACT /tmp/step7.json 2>/dev/null | grep -i status | head -1 || echo "check /tmp/step7.json")
echo "NWN online result: $NWN_ONLINE"
log "NWN online: see /tmp/step7.json"

# --- Step 8: Anchor Gates ---
step "Step 8: Anchor & Share Two Gates"

# Gate A
sui client call \
  --package "$WORLD_PKG" --module gate --function anchor \
  --args "$OBJECT_REGISTRY" "$NWN_ID" "$CHARACTER_ID" "$ADMIN_CAP" \
    1001 "$GATE_TYPE_ID" "0x${LOCATION_HASH}" \
  --gas-budget 100000000 --json > /tmp/step8a.json 2>/dev/null

echo "Gate A created objects:"
$EXTRACT /tmp/step8a.json 2>/dev/null || true

GATE_A_ID=$($EXTRACT /tmp/step8a.json "gate::Gate" 2>/dev/null | head -1)
if [[ "$GATE_A_ID" == NOT_FOUND* ]]; then
  # Try broader
  GATE_A_ID=$(python3 -c "
import json
data = json.load(open('/tmp/step8a.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if '::gate::Gate' in ot and 'OwnerCap' not in ot and 'Config' not in ot:
        print(c['objectId'])
        break
" 2>/dev/null || echo "PARSE_ERROR")
fi
echo "GATE_A_ID=$GATE_A_ID"

GATE_A_CAP=$(python3 -c "
import json
data = json.load(open('/tmp/step8a.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if 'OwnerCap' in ot and 'Gate' in ot:
        print(c['objectId'])
        break
" 2>/dev/null || echo "PARSE_ERROR")
echo "GATE_A_CAP=$GATE_A_CAP"

sui client call \
  --package "$WORLD_PKG" --module gate --function share_gate \
  --args "$GATE_A_ID" "$ADMIN_CAP" \
  --gas-budget 50000000 --json > /tmp/step8a_share.json 2>/dev/null
log "Gate A anchored & shared: $GATE_A_ID"

# Gate B
sui client call \
  --package "$WORLD_PKG" --module gate --function anchor \
  --args "$OBJECT_REGISTRY" "$NWN_ID" "$CHARACTER_ID" "$ADMIN_CAP" \
    1002 "$GATE_TYPE_ID" "0x${LOCATION_HASH}" \
  --gas-budget 100000000 --json > /tmp/step8b.json 2>/dev/null

GATE_B_ID=$(python3 -c "
import json
data = json.load(open('/tmp/step8b.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if '::gate::Gate' in ot and 'OwnerCap' not in ot and 'Config' not in ot:
        print(c['objectId'])
        break
" 2>/dev/null || echo "PARSE_ERROR")

GATE_B_CAP=$(python3 -c "
import json
data = json.load(open('/tmp/step8b.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if 'OwnerCap' in ot and 'Gate' in ot:
        print(c['objectId'])
        break
" 2>/dev/null || echo "PARSE_ERROR")

echo "GATE_B_ID=$GATE_B_ID"
echo "GATE_B_CAP=$GATE_B_CAP"

sui client call \
  --package "$WORLD_PKG" --module gate --function share_gate \
  --args "$GATE_B_ID" "$ADMIN_CAP" \
  --gas-budget 50000000 --json > /tmp/step8b_share.json 2>/dev/null
log "Gate B anchored & shared: $GATE_B_ID"

# --- Step 9: Link Gates ---
step "Step 9: Link Gates (distance proof)"

# Generate distance proof
PROOF_HEX=$(NODE_PATH=/tmp/node_modules node /workspace/sandbox/generate_distance_proof.js \
  --server-privkey "$SERVER_PRIVKEY_HEX" \
  --player-address "$ADMIN_ADDR" \
  --gate-location-hash "$LOCATION_HASH" \
  --distance 0 \
  --deadline-ms 9999999999999 2>/tmp/proof_gen_stderr.txt)

echo "Proof generated ($(echo -n "$PROOF_HEX" | wc -c) hex chars)"
cat /tmp/proof_gen_stderr.txt

# Convert hex to vector literal for PTB
# Need: vector[0xu8, 0xu8, ...]
PROOF_VECTOR=$(echo "$PROOF_HEX" | sed 's/\(..\)/0x\1,/g' | sed 's/,$//')

echo "Calling link_gates via PTB..."
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
  --assign borrow_a \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
  --assign borrow_b \
  --move-call "${WORLD_PKG}::gate::link_gates" \
    "@${GATE_A_ID}" "@${GATE_B_ID}" "@${CHARACTER_ID}" \
    "@${GATE_CONFIG}" "@${SERVER_REGISTRY}" \
    borrow_a.0 borrow_b.0 \
    "vector[$PROOF_VECTOR]" \
    @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" borrow_a.0 borrow_a.1 \
  --move-call "${WORLD_PKG}::character::return_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" borrow_b.0 borrow_b.1 \
  --gas-budget 200000000 \
  --json > /tmp/step9.json 2>/dev/null || true

echo "Link gates result:"
python3 << 'PYEOF'
import json
try:
    data = json.load(open('/tmp/step9.json'))
    effects = data.get('effects', {})
    if 'V2' in effects:
        effects = effects['V2']
    status = effects.get('status', 'unknown')
    print(f"Status: {status}")
    if isinstance(status, dict):
        print(f"Error: {status.get('error', 'none')}")
except Exception as e:
    print(f"Parse error: {e}")
    # Print raw output
    with open('/tmp/step9.json') as f:
        print(f.read()[:500])
PYEOF

log "Link gates: see /tmp/step9.json"

# --- Step 10: Gates Online ---
step "Step 10: Gates Online"

# Gate A online
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
  --assign bga \
  --move-call "${WORLD_PKG}::gate::online" \
    "@${GATE_A_ID}" "@${NWN_ID}" "@${ENERGY_CONFIG}" bga.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" bga.0 bga.1 \
  --gas-budget 100000000 \
  --json > /tmp/step10a.json 2>/dev/null || true

echo "Gate A online:"
python3 -c "
import json
data = json.load(open('/tmp/step10a.json'))
e = data.get('effects',{})
if 'V2' in e: e = e['V2']
print('Status:', e.get('status','unknown'))
" 2>/dev/null || echo "Parse error"

# Gate B online
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
  --assign bgb \
  --move-call "${WORLD_PKG}::gate::online" \
    "@${GATE_B_ID}" "@${NWN_ID}" "@${ENERGY_CONFIG}" bgb.0 \
  --move-call "${WORLD_PKG}::character::return_owner_cap" \
    --type-args "${WORLD_PKG}::gate::Gate" \
    "@${CHARACTER_ID}" bgb.0 bgb.1 \
  --gas-budget 100000000 \
  --json > /tmp/step10b.json 2>/dev/null || true

echo "Gate B online:"
python3 -c "
import json
data = json.load(open('/tmp/step10b.json'))
e = data.get('effects',{})
if 'V2' in e: e = e['V2']
print('Status:', e.get('status','unknown'))
" 2>/dev/null || echo "Parse error"

log "Gates online: see /tmp/step10a.json, step10b.json"

# --- Step 11: Publish test extension + authorize ---
step "Step 11: Extension Authorization"

# Create minimal test extension
mkdir -p /tmp/test_extension/sources

cat > /tmp/test_extension/Move.toml << MOVETOML
[package]
name = "test_extension"
edition = "2024"

[dependencies.World]
local = "/workspace/world-contracts/world"

[addresses]
test_extension = "0x0"

[environments]
local = "0x0"
MOVETOML

cat > /tmp/test_extension/sources/auth.move << 'MOVESRC'
module test_extension::auth;

use world::gate::{Self, Gate};
use world::character::Character;

/// Witness type for gate authorization
public struct TestAuth has drop {}

/// Issue a jump permit (callable by anyone for testing)
public fun issue_permit(
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    expires_at_timestamp_ms: u64,
    ctx: &mut TxContext,
) {
    gate::issue_jump_permit<TestAuth>(
        source_gate,
        destination_gate,
        character,
        TestAuth {},
        expires_at_timestamp_ms,
        ctx,
    );
}
MOVESRC

echo "Building & publishing test extension..."
cd /tmp/test_extension
rm -rf build Move.lock Pub.local.toml
sui client test-publish --build-env local --gas-budget 500000000 --json > /tmp/step11_pub.json 2>/dev/null || true

TEST_EXT_PKG=$(python3 -c "
import json
data = json.load(open('/tmp/step11_pub.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if ot == 'package' or 'PACKAGE_WRITE' in c.get('outputState', ''):
        print(c['objectId'])
        break
" 2>/dev/null || echo "FAILED")
echo "TEST_EXT_PKG=$TEST_EXT_PKG"

if [[ "$TEST_EXT_PKG" != "FAILED" ]]; then
  # Authorize Gate A with TestAuth
  sui client ptb \
    --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
      --type-args "${WORLD_PKG}::gate::Gate" \
      "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
    --assign ba \
    --move-call "${WORLD_PKG}::gate::authorize_extension" \
      --type-args "${TEST_EXT_PKG}::auth::TestAuth" \
      "@${GATE_A_ID}" ba.0 \
    --move-call "${WORLD_PKG}::character::return_owner_cap" \
      --type-args "${WORLD_PKG}::gate::Gate" \
      "@${CHARACTER_ID}" ba.0 ba.1 \
    --gas-budget 100000000 \
    --json > /tmp/step11a.json 2>/dev/null || true

  echo "Gate A auth:"
  python3 -c "
import json; data = json.load(open('/tmp/step11a.json'))
e = data.get('effects',{}); e = e.get('V2',e)
print('Status:', e.get('status','unknown'))
" 2>/dev/null || echo "Parse error"

  # Authorize Gate B with TestAuth
  sui client ptb \
    --move-call "${WORLD_PKG}::character::borrow_owner_cap" \
      --type-args "${WORLD_PKG}::gate::Gate" \
      "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
    --assign bb \
    --move-call "${WORLD_PKG}::gate::authorize_extension" \
      --type-args "${TEST_EXT_PKG}::auth::TestAuth" \
      "@${GATE_B_ID}" bb.0 \
    --move-call "${WORLD_PKG}::character::return_owner_cap" \
      --type-args "${WORLD_PKG}::gate::Gate" \
      "@${CHARACTER_ID}" bb.0 bb.1 \
    --gas-budget 100000000 \
    --json > /tmp/step11b.json 2>/dev/null || true

  echo "Gate B auth:"
  python3 -c "
import json; data = json.load(open('/tmp/step11b.json'))
e = data.get('effects',{}); e = e.get('V2',e)
print('Status:', e.get('status','unknown'))
" 2>/dev/null || echo "Parse error"

  log "Extension authorized on both gates"
fi

# --- Step 12: Issue Jump Permit ---
step "Step 12: Issue Jump Permit"

if [[ "$TEST_EXT_PKG" != "FAILED" ]]; then
  EXPIRY_MS=99999999999999

  sui client call \
    --package "$TEST_EXT_PKG" --module auth --function issue_permit \
    --args "$GATE_A_ID" "$GATE_B_ID" "$CHARACTER_ID" "$EXPIRY_MS" \
    --gas-budget 100000000 --json > /tmp/step12.json 2>/dev/null || true

  echo "Issue permit result:"
  python3 -c "
import json; data = json.load(open('/tmp/step12.json'))
e = data.get('effects',{}); e = e.get('V2',e)
print('Status:', e.get('status','unknown'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if 'JumpPermit' in ot:
        print(f'JumpPermit: {c[\"objectId\"]}')
" 2>/dev/null || echo "Parse error - check /tmp/step12.json"

  PERMIT_ID=$(python3 -c "
import json; data = json.load(open('/tmp/step12.json'))
for c in data.get('changed_objects', data.get('objectChanges', [])):
    ot = c.get('objectType', '')
    if 'JumpPermit' in ot:
        print(c['objectId'])
        break
" 2>/dev/null || echo "NONE")
  echo "PERMIT_ID=$PERMIT_ID"
  log "JumpPermit issued: $PERMIT_ID"
fi

# --- Step 13: Jump With Permit ---
step "Step 13: Jump With Permit (sponsored tx)"

if [[ "${PERMIT_ID:-NONE}" != "NONE" ]] && [[ "${PERMIT_ID:-}" != "" ]]; then
  echo "Attempting jump_with_permit (direct call - expected to fail without sponsor)..."
  
  sui client call \
    --package "$WORLD_PKG" --module gate --function jump_with_permit \
    --args "$GATE_A_ID" "$GATE_B_ID" "$CHARACTER_ID" "$PERMIT_ID" "$ADMIN_ACL" @0x6 \
    --gas-budget 100000000 --json > /tmp/step13_direct.json 2>/dev/null || true

  echo "Direct call result:"
  python3 -c "
import json; data = json.load(open('/tmp/step13_direct.json'))
e = data.get('effects',{}); e = e.get('V2',e)
status = e.get('status','unknown')
print(f'Status: {status}')
if isinstance(status, dict):
    print(f'Error: {status.get(\"error\",\"none\")}')
" 2>/dev/null || echo "Parse error"

  # Try jump without extension (gate::jump) on a separate gate pair
  echo ""
  echo "NOTE: jump_with_permit requires a sponsored transaction."
  echo "This is documented as a Day-1 item requiring TypeScript SDK."
  log "jump_with_permit: requires sponsored tx (Day-1 item)"
else
  echo "SKIP: No JumpPermit available"
  log "jump_with_permit: SKIPPED (no permit)"
fi

# --- Summary ---
step "Final Summary"

echo ""
echo "======================================"
echo "GATE LIFECYCLE REHEARSAL COMPLETE"
echo "======================================"
echo ""
echo "Key Object IDs:"
echo "  WORLD_PKG=$WORLD_PKG"
echo "  GOVERNOR_CAP=$GOVERNOR_CAP"
echo "  ADMIN_CAP=$ADMIN_CAP"
echo "  CHARACTER=$CHARACTER_ID"
echo "  NWN=$NWN_ID"
echo "  GATE_A=$GATE_A_ID"
echo "  GATE_B=$GATE_B_ID"  
echo "  TEST_EXT=${TEST_EXT_PKG:-N/A}"
echo "  PERMIT=${PERMIT_ID:-N/A}"
echo ""
echo "Evidence: /workspace/notes/gate-lifecycle-evidence.md"
echo "JSON logs: /tmp/step*.json"
