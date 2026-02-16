/**
 * generate_test_input.js
 * 
 * Generates test inputs for the Merkle membership circuit.
 * Uses poseidon-lite for hashing (same as the ZK PoC).
 * 
 * Builds a depth-10 binary Merkle tree with Poseidon(2) hashing,
 * then generates:
 *   - input.json (circuit inputs: leaf, pathElements, pathIndices, root)
 *   - tree_info.json (all leaves, root, tree metadata)
 */

const { poseidon2, poseidon1 } = require('poseidon-lite');
const fs = require('fs');
const path = require('path');

const DEPTH = 10;
const TREE_SIZE = 1 << DEPTH; // 1024

// ============== Merkle Tree Construction ==============

function buildMerkleTree(leaves) {
    const paddedLeaves = [...leaves];
    // Pad with zeros to fill tree
    while (paddedLeaves.length < TREE_SIZE) {
        paddedLeaves.push(0n);
    }
    
    // Build tree bottom-up
    const tree = [paddedLeaves.map(l => BigInt(l))];
    
    for (let level = 0; level < DEPTH; level++) {
        const currentLevel = tree[level];
        const nextLevel = [];
        for (let i = 0; i < currentLevel.length; i += 2) {
            const left = currentLevel[i];
            const right = currentLevel[i + 1];
            nextLevel.push(poseidon2([left, right]));
        }
        tree.push(nextLevel);
    }
    
    return tree;
}

function getMerkleProof(tree, leafIndex) {
    const pathElements = [];
    const pathIndices = [];
    
    let currentIndex = leafIndex;
    
    for (let level = 0; level < DEPTH; level++) {
        const isRight = currentIndex % 2;
        const siblingIndex = isRight ? currentIndex - 1 : currentIndex + 1;
        
        pathElements.push(tree[level][siblingIndex].toString());
        pathIndices.push(isRight);
        
        currentIndex = Math.floor(currentIndex / 2);
    }
    
    return { pathElements, pathIndices };
}

// ============== Test Data Generation ==============

// Create some test "member" values (e.g., hashed character IDs)
// Using simple values for testing — in production these would be Poseidon hashes of character data
const memberValues = [
    42n,   // Member 0 — our test prover
    100n,  // Member 1
    255n,  // Member 2
    1000n, // Member 3
    9999n, // Member 4
];

console.log(`Building Merkle tree with ${memberValues.length} members (depth ${DEPTH}, ${TREE_SIZE} leaves)...`);

const tree = buildMerkleTree(memberValues);
const root = tree[DEPTH][0];

console.log(`Root: ${root.toString()}`);

// Generate proof for member 0 (leaf index 0, value 42)
const proveIndex = 0;
const proveLeaf = memberValues[proveIndex];
const { pathElements, pathIndices } = getMerkleProof(tree, proveIndex);

// Verify proof locally before writing
let computed = proveLeaf;
for (let i = 0; i < DEPTH; i++) {
    const sibling = BigInt(pathElements[i]);
    if (pathIndices[i] === 0) {
        computed = poseidon2([computed, sibling]);
    } else {
        computed = poseidon2([sibling, computed]);
    }
}

if (computed !== root) {
    console.error('ERROR: Local proof verification failed!');
    console.error(`  Computed: ${computed}`);
    console.error(`  Expected: ${root}`);
    process.exit(1);
}

console.log('Local proof verification: PASSED');

// Write circuit input
const circuitInput = {
    root: root.toString(),
    leaf: proveLeaf.toString(),
    pathElements: pathElements,
    pathIndices: pathIndices,
};

const buildDir = path.join(__dirname, 'build');
fs.writeFileSync(path.join(buildDir, 'input.json'), JSON.stringify(circuitInput, null, 2));

// Write tree info for reference
const treeInfo = {
    depth: DEPTH,
    treeSize: TREE_SIZE,
    memberCount: memberValues.length,
    members: memberValues.map(v => v.toString()),
    root: root.toString(),
    proveIndex,
    proveLeaf: proveLeaf.toString(),
};

fs.writeFileSync(path.join(buildDir, 'tree_info.json'), JSON.stringify(treeInfo, null, 2));

console.log(`\nFiles written to ${buildDir}/:`);
console.log('  input.json — circuit input for proof generation');
console.log('  tree_info.json — tree metadata');
console.log(`\nCircuit input summary:`);
console.log(`  root (public):  ${root.toString().substring(0, 40)}...`);
console.log(`  leaf (private): ${proveLeaf}`);
console.log(`  pathIndices:    [${pathIndices.join(', ')}]`);
