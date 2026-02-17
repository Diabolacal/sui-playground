#!/bin/bash
# Step 4: Configure fuel, energy, gate distance
set -euo pipefail

WORLD_PKG=0x060633cec8d5e74b2d518f364aef87d4adf4cd87e3e6b9f712d15f0c996386f1
ADMIN_CAP=0x5f72ed01230a904bf76497ae97a5ea58b2411a7e7ba84b5552990c8e12954559
FUEL_CONFIG=0xa0427a1015e24a0c15d373ae3ce8e832fdf0afd3a9a4b376662625eed5085fe0
ENERGY_CONFIG=0x4b889dc5dac92e1b2b8fba4451d589782de914d040138e7728d08fcfab6661b0
GATE_CONFIG=0xf6d5052d02fbe95d30047351fc2caf3552ef0c0ba2a3bda7d056b4e7c0c30489

GATE_TYPE_ID=8888

echo "Step 4a: Set fuel efficiency (type=1, eff=100)"
sui client call \
  --package "$WORLD_PKG" --module fuel --function set_fuel_efficiency \
  --args "$FUEL_CONFIG" "$ADMIN_CAP" 1 100 \
  --gas-budget 50000000 --json > /tmp/step4a.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step4a.json

echo ""
echo "Step 4b: Set energy config (gate_type=$GATE_TYPE_ID, energy=50)"
sui client call \
  --package "$WORLD_PKG" --module energy --function set_energy_config \
  --args "$ENERGY_CONFIG" "$ADMIN_CAP" "$GATE_TYPE_ID" 50 \
  --gas-budget 50000000 --json > /tmp/step4b.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step4b.json

echo ""
echo "Step 4c: Set gate max distance (type=$GATE_TYPE_ID, maxDist=1000000000)"
sui client call \
  --package "$WORLD_PKG" --module gate --function set_max_distance \
  --args "$GATE_CONFIG" "$ADMIN_CAP" "$GATE_TYPE_ID" 1000000000 \
  --gas-budget 50000000 --json > /tmp/step4c.json 2>&1
python3 /workspace/sandbox/parse_step.py /tmp/step4c.json
