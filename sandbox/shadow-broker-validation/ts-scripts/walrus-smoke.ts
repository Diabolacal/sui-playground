/**
 * walrus-smoke.ts — Phase 2: Walrus SDK validation
 * Tests upload and download of blobs against Walrus testnet.
 * Automatically exchanges SUI for WAL tokens if needed.
 */
import { WalrusClient, TESTNET_WALRUS_PACKAGE_CONFIG } from '@mysten/walrus';
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Transaction } from '@mysten/sui/transactions';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import { randomBytes } from 'crypto';

// Walrus runs on Sui testnet — needs a testnet-funded wallet
const SUI_TESTNET_URL = 'https://fullnode.testnet.sui.io:443';

// Walrus exchange contract (SUI <-> WAL)
const WAL_EXCHANGE_PKG = '0x82593828ed3fcb8c6a235eac9abd0adbe9c5f9bbffa9b1e7a45cdd884481ef9f';
const WAL_EXCHANGE_OBJ = '0xf4d164ea2def5fe07dc573992a029e010dba09b1a8dcbc44c5c2e79567f39073';
const WAL_TYPE = '0x8270feb7375eee355e64fdb69c50abb6b5f9393a722883c1cf45f8e26048810a::wal::WAL';

function loadKeypair(): Ed25519Keypair {
  const keystorePath = join(homedir(), '.sui', 'sui_config', 'sui.keystore');
  const keystore: string[] = JSON.parse(readFileSync(keystorePath, 'utf-8'));
  const rawBytes = Buffer.from(keystore[0], 'base64');
  const secretKeyBytes = rawBytes.subarray(1);
  return Ed25519Keypair.fromSecretKey(secretKeyBytes);
}

async function exchangeSuiForWal(
  suiClient: SuiJsonRpcClient,
  keypair: Ed25519Keypair,
  suiAmount: bigint,
): Promise<string> {
  const tx = new Transaction();
  const [coin] = tx.splitCoins(tx.gas, [suiAmount]);
  const [walCoin] = tx.moveCall({
    target: `${WAL_EXCHANGE_PKG}::wal_exchange::exchange_all_for_wal`,
    arguments: [tx.object(WAL_EXCHANGE_OBJ), coin],
  });
  tx.transferObjects([walCoin], tx.pure.address(keypair.getPublicKey().toSuiAddress()));
  const result = await suiClient.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx,
    options: { showEffects: true },
  });
  console.log(`Exchange tx: ${result.digest} — status: ${result.effects?.status.status}`);
  return result.digest;
}

async function checkWalBalance(suiClient: SuiJsonRpcClient, address: string): Promise<bigint> {
  const coins = await suiClient.getCoins({ owner: address, coinType: WAL_TYPE });
  return coins.data.reduce((sum: bigint, c: any) => sum + BigInt(c.balance), 0n);
}

async function main() {
  const keypair = loadKeypair();
  const address = keypair.getPublicKey().toSuiAddress();
  console.log('Address:', address);

  const suiClient = new SuiJsonRpcClient({ url: SUI_TESTNET_URL });
  const walrus = new WalrusClient({
    network: 'testnet',
    suiClient,
    packageConfig: TESTNET_WALRUS_PACKAGE_CONFIG,
  });

  // --- Step 0: Ensure WAL balance ---
  let walBalance = await checkWalBalance(suiClient, address);
  console.log(`WAL balance: ${walBalance}`);
  if (walBalance < 500_000n) {
    console.log('Exchanging 0.5 SUI for WAL...');
    await exchangeSuiForWal(suiClient, keypair, 500_000_000n);
    // Wait for indexing
    await new Promise((r) => setTimeout(r, 3000));
    walBalance = await checkWalBalance(suiClient, address);
    console.log(`WAL balance after exchange: ${walBalance}`);
  }

  // --- Test 1: Upload an encrypted audio blob (simulated) ---
  console.log('\n=== Test 1: Upload encrypted audio blob ===');
  const encryptedAudio = randomBytes(1024); // 1KB simulated encrypted audio
  const t1Start = Date.now();

  let blobId: string;
  try {
    const result = await walrus.writeBlob({
      blob: encryptedAudio,
      deletable: true,
      epochs: 3,
      signer: keypair,
    });
    blobId = result.blobId;
    console.log(`Upload 1 OK — blobId: ${blobId}, time: ${Date.now() - t1Start}ms`);
  } catch (e: any) {
    console.error('Upload 1 FAIL:', e.message);
    console.error('Full error:', e);
    process.exit(1);
  }

  // --- Test 2: Download and verify ---
  console.log('\n=== Test 2: Download and verify ===');
  const t2Start = Date.now();
  try {
    const blob = await walrus.getBlob({ blobId });
    const downloadedBytes = await blob.asFile().bytes();
    const match = Buffer.from(downloadedBytes).equals(encryptedAudio);
    console.log(`Download OK — size: ${downloadedBytes.length}, match: ${match}, time: ${Date.now() - t2Start}ms`);
    if (!match) {
      console.error('FAIL: Downloaded bytes do not match uploaded bytes');
      process.exit(1);
    }
  } catch (e: any) {
    console.error('Download FAIL:', e.message);
    process.exit(1);
  }

  // --- Test 3: Upload teaser blob (unencrypted) ---
  console.log('\n=== Test 3: Upload teaser blob ===');
  const teaser = randomBytes(100); // 100 bytes simulated teaser
  const t3Start = Date.now();

  let teaserBlobId: string;
  try {
    const result = await walrus.writeBlob({
      blob: teaser,
      deletable: true,
      epochs: 3,
      signer: keypair,
    });
    teaserBlobId = result.blobId;
    console.log(`Upload 2 OK — teaserBlobId: ${teaserBlobId}, time: ${Date.now() - t3Start}ms`);
  } catch (e: any) {
    console.error('Upload 2 FAIL:', e.message);
    process.exit(1);
  }

  // --- Test 4: Download teaser and verify ---
  console.log('\n=== Test 4: Download teaser and verify ===');
  const t4Start = Date.now();
  try {
    const blob = await walrus.getBlob({ blobId: teaserBlobId });
    const downloadedBytes = await blob.asFile().bytes();
    const match = Buffer.from(downloadedBytes).equals(teaser);
    console.log(`Teaser download OK — size: ${downloadedBytes.length}, match: ${match}, time: ${Date.now() - t4Start}ms`);
    if (!match) {
      console.error('FAIL: Teaser bytes do not match');
      process.exit(1);
    }
  } catch (e: any) {
    console.error('Teaser download FAIL:', e.message);
    process.exit(1);
  }

  // --- Summary ---
  console.log('\n=== WALRUS SMOKE TEST RESULTS ===');
  console.log('Upload encrypted blob: PASS');
  console.log('Download + verify: PASS');
  console.log('Upload teaser: PASS');
  console.log('Download teaser + verify: PASS');
  console.log('\nEvidence:', JSON.stringify({
    blobId,
    teaserBlobId,
    encryptedBlobSize: encryptedAudio.length,
    teaserSize: teaser.length,
    network: 'walrus-testnet',
  }, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
