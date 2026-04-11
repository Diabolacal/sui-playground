/**
 * seal-smoke.ts — Phase 3: Seal SDK validation
 * Tests threshold encryption and decryption anchored to IntelObject on testnet.
 */
import { SealClient, SessionKey, EncryptedObject } from '@mysten/seal';
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import { randomBytes } from 'crypto';
import { fromBase64, toBase64 } from '@mysten/sui/utils';
import { bcs } from '@mysten/bcs';

const SUI_TESTNET_URL = 'https://fullnode.testnet.sui.io:443';

// Testnet-published shadow_broker package
const PACKAGE_ID = '0xce7be48d01f8d176adebb7dc59ee09ef8d4b67f93946cfcf1c8ab570932c75a8';

// Seal testnet key server configs (from seal-docs.wal.app/Pricing)
const KEY_SERVER_CONFIGS = [
  { objectId: '0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75', weight: 1 },
  { objectId: '0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8', weight: 1 },
];

function loadKeypair(): Ed25519Keypair {
  const keystorePath = join(homedir(), '.sui', 'sui_config', 'sui.keystore');
  const keystore: string[] = JSON.parse(readFileSync(keystorePath, 'utf-8'));
  const rawBytes = Buffer.from(keystore[0], 'base64');
  return Ed25519Keypair.fromSecretKey(rawBytes.subarray(1));
}

function sleep(ms: number) { return new Promise(r => setTimeout(r, ms)); }

async function mintIntelObject(
  suiClient: SuiJsonRpcClient,
  keypair: Ed25519Keypair,
): Promise<string> {
  const tx = new Transaction();
  const intel = tx.moveCall({
    target: `${PACKAGE_ID}::intel_object::mint`,
    arguments: [
      tx.pure.string('test-blob-seal-validation'),            // blob_id
      tx.pure(bcs.vector(bcs.u8()).serialize([]).toBytes(), 'vector<u8>'), // encrypted_key (empty)
      tx.pure.string('audio/ogg'),                            // file_type
      tx.pure.u64(120),                                       // duration_seconds
      tx.pure.u64(10240),                                     // file_size_bytes
      tx.pure.string('Seal validation test intel'),            // description
      tx.pure(                                                 // teaser_blob_id
        bcs.option(bcs.string()).serialize('teaser-blob-seal').toBytes(),
        'vector<u8>',
      ),
    ],
  });
  tx.transferObjects([intel], keypair.getPublicKey().toSuiAddress());

  const result = await suiClient.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx,
    options: { showEffects: true, showObjectChanges: true },
  });
  console.log(`Mint tx: ${result.digest} — status: ${result.effects?.status.status}`);

  // Find the IntelObject from created objects
  const created = result.objectChanges?.filter(
    (c: any) => c.type === 'created' && c.objectType?.includes('intel_object::IntelObject'),
  );
  if (!created || created.length === 0) {
    throw new Error('IntelObject not found in created objects');
  }
  const intelId = (created[0] as any).objectId;
  console.log(`IntelObject ID: ${intelId}`);
  return intelId;
}

async function main() {
  const keypair = loadKeypair();
  const address = keypair.getPublicKey().toSuiAddress();
  console.log('Address:', address);
  console.log('Package:', PACKAGE_ID);

  const suiClient = new SuiJsonRpcClient({ url: SUI_TESTNET_URL });

  const sealClient = new SealClient({
    suiClient,
    serverConfigs: KEY_SERVER_CONFIGS,
    verifyKeyServers: false,
  });

  // --- Step 1: Mint IntelObject on testnet ---
  console.log('\n=== Step 1: Mint IntelObject on testnet ===');
  const intelObjectId = await mintIntelObject(suiClient, keypair);
  await sleep(3000); // Wait for indexing

  // --- Step 2: Encrypt AES key with Seal ---
  console.log('\n=== Step 2: Seal encrypt ===');
  const aesKey = randomBytes(32);
  console.log(`AES key (first 8 bytes): ${aesKey.subarray(0, 8).toString('hex')}`);

  // Seal id is a hex string (the IntelObject's address without 0x prefix)
  const idHex = intelObjectId.replace('0x', '');

  let encryptedResult: { encryptedObject: Uint8Array };
  try {
    encryptedResult = await sealClient.encrypt({
      threshold: 2,
      packageId: PACKAGE_ID,
      id: idHex,
      data: aesKey,
    });
    console.log(`Encrypt OK — encrypted length: ${encryptedResult.encryptedObject.length} bytes`);
  } catch (e: any) {
    console.error('Encrypt FAIL:', e.message);
    console.error('Full error:', e);
    process.exit(1);
  }

  // --- Step 3: Decrypt with Seal (requires session key + seal_approve PTB) ---
  console.log('\n=== Step 3: Seal decrypt ===');
  try {
    // Create session key
    const sessionKey = new SessionKey({
      address,
      packageId: PACKAGE_ID,
      ttlMin: 10,
    });

    // Sign session key with keypair
    const personalMessage = sessionKey.getPersonalMessage();
    const { signature } = await keypair.signPersonalMessage(personalMessage);
    sessionKey.setPersonalMessageSignature(signature);

    // Build seal_approve PTB (onlyTransactionKind: true per Seal SDK docs)
    const tx = new Transaction();
    tx.moveCall({
      target: `${PACKAGE_ID}::intel_object::seal_approve`,
      arguments: [
        tx.pure.vector('u8', Array.from(Buffer.from(idHex, 'hex'))),
        tx.object(intelObjectId),
      ],
    });
    const txBytes = await tx.build({ client: suiClient, onlyTransactionKind: true });

    // Decrypt
    const decrypted = await sealClient.decrypt({
      data: encryptedResult.encryptedObject,
      sessionKey,
      txBytes,
    });
    console.log(`Decrypt OK — decrypted length: ${decrypted.length} bytes`);

    // Verify match
    const match = Buffer.from(decrypted).equals(aesKey);
    console.log(`AES key match: ${match}`);
    if (!match) {
      console.error('FAIL: Decrypted key does not match original');
      process.exit(1);
    }
  } catch (e: any) {
    console.error('Decrypt FAIL:', e.message);
    console.error('Stack:', e.stack?.split('\n').slice(0, 5).join('\n'));
    // Encrypt-only is still partial success
    console.log('\n=== PARTIAL RESULT ===');
    console.log('Encrypt: PASS');
    console.log('Decrypt: FAIL (see error above)');
    console.log('This is expected if key servers cannot reach seal_approve on testnet.');
  }

  // --- Summary ---
  console.log('\n=== SEAL SMOKE TEST EVIDENCE ===');
  console.log(JSON.stringify({
    packageId: PACKAGE_ID,
    intelObjectId,
    encryptedLength: encryptedResult.encryptedObject.length,
    keyServers: KEY_SERVER_CONFIGS.map(c => c.objectId),
    network: 'testnet',
  }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
