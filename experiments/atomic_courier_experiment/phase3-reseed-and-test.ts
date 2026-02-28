/**
 * Phase 3: Re-seed world objects using newly published package, then test atomic transfer.
 *
 * The test-publish with --with-unpublished-dependencies created a SINGLE package
 * containing both world and experiment modules. We need fresh world objects under
 * this new package to test the atomic transfer feasibility.
 *
 * Usage (inside container):
 *   NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx phase3-reseed-and-test.ts
 */

import { SuiJsonRpcClient } from "@mysten/sui/jsonRpc";
import { Transaction } from "@mysten/sui/transactions";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { bcs } from "@mysten/sui/bcs";

// ============================================================================
// CONFIGURATION — from the test-publish output
// ============================================================================

const RPC_URL = "http://127.0.0.1:9000";
const PKG = "0xe8aff0035db4e0754fa3565bb68049cb4cb1a1daa6bda6b9e20b016efb511d25";

// Created objects from the publish transaction:
const ADMIN_ACL      = "0x9d48cf16ac306b724b8cd5495391c59bb150f86977cf652ccf9653e7b14ad5cb";
const GOVERNOR_CAP   = "0x1d6a4606f79e271a76189efb17546d7f0b31a41a7a2c5059abfb47124b475496";
const OBJ_REGISTRY   = "0xfd3e4e6a61f1c5ec551a68167566c39a00e1c6fe3ba6e5ff7a4dee04094edb93";
const ENERGY_CONFIG  = "0x0ba2f26027715c6b01572be53fccbdb589b907909d875529bcae8ae5c9f228aa";
const SERVER_REGISTRY = "0x508a912954acb7c7dff7d674161ca2ed111db2c1b4b63c2a0305a9849675692a";
const EXT_CONFIG     = "0xef20f7f5e2a9e9df8cc19a62e48063adc15739ca1cf858437f3fde3f17c2d422";

// Admin keypair (same as before — this address published the package)
const ADMIN_PRIVATE_KEY = "suiprivkey1qpfudud34mvygawwg80gl3t9tvu6r7nd8hypwf57zyh7a9s3uy7nsra0u8t";

// Constants
const ITEM_TYPE_ID = 446;
const CLOCK = "0x6";

// 32-byte dummy location hash
const LOCATION_HASH = new Uint8Array(32);
LOCATION_HASH[0] = 0xDE; LOCATION_HASH[1] = 0xAD;

// ============================================================================

const client = new SuiJsonRpcClient({ url: RPC_URL });

function getKeypair(privKey: string): Ed25519Keypair {
  const { schema, secretKey } = decodeSuiPrivateKey(privKey) as any;
  return Ed25519Keypair.fromSecretKey(secretKey);
}

async function signAndExecute(tx: Transaction, keypair: Ed25519Keypair, label: string) {
  tx.setGasBudget(500_000_000);
  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });
  if ((result as any).effects?.status?.status !== "success") {
    console.error(`[FAIL] ${label}:`, JSON.stringify((result as any).effects?.status, null, 2));
    throw new Error(`${label} failed`);
  }
  console.log(`[OK] ${label} — digest: ${(result as any).digest}`);
  // Wait for state to propagate on local devnet
  await new Promise(r => setTimeout(r, 1500));
  return result as any;
}

function findCreatedByType(result: any, typeSubstring: string) {
  return result.objectChanges?.find(
    (c: any) => c.type === "created" && c.objectType?.includes(typeSubstring)
      && !c.objectType?.includes("OwnerCap")
  );
}

function findCreatedOwnerCap(result: any, excludeIds: string[] = []) {
  return result.objectChanges?.find(
    (c: any) => c.type === "created" && c.objectType?.includes("OwnerCap")
      && !excludeIds.includes(c.objectId)
  );
}

async function main() {
  const adminKp = getKeypair(ADMIN_PRIVATE_KEY);
  const adminAddr = adminKp.toSuiAddress();
  console.log(`Admin: ${adminAddr}`);
  console.log(`Package: ${PKG}`);
  console.log("========================");

  // ── Step 1: Setup Access ──
  // Split into separate transactions so a failure in register doesn't block add_sponsor
  console.log("\n── Step 1: Setup Access ──");
  try {
    const tx1 = new Transaction();
    tx1.moveCall({
      target: `${PKG}::access::register_server_address`,
      arguments: [
        tx1.object(SERVER_REGISTRY),
        tx1.object(GOVERNOR_CAP),
        tx1.pure.address(adminAddr),
      ],
    });
    await signAndExecute(tx1, adminKp, "Register server address");
  } catch {
    console.log("  (register_server_address skipped — already done)");
  }
  // Wait for state to propagate
  await new Promise(r => setTimeout(r, 1000));
  try {
    const tx2 = new Transaction();
    tx2.moveCall({
      target: `${PKG}::access::add_sponsor_to_acl`,
      arguments: [
        tx2.object(ADMIN_ACL),
        tx2.object(GOVERNOR_CAP),
        tx2.pure.address(adminAddr),
      ],
    });
    await signAndExecute(tx2, adminKp, "Add sponsor to ACL");
  } catch {
    console.log("  (add_sponsor_to_acl skipped — already done)");
  }
  // Wait for state
  await new Promise(r => setTimeout(r, 1000));

  // ── Step 2: Create Character ──
  console.log("\n── Step 2: Create Character ──");
  let characterId: string;
  {
    const tx = new Transaction();
    const character = tx.moveCall({
      target: `${PKG}::character::create_character`,
      arguments: [
        tx.object(OBJ_REGISTRY),
        tx.object(ADMIN_ACL),
        tx.pure.u32(8001),                    // game_character_id (unique)
        tx.pure.string("test_tenant"),         // tenant
        tx.pure.u32(1),                        // tribe_id
        tx.pure.address(adminAddr),            // character_address
        tx.pure.string("TestCourier2"),         // name
      ],
    });
    tx.moveCall({
      target: `${PKG}::character::share_character`,
      arguments: [
        character,
        tx.object(ADMIN_ACL),
      ],
    });
    const res = await signAndExecute(tx, adminKp, "Create character");
    const charObj = findCreatedByType(res, "character::Character");
    characterId = charObj?.objectId;
    console.log(`  Character ID: ${characterId}`);
  }

  // ── Step 3: Create Network Node ──
  console.log("\n── Step 3: Create NWN ──");
  let nwnId: string;
  let nwnOwnerCapId: string;
  {
    const tx = new Transaction();
    const nwn = tx.moveCall({
      target: `${PKG}::network_node::anchor`,
      arguments: [
        tx.object(OBJ_REGISTRY),
        tx.object(characterId!),
        tx.object(ADMIN_ACL),
        tx.pure.u64(50001),           // item_id (unique)
        tx.pure.u64(84),             // type_id
        tx.pure(bcs.vector(bcs.u8()).serialize(Array.from(LOCATION_HASH)).toBytes()), // location_hash (32 bytes)
        tx.pure.u64(100000),         // fuel_max_capacity
        tx.pure.u64(60000),          // fuel_burn_rate_in_ms (min 60000)
        tx.pure.u64(50000),          // max_energy_production
      ],
    });
    tx.moveCall({
      target: `${PKG}::network_node::share_network_node`,
      arguments: [
        nwn,
        tx.object(ADMIN_ACL),
      ],
    });
    const res = await signAndExecute(tx, adminKp, "Create NWN");
    const nwnObj = findCreatedByType(res, "network_node::NetworkNode");
    nwnId = nwnObj?.objectId;
    const nwnCap = findCreatedOwnerCap(res);
    nwnOwnerCapId = nwnCap?.objectId;
    console.log(`  NWN ID: ${nwnId}`);
    console.log(`  NWN OwnerCap: ${nwnOwnerCapId}`);
  }

  // ── Step 4: Deposit Fuel + Online NWN ──
  console.log("\n── Step 4: Deposit Fuel + Online NWN ──");
  {
    const tx = new Transaction();
    // Borrow NWN OwnerCap via character
    const [nwnOwnerCap, receipt] = tx.moveCall({
      target: `${PKG}::character::borrow_owner_cap`,
      typeArguments: [`${PKG}::network_node::NetworkNode`],
      arguments: [
        tx.object(characterId!),
        tx.object(nwnOwnerCapId!),
      ],
    });
    // Deposit fuel
    tx.moveCall({
      target: `${PKG}::network_node::deposit_fuel`,
      arguments: [
        tx.object(nwnId!),
        tx.object(ADMIN_ACL),
        nwnOwnerCap,
        tx.pure.u64(87),     // fuel_type_id
        tx.pure.u64(1),      // volume (unit_volume)
        tx.pure.u64(100),    // quantity (volume * quantity <= max_capacity)
        tx.object(CLOCK),
      ],
    });
    // Online
    tx.moveCall({
      target: `${PKG}::network_node::online`,
      arguments: [
        tx.object(nwnId!),
        nwnOwnerCap,
        tx.object(CLOCK),
      ],
    });
    // Return OwnerCap
    tx.moveCall({
      target: `${PKG}::character::return_owner_cap`,
      typeArguments: [`${PKG}::network_node::NetworkNode`],
      arguments: [
        tx.object(characterId!),
        nwnOwnerCap,
        receipt,
      ],
    });
    await signAndExecute(tx, adminKp, "Deposit fuel + Online NWN");
  }

  // ── Step 5: Create SSU A ──
  console.log("\n── Step 5: Create SSU A ──");
  let ssuAId: string;
  let ssuAOwnerCapId: string;
  {
    const tx = new Transaction();
    const ssu = tx.moveCall({
      target: `${PKG}::storage_unit::anchor`,
      arguments: [
        tx.object(OBJ_REGISTRY),
        tx.object(nwnId!),
        tx.object(characterId!),
        tx.object(ADMIN_ACL),
        tx.pure.u64(51001),           // item_id (unique)
        tx.pure.u64(85),             // type_id
        tx.pure.u64(100),            // max_capacity
        tx.pure(bcs.vector(bcs.u8()).serialize(Array.from(LOCATION_HASH)).toBytes()), // location_hash (32 bytes)
      ],
    });
    tx.moveCall({
      target: `${PKG}::storage_unit::share_storage_unit`,
      arguments: [
        ssu,
        tx.object(ADMIN_ACL),
      ],
    });
    const res = await signAndExecute(tx, adminKp, "Create SSU A");
    const ssuObj = findCreatedByType(res, "storage_unit::StorageUnit");
    ssuAId = ssuObj?.objectId;
    const capA = findCreatedOwnerCap(res);
    ssuAOwnerCapId = capA?.objectId;
    console.log(`  SSU A: ${ssuAId}`);
    console.log(`  SSU A OwnerCap: ${ssuAOwnerCapId}`);
  }

  // ── Step 6: Create SSU B ──
  console.log("\n── Step 6: Create SSU B ──");
  let ssuBId: string;
  let ssuBOwnerCapId: string;
  {
    const tx = new Transaction();
    const ssu = tx.moveCall({
      target: `${PKG}::storage_unit::anchor`,
      arguments: [
        tx.object(OBJ_REGISTRY),
        tx.object(nwnId!),
        tx.object(characterId!),
        tx.object(ADMIN_ACL),
        tx.pure.u64(51002),           // item_id (unique)
        tx.pure.u64(85),             // type_id
        tx.pure.u64(100),            // max_capacity
        tx.pure(bcs.vector(bcs.u8()).serialize(Array.from(LOCATION_HASH)).toBytes()), // location_hash (32 bytes)
      ],
    });
    tx.moveCall({
      target: `${PKG}::storage_unit::share_storage_unit`,
      arguments: [
        ssu,
        tx.object(ADMIN_ACL),
      ],
    });
    const res = await signAndExecute(tx, adminKp, "Create SSU B");
    const ssuObj = findCreatedByType(res, "storage_unit::StorageUnit");
    ssuBId = ssuObj?.objectId;
    const capB = findCreatedOwnerCap(res);
    ssuBOwnerCapId = capB?.objectId;
    console.log(`  SSU B: ${ssuBId}`);
    console.log(`  SSU B OwnerCap: ${ssuBOwnerCapId}`);
  }

  // ── Step 7: Online SSU A + SSU B ──
  console.log("\n── Step 7: Online SSUs ──");
  for (const [label, ssuId, capId] of [
    ["SSU A", ssuAId!, ssuAOwnerCapId!],
    ["SSU B", ssuBId!, ssuBOwnerCapId!],
  ] as const) {
    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${PKG}::character::borrow_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        tx.object(capId),
      ],
    });
    tx.moveCall({
      target: `${PKG}::storage_unit::online`,
      arguments: [
        tx.object(ssuId),
        tx.object(nwnId!),
        tx.object(ENERGY_CONFIG),
        ownerCap,
      ],
    });
    tx.moveCall({
      target: `${PKG}::character::return_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        ownerCap,
        receipt,
      ],
    });
    await signAndExecute(tx, adminKp, `Online ${label}`);
  }

  // ── Step 8: Authorize Extension on both SSUs ──
  console.log("\n── Step 8: Authorize Extension (XAuth) on SSUs ──");
  for (const [label, ssuId, capId] of [
    ["SSU A", ssuAId!, ssuAOwnerCapId!],
    ["SSU B", ssuBId!, ssuBOwnerCapId!],
  ] as const) {
    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${PKG}::character::borrow_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        tx.object(capId),
      ],
    });
    tx.moveCall({
      target: `${PKG}::storage_unit::authorize_extension`,
      typeArguments: [`${PKG}::config::XAuth`],
      arguments: [
        tx.object(ssuId),
        ownerCap,
      ],
    });
    tx.moveCall({
      target: `${PKG}::character::return_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        ownerCap,
        receipt,
      ],
    });
    await signAndExecute(tx, adminKp, `Authorize extension ${label}`);
  }

  // ── Step 9: Mint items into SSU A ──
  console.log("\n── Step 9: Mint items into SSU A ──");
  {
    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${PKG}::character::borrow_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        tx.object(ssuAOwnerCapId!),
      ],
    });
    tx.moveCall({
      target: `${PKG}::storage_unit::game_item_to_chain_inventory`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(ssuAId!),
        tx.object(ADMIN_ACL),
        tx.object(characterId!),
        ownerCap,
        tx.pure.u64(52001),         // item_id (unique)
        tx.pure.u64(ITEM_TYPE_ID), // type_id
        tx.pure.u64(10),           // volume
        tx.pure.u32(1),            // quantity (u32!)
      ],
    });
    tx.moveCall({
      target: `${PKG}::character::return_owner_cap`,
      typeArguments: [`${PKG}::storage_unit::StorageUnit`],
      arguments: [
        tx.object(characterId!),
        ownerCap,
        receipt,
      ],
    });
    await signAndExecute(tx, adminKp, "Mint item into SSU A");
  }

  // ══════════════════════════════════════════════════════════
  // ── Step 10: ATOMIC TRANSFER TEST ──
  // ══════════════════════════════════════════════════════════
  console.log("\n══════════════════════════════════════════════════════════");
  console.log("══ Step 10: ATOMIC TRANSFER TEST ══");
  console.log("══════════════════════════════════════════════════════════");

  {
    const tx = new Transaction();

    // Split off a small reward coin (1000 MIST) from gas
    const [rewardCoin] = tx.splitCoins(tx.gas, [1000]);

    // Call atomic_transfer_test
    tx.moveCall({
      target: `${PKG}::atomic_transfer::atomic_transfer_test`,
      arguments: [
        tx.object(ssuAId!),       // source SSU
        tx.object(ssuBId!),       // destination SSU
        tx.object(characterId!),  // character
        tx.pure.u64(ITEM_TYPE_ID),// item_type_id
        rewardCoin,               // reward coin
      ],
    });

    try {
      const res = await signAndExecute(tx, adminKp, "ATOMIC TRANSFER");

      // Check events
      const events = (res as any).events || [];
      const transferEvent = events.find((e: any) =>
        e.type?.includes("AtomicTransferEvent")
      );

      console.log("\n══════════════════════════════════════════════════════════");
      console.log("  ✓ FEASIBILITY CONFIRMED");
      console.log("══════════════════════════════════════════════════════════");
      console.log("\nAtomicTransferEvent:", JSON.stringify(transferEvent?.parsedJson || transferEvent, null, 2));

      // Gas analysis
      const gas = (res as any).effects?.gasUsed;
      console.log(`\nGas used:`);
      console.log(`  Computation: ${gas?.computationCost}`);
      console.log(`  Storage:     ${gas?.storageCost}`);
      console.log(`  Rebate:      ${gas?.storageRebate}`);
      console.log(`  Net:         ${Number(gas?.computationCost) + Number(gas?.storageCost) - Number(gas?.storageRebate)}`);

      // Object changes
      const modified = (res as any).objectChanges?.filter((c: any) => c.type === "mutated");
      console.log(`\nObjects mutated: ${modified?.length}`);
      modified?.forEach((m: any) => {
        console.log(`  - ${m.objectType?.split("::")?.slice(-1)}: ${m.objectId}`);
      });

    } catch (err: any) {
      console.log("\n══════════════════════════════════════════════════════════");
      console.log("  ✗ FEASIBILITY FAILED");
      console.log("══════════════════════════════════════════════════════════");
      console.log("Error:", err.message || err);
      process.exit(1);
    }
  }

  console.log("\n══ EXPERIMENT COMPLETE ══");
}

main().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});
