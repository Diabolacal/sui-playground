/**
 * on-chain-smoke.ts — Phase 1.7: On-chain smoke test
 * Mints an IntelObject, lists it, then purchases it on local devnet.
 */
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';
import { Transaction } from '@mysten/sui/transactions';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const PKG = '0x2966ff1c877047b4d0eb434e66b493051036348ef8517d250c9d766c2c395372';
const RPC_URL = 'http://127.0.0.1:9000';

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
  // Load keypair from Sui keystore (base64 format)
  const keystorePath = join(homedir(), '.sui', 'sui_config', 'sui.keystore');
  const keystore: string[] = JSON.parse(readFileSync(keystorePath, 'utf-8'));
  // Keystore entries are base64-encoded: first byte is scheme flag, rest is secret key
  const rawBytes = Buffer.from(keystore[0], 'base64');
  const schemeFlag = rawBytes[0]; // 0 = Ed25519
  const secretKeyBytes = rawBytes.subarray(1);
  const keypair = Ed25519Keypair.fromSecretKey(secretKeyBytes);
  const address = keypair.getPublicKey().toSuiAddress();

  const client = new SuiJsonRpcClient({ url: RPC_URL });

  console.log('Address:', address);
  console.log('Package:', PKG);

  // --- Step 1: Mint IntelObject ---
  console.log('\n=== Step 1: Mint IntelObject ===');
  const mintTx = new Transaction();
  const intel = mintTx.moveCall({
    target: `${PKG}::intel_object::mint`,
    arguments: [
      mintTx.pure.string('test-blob-123'),
      mintTx.pure('vector<u8>', []),
      mintTx.pure.string('audio/mp3'),
      mintTx.pure.u64(120),
      mintTx.pure.u64(1048576),
      mintTx.pure.string('Fleet movements near X-7OMU'),
      mintTx.pure('option<string>', null),
    ],
  });
  mintTx.transferObjects([intel], mintTx.pure.address(address));

  const mintResult = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: mintTx,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });
  console.log('Mint tx digest:', mintResult.digest);
  console.log('Mint status:', mintResult.effects?.status?.status);

  // Find the created IntelObject ID
  const intelObj = mintResult.objectChanges?.find(
    (c: any) => c.type === 'created' && c.objectType?.includes('intel_object::IntelObject')
  );
  const intelObjectId = (intelObj as any)?.objectId;
  console.log('IntelObject ID:', intelObjectId);

  // Show events
  if (mintResult.events?.length) {
    console.log('Events:', JSON.stringify(mintResult.events[0].parsedJson, null, 2));
  }

  if (!intelObjectId) {
    console.error('FAIL: IntelObject not created');
    process.exit(1);
  }

  // --- Step 2: List on marketplace ---
  console.log('\n=== Step 2: List on marketplace ===');
  await sleep(2000); // Wait for object indexing on local devnet
  const listTx = new Transaction();
  listTx.moveCall({
    target: `${PKG}::marketplace::list`,
    arguments: [
      listTx.object(intelObjectId),
      listTx.pure.u64(1_000_000_000), // 1 SUI
    ],
  });

  const listResult = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: listTx,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });
  console.log('List tx digest:', listResult.digest);
  console.log('List status:', listResult.effects?.status?.status);

  const listingObj = listResult.objectChanges?.find(
    (c: any) => c.type === 'created' && c.objectType?.includes('marketplace::Listing')
  );
  const listingId = (listingObj as any)?.objectId;
  console.log('Listing ID:', listingId);

  if (listResult.events?.length) {
    console.log('Events:', JSON.stringify(listResult.events[0].parsedJson, null, 2));
  }

  if (!listingId) {
    console.error('FAIL: Listing not created');
    process.exit(1);
  }

  // --- Step 3: Purchase ---
  console.log('\n=== Step 3: Purchase ===');
  await sleep(2000); // Wait for Listing to be indexed
  const purchaseTx = new Transaction();
  const [paymentCoin] = purchaseTx.splitCoins(purchaseTx.gas, [1_000_000_000]);
  const purchasedIntel = purchaseTx.moveCall({
    target: `${PKG}::marketplace::purchase`,
    arguments: [
      purchaseTx.object(listingId),
      paymentCoin,
    ],
  });
  purchaseTx.transferObjects([purchasedIntel], purchaseTx.pure.address(address));

  const purchaseResult = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: purchaseTx,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });
  console.log('Purchase tx digest:', purchaseResult.digest);
  console.log('Purchase status:', purchaseResult.effects?.status?.status);

  if (purchaseResult.events?.length) {
    console.log('Events:', JSON.stringify(purchaseResult.events[0].parsedJson, null, 2));
  }

  // Verify IntelObject is back in wallet
  const ownedObjects = await client.getOwnedObjects({
    owner: address,
    filter: { StructType: `${PKG}::intel_object::IntelObject` },
  });
  console.log('\nIntelObjects owned after purchase:', ownedObjects.data.length);

  // --- Summary ---
  console.log('\n=== SMOKE TEST RESULTS ===');
  console.log('Mint:', mintResult.effects?.status?.status === 'success' ? 'PASS' : 'FAIL');
  console.log('List:', listResult.effects?.status?.status === 'success' ? 'PASS' : 'FAIL');
  console.log('Purchase:', purchaseResult.effects?.status?.status === 'success' ? 'PASS' : 'FAIL');
  console.log('IntelObject recovered:', ownedObjects.data.length > 0 ? 'PASS' : 'FAIL');

  // Output JSON evidence
  const evidence = {
    packageId: PKG,
    address,
    mintDigest: mintResult.digest,
    intelObjectId,
    listDigest: listResult.digest,
    listingId,
    purchaseDigest: purchaseResult.digest,
    intelObjectRecovered: ownedObjects.data.length > 0,
  };
  console.log('\nEvidence JSON:', JSON.stringify(evidence, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
