/**
 * e2e-smoke.ts — Phase 4: End-to-end envelope encryption pipeline
 * Full seller → buyer flow using Sui Move, Walrus, and Seal.
 * Uses a single keypair for validation (seller = buyer).
 *
 * Pipeline:
 *  1. Generate AES-256 key + test audio payload
 *  2. AES-GCM encrypt the audio
 *  3. Upload encrypted audio to Walrus → blobId
 *  4. Upload teaser to Walrus → teaserBlobId
 *  5. Mint IntelObject (empty encrypted_key)
 *  6. Seal-encrypt AES key anchored to IntelObject
 *  7. Update IntelObject's encrypted_key on-chain
 *  8. List IntelObject on marketplace
 *  9. Purchase listing (same wallet)
 * 10. Download teaser from Walrus, verify
 * 11. Seal-decrypt encrypted_key → recover AES key
 * 12. Download encrypted audio from Walrus
 * 13. AES-GCM decrypt → verify matches original
 */
import { WalrusClient, TESTNET_WALRUS_PACKAGE_CONFIG } from '@mysten/walrus';
import { SealClient, SessionKey } from '@mysten/seal';
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import { randomBytes, webcrypto } from 'crypto';
import { bcs } from '@mysten/bcs';

// --- Constants ---
const SUI_TESTNET_URL = 'https://fullnode.testnet.sui.io:443';
const PACKAGE_ID = '0xce7be48d01f8d176adebb7dc59ee09ef8d4b67f93946cfcf1c8ab570932c75a8';
const KEY_SERVER_CONFIGS = [
  { objectId: '0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75', weight: 1 },
  { objectId: '0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8', weight: 1 },
];

// WAL exchange
const WAL_EXCHANGE_PKG = '0x82593828ed3fcb8c6a235eac9abd0adbe9c5f9bbffa9b1e7a45cdd884481ef9f';
const WAL_EXCHANGE_OBJ = '0xf4d164ea2def5fe07dc573992a029e010dba09b1a8dcbc44c5c2e79567f39073';
const WAL_TYPE = '0x8270feb7375eee355e64fdb69c50abb6b5f9393a722883c1cf45f8e26048810a::wal::WAL';

// --- Utilities ---

function loadKeypair(): Ed25519Keypair {
  const keystorePath = join(homedir(), '.sui', 'sui_config', 'sui.keystore');
  const keystore: string[] = JSON.parse(readFileSync(keystorePath, 'utf-8'));
  const rawBytes = Buffer.from(keystore[0], 'base64');
  return Ed25519Keypair.fromSecretKey(rawBytes.subarray(1));
}

function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

async function aesEncrypt(key: Uint8Array, plaintext: Uint8Array): Promise<Uint8Array> {
  const iv = webcrypto.getRandomValues(new Uint8Array(12));
  const cryptoKey = await webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['encrypt']);
  const ciphertext = new Uint8Array(await webcrypto.subtle.encrypt({ name: 'AES-GCM', iv }, cryptoKey, plaintext));
  // Prepend IV to ciphertext: [12-byte IV | ciphertext]
  const combined = new Uint8Array(iv.length + ciphertext.length);
  combined.set(iv);
  combined.set(ciphertext, iv.length);
  return combined;
}

async function aesDecrypt(key: Uint8Array, combined: Uint8Array): Promise<Uint8Array> {
  const iv = combined.slice(0, 12);
  const ciphertext = combined.slice(12);
  const cryptoKey = await webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['decrypt']);
  return new Uint8Array(await webcrypto.subtle.decrypt({ name: 'AES-GCM', iv }, cryptoKey, ciphertext));
}

async function ensureWalBalance(suiClient: SuiJsonRpcClient, keypair: Ed25519Keypair) {
  const address = keypair.getPublicKey().toSuiAddress();
  const coins = await suiClient.getCoins({ owner: address, coinType: WAL_TYPE });
  const balance = coins.data.reduce((sum: bigint, c: any) => sum + BigInt(c.balance), 0n);
  if (balance < 500_000n) {
    console.log('  Exchanging 0.5 SUI for WAL tokens...');
    const tx = new Transaction();
    const [coin] = tx.splitCoins(tx.gas, [500_000_000n]);
    const [walCoin] = tx.moveCall({
      target: `${WAL_EXCHANGE_PKG}::wal_exchange::exchange_all_for_wal`,
      arguments: [tx.object(WAL_EXCHANGE_OBJ), coin],
    });
    tx.transferObjects([walCoin], tx.pure.address(address));
    await suiClient.signAndExecuteTransaction({ signer: keypair, transaction: tx });
    await sleep(3000);
  }
}

// --- Main Pipeline ---

interface StepResult {
  step: number;
  name: string;
  status: 'PASS' | 'FAIL';
  durationMs: number;
  data?: Record<string, unknown>;
  error?: string;
}

async function main() {
  const keypair = loadKeypair();
  const address = keypair.getPublicKey().toSuiAddress();
  const suiClient = new SuiJsonRpcClient({ url: SUI_TESTNET_URL });
  const walrus = new WalrusClient({ network: 'testnet', suiClient, packageConfig: TESTNET_WALRUS_PACKAGE_CONFIG });
  const sealClient = new SealClient({ suiClient, serverConfigs: KEY_SERVER_CONFIGS, verifyKeyServers: false });

  const results: StepResult[] = [];
  const pipelineStart = Date.now();

  console.log('=== Shadow Broker E2E Pipeline ===');
  console.log(`Address: ${address}`);
  console.log(`Package: ${PACKAGE_ID}`);

  // Ensure WAL balance for Walrus uploads
  await ensureWalBalance(suiClient, keypair);

  // ---- Step 1: Generate AES key + test audio ----
  let t = Date.now();
  const aesKey = randomBytes(32);
  const audioPayload = randomBytes(10240); // 10KB simulated audio
  const teaser = audioPayload.slice(0, 100); // First 100 bytes as teaser
  results.push({ step: 1, name: 'Generate AES key + audio', status: 'PASS', durationMs: Date.now() - t,
    data: { aesKeyPrefix: aesKey.subarray(0, 8).toString('hex'), audioSize: audioPayload.length } });
  console.log(`\n[1] Generate AES key + audio — PASS (${audioPayload.length} bytes)`);

  // ---- Step 2: AES-GCM encrypt audio ----
  t = Date.now();
  let encryptedAudio: Uint8Array;
  try {
    encryptedAudio = await aesEncrypt(aesKey, audioPayload);
    results.push({ step: 2, name: 'AES-GCM encrypt audio', status: 'PASS', durationMs: Date.now() - t,
      data: { encryptedSize: encryptedAudio.length } });
    console.log(`[2] AES-GCM encrypt — PASS (${encryptedAudio.length} bytes, includes 12-byte IV)`);
  } catch (e: any) {
    results.push({ step: 2, name: 'AES-GCM encrypt audio', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[2] AES-GCM encrypt — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 3: Upload encrypted audio to Walrus ----
  t = Date.now();
  let audioBlobId: string;
  try {
    const res = await walrus.writeBlob({ blob: encryptedAudio, deletable: true, epochs: 3, signer: keypair });
    audioBlobId = res.blobId;
    results.push({ step: 3, name: 'Upload encrypted audio to Walrus', status: 'PASS', durationMs: Date.now() - t,
      data: { blobId: audioBlobId } });
    console.log(`[3] Walrus upload (audio) — PASS (blobId: ${audioBlobId.slice(0, 20)}...)`);
  } catch (e: any) {
    results.push({ step: 3, name: 'Upload encrypted audio to Walrus', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[3] Walrus upload (audio) — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 4: Upload teaser to Walrus ----
  t = Date.now();
  let teaserBlobId: string;
  try {
    const res = await walrus.writeBlob({ blob: teaser, deletable: true, epochs: 3, signer: keypair });
    teaserBlobId = res.blobId;
    results.push({ step: 4, name: 'Upload teaser to Walrus', status: 'PASS', durationMs: Date.now() - t,
      data: { teaserBlobId } });
    console.log(`[4] Walrus upload (teaser) — PASS (blobId: ${teaserBlobId.slice(0, 20)}...)`);
  } catch (e: any) {
    results.push({ step: 4, name: 'Upload teaser to Walrus', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[4] Walrus upload (teaser) — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 5: Mint IntelObject (empty encrypted_key) ----
  t = Date.now();
  let intelObjectId: string;
  try {
    const tx = new Transaction();
    const intel = tx.moveCall({
      target: `${PACKAGE_ID}::intel_object::mint`,
      arguments: [
        tx.pure.string(audioBlobId),
        tx.pure(bcs.vector(bcs.u8()).serialize([]).toBytes(), 'vector<u8>'), // empty encrypted_key
        tx.pure.string('audio/ogg'),
        tx.pure.u64(120),
        tx.pure.u64(encryptedAudio.length),
        tx.pure.string('E2E validation: encrypted intelligence'),
        tx.pure(bcs.option(bcs.string()).serialize(teaserBlobId).toBytes(), 'vector<u8>'),
      ],
    });
    tx.transferObjects([intel], address);
    const res = await suiClient.signAndExecuteTransaction({
      signer: keypair, transaction: tx, options: { showEffects: true, showObjectChanges: true },
    });
    const created = res.objectChanges?.filter(
      (c: any) => c.type === 'created' && c.objectType?.includes('intel_object::IntelObject'),
    );
    intelObjectId = (created![0] as any).objectId;
    results.push({ step: 5, name: 'Mint IntelObject', status: 'PASS', durationMs: Date.now() - t,
      data: { intelObjectId, digest: res.digest } });
    console.log(`[5] Mint IntelObject — PASS (${intelObjectId})`);
    await sleep(2000);
  } catch (e: any) {
    results.push({ step: 5, name: 'Mint IntelObject', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[5] Mint IntelObject — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 6: Seal-encrypt AES key ----
  t = Date.now();
  const idHex = intelObjectId.replace('0x', '');
  let sealEncrypted: Uint8Array;
  try {
    const res = await sealClient.encrypt({
      threshold: 2,
      packageId: PACKAGE_ID,
      id: idHex,
      data: aesKey,
    });
    sealEncrypted = res.encryptedObject;
    results.push({ step: 6, name: 'Seal encrypt AES key', status: 'PASS', durationMs: Date.now() - t,
      data: { encryptedLength: sealEncrypted.length } });
    console.log(`[6] Seal encrypt — PASS (${sealEncrypted.length} bytes)`);
  } catch (e: any) {
    results.push({ step: 6, name: 'Seal encrypt AES key', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[6] Seal encrypt — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 7: Update encrypted_key on-chain ----
  t = Date.now();
  try {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::intel_object::update_encrypted_key`,
      arguments: [
        tx.object(intelObjectId),
        tx.pure.vector('u8', Array.from(sealEncrypted)),
      ],
    });
    const res = await suiClient.signAndExecuteTransaction({
      signer: keypair, transaction: tx, options: { showEffects: true },
    });
    results.push({ step: 7, name: 'Update encrypted_key on-chain', status: 'PASS', durationMs: Date.now() - t,
      data: { digest: res.digest } });
    console.log(`[7] Update encrypted_key — PASS (${res.digest})`);
    await sleep(2000);
  } catch (e: any) {
    results.push({ step: 7, name: 'Update encrypted_key on-chain', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[7] Update encrypted_key — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 8: List on marketplace ----
  t = Date.now();
  let listingId: string;
  try {
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::marketplace::list`,
      arguments: [
        tx.object(intelObjectId),
        tx.pure.u64(1_000_000), // 0.001 SUI
      ],
    });
    const res = await suiClient.signAndExecuteTransaction({
      signer: keypair, transaction: tx, options: { showEffects: true, showObjectChanges: true },
    });
    const created = res.objectChanges?.filter(
      (c: any) => c.type === 'created' && c.objectType?.includes('marketplace::Listing'),
    );
    listingId = (created![0] as any).objectId;
    results.push({ step: 8, name: 'List on marketplace', status: 'PASS', durationMs: Date.now() - t,
      data: { listingId, digest: res.digest } });
    console.log(`[8] List on marketplace — PASS (${listingId})`);
    await sleep(2000);
  } catch (e: any) {
    results.push({ step: 8, name: 'List on marketplace', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[8] List on marketplace — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 9: Purchase listing ----
  t = Date.now();
  let recoveredIntelId: string;
  try {
    const tx = new Transaction();
    const [coin] = tx.splitCoins(tx.gas, [1_000_000n]);
    const recoveredIntel = tx.moveCall({
      target: `${PACKAGE_ID}::marketplace::purchase`,
      arguments: [tx.object(listingId), coin],
    });
    tx.transferObjects([recoveredIntel], address);
    const res = await suiClient.signAndExecuteTransaction({
      signer: keypair, transaction: tx, options: { showEffects: true, showObjectChanges: true },
    });
    // The purchased IntelObject should appear in objectChanges
    const received = res.objectChanges?.filter(
      (c: any) => c.type === 'created' && c.objectType?.includes('intel_object::IntelObject'),
    );
    // It might show as 'mutated' since it was extracted from the listing
    const mutated = res.objectChanges?.filter(
      (c: any) => (c.type === 'mutated' || c.type === 'created') && c.objectType?.includes('intel_object::IntelObject'),
    );
    recoveredIntelId = mutated && mutated.length > 0 ? (mutated[0] as any).objectId : intelObjectId;
    results.push({ step: 9, name: 'Purchase listing', status: 'PASS', durationMs: Date.now() - t,
      data: { digest: res.digest, recoveredIntelId } });
    console.log(`[9] Purchase listing — PASS (recovered intel: ${recoveredIntelId})`);
    await sleep(2000);
  } catch (e: any) {
    results.push({ step: 9, name: 'Purchase listing', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[9] Purchase listing — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 10: Download teaser from Walrus, verify ----
  t = Date.now();
  try {
    const blob = await walrus.getBlob({ blobId: teaserBlobId });
    const downloaded = await blob.asFile().bytes();
    const match = Buffer.from(downloaded).equals(Buffer.from(teaser));
    if (!match) throw new Error('Teaser bytes mismatch');
    results.push({ step: 10, name: 'Download teaser + verify', status: 'PASS', durationMs: Date.now() - t,
      data: { size: downloaded.length } });
    console.log(`[10] Download teaser — PASS (${downloaded.length} bytes, verified)`);
  } catch (e: any) {
    results.push({ step: 10, name: 'Download teaser + verify', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[10] Download teaser — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 11: Seal-decrypt to recover AES key ----
  t = Date.now();
  let recoveredAesKey: Uint8Array;
  try {
    // Read the encrypted_key from on-chain (JSON-RPC with showContent)
    const objResp = await suiClient.getObject({
      id: recoveredIntelId,
      options: { showContent: true },
    });
    const fields = (objResp.data?.content as any)?.fields;
    if (!fields?.encrypted_key) throw new Error('Could not read encrypted_key from on-chain object');
    const onChainEncryptedKey = new Uint8Array(fields.encrypted_key.map(Number));

    // Create session key and decrypt
    const sessionKey = new SessionKey({ address, packageId: PACKAGE_ID, ttlMin: 10 });
    const personalMessage = sessionKey.getPersonalMessage();
    const { signature } = await keypair.signPersonalMessage(personalMessage);
    sessionKey.setPersonalMessageSignature(signature);

    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::intel_object::seal_approve`,
      arguments: [
        tx.pure.vector('u8', Array.from(Buffer.from(idHex, 'hex'))),
        tx.object(recoveredIntelId),
      ],
    });
    const txBytes = await tx.build({ client: suiClient, onlyTransactionKind: true });

    recoveredAesKey = await sealClient.decrypt({
      data: onChainEncryptedKey,
      sessionKey,
      txBytes,
    });

    const keyMatch = Buffer.from(recoveredAesKey).equals(Buffer.from(aesKey));
    if (!keyMatch) throw new Error('Recovered AES key does not match original');

    results.push({ step: 11, name: 'Seal decrypt AES key', status: 'PASS', durationMs: Date.now() - t,
      data: { recoveredKeySize: recoveredAesKey.length } });
    console.log(`[11] Seal decrypt — PASS (${recoveredAesKey.length} bytes, key verified)`);
  } catch (e: any) {
    results.push({ step: 11, name: 'Seal decrypt AES key', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[11] Seal decrypt — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 12: Download encrypted audio from Walrus ----
  t = Date.now();
  let downloadedEncryptedAudio: Uint8Array;
  try {
    const blob = await walrus.getBlob({ blobId: audioBlobId });
    downloadedEncryptedAudio = await blob.asFile().bytes();
    const match = Buffer.from(downloadedEncryptedAudio).equals(Buffer.from(encryptedAudio));
    if (!match) throw new Error('Downloaded encrypted audio does not match uploaded');
    results.push({ step: 12, name: 'Download encrypted audio', status: 'PASS', durationMs: Date.now() - t,
      data: { size: downloadedEncryptedAudio.length } });
    console.log(`[12] Download encrypted audio — PASS (${downloadedEncryptedAudio.length} bytes)`);
  } catch (e: any) {
    results.push({ step: 12, name: 'Download encrypted audio', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[12] Download encrypted audio — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  // ---- Step 13: AES-GCM decrypt + verify ----
  t = Date.now();
  try {
    const decryptedAudio = await aesDecrypt(recoveredAesKey, downloadedEncryptedAudio);
    const match = Buffer.from(decryptedAudio).equals(Buffer.from(audioPayload));
    if (!match) throw new Error('Decrypted audio does not match original');
    results.push({ step: 13, name: 'AES-GCM decrypt + verify', status: 'PASS', durationMs: Date.now() - t,
      data: { decryptedSize: decryptedAudio.length } });
    console.log(`[13] AES-GCM decrypt — PASS (${decryptedAudio.length} bytes, matches original)`);
  } catch (e: any) {
    results.push({ step: 13, name: 'AES-GCM decrypt + verify', status: 'FAIL', durationMs: Date.now() - t, error: e.message });
    console.error(`[13] AES-GCM decrypt — FAIL: ${e.message}`);
    return printSummary(results, pipelineStart);
  }

  printSummary(results, pipelineStart);
}

function printSummary(results: StepResult[], startTime: number) {
  const totalMs = Date.now() - startTime;
  const passCount = results.filter(r => r.status === 'PASS').length;
  const failCount = results.filter(r => r.status === 'FAIL').length;

  console.log('\n' + '='.repeat(60));
  console.log('SHADOW BROKER E2E PIPELINE — RESULTS');
  console.log('='.repeat(60));
  for (const r of results) {
    console.log(`  [${r.step.toString().padStart(2)}] ${r.status} ${r.name} (${r.durationMs}ms)`);
    if (r.error) console.log(`       Error: ${r.error}`);
  }
  console.log('-'.repeat(60));
  console.log(`  Total: ${passCount} PASS / ${failCount} FAIL / ${13 - results.length} SKIPPED`);
  console.log(`  Duration: ${(totalMs / 1000).toFixed(1)}s`);
  console.log('='.repeat(60));

  // JSON evidence dump
  console.log('\n=== E2E EVIDENCE JSON ===');
  console.log(JSON.stringify({
    packageId: PACKAGE_ID,
    network: 'testnet',
    totalSteps: 13,
    passCount,
    failCount,
    totalDurationMs: totalMs,
    steps: results.map(r => ({
      step: r.step,
      name: r.name,
      status: r.status,
      durationMs: r.durationMs,
      ...(r.data || {}),
      ...(r.error ? { error: r.error } : {}),
    })),
  }, null, 2));

  if (failCount > 0) process.exit(1);
}

main().catch((e) => { console.error(e); process.exit(1); });
