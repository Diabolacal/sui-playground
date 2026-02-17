#!/usr/bin/env python3
"""Parse sui client JSON output and find objects by type substring."""
import json
import sys

def parse(filepath, *type_filters):
    data = json.load(open(filepath))
    
    # Get status
    effects = data.get('effects', {})
    if 'V2' in effects:
        effects = effects['V2']
    status = effects.get('status', 'unknown')
    print(f"Status: {status}")
    
    if isinstance(status, dict) and status.get('status') == 'failure':
        print(f"Error: {status.get('error', {})}")
        return
    
    # Get objects
    objects = data.get('changed_objects', data.get('objectChanges', []))
    
    for obj in objects:
        if not isinstance(obj, dict):
            continue
        oid = obj.get('objectId', '')
        otype = obj.get('objectType', '')
        op = obj.get('idOperation', '')
        
        if op != 'CREATED':
            continue
        
        # Check filters
        if type_filters:
            for f in type_filters:
                if f.lower() in otype.lower():
                    print(f"{f}: {oid}")
        else:
            print(f"  {oid} ({otype})")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 parse_step.py <json_file> [TypeFilter1] [TypeFilter2] ...")
        sys.exit(1)
    parse(sys.argv[1], *sys.argv[2:])
