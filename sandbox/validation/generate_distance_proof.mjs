/**
 * generate_distance_proof.mjs (ESM version)
 * 
 * Generates a BCS-serialized distance proof for world-contracts gate::link_gates.
 * 
 * Usage: cd /tmp && node generate_distance_proof.mjs \
 *   --server-privkey <hex> \
 *   --player-address <hex> \
 *   --gate-location-hash <hex> \
 *   [--distance 0] \
 *   [--deadline-ms 9999999999999]
 * 
 * Output (stdout): hex-encoded BCS proof bytes
 * Diagnostics on stderr
 */

import crypto from 'crypto';
import { blake2b } from '@noble/hashes/blake2.js';

// === BCS Encoding Helpers ===

function bcsAddress(hexStr) {
  const hex = hexStr.startsWith('0x') ? hexStr.slice(2) : hexStr;
  return Buffer.from(hex.padStart(64, '0'), 'hex');
}

function bcsVectorU8(buf) {
  const lenBytes = uleb128Encode(buf.length);
  return Buffer.concat([lenBytes, buf]);
}

function bcsU64(value) {
  const buf = Buffer.alloc(8);
  buf.writeBigUInt64LE(BigInt(value));
  return buf;
}

function uleb128Encode(value) {
  const bytes = [];
  while (value >= 0x80) {
    bytes.push((value & 0x7f) | 0x80);
    value >>>= 7;
  }
  bytes.push(value & 0x7f);
  return Buffer.from(bytes);
}

// === Address Derivation ===

function deriveAddressFromPubkey(pubkeyBytes) {
  const prefixed = Buffer.concat([Buffer.from([0x00]), pubkeyBytes]);
  const hash = blake2b(prefixed, { dkLen: 32 });
  return Buffer.from(hash);
}

// === BCS-serialize LocationProofMessage ===

function bcsSerializeMessage(msg) {
  return Buffer.concat([
    bcsAddress(msg.serverAddress),
    bcsAddress(msg.playerAddress),
    bcsAddress(msg.sourceStructureId),
    bcsVectorU8(msg.sourceLocationHash),
    bcsAddress(msg.targetStructureId),
    bcsVectorU8(msg.targetLocationHash),
    bcsU64(msg.distance),
    bcsVectorU8(msg.data),
    bcsU64(msg.deadlineMs),
  ]);
}

// === BCS-serialize full LocationProof (message + signature) ===

function bcsSerializeProof(msg, signature) {
  const msgBytes = bcsSerializeMessage(msg);
  const sigVec = bcsVectorU8(signature);
  return Buffer.concat([msgBytes, sigVec]);
}

// === Main ===

function main() {
  const args = process.argv.slice(2);
  const getArg = (name, defaultVal) => {
    const idx = args.indexOf(name);
    if (idx >= 0 && idx + 1 < args.length) return args[idx + 1];
    if (defaultVal !== undefined) return defaultVal;
    console.error(`Missing required argument: ${name}`);
    process.exit(1);
  };

  const serverPrivkeyHex = getArg('--server-privkey');
  const playerAddress = getArg('--player-address');
  const gateLocationHashHex = getArg('--gate-location-hash');
  const distance = parseInt(getArg('--distance', '0'));
  const deadlineMs = getArg('--deadline-ms', '9999999999999');

  // Generate keypair from private key seed
  const privKeyBuf = Buffer.from(
    serverPrivkeyHex.startsWith('0x') ? serverPrivkeyHex.slice(2) : serverPrivkeyHex,
    'hex'
  );
  
  const keyObj = crypto.createPrivateKey({
    key: Buffer.concat([
      Buffer.from('302e020100300506032b657004220420', 'hex'),
      privKeyBuf,
    ]),
    format: 'der',
    type: 'pkcs8',
  });
  
  const pubKeyDer = crypto.createPublicKey(keyObj).export({ type: 'spki', format: 'der' });
  const pubKeyBytes = pubKeyDer.slice(-32);
  
  const serverAddress = deriveAddressFromPubkey(pubKeyBytes);
  
  console.error('Server pubkey:', Buffer.from(pubKeyBytes).toString('hex'));
  console.error('Server address:', '0x' + serverAddress.toString('hex'));

  const locationHash = Buffer.from(
    gateLocationHashHex.startsWith('0x') ? gateLocationHashHex.slice(2) : gateLocationHashHex,
    'hex'
  );

  const dummySourceId = '0x' + '00'.repeat(31) + '01';
  const dummyTargetId = '0x' + '00'.repeat(31) + '02';

  const msg = {
    serverAddress: '0x' + serverAddress.toString('hex'),
    playerAddress: playerAddress,
    sourceStructureId: dummySourceId,
    sourceLocationHash: locationHash,
    targetStructureId: dummyTargetId,
    targetLocationHash: locationHash,
    distance: distance,
    data: Buffer.alloc(0),
    deadlineMs: deadlineMs,
  };

  const msgBytes = bcsSerializeMessage(msg);
  
  // Hash: blake2b256(0x030000 || bcs_message_bytes)
  const intentPrefix = Buffer.from('030000', 'hex');
  const intentMsg = Buffer.concat([intentPrefix, msgBytes]);
  const digest = Buffer.from(blake2b(intentMsg, { dkLen: 32 }));

  console.error('Message BCS bytes:', msgBytes.length, 'bytes');
  console.error('Digest:', digest.toString('hex'));

  // Sign the digest with Ed25519
  const rawSig = crypto.sign(null, digest, keyObj);
  
  console.error('Signature:', rawSig.toString('hex'));
  console.error('Signature length:', rawSig.length);

  // Compose Sui-format signature: [0x00 flag] + [64-byte sig] + [32-byte pubkey]
  const suiSig = Buffer.concat([
    Buffer.from([0x00]),
    rawSig,
    pubKeyBytes,
  ]);
  
  console.error('Sui signature length:', suiSig.length, '(expected 97)');

  // BCS-serialize full proof
  const proofBytes = bcsSerializeProof(msg, suiSig);
  
  console.error('Proof bytes length:', proofBytes.length);
  
  // Output hex-encoded on stdout
  console.log(proofBytes.toString('hex'));
}

main();
