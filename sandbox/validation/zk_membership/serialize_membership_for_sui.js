/**
 * serialize_membership_for_sui.js
 * 
 * Converts snarkjs membership proof, VK, and public signals into 
 * Sui-compatible arkworks compressed format.
 * 
 * Reuses the same serialization logic from sandbox/validation/serialize_for_sui.js
 * but specialized for the membership circuit output.
 */

const fs = require('fs');
const path = require('path');

const buildDir = path.join(__dirname, 'build');

const proof = JSON.parse(fs.readFileSync(path.join(buildDir, 'proof.json'), 'utf8'));
const vkey = JSON.parse(fs.readFileSync(path.join(buildDir, 'verification_key.json'), 'utf8'));
const publicSignals = JSON.parse(fs.readFileSync(path.join(buildDir, 'public.json'), 'utf8'));

// ============================================================
// BN254 field modulus
// ============================================================
const P = 21888242871839275222246405745257275088696311157297823662689037894645226208583n;

// ============================================================
// Arkworks compressed serialization helpers
// ============================================================

function bigintToLE32(val) {
    const buf = Buffer.alloc(32);
    let v = BigInt(val);
    for (let i = 0; i < 32; i++) {
        buf[i] = Number(v & 0xFFn);
        v >>= 8n;
    }
    return buf;
}

function compressG1(point) {
    const x = BigInt(point[0]);
    const y = BigInt(point[1]);

    if (x === 0n && y === 0n) {
        const buf = Buffer.alloc(32);
        buf[31] = 0x40; // infinity flag
        return buf;
    }

    const buf = bigintToLE32(x);
    // Set flags in the most significant byte
    const yNeg = P - y;
    if (y > yNeg) {
        buf[31] |= 0x80; // largest flag
    }
    return buf;
}

function compressG2(point) {
    const x0 = BigInt(point[0][0]);
    const x1 = BigInt(point[0][1]);
    const y0 = BigInt(point[1][0]);
    const y1 = BigInt(point[1][1]);

    // G2 point: x = x0 + x1*u, y = y0 + y1*u
    // Compress: store x (c0 || c1, each 32 bytes LE) + flag on last byte

    if (x0 === 0n && x1 === 0n && y0 === 0n && y1 === 0n) {
        const buf = Buffer.alloc(64);
        buf[63] = 0x40; // infinity flag
        return buf;
    }

    const bufC0 = bigintToLE32(x0);
    const bufC1 = bigintToLE32(x1);
    const combined = Buffer.concat([bufC0, bufC1]);

    // Lexicographic comparison for largest: compare (y1, y0) vs (P-y1, P-y0)
    const y1Neg = P - y1;
    const y0Neg = P - y0;
    let largest = false;
    if (y1 > y1Neg) {
        largest = true;
    } else if (y1 === y1Neg) {
        largest = y0 > y0Neg;
    }

    if (largest) {
        combined[63] |= 0x80;
    }
    return combined;
}

function serializePublicInputs(signals) {
    const buffers = signals.map(s => bigintToLE32(BigInt(s)));
    return Buffer.concat(buffers);
}

// ============================================================
// Serialize proof
// ============================================================

const proofA = compressG1(proof.pi_a);
const proofB = compressG2(proof.pi_b);
const proofC = compressG1(proof.pi_c);
const proofBytes = Buffer.concat([proofA, proofB, proofC]);

console.log(`Proof bytes (${proofBytes.length} bytes):`);
console.log(`  HEX: ${proofBytes.toString('hex')}`);

// ============================================================
// Serialize verification key
// ============================================================

const vkAlpha = compressG1(vkey.vk_alpha_1);
const vkBeta = compressG2(vkey.vk_beta_2);
const vkGamma = compressG2(vkey.vk_gamma_2);
const vkDelta = compressG2(vkey.vk_delta_2);

// IC length as u64 LE
const icLen = Buffer.alloc(8);
icLen.writeUInt32LE(vkey.IC.length, 0);

const icPoints = vkey.IC.map(ic => compressG1(ic));
const vkBytes = Buffer.concat([vkAlpha, vkBeta, vkGamma, vkDelta, icLen, ...icPoints]);

console.log(`\nVK bytes (${vkBytes.length} bytes):`);
console.log(`  HEX: ${vkBytes.toString('hex')}`);
console.log(`  IC count: ${vkey.IC.length}`);

// ============================================================
// Serialize public inputs
// ============================================================

const publicInputsBytes = serializePublicInputs(publicSignals);
console.log(`\nPublic inputs bytes (${publicInputsBytes.length} bytes):`);
console.log(`  HEX: ${publicInputsBytes.toString('hex')}`);
console.log(`  Values: ${publicSignals}`);

// ============================================================
// Generate Move vector literals
// ============================================================

function toMoveVector(buf) {
    const bytes = Array.from(buf);
    return `vector[${bytes.join('u8, ')}u8]`;
}

console.log('\n====================================');
console.log('MOVE VECTOR LITERALS');
console.log('====================================');
console.log(`\n// Proof (${proofBytes.length} bytes):`);
console.log(`let proof_points_bytes = ${toMoveVector(proofBytes)};`);
console.log(`\n// VK (${vkBytes.length} bytes):`);
console.log(`let vkey_bytes = ${toMoveVector(vkBytes)};`);
console.log(`\n// Public inputs (${publicInputsBytes.length} bytes):`);
console.log(`let public_inputs_bytes = ${toMoveVector(publicInputsBytes)};`);

// ============================================================
// Write output files
// ============================================================

const output = {
    proof: {
        hex: proofBytes.toString('hex'),
        bytes: Array.from(proofBytes),
        length: proofBytes.length,
    },
    vk: {
        hex: vkBytes.toString('hex'),
        bytes: Array.from(vkBytes),
        length: vkBytes.length,
        icCount: vkey.IC.length,
    },
    publicInputs: {
        hex: publicInputsBytes.toString('hex'),
        bytes: Array.from(publicInputsBytes),
        length: publicInputsBytes.length,
        values: publicSignals,
    },
};

fs.writeFileSync(path.join(buildDir, 'sui_serialized.json'), JSON.stringify(output, null, 2));
console.log(`\nSerialized data written to build/sui_serialized.json`);

// Also write tree info summary
const treeInfo = JSON.parse(fs.readFileSync(path.join(buildDir, 'tree_info.json'), 'utf8'));
console.log(`\n====================================`);
console.log(`CIRCUIT SUMMARY`);
console.log(`====================================`);
console.log(`Circuit: Merkle membership proof (depth ${treeInfo.depth})`);
console.log(`Tree capacity: ${treeInfo.treeSize} leaves`);
console.log(`Members: ${treeInfo.memberCount}`);
console.log(`Constraints: 2,430`);
console.log(`Public inputs: 1 (root)`);
console.log(`Private inputs: 21 (leaf + 10 pathElements + 10 pathIndices)`);
console.log(`Proof size: ${proofBytes.length} bytes`);
console.log(`VK size: ${vkBytes.length} bytes`);
console.log(`Public inputs size: ${publicInputsBytes.length} bytes`);
