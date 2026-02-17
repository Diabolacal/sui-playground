#!/bin/bash
# Step 9: Link gates with distance proof
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
CHARACTER_ID=0x37c8b4e4dd0cdf7c6dd88f9b75d799ce38bcc1b3b410e9838c183e5e744034b9
GATE_A=0x620638f603dab2bffb2dc1d2b7bb3c53f2121ee6c2dd5c1385ff692792534aa0
GATE_B=0x09eeb540a1221fa60d654a9f64fdc59ade9c814de695969583e2a7b10628bb58
GATE_A_CAP=0xb3cd16e364d22249096858b44dc8009ca7c4379d763b3d615f6d744eca8b4a00
GATE_B_CAP=0x89183fcb02c940b2eac1a94aa099602d00882e11fa44ae31c82042b0d95b9a41
GATE_CONFIG=0xf6d5052d02fbe95d30047351fc2caf3552ef0c0ba2a3bda7d056b4e7c0c30489
SERVER_REGISTRY=0x7df06997b37c8d2393d75090c8c5b1fcf122bc6d8d72690a9684341cb03d2168
ADMIN_ADDR=0x85483f9da07887da6024fdfbc22c1a0eb53475c70c7033aaca9ff06c13a688fe
LOCATION_HASH="16217de8ec7330ec3eac32831df5c9cd9b21a255756a5fd5762dd7f49f6cc049"
SERVER_PRIVKEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

echo "Step 9: Link gates with distance proof"

# Generate distance proof
cp /workspace/sandbox/generate_distance_proof.mjs /tmp/generate_distance_proof.mjs
PROOF_HEX=$(cd /tmp && node generate_distance_proof.mjs \
  --server-privkey "$SERVER_PRIVKEY" \
  --player-address "$ADMIN_ADDR" \
  --gate-location-hash "$LOCATION_HASH" \
  --distance 0 \
  --deadline-ms 9999999999999 2>/tmp/proof_gen.log)

echo "Proof hex length: $(echo -n "$PROOF_HEX" | wc -c) chars ($(( $(echo -n "$PROOF_HEX" | wc -c) / 2 )) bytes)"

# Convert hex to vector[0xHH, 0xHH, ...] format for PTB
PROOF_VECTOR=$(echo "$PROOF_HEX" | sed 's/\(..\)/0x\1,/g' | sed 's/,$//')

echo "Calling link_gates via PTB..."
# link_gates needs:
# source_gate, destination_gate, character, gate_config, server_registry,
# source_owner_cap, dest_owner_cap, distance_proof (vector<u8>), clock, ctx
sui client ptb \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_A_CAP}" \
  --assign borrow_a \
  --move-call "${WORLD_PKG}::character::borrow_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" "@${GATE_B_CAP}" \
  --assign borrow_b \
  --move-call "${WORLD_PKG}::gate::link_gates" \
    "@${GATE_A}" "@${GATE_B}" "@${CHARACTER_ID}" \
    "@${GATE_CONFIG}" "@${SERVER_REGISTRY}" \
    borrow_a.0 borrow_b.0 \
    "vector[$PROOF_VECTOR]" \
    @0x6 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" borrow_a.0 borrow_a.1 \
  --move-call "${WORLD_PKG}::character::return_owner_cap<${WORLD_PKG}::gate::Gate>" \
    "@${CHARACTER_ID}" borrow_b.0 borrow_b.1 \
  --gas-budget 200000000 \
  --json > /tmp/step9.json 2>&1

python3 /workspace/sandbox/extract_objects.py /tmp/step9.json
