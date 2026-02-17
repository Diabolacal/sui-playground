#!/bin/bash
# Parse the publish JSON and extract key fields
import json

data = json.load(open('/tmp/world_publish.json'))
print("Top-level keys:", list(data.keys()))

# Try direct fields
if 'digest' in data:
    print(f"Digest: {data['digest']}")
if 'effects' in data:
    print(f"Status: {data['effects'].get('status', {})}")
    
# Check for objectChanges
if 'objectChanges' in data:
    print(f"Object changes: {len(data['objectChanges'])}")
    for c in data['objectChanges']:
        ot = c.get('objectType', '')
        oid = c.get('objectId', '')
        ctype = c.get('type', '')
        if ctype in ('published', 'created'):
            print(f'  {ctype}: {oid} -> {ot}')

# Maybe nested in transaction
if 'transaction' in data:
    print("Has 'transaction' key - this might be serialized-unsigned output")
    
# Check if it's a different format
for key in list(data.keys())[:5]:
    val = data[key]
    if isinstance(val, dict):
        print(f"  {key}: dict with keys {list(val.keys())[:5]}")
    elif isinstance(val, str):
        print(f"  {key}: '{val[:80]}'")
    elif isinstance(val, list):
        print(f"  {key}: list[{len(val)}]")
    else:
        print(f"  {key}: {type(val).__name__}")
