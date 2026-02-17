"""
Utility to extract object IDs from sui client JSON output.
Works with both test-publish format and regular call format.
"""
import json
import sys

def extract_objects(json_file):
    """Extract object info from sui client JSON output."""
    data = json.load(open(json_file))
    
    results = {
        'status': 'unknown',
        'digest': 'unknown',
        'package': None,
        'created': [],
        'all_objects': []
    }
    
    # Handle effects structure (V2 or flat)
    effects = data.get('effects', {})
    if 'V2' in effects:
        effects = effects['V2']
    results['status'] = effects.get('status', data.get('effects', {}).get('status', {}).get('status', 'unknown'))
    results['digest'] = effects.get('transaction_digest', data.get('digest', 'unknown'))
    
    # Handle both formats: changed_objects (test-publish) and objectChanges (regular call)
    objects = data.get('changed_objects', data.get('objectChanges', []))
    
    for obj in objects:
        # Flat dict format (test-publish / newer CLI)
        if isinstance(obj, dict):
            oid = obj.get('objectId', '')
            otype = obj.get('objectType', '')
            op = obj.get('idOperation', '')
            output_state = obj.get('outputState', '')
            owner_info = obj.get('outputOwner', {})
            
            entry = {
                'objectId': oid,
                'objectType': otype,
                'operation': op,
                'owner': owner_info
            }
            results['all_objects'].append(entry)
            
            if op == 'CREATED':
                results['created'].append(entry)
                if otype == 'package' or 'PACKAGE_WRITE' in str(output_state):
                    results['package'] = oid
    
    return results

def find_by_type(results, type_substring):
    """Find object ID by type name substring."""
    for obj in results['created']:
        if type_substring in obj.get('objectType', ''):
            return obj['objectId']
    return None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 extract_objects.py <json_file> [type_filter]")
        sys.exit(1)
    
    results = extract_objects(sys.argv[1])
    
    if len(sys.argv) >= 3:
        # Filter mode: return just the object ID for the given type
        oid = find_by_type(results, sys.argv[2])
        if oid:
            print(oid)
        else:
            print(f"NOT_FOUND:{sys.argv[2]}")
    else:
        # Full report
        print(f"Status: {results['status']}")
        print(f"Digest: {results['digest']}")
        if results['package']:
            print(f"Package: {results['package']}")
        print(f"\nCreated objects ({len(results['created'])}):")
        for obj in results['created']:
            owner = obj.get('owner', {})
            owner_str = 'shared' if owner.get('kind') == 'SHARED' else owner.get('kind', 'unknown')
            print(f"  {obj['objectId']}")
            print(f"    type: {obj['objectType']}")
            print(f"    owner: {owner_str}")
