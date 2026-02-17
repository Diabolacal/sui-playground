import json

data = json.load(open('/tmp/world_publish.json'))

# Get effects V2 structure
effects = data.get('effects', {}).get('V2', {})
print("Effects keys:", list(effects.keys()))
status = effects.get('status', 'unknown')
print(f"Status: {status}")
tx_digest = effects.get('transactionDigest', 'unknown')
print(f"TX Digest: {tx_digest}")

# Parse changed_objects
print("\nChanged objects:")
for obj in data.get('changed_objects', []):
    # Each is [objectId, {input_state, output_state, ...}]
    if isinstance(obj, list) and len(obj) >= 2:
        oid = obj[0]
        details = obj[1]
        output = details.get('outputState', {})
        if isinstance(output, dict):
            # Check for object write
            obj_write = output.get('ObjectWrite', None)
            pkg_write = output.get('PackageWrite', None)
            if pkg_write:
                print(f"  PACKAGE: {oid}")
                print(f"    digest: {pkg_write}")
            elif obj_write:
                owner_info = obj_write[1] if len(obj_write) > 1 else 'unknown'
                print(f"  OBJECT: {oid}")
                print(f"    owner: {owner_info}")
        elif output == 'DoesNotExist':
            pass  # Deleted/consumed objects
    else:
        print(f"  Unknown format: {obj}")

# Actually let me just look at the raw JSON more carefully
print("\n\nFirst changed_object structure:")
if data.get('changed_objects'):
    print(json.dumps(data['changed_objects'][0], indent=2))
    print("\n...")
    # Find the package
    for obj in data['changed_objects']:
        if isinstance(obj, list) and len(obj) >= 2:
            details = obj[1]
            output = details.get('outputState', {})
            if isinstance(output, dict) and 'PackageWrite' in output:
                print(f"\nPACKAGE ID: {obj[0]}")
