#!/bin/bash
# ZK proof generation script for standalone Groth16 verification test
# Runs inside the Docker container

set -e
cd /tmp/zk_test

# Create input (a=3, b=7 => c=21)
cat > input.json << 'INPUTEOF'
{
  "a": "3",
  "b": "7"
}
INPUTEOF

echo "=== Input file ==="
cat input.json

echo "=== Generating proof ==="
snarkjs groth16 fullprove input.json multiplier_js/multiplier.wasm multiplier_final.zkey proof.json public.json

echo "=== Proof ==="
cat proof.json

echo "=== Public signals ==="
cat public.json

echo "=== Verification key ==="
cat verification_key.json

echo "=== Verifying off-chain ==="
snarkjs groth16 verify verification_key.json public.json proof.json
echo "Done"
