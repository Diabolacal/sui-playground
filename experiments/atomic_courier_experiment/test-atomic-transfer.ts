/**
 * Atomic Courier Feasibility Test
 *
 * End-to-end test: set up world, deploy experiment, execute atomic transfer.
 * All operations use the ADMIN keypair as single signer (character_address = admin)
 * to avoid dual-sign sponsorship complexity.
 *
 * Pipeline:
 * 1. Setup ACL (register server + add sponsor)
 * 2. Create character (character_address = admin)
 * 3. Create NWN + deposit fuel + online
 * 4. Create SSU A + SSU B + online both
 * 5. Mint item into SSU A
 * 6. Publish experiment package
 * 7. Authorize extension on both SSUs
 * 8. Execute atomic_transfer_test (withdraw + deposit + coin transfer in one PTB)
 */

import { SuiJsonRpcClient } from "@mysten/sui/jsonRpc";
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";
import { bcs } from "@mysten/sui/bcs";
import { execSync } from "node:child_process";
import * as fs from "node:fs";

// ═══════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════

const RPC_URL = "http://127.0.0.1:9000";
const CLOCK = "0x6";

// Load keys from .env.sui
const envPath = "/workspace/builder-scaffold/docker/.env.sui";
const envContent = fs.readFileSync(envPath, "utf-8");
const env: Record<string, string> = {};
for (const line of envContent.split("\n")) {
  const match = line.match(/^([A-Z_]+)=(.+)$/);
  if (match) env[match[1]] = match[2].trim();
}

const ADMIN_KEY = env.ADMIN_PRIVATE_KEY;

// Load world object IDs
const extractedIds = JSON.parse(
  fs.readFileSync(
    "/workspace/world-contracts/deployments/localnet/extracted-object-ids.json",
    "utf-8"
  )
);
const WORLD_PKG: string = extractedIds.world.packageId;
const ADMIN_ACL: string = extractedIds.world.adminAcl;
const OBJECT_REGISTRY: string = extractedIds.world.objectRegistry;
const ENERGY_CONFIG: string = extractedIds.world.energyConfig;
const GOVERNOR_CAP: string = extractedIds.world.governorCap;
const SERVER_REGISTRY: string = extractedIds.world.serverAddressRegistry;

// Test constants
const TENANT = "dev";
const LOCATION_HASH =
  "0x16217de8ec7330ec3eac32831df5c9cd9b21a255756a5fd5762dd7f49f6cc049";

// Game IDs (arbitrary but must be unique)
const CHAR_ID = 811880;
const NWN_ITEM_ID = 5550000012;
const NWN_TYPE_ID = 555;
const SSU_A_ITEM_ID = 888800006;
const SSU_B_ITEM_ID = 888800007;
const SSU_TYPE_ID = 88082;
const ITEM_TYPE_ID = 446;
const ITEM_ITEM_ID = 444000001;

// NWN parameters (matching builder-scaffold)
const FUEL_MAX_CAPACITY = 10000;
const FUEL_BURN_RATE_MS = 3600 * 1000; // 1hr
const MAX_ENERGY_PRODUCTION = 100;
const SSU_MAX_CAPACITY = 1_000_000_000;

// Fuel for deposit
const FUEL_TYPE_ID = 78437;
const FUEL_QUANTITY = 2;
const FUEL_VOLUME = 10;

// ═══════════════════════════════════════════
// Utilities
// ═══════════════════════════════════════════

function makeKeypair(key: string): Ed25519Keypair {
  const { secretKey } = decodeSuiPrivateKey(key);
  return Ed25519Keypair.fromSecretKey(secretKey);
}

function hexToBytes(hex: string): number[] {
  const stripped = hex.startsWith("0x") ? hex.slice(2) : hex;
  const bytes: number[] = [];
  for (let i = 0; i < stripped.length; i += 2) {
    bytes.push(parseInt(stripped.substring(i, i + 2), 16));
  }
  return bytes;
}

function locationHashPure(tx: Transaction) {
  return tx.pure(
    bcs.vector(bcs.u8()).serialize(hexToBytes(LOCATION_HASH))
  );
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function signAndExecute(
  client: SuiJsonRpcClient,
  tx: Transaction,
  keypair: Ed25519Keypair,
  label: string
): Promise<any> {
  tx.setGasBudget(500_000_000);

  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true, showEvents: true, showObjectChanges: true },
  });

  if (result.effects?.status?.status !== "success") {
    console.error(
      `[FAIL] ${label}:`,
      JSON.stringify(result.effects?.status, null, 2)
    );
    throw new Error(`${label} failed: ${result.effects?.status?.error}`);
  }
  console.log(`[OK] ${label} (digest: ${result.digest})`);
  return result;
}

function extractEventField(
  result: any,
  eventSuffix: string,
  field: string
): string {
  const event = result.events?.find((e: any) =>
    e.type.endsWith(eventSuffix)
  );
  if (!event?.parsedJson?.[field]) {
    throw new Error(
      `Event ${eventSuffix} field ${field} not found in result`
    );
  }
  return event.parsedJson[field];
}

async function getOwnerCapId(
  client: SuiJsonRpcClient,
  objectId: string
): Promise<string> {
  const obj = await client.getObject({
    id: objectId,
    options: { showContent: true },
  });
  const fields = (obj.data?.content as any)?.fields;
  if (!fields?.owner_cap_id) {
    throw new Error(`owner_cap_id not found on object ${objectId}`);
  }
  return fields.owner_cap_id;
}

// ═══════════════════════════════════════════
// PTB helper: borrow OwnerCap + action + return
// ═══════════════════════════════════════════
function borrowOwnerCapCall(
  tx: Transaction,
  characterId: string,
  ownerCapId: string,
  assemblyType: string // e.g. `${WORLD_PKG}::storage_unit::StorageUnit`
) {
  const [ownerCap, receipt] = tx.moveCall({
    target: `${WORLD_PKG}::character::borrow_owner_cap`,
    typeArguments: [assemblyType],
    arguments: [tx.object(characterId), tx.object(ownerCapId)],
  });
  return { ownerCap, receipt };
}

function returnOwnerCapCall(
  tx: Transaction,
  characterId: string,
  ownerCap: any,
  receipt: any,
  assemblyType: string
) {
  tx.moveCall({
    target: `${WORLD_PKG}::character::return_owner_cap`,
    typeArguments: [assemblyType],
    arguments: [tx.object(characterId), ownerCap, receipt],
  });
}

// ═══════════════════════════════════════════
// Main test flow
// ═══════════════════════════════════════════

async function main() {
  console.log("═══════════════════════════════════════════");
  console.log("  ATOMIC COURIER FEASIBILITY TEST");
  console.log("═══════════════════════════════════════════\n");

  const client = new SuiJsonRpcClient({ url: RPC_URL });
  const adminKp = makeKeypair(ADMIN_KEY);
  const adminAddress = adminKp.getPublicKey().toSuiAddress();

  console.log(`World Package: ${WORLD_PKG}`);
  console.log(`Admin: ${adminAddress}`);
  console.log(`GovernorCap: ${GOVERNOR_CAP}`);
  console.log(`AdminACL: ${ADMIN_ACL}\n`);

  // ── Step 1: Setup access ──
  console.log("── Step 1: Setup access (register server + add sponsor) ──");
  {
    const tx = new Transaction();
    // Register admin as server address
    tx.moveCall({
      target: `${WORLD_PKG}::access::register_server_address`,
      arguments: [
        tx.object(SERVER_REGISTRY),
        tx.object(GOVERNOR_CAP),
        tx.pure.address(adminAddress),
      ],
    });
    // Add admin as ACL sponsor
    tx.moveCall({
      target: `${WORLD_PKG}::access::add_sponsor_to_acl`,
      arguments: [
        tx.object(ADMIN_ACL),
        tx.object(GOVERNOR_CAP),
        tx.pure.address(adminAddress),
      ],
    });
    await signAndExecute(client, tx, adminKp, "Setup access");
  }
  await delay(1500);

  // ── Step 2: Create Character (character_address = admin) ──
  console.log("\n── Step 2: Create Character ──");
  let characterId: string;
  {
    const tx = new Transaction();
    const [character] = tx.moveCall({
      target: `${WORLD_PKG}::character::create_character`,
      arguments: [
        tx.object(OBJECT_REGISTRY),
        tx.object(ADMIN_ACL),
        tx.pure.u32(CHAR_ID),
        tx.pure.string(TENANT),
        tx.pure.u32(100), // tribe_id
        tx.pure.address(adminAddress), // character_address = admin (simplifies all subsequent calls)
        tx.pure.string("TestCourier"),
      ],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::character::share_character`,
      arguments: [character, tx.object(ADMIN_ACL)],
    });
    const result = await signAndExecute(client, tx, adminKp, "Create Character");
    characterId = extractEventField(
      result,
      "::character::CharacterCreatedEvent",
      "character_id"
    );
    console.log(`  Character ID: ${characterId}`);
  }
  await delay(1500);

  // ── Step 3: Create NWN + deposit fuel + online ──
  console.log("\n── Step 3: Create Network Node ──");
  let nwnId: string;
  let nwnOwnerCapId: string;
  {
    const tx = new Transaction();
    const [nwn] = tx.moveCall({
      target: `${WORLD_PKG}::network_node::anchor`,
      arguments: [
        tx.object(OBJECT_REGISTRY),
        tx.object(characterId),
        tx.object(ADMIN_ACL),
        tx.pure.u64(NWN_ITEM_ID),
        tx.pure.u64(NWN_TYPE_ID),
        locationHashPure(tx),
        tx.pure.u64(FUEL_MAX_CAPACITY),
        tx.pure.u64(FUEL_BURN_RATE_MS),
        tx.pure.u64(MAX_ENERGY_PRODUCTION),
      ],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::network_node::share_network_node`,
      arguments: [nwn, tx.object(ADMIN_ACL)],
    });
    const result = await signAndExecute(client, tx, adminKp, "Create NWN");
    nwnId = extractEventField(
      result,
      "::network_node::NetworkNodeCreatedEvent",
      "network_node_id"
    );
    nwnOwnerCapId = extractEventField(
      result,
      "::network_node::NetworkNodeCreatedEvent",
      "owner_cap_id"
    );
    console.log(`  NWN ID: ${nwnId}`);
    console.log(`  NWN OwnerCap: ${nwnOwnerCapId}`);
  }
  await delay(1500);

  // Deposit fuel
  console.log("  Depositing fuel...");
  {
    const nwnType = `${WORLD_PKG}::network_node::NetworkNode`;
    const tx = new Transaction();
    const { ownerCap, receipt } = borrowOwnerCapCall(
      tx,
      characterId,
      nwnOwnerCapId,
      nwnType
    );
    tx.moveCall({
      target: `${WORLD_PKG}::network_node::deposit_fuel`,
      arguments: [
        tx.object(nwnId),
        tx.object(ADMIN_ACL),
        ownerCap,
        tx.pure.u64(FUEL_TYPE_ID),
        tx.pure.u64(FUEL_VOLUME),
        tx.pure.u64(FUEL_QUANTITY),
        tx.object(CLOCK),
      ],
    });
    returnOwnerCapCall(tx, characterId, ownerCap, receipt, nwnType);
    await signAndExecute(client, tx, adminKp, "Deposit fuel");
  }
  await delay(1500);

  // Online NWN
  console.log("  Bringing NWN online...");
  {
    const nwnType = `${WORLD_PKG}::network_node::NetworkNode`;
    const tx = new Transaction();
    const { ownerCap, receipt } = borrowOwnerCapCall(
      tx,
      characterId,
      nwnOwnerCapId,
      nwnType
    );
    tx.moveCall({
      target: `${WORLD_PKG}::network_node::online`,
      arguments: [tx.object(nwnId), ownerCap, tx.object(CLOCK)],
    });
    returnOwnerCapCall(tx, characterId, ownerCap, receipt, nwnType);
    await signAndExecute(client, tx, adminKp, "Online NWN");
  }
  await delay(1500);

  // ── Step 4: Create SSU A + SSU B ──
  console.log("\n── Step 4: Create SSU A (Source) ──");
  let ssuAId: string;
  let ssuAOwnerCapId: string;
  {
    const tx = new Transaction();
    const [ssu] = tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::anchor`,
      arguments: [
        tx.object(OBJECT_REGISTRY),
        tx.object(nwnId),
        tx.object(characterId),
        tx.object(ADMIN_ACL),
        tx.pure.u64(SSU_A_ITEM_ID),
        tx.pure.u64(SSU_TYPE_ID),
        tx.pure.u64(SSU_MAX_CAPACITY),
        locationHashPure(tx),
      ],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::share_storage_unit`,
      arguments: [ssu, tx.object(ADMIN_ACL)],
    });
    const result = await signAndExecute(client, tx, adminKp, "Create SSU A");
    ssuAId = extractEventField(
      result,
      "::storage_unit::StorageUnitCreatedEvent",
      "storage_unit_id"
    );
    ssuAOwnerCapId = extractEventField(
      result,
      "::storage_unit::StorageUnitCreatedEvent",
      "owner_cap_id"
    );
    console.log(`  SSU A: ${ssuAId}`);
    console.log(`  SSU A OwnerCap: ${ssuAOwnerCapId}`);
  }
  await delay(1500);

  console.log("\n── Step 4b: Create SSU B (Destination) ──");
  let ssuBId: string;
  let ssuBOwnerCapId: string;
  {
    const tx = new Transaction();
    const [ssu] = tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::anchor`,
      arguments: [
        tx.object(OBJECT_REGISTRY),
        tx.object(nwnId),
        tx.object(characterId),
        tx.object(ADMIN_ACL),
        tx.pure.u64(SSU_B_ITEM_ID),
        tx.pure.u64(SSU_TYPE_ID),
        tx.pure.u64(SSU_MAX_CAPACITY),
        locationHashPure(tx),
      ],
    });
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::share_storage_unit`,
      arguments: [ssu, tx.object(ADMIN_ACL)],
    });
    const result = await signAndExecute(client, tx, adminKp, "Create SSU B");
    ssuBId = extractEventField(
      result,
      "::storage_unit::StorageUnitCreatedEvent",
      "storage_unit_id"
    );
    ssuBOwnerCapId = extractEventField(
      result,
      "::storage_unit::StorageUnitCreatedEvent",
      "owner_cap_id"
    );
    console.log(`  SSU B: ${ssuBId}`);
    console.log(`  SSU B OwnerCap: ${ssuBOwnerCapId}`);
  }
  await delay(1500);

  // ── Step 5: Online both SSUs ──
  console.log("\n── Step 5: Bring SSUs online ──");
  const ssuType = `${WORLD_PKG}::storage_unit::StorageUnit`;
  {
    const tx = new Transaction();
    const { ownerCap, receipt } = borrowOwnerCapCall(
      tx,
      characterId,
      ssuAOwnerCapId,
      ssuType
    );
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::online`,
      arguments: [
        tx.object(ssuAId),
        tx.object(nwnId),
        tx.object(ENERGY_CONFIG),
        ownerCap,
      ],
    });
    returnOwnerCapCall(tx, characterId, ownerCap, receipt, ssuType);
    await signAndExecute(client, tx, adminKp, "Online SSU A");
  }
  await delay(1500);
  {
    const tx = new Transaction();
    const { ownerCap, receipt } = borrowOwnerCapCall(
      tx,
      characterId,
      ssuBOwnerCapId,
      ssuType
    );
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::online`,
      arguments: [
        tx.object(ssuBId),
        tx.object(nwnId),
        tx.object(ENERGY_CONFIG),
        ownerCap,
      ],
    });
    returnOwnerCapCall(tx, characterId, ownerCap, receipt, ssuType);
    await signAndExecute(client, tx, adminKp, "Online SSU B");
  }
  await delay(1500);

  // ── Step 6: Mint item into SSU A ──
  console.log("\n── Step 6: Mint item into SSU A ──");
  {
    const tx = new Transaction();
    const { ownerCap, receipt } = borrowOwnerCapCall(
      tx,
      characterId,
      ssuAOwnerCapId,
      ssuType
    );
    tx.moveCall({
      target: `${WORLD_PKG}::storage_unit::game_item_to_chain_inventory`,
      typeArguments: [ssuType],
      arguments: [
        tx.object(ssuAId),
        tx.object(ADMIN_ACL),
        tx.object(characterId),
        ownerCap,
        tx.pure.u64(ITEM_ITEM_ID),
        tx.pure.u64(ITEM_TYPE_ID),
        tx.pure.u64(1), // volume
        tx.pure.u32(100), // quantity
      ],
    });
    returnOwnerCapCall(tx, characterId, ownerCap, receipt, ssuType);
    await signAndExecute(client, tx, adminKp, "Mint items into SSU A");
  }
  await delay(1500);

  // ── Step 7: Publish experiment package ──
  console.log("\n── Step 7: Publish experiment package ──");
  let experimentPkgId: string;
  {
    // Remove stale Move.lock
    try {
      execSync(
        "rm -f /workspace/experiments/atomic_courier_experiment/Move.lock",
        { encoding: "utf-8" }
      );
    } catch {}

    const publishOutput = execSync(
      "cd /workspace/experiments/atomic_courier_experiment && rm -f Move.lock && sui client publish --skip-dependency-verification --json 2>&1",
      { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 }
    );

    // Extract JSON block from output
    const jsonMatch = publishOutput.match(/\{[\s\S]*\}$/);
    if (!jsonMatch) {
      console.error("Publish output:", publishOutput);
      throw new Error("Failed to parse publish JSON");
    }
    const publishResult = JSON.parse(jsonMatch[0]);

    if (publishResult.effects?.status?.status !== "success") {
      throw new Error(
        `Publish failed: ${publishResult.effects?.status?.error}`
      );
    }

    const published = publishResult.objectChanges?.find(
      (c: any) => c.type === "published"
    );
    experimentPkgId = published?.packageId;
    console.log(`[OK] Experiment published`);
    console.log(`  Package ID: ${experimentPkgId}`);

    const extConfig = publishResult.objectChanges?.find(
      (c: any) =>
        c.type === "created" && c.objectType?.includes("ExtensionConfig")
    );
    console.log(`  ExtensionConfig: ${extConfig?.objectId}`);
  }
  await delay(1500);

  // ── Step 8: Authorize extension on both SSUs ──
  console.log("\n── Step 8: Authorize extension on SSUs ──");
  {
    const authType = `${experimentPkgId}::config::XAuth`;

    const tx1 = new Transaction();
    const a = borrowOwnerCapCall(
      tx1,
      characterId,
      ssuAOwnerCapId,
      ssuType
    );
    tx1.moveCall({
      target: `${WORLD_PKG}::storage_unit::authorize_extension`,
      typeArguments: [authType],
      arguments: [tx1.object(ssuAId), a.ownerCap],
    });
    returnOwnerCapCall(tx1, characterId, a.ownerCap, a.receipt, ssuType);
    await signAndExecute(client, tx1, adminKp, "Authorize ext on SSU A");
    await delay(1500);

    const tx2 = new Transaction();
    const b = borrowOwnerCapCall(
      tx2,
      characterId,
      ssuBOwnerCapId,
      ssuType
    );
    tx2.moveCall({
      target: `${WORLD_PKG}::storage_unit::authorize_extension`,
      typeArguments: [authType],
      arguments: [tx2.object(ssuBId), b.ownerCap],
    });
    returnOwnerCapCall(tx2, characterId, b.ownerCap, b.receipt, ssuType);
    await signAndExecute(client, tx2, adminKp, "Authorize ext on SSU B");
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

    // Split a small coin for the reward payment (0.001 SUI)
    const [rewardCoin] = tx.splitCoins(tx.gas, [1_000_000]);

    tx.moveCall({
      target: `${experimentPkgId}::atomic_transfer::atomic_transfer_test`,
      arguments: [
        tx.object(ssuAId), // source SSU  (&mut StorageUnit)
        tx.object(ssuBId), // dest SSU    (&mut StorageUnit)
        tx.object(characterId), // character (&Character)
        tx.pure.u64(ITEM_TYPE_ID), // item type to transfer
        rewardCoin, // Coin<SUI> payment
      ],
    });

    try {
      const result = await signAndExecute(
        client,
        tx,
        adminKp,
        "ATOMIC TRANSFER TEST"
      );

      console.log("\n═══════════════════════════════════════════");
      console.log("  RESULT: SUCCESS ✓");
      console.log("═══════════════════════════════════════════\n");

      // Gas report
      const gasUsed = result.effects?.gasUsed;
      const totalGas = gasUsed
        ? BigInt(gasUsed.computationCost) +
          BigInt(gasUsed.storageCost) -
          BigInt(gasUsed.storageRebate)
        : "unknown";

      console.log(`Gas Used: ${totalGas} MIST`);
      console.log(`  Computation: ${gasUsed?.computationCost}`);
      console.log(`  Storage: ${gasUsed?.storageCost}`);
      console.log(`  Rebate: ${gasUsed?.storageRebate}`);

      const mutated = result.effects?.mutated?.length || 0;
      const created = result.effects?.created?.length || 0;
      console.log(`\nObjects mutated: ${mutated}`);
      console.log(`Objects created: ${created}`);

      console.log("\nEvents:");
      for (const event of result.events || []) {
        console.log(`  ${event.type}`);
        console.log(`    ${JSON.stringify(event.parsedJson, null, 4)}`);
      }

      console.log("\nObject changes:");
      for (const change of result.objectChanges || []) {
        if (change.type === "mutated") {
          console.log(
            `  [mutated] ${change.objectType} (${change.objectId})`
          );
        }
      }
    } catch (error) {
      console.log("\n═══════════════════════════════════════════");
      console.log("  RESULT: FAILURE ✗");
      console.log("═══════════════════════════════════════════\n");
      console.error(
        "Error:",
        error instanceof Error ? error.message : error
      );

      if (error instanceof Error) {
        const msg = error.message;
        if (msg.includes("borrow"))
          console.error("ROOT CAUSE: Borrow checker conflict");
        if (msg.includes("shared"))
          console.error("ROOT CAUSE: Shared object conflict");
        if (msg.includes("capability"))
          console.error("ROOT CAUSE: Capability mismatch");
        if (msg.includes("extension"))
          console.error("ROOT CAUSE: Extension authorization");
      }
    }
  }
}

main().catch(console.error);
