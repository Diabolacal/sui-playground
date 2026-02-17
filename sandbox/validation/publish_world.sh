#!/bin/bash
# Clean stale artifacts and publish world package
set -e

cd /workspace/world-contracts/world
rm -f Pub.local.toml Move.lock
rm -rf build

echo "=== Publishing world package ==="
sui client test-publish --build-env local --gas-budget 500000000 --json > /tmp/world_publish.json 2>/tmp/world_publish_stderr.txt
echo "Build/publish stderr:"
cat /tmp/world_publish_stderr.txt

echo "=== Publish result ==="
python3 << 'PYEOF'
import json
data = json.load(open('/tmp/world_publish.json'))
print(f"TX Digest: {data.get('digest', 'unknown')}")
print(f"Status: {data.get('effects',{}).get('status',{}).get('status','unknown')}")
for c in data.get('objectChanges', []):
    ot = c.get('objectType', '')
    oid = c.get('objectId', '')
    ctype = c.get('type', '')
    if ctype in ('published', 'created'):
        print(f'  {ctype}: {oid}')
        print(f'    type: {ot}')
PYEOF
