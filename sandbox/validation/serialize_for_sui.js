#!/usr/bin/env node
// Converts snarkjs Groth16 proof/VK to Sui-compatible arkworks compressed format
// Based on eve-frontier-proximity-zk-poc serialization logic

const fs = require('fs');
const path = '/tmp/zk_test';

const proof = JSON.parse(fs.readFileSync(`${path}/proof.json`, 'utf8'));
const vkey = JSON.parse(fs.readFileSync(`${path}/verification_key.json`, 'utf8'));
const publicSignals = JSON.parse(fs.readFileSync(`${path}/public.json`, 'utf8'));

// BN254 field modulus
const p = BigInt("21888242871839275222246405745257275088696311157297823662689037894645226208583");

function bigintToLE32(n) {
  let bn = BigInt(n);
  const bytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    bytes[i] = Number(bn & 0xFFn);
    bn >>= 8n;
  }
  return bytes;
}

// Compress G1 point: x-coordinate in little-endian, flags in last byte
function compressG1(point) {
  const x = BigInt(point[0]);
  const y = BigInt(point[1]);
  const infinity = (point[2] === "0");
  
  const xBytes = bigintToLE32(x);
  
  // Clear flag bits
  xBytes[31] &= 0x3F;
  
  // Set infinity flag (bit 6)
  if (infinity) {
    xBytes[31] |= 0x40;
  }
  
  // Set sign bit (bit 7) if y > (p-1)/2
  const halfP = (p - 1n) / 2n;
  if (y > halfP) {
    xBytes[31] |= 0x80;
  }
  
  return xBytes;
}

// Compress G2 point: [x1_LE, x2_LE] with flags
function compressG2(point) {
  // point[0] = [c0, c1] = [real, imaginary] x-coordinates
  // point[1] = [c0, c1] y-coordinates  
  const x_c0 = BigInt(point[0][0]); // real part
  const x_c1 = BigInt(point[0][1]); // imaginary part
  const y_c0 = BigInt(point[1][0]); // real part of y
  const y_c1 = BigInt(point[1][1]); // imaginary part of y
  const infinity = (point[2] && point[2][0] === "0" && point[2][1] === "0");
  
  // arkworks serializes G2 as x.c0 || x.c1 (each 32 bytes LE)
  const x_c0_bytes = bigintToLE32(x_c0);
  const x_c1_bytes = bigintToLE32(x_c1);
  
  const halfP = (p - 1n) / 2n;
  
  // Flags on the LAST byte of the serialization (byte 63, which is x_c1[31])
  x_c1[31] &= 0x3F;
  
  // For G2 sign: use the "larger" y component for sign determination
  // arkworks uses: if c1 != 0, sign of c1; else sign of c0
  let setSignBit = false;
  if (y_c1 !== 0n) {
    setSignBit = y_c1 > halfP;
  } else {
    setSignBit = y_c0 > halfP;
  }
  
  // Clear and set flags on c0 last byte for arkworks format
  x_c0_bytes[31] &= 0x3F;
  x_c1_bytes[31] &= 0x3F;
  
  if (setSignBit) {
    x_c1_bytes[31] |= 0x80;
  }
  
  if (infinity) {
    x_c1_bytes[31] |= 0x40;
  }
  
  // Concatenate: c0 || c1
  const result = new Uint8Array(64);
  result.set(x_c0_bytes, 0);
  result.set(x_c1_bytes, 32);
  return result;
}

// Serialize proof points: pi_a || pi_b || pi_c = 128 bytes
const pi_a = compressG1(proof.pi_a);
const pi_b = compressG2(proof.pi_b);
const pi_c = compressG1(proof.pi_c);

const proofPoints = new Uint8Array(128);
proofPoints.set(pi_a, 0);
proofPoints.set(pi_b, 32);
proofPoints.set(pi_c, 96);

// Serialize VK: alpha_1 || beta_2 || gamma_2 || delta_2 || IC[0] || IC[1] || ... || IC[n]
const vk_alpha_1 = compressG1(vkey.vk_alpha_1);
const vk_beta_2 = compressG2(vkey.vk_beta_2);
const vk_gamma_2 = compressG2(vkey.vk_gamma_2);
const vk_delta_2 = compressG2(vkey.vk_delta_2);

const icPoints = vkey.IC.map(ic => compressG1(ic));

// arkworks CanonicalSerialize for VerifyingKey includes a u64 LE length prefix for the IC Vec
const vkSize = 32 + 64 + 64 + 64 + 8 + icPoints.length * 32;
const vkBytes = new Uint8Array(vkSize);
let offset = 0;
vkBytes.set(vk_alpha_1, offset); offset += 32;
vkBytes.set(vk_beta_2, offset); offset += 64;
vkBytes.set(vk_gamma_2, offset); offset += 64;
vkBytes.set(vk_delta_2, offset); offset += 64;
// Write IC array length as u64 LE
const icLen = icPoints.length;
vkBytes[offset] = icLen & 0xFF;
vkBytes[offset+1] = (icLen >> 8) & 0xFF;
vkBytes[offset+2] = (icLen >> 16) & 0xFF;
vkBytes[offset+3] = (icLen >> 24) & 0xFF;
vkBytes[offset+4] = 0; vkBytes[offset+5] = 0; vkBytes[offset+6] = 0; vkBytes[offset+7] = 0;
offset += 8;
for (const ic of icPoints) {
  vkBytes.set(ic, offset); offset += 32;
}

// Serialize public inputs: each signal as 32-byte LE field element
// Public signals from snarkjs: [c=21, b=7] (outputs first, then inputs)
const publicInputBytes = new Uint8Array(publicSignals.length * 32);
for (let i = 0; i < publicSignals.length; i++) {
  const fieldBytes = bigintToLE32(publicSignals[i]);
  publicInputBytes.set(fieldBytes, i * 32);
}

// Output as hex strings for Move
function toHex(bytes) {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

// Output as Move vector literal
function toMoveVector(bytes) {
  return 'vector[' + Array.from(bytes).map(b => `${b}u8`).join(', ') + ']';
}

console.log('=== PROOF POINTS (128 bytes) ===');
console.log('HEX:', toHex(proofPoints));
console.log('');
console.log('=== VK BYTES (' + vkSize + ' bytes) ===');
console.log('HEX:', toHex(vkBytes));
console.log('');
console.log('=== PUBLIC INPUTS (' + publicInputBytes.length + ' bytes) ===');
console.log('HEX:', toHex(publicInputBytes));
console.log('');
console.log('=== Public signals (decimal) ===');
console.log(publicSignals);
console.log('');
console.log('=== MOVE CONSTANTS ===');
console.log('');
console.log('// Proof points (128 bytes)');
console.log('let proof_points_bytes = ' + toMoveVector(proofPoints) + ';');
console.log('');
console.log('// VK bytes (' + vkSize + ' bytes)');
console.log('let vkey_bytes = ' + toMoveVector(vkBytes) + ';');
console.log('');
console.log('// Public inputs (' + publicInputBytes.length + ' bytes, little-endian)');
console.log('let public_inputs_bytes = ' + toMoveVector(publicInputBytes) + ';');
