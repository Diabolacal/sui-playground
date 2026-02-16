#!/bin/bash
# Publish and extract results
cd /tmp/zk_gatepass_validation
OUTPUT=$(sui client test-publish --build-env local --gas-budget 100000000 --json 2>/dev/null)

echo "$OUTPUT" | node -e '
const data = JSON.parse(require("fs").readFileSync("/dev/stdin","utf8"));
const effects = data.effects;
console.log("=== PUBLISH RESULT ===");
console.log("Status:", JSON.stringify(effects.status));
console.log("Gas:", JSON.stringify(effects.gasUsed));
console.log("Digest:", data.digest);

// Find package ID in created objects
const created = effects.created || [];
for (const obj of created) {
  if (obj.owner === "Immutable") {
    console.log("Package ID:", obj.reference.objectId);
  }
}
'
