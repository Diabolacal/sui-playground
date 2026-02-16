pragma circom 2.2.0;

include "circomlib/circuits/poseidon.circom";

/// Merkle Membership Proof Circuit
/// ================================
/// Proves that a leaf is a member of a Merkle tree with a given root,
/// without revealing which leaf.
///
/// Private inputs:
///   - leaf: the value at the leaf position
///   - pathElements[DEPTH]: sibling hashes along the path from leaf to root
///   - pathIndices[DEPTH]: 0 or 1 indicating left/right position at each level
///
/// Public inputs:
///   - root: the Merkle tree root hash
///
/// Hash function: Poseidon(2) over BN254 — matches the PoC's Merkle tree construction
/// Tree structure: binary Merkle tree, depth = DEPTH
///
/// Constraint count: ~DEPTH * Poseidon(2) constraints ≈ DEPTH * 254 ≈ 2540 for depth 10

template MerkleProof(DEPTH) {
    // Public input
    signal input root;

    // Private inputs
    signal input leaf;
    signal input pathElements[DEPTH];
    signal input pathIndices[DEPTH];

    // Internal: compute root from leaf + path
    signal levelHashes[DEPTH + 1];
    levelHashes[0] <== leaf;

    component hashers[DEPTH];

    // Intermediate signals for mux logic
    signal leftDiff[DEPTH];
    signal leftInput[DEPTH];
    signal rightDiff[DEPTH];
    signal rightInput[DEPTH];

    for (var i = 0; i < DEPTH; i++) {
        // pathIndices[i] must be 0 or 1
        pathIndices[i] * (1 - pathIndices[i]) === 0;

        // Select left and right inputs based on path index
        // If pathIndices[i] == 0: current hash is LEFT, sibling is RIGHT
        // If pathIndices[i] == 1: current hash is RIGHT, sibling is LEFT
        //
        // left  = levelHashes[i] + pathIndices[i] * (pathElements[i] - levelHashes[i])
        // right = pathElements[i] + pathIndices[i] * (levelHashes[i] - pathElements[i])

        leftDiff[i] <== pathElements[i] - levelHashes[i];
        leftInput[i] <== levelHashes[i] + pathIndices[i] * leftDiff[i];

        rightDiff[i] <== levelHashes[i] - pathElements[i];
        rightInput[i] <== pathElements[i] + pathIndices[i] * rightDiff[i];

        // Hash(left, right) using Poseidon with 2 inputs
        hashers[i] = Poseidon(2);
        hashers[i].inputs[0] <== leftInput[i];
        hashers[i].inputs[1] <== rightInput[i];

        levelHashes[i + 1] <== hashers[i].out;
    }

    // The computed root must equal the public root
    root === levelHashes[DEPTH];
}

/// Instantiate with depth 10 (supports up to 1024 members)
component main {public [root]} = MerkleProof(10);
