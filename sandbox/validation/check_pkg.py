import json
with open('/tmp/node_modules/@noble/hashes/package.json') as f:
    d = json.load(f)
print("version:", d.get("version"))
print("type:", d.get("type", "NONE"))
exports = d.get("exports", {})
print("exports keys:", list(exports.keys())[:10])
blake2b_export = exports.get("./blake2b", "NOT_FOUND")
print("./blake2b export:", blake2b_export)
