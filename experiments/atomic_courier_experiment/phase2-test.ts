/**
 * Phase 2: Publish experiment + authorize + execute atomic transfer.
 * Requires world infrastructure already set up by the full test script.
 * 
 * Usage: NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx this_script.ts
 *   <charId> <ssuAId> <ssuAOwnerCap> <ssuBId> <ssuBOwnerCap>
 */

import { SuiJsonRpcClient } from "@mysten/sui/jsonRpc";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";
import { execSync } from "node:child_process";
import * as fs from "node:fs";

const RPC_URL = "http://127.0.0.1:9000";

// Load keys
const envPath = "/workspace/builder-scaffold/docker/.env.sui";
const envContent = fs.readFileSync(envPath, "utf-8");
const env: Record<string, string> = {};
for (const line of envContent.split("\n")) {
  const m = line.match(/^([A-Z_]+)=(.+)$/);
  if (m) env[m[1]] = m[2].trim();
}

// Load world IDs
const ids = JSON.parse(
  fs.readFileSync("/workspace/world-contracts/deployments/localnet/extracted-object-ids.json", "utf-8")
);
const WORLD_PKG: string = ids.world.packageId;

const ITEM_TYPE_ID = 446;

function makeKeypair(key: string): Ed25519Keypair {
  const { secretKey } = decodeSuiPrivateKey(key);
  return Ed25519Keypair.fromSecretKey(secretKey);
}

function delay(ms: number): Promise<void> {
  return new Promise(r => setTimeout(r, ms));
}

async function signAndExecute(client: SuiJsonRpcClient, tx: Transaction, kp: Ed25519Keypair, label: string) {
  tx.setGasBudget(500_000_000);
  const result = await client.signAndExecuteTransaction({
    transaction: tx, signer: kp,
    options: { showEffects: true, showEvents: true, showObjectChanges: true },
  });
  if (result.effects?.status?.status !== "success") {
    console.error(`[FAIL] ${label}:`, JSON.stringify(result.effects?.status, null, 2));
    throw new Error(`${label} failed: ${result.effects?.status?.error}`);
  }
  console.log(`[OK] ${label} (digest: ${result.digest})`);
  return result;
}

async function main() {
  // IDs from Phase 1 (setup)
  const characterId = process.argv[2];
  const ssuAId = process.argv[3];
  const ssuAOwnerCapId = process.argv[4];
  const ssuBId = process.argv[5];
  const ssuBOwnerCapId = process.argv[6];

  if (!characterId || !ssuAId || !ssuAOwnerCapId || !ssuBId || !ssuBOwnerCapId) {
    console.error("Usage: tsx phase2.ts <charId> <ssuAId> <ssuAOwnerCap> <ssuBId> <ssuBOwnerCap>");
    process.exit(1);
  }

  const client = new SuiJsonRpcClient({ url: RPC_URL });
  const adminKp = makeKeypair(env.ADMIN_PRIVATE_KEY);
  const ssuType = `${WORLD_PKG}::storage_unit::StorageUnit`;

  console.log("═══════════════════════════════════════════");
  console.log("  PHASE 2: PUBLISH + AUTHORIZE + TEST");
  console.log("═══════════════════════════════════════════\n");

  // ── Publish ──
  console.log("── Publish experiment package ──");
  let experimentPkgId: string;
  {
    const output = execSync(
      "cd /workspace/experiments/atomic_courier_experiment && rm -f Move.lock && sui client test-publish --skip-dependency-verification --json 2>&1",
      { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 }
    );
    const jsonMatch = output.match(/\{[\s\S]*\}$/);
    if (!jsonMatch) {
      console.error("Raw output:", output);
      throw new Error("Failed to parse publish JSON");
    }
    const result = JSON.parse(jsonMatch[0]);
    if (result.effects?.status?.status !== "success") {
      throw new Error(`Publish failed: ${result.effects?.status?.error}`);
    }
    const pub = result.objectChanges?.find((c: any) => c.type === "published");
    experimentPkgId = pub?.packageId;
    console.log(`[OK] Published at: ${experimentPkgId}`);
  }
  await delay(1500);

  // ── Authorize extension on SSU A ──
  console.log("\n── Authorize extension on SSU A ──");
  {
    const authType = `${experimentPkgId}::config::XAuth`;
    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${WORLD_PKG}::character::borrow_owner_cap`,
      typeArguments: [ssuType],
      arguments: [tx.object(characterId), tx.object(ssuAOwnerCapId)],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::authorize_extension`,
      typeArguments: [authType],
      arguments: [tx.object(ssuAId), ownerCap],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::character::return_owner_cap`,
      typeArguments: [ssuType],
      arguments: [tx.object(characterId), ownerCap, receipt],
    });
    await signAndExecute(client, tx, adminKp, "Authorize ext SSU A");
  }
  await delay(1500);

  // ── Authorize extension on SSU B ──
  console.log("── Authorize extension on SSU B ──");
  {
    const authType = `${experimentPkgId}::config::XAuth`;
    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${WORLD_PKG}::character::borrow_owner_cap`,
      typeArguments: [ssuType],
      arguments: [tx.object(characterId), tx.object(ssuBOwnerCapId)],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::authorize_extension`,
      typeArguments: [authType],
      arguments: [tx.object(ssuBId), ownerCap],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::character::return_owner_cap`,
      typeArguments: [ssuType],
      arguments: [tx.object(characterId), ownerCap, receipt],
    });
    await signAndExecute(client, tx, adminKp, "Authorize ext SSU B");
  }
  await delay(1500);

  // ═══════════════════════════════════════════
  // CORE TEST: atomic_transfer_test
  // ═══════════════════════════════════════════
  console.log("\n═══════════════════════════════════════════");
  console.log("  CORE TEST: atomic_transfer_test");
  console.log("═══════════════════════════════════════════\n");
  {
    const tx = new Transaction();
    const [rewardCoin] = tx.splitCoins(tx.gas, [1_000_000]);
    tx.moveCall({
      target: `${experimentPkgId}::atomic_transfer::atomic_transfer_test`,
      arguments: [
        tx.object(ssuAId),
        tx.object(ssuBId),
        tx.object(characterId),
        tx.pure.u64(ITEM_TYPE_ID),
        rewardCoin,
      ],
    });

    try {
      const result = await signAndExecute(client, tx, adminKp, "ATOMIC TRANSFER TEST");

      console.log("\n═══════════════════════════════════════════");
      console.log("  RESULT: SUCCESS ✓");
      console.log("═══════════════════════════════════════════\n");

      const gasUsed = result.effects?.gasUsed;
      const totalGas = gasUsed
        ? BigInt(gasUsed.computationCost) + BigInt(gasUsed.storageCost) - BigInt(gasUsed.storageRebate)
        : "unknown";
      console.log(`Gas Used: ${totalGas} MIST`);
      console.log(`  Computation: ${gasUsed?.computationCost}`);
      console.log(`  Storage: ${gasUsed?.storageCost}`);
      console.log(`  Rebate: ${gasUsed?.storageRebate}`);

      const mutated = result.effects?.mutated?.length || 0;
      const created = result.effects?.created?.length || 0;
      console.log(`Objects mutated: ${mutated}, created: ${created}`);

      console.log("\nEvents:");
      for (const event of result.events || []) {
        console.log(`  ${event.type}`);
        console.log(`    ${JSON.stringify(event.parsedJson, null, 4)}`);
      }

      console.log("\nMutated objects:");
      for (const ch of result.objectChanges || []) {
        if (ch.type === "mutated") {
          console.log(`  ${ch.objectType} (${ch.objectId})`);
        }
      }
    } catch (error) {
      console.log("\n═══════════════════════════════════════════");
      console.log("  RESULT: FAILURE ✗");
      console.log("═══════════════════════════════════════════\n");
      console.error("Error:", error instanceof Error ? error.message : error);
    }
  }
}

main().catch(console.error);
