/**
 * Setup script: provisions the localnet topology for posture-switch validation.
 *
 * PTB1: Governor setup (add sponsor, register server address)
 * PTB2: Create topology (character, network node, 2 gates, 2 turrets) + share all
 * PTB3: Authorize CC extension on both gates
 * PTB4: Set initial posture to BUSINESS (toll config, turrets stay offline)
 *
 * Writes topology IDs to topology.json for use by posture-switch.ts.
 */
import { Transaction } from "@mysten/sui/transactions";
import {
  IDS,
  client,
  getAdminKeypair,
  executeTransaction,
  getObjectFields,
} from "./utils.js";
import { writeFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TOPOLOGY_FILE = resolve(__dirname, "../topology.json");

const W = IDS.worldPkg;
const CC = IDS.ccPkg;

async function main() {
  console.log("=== CivilizationControl Posture-Switch — Localnet Setup ===\n");

  const keypair = getAdminKeypair();
  const adminAddr = keypair.getPublicKey().toSuiAddress();
  console.log(`Admin address: ${adminAddr}`);
  console.log(`World package: ${W}`);
  console.log(`CC package:    ${CC}\n`);

  // -----------------------------------------------------------------------
  // PTB1: Governor setup — add sponsor + register server address
  // -----------------------------------------------------------------------
  console.log("--- PTB1: Governor Setup ---");
  {
    const tx = new Transaction();
    tx.moveCall({
      target: `${W}::access::add_sponsor_to_acl`,
      arguments: [
        tx.object(IDS.adminAcl),
        tx.object(IDS.governorCap),
        tx.pure.address(adminAddr),
      ],
    });
    tx.moveCall({
      target: `${W}::access::register_server_address`,
      arguments: [
        tx.object(IDS.serverAddressRegistry),
        tx.object(IDS.governorCap),
        tx.pure.address(adminAddr),
      ],
    });
    const r = await executeTransaction(tx, keypair, "governor-setup");
    if (!r.success) {
      // Tolerate "already exists" — sponsor may have been added in a prior run
      if (r.error?.includes("dynamic_field") && r.error?.includes("add")) {
        console.log("  (Sponsor already in ACL — continuing)\n");
      } else {
        throw new Error(`PTB1 failed: ${r.error}`);
      }
    }
  }

  // -----------------------------------------------------------------------
  // PTB2: Create topology — all assemblies in one transaction
  // -----------------------------------------------------------------------
  console.log("\n--- PTB2: Create Topology ---");
  let characterId = "";
  let networkNodeId = "";
  let gate1Id = "";
  let gate2Id = "";
  let turret1Id = "";
  let turret2Id = "";
  let gateCapIds: string[] = [];
  let turretCapIds: string[] = [];
  let networkNodeCapId = "";

  // Small delay to ensure PTB1's state is fully committed
  await new Promise((r) => setTimeout(r, 2000));

  // Use random base to avoid game_id collisions with prior runs on same chain
  const BASE = Math.floor(Math.random() * 900000) + 100000;
  {
    const tx = new Transaction();
    tx.setGasBudget(500_000_000); // Explicit budget to bypass dry-run issues

    // 2a. Create character
    const [character] = tx.moveCall({
      target: `${W}::character::create_character`,
      arguments: [
        tx.object(IDS.objectRegistry),
        tx.object(IDS.adminAcl),
        tx.pure.u32(BASE),
        tx.pure.string("cc_test"),
        tx.pure.u32(42),
        tx.pure.address(adminAddr),
        tx.pure.string("CC Operator"),
      ],
    });

    // 2b. Anchor network node
    const zeroHash = Array.from(new Uint8Array(32));
    const [networkNode] = tx.moveCall({
      target: `${W}::network_node::anchor`,
      arguments: [
        tx.object(IDS.objectRegistry),
        character,
        tx.object(IDS.adminAcl),
        tx.pure.u64(BASE + 1),
        tx.pure.u64(100),
        tx.pure.vector('u8', zeroHash),
        tx.pure.u64(1_000_000),
        tx.pure.u64(60_000),  // fuel_burn_rate_in_ms (min 60s = 60000ms)
        tx.pure.u64(100_000),
      ],
    });

    // 2c. Anchor gate1
    const [gate1] = tx.moveCall({
      target: `${W}::gate::anchor`,
      arguments: [
        tx.object(IDS.objectRegistry),
        networkNode,
        character,
        tx.object(IDS.adminAcl),
        tx.pure.u64(BASE + 2),
        tx.pure.u64(200),
        tx.pure.vector('u8', zeroHash),
      ],
    });

    // 2d. Anchor gate2
    const [gate2] = tx.moveCall({
      target: `${W}::gate::anchor`,
      arguments: [
        tx.object(IDS.objectRegistry),
        networkNode,
        character,
        tx.object(IDS.adminAcl),
        tx.pure.u64(BASE + 3),
        tx.pure.u64(200),
        tx.pure.vector('u8', zeroHash),
      ],
    });

    // 2e. Anchor turret1
    const [turret1] = tx.moveCall({
      target: `${W}::turret::anchor`,
      arguments: [
        tx.object(IDS.objectRegistry),
        networkNode,
        character,
        tx.object(IDS.adminAcl),
        tx.pure.u64(BASE + 4),
        tx.pure.u64(300),
        tx.pure.vector('u8', zeroHash),
      ],
    });

    // 2f. Anchor turret2
    const [turret2] = tx.moveCall({
      target: `${W}::turret::anchor`,
      arguments: [
        tx.object(IDS.objectRegistry),
        networkNode,
        character,
        tx.object(IDS.adminAcl),
        tx.pure.u64(BASE + 5),
        tx.pure.u64(300),
        tx.pure.vector('u8', zeroHash),
      ],
    });

    // 2g. Share all objects
    tx.moveCall({
      target: `${W}::character::share_character`,
      arguments: [character, tx.object(IDS.adminAcl)],
    });
    tx.moveCall({
      target: `${W}::network_node::share_network_node`,
      arguments: [networkNode, tx.object(IDS.adminAcl)],
    });
    tx.moveCall({
      target: `${W}::gate::share_gate`,
      arguments: [gate1, tx.object(IDS.adminAcl)],
    });
    tx.moveCall({
      target: `${W}::gate::share_gate`,
      arguments: [gate2, tx.object(IDS.adminAcl)],
    });
    tx.moveCall({
      target: `${W}::turret::share_turret`,
      arguments: [turret1, tx.object(IDS.adminAcl)],
    });
    tx.moveCall({
      target: `${W}::turret::share_turret`,
      arguments: [turret2, tx.object(IDS.adminAcl)],
    });

    const r = await executeTransaction(tx, keypair, "create-topology");
    if (!r.success) throw new Error(`PTB2 failed: ${r.error}`);

    // Parse objectChanges to find IDs by type
    const created = r.objectChanges.filter(
      (c: any) => c.type === "created"
    );

    const gateCapIdsInner: string[] = [];
    const turretCapIdsInner: string[] = [];

    for (const obj of created) {
      const t: string = obj.objectType ?? "";
      const id: string = obj.objectId ?? "";
      if (t.includes("::character::Character") && !t.includes("OwnerCap")) {
        characterId = id;
      } else if (
        t.includes("::network_node::NetworkNode") &&
        !t.includes("OwnerCap")
      ) {
        networkNodeId = id;
      } else if (t.includes("::gate::Gate") && !t.includes("OwnerCap")) {
        if (!gate1Id) gate1Id = id;
        else gate2Id = id;
      } else if (t.includes("::turret::Turret") && !t.includes("OwnerCap")) {
        if (!turret1Id) turret1Id = id;
        else turret2Id = id;
      } else if (t.includes("OwnerCap") && t.includes("gate::Gate")) {
        gateCapIdsInner.push(id);
      } else if (t.includes("OwnerCap") && t.includes("turret::Turret")) {
        turretCapIdsInner.push(id);
      } else if (t.includes("OwnerCap") && t.includes("network_node::NetworkNode")) {
        networkNodeCapId = id;
      }
    }
    gateCapIds = gateCapIdsInner;
    turretCapIds = turretCapIdsInner;

    console.log("\n  Created topology:");
    console.log(`    Character:   ${characterId}`);
    console.log(`    NetworkNode: ${networkNodeId}`);
    console.log(`    Gate1:       ${gate1Id}`);
    console.log(`    Gate2:       ${gate2Id}`);
    console.log(`    Turret1:     ${turret1Id}`);
    console.log(`    Turret2:     ${turret2Id}`);
    console.log(`    Gate OwnerCap IDs:   [${gateCapIds.join(", ")}]`);
    console.log(`    Turret OwnerCap IDs: [${turretCapIds.join(", ")}]`);
    console.log(`    NwNode OwnerCap ID:  ${networkNodeCapId}`);
  }

  // -----------------------------------------------------------------------
  // Resolve OwnerCap refs (need version + digest for Receiving<T>)
  // -----------------------------------------------------------------------
  console.log("\n--- Resolving OwnerCap Refs ---");

  // Wait briefly for indexer to catch up
  await new Promise((r) => setTimeout(r, 1000));

  // First try getOwnedObjects approach (may work after delay)
  let ownerCaps = await discoverOwnerCaps(characterId);

  // If getOwnedObjects didn't find them, use the IDs from objectChanges
  // and query each one individually
  if (ownerCaps.gate.length < 2 || ownerCaps.turret.length < 2) {
    console.log("  getOwnedObjects missed caps — querying by ID directly...");
    ownerCaps = { gate: [], turret: [] };
    for (const id of gateCapIds) {
      const obj = await client.getObject({ id, options: { showType: true } });
      if (obj.data) {
        ownerCaps.gate.push({
          id: obj.data.objectId,
          version: obj.data.version!,
          digest: obj.data.digest!,
        });
      }
    }
    for (const id of turretCapIds) {
      const obj = await client.getObject({ id, options: { showType: true } });
      if (obj.data) {
        ownerCaps.turret.push({
          id: obj.data.objectId,
          version: obj.data.version!,
          digest: obj.data.digest!,
        });
      }
    }
  }
  console.log(
    `  Gate OwnerCaps:   [${ownerCaps.gate.map((c) => c.id).join(", ")}]`
  );
  console.log(
    `  Turret OwnerCaps: [${ownerCaps.turret.map((c) => c.id).join(", ")}]`
  );

  if (ownerCaps.gate.length < 2) throw new Error("Need 2 gate OwnerCaps");
  if (ownerCaps.turret.length < 2) throw new Error("Need 2 turret OwnerCaps");

  // Build cap→gate and cap→turret mapping by reading authorized_object_id
  const gateCapMap = new Map<string, OwnerCapRef>(); // gateId → cap
  for (const cap of ownerCaps.gate) {
    const fields = await getObjectFields(cap.id);
    const authId = fields?.authorized_object_id;
    if (authId) {
      gateCapMap.set(authId, cap);
      console.log(`  Gate OwnerCap ${cap.id.slice(0, 10)} → gate ${authId.slice(0, 10)}`);
    }
  }
  const turretCapMap = new Map<string, OwnerCapRef>(); // turretId → cap
  for (const cap of ownerCaps.turret) {
    const fields = await getObjectFields(cap.id);
    const authId = fields?.authorized_object_id;
    if (authId) {
      turretCapMap.set(authId, cap);
      console.log(`  Turret OwnerCap ${cap.id.slice(0, 10)} → turret ${authId.slice(0, 10)}`);
    }
  }

  // -----------------------------------------------------------------------
  // PTB2b: Fuel + Energy setup — bring NetworkNode online
  // -----------------------------------------------------------------------
  console.log("\n--- PTB2b: Fuel & Energy Setup ---");
  await new Promise((r) => setTimeout(r, 1000));
  {
    // Resolve NetworkNode OwnerCap
    const nwnCapObj = await client.getObject({ id: networkNodeCapId, options: { showContent: true } });
    if (!nwnCapObj.data) throw new Error("NetworkNode OwnerCap not found");
    const nwnCap: OwnerCapRef = {
      id: nwnCapObj.data.objectId,
      version: nwnCapObj.data.version!,
      digest: nwnCapObj.data.digest!,
    };

    const tx = new Transaction();
    const CLOCK = "0x6"; // Sui system clock

    // 2b-1: Set fuel efficiency (fuel_type_id=1, efficiency=100%)
    tx.moveCall({
      target: `${W}::fuel::set_fuel_efficiency`,
      arguments: [
        tx.object(IDS.fuelConfig),
        tx.object(IDS.adminAcl),
        tx.pure.u64(1),   // fuel_type_id
        tx.pure.u64(100), // 100% efficiency
      ],
    });

    // 2b-2: Borrow OwnerCap<NetworkNode> from Character
    const [ownerCap, receipt] = tx.moveCall({
      target: `${W}::character::borrow_owner_cap`,
      typeArguments: [`${W}::network_node::NetworkNode`],
      arguments: [
        tx.object(characterId),
        tx.receivingRef({
          objectId: nwnCap.id,
          version: nwnCap.version,
          digest: nwnCap.digest,
        }),
      ],
    });

    // 2b-3: Deposit fuel
    tx.moveCall({
      target: `${W}::network_node::deposit_fuel`,
      arguments: [
        tx.object(networkNodeId),
        tx.object(IDS.adminAcl),
        ownerCap,
        tx.pure.u64(1),   // fuel_type_id (matches set above)
        tx.pure.u64(100), // volume
        tx.pure.u64(10),  // quantity (10 units)
        tx.object(CLOCK),
      ],
    });

    // 2b-4: Bring NetworkNode online
    tx.moveCall({
      target: `${W}::network_node::online`,
      arguments: [
        tx.object(networkNodeId),
        ownerCap,
        tx.object(CLOCK),
      ],
    });

    // 2b-5: Return OwnerCap<NetworkNode>
    tx.moveCall({
      target: `${W}::character::return_owner_cap`,
      typeArguments: [`${W}::network_node::NetworkNode`],
      arguments: [tx.object(characterId), ownerCap, receipt],
    });

    const r = await executeTransaction(tx, keypair, "fuel-energy-setup");
    if (!r.success) throw new Error(`PTB2b failed: ${r.error}`);
    console.log("  NetworkNode is now online with fuel and energy.");
  }

  // -----------------------------------------------------------------------
  // PTB3: Authorize CC extension on both gates
  // -----------------------------------------------------------------------
  console.log("\n--- PTB3: Authorize Extension on Gates ---");
  // Delay + re-read gate caps for fresh versions after PTB2b touched Character
  await new Promise((r) => setTimeout(r, 2000));
  {
    // Re-read gate cap versions (Character changed in PTB2b)
    for (const [gateId, cap] of gateCapMap.entries()) {
      const obj = await client.getObject({ id: cap.id, options: { showType: true } });
      if (obj.data) {
        gateCapMap.set(gateId, {
          id: obj.data.objectId,
          version: obj.data.version!,
          digest: obj.data.digest!,
        });
      }
    }

    const tx = new Transaction();
    const xAuthType = `${CC}::config::XAuth`;
    const gateIds = [gate1Id, gate2Id];

    for (const gateId of gateIds) {
      const cap = gateCapMap.get(gateId);
      if (!cap) throw new Error(`No OwnerCap found for gate ${gateId}`);

      const [ownerCap, receipt] = tx.moveCall({
        target: `${W}::character::borrow_owner_cap`,
        typeArguments: [`${W}::gate::Gate`],
        arguments: [
          tx.object(characterId),
          tx.receivingRef({
            objectId: cap.id,
            version: cap.version,
            digest: cap.digest,
          }),
        ],
      });

      tx.moveCall({
        target: `${W}::gate::authorize_extension`,
        typeArguments: [xAuthType],
        arguments: [tx.object(gateId), ownerCap],
      });

      tx.moveCall({
        target: `${W}::character::return_owner_cap`,
        typeArguments: [`${W}::gate::Gate`],
        arguments: [tx.object(characterId), ownerCap, receipt],
      });
    }

    const r = await executeTransaction(tx, keypair, "authorize-extension");
    if (!r.success) throw new Error(`PTB3 failed: ${r.error}`);
  }

  // -----------------------------------------------------------------------
  // PTB4: Set initial posture to BUSINESS (turrets stay offline from anchor)
  // -----------------------------------------------------------------------
  console.log("\n--- PTB4: Set Initial Posture (BUSINESS) ---");
  // Brief delay for gas coin version sync
  await new Promise((r) => setTimeout(r, 1000));
  {
    const tx = new Transaction();

    tx.moveCall({
      target: `${CC}::posture::set_posture`,
      arguments: [
        tx.object(IDS.ccExtensionConfig),
        tx.object(IDS.ccAdminCap),
        tx.pure.u8(0), // BUSINESS
      ],
    });

    tx.moveCall({
      target: `${CC}::posture::set_toll_config`,
      arguments: [
        tx.object(IDS.ccExtensionConfig),
        tx.object(IDS.ccAdminCap),
        tx.pure.u64(100), // toll = 100 (stub)
      ],
    });

    // Clear any stale defense config from prior runs (shared ExtensionConfig)
    tx.moveCall({
      target: `${CC}::posture::clear_tribe_config`,
      arguments: [
        tx.object(IDS.ccExtensionConfig),
        tx.object(IDS.ccAdminCap),
      ],
    });

    const r = await executeTransaction(tx, keypair, "set-business-posture");
    if (!r.success) throw new Error(`PTB4 failed: ${r.error}`);

    for (const ev of r.events) {
      if (ev.type?.includes("PostureChangedEvent")) {
        console.log(`  PostureChangedEvent: ${JSON.stringify(ev.parsedJson)}`);
      }
    }
  }

  // -----------------------------------------------------------------------
  // Refresh OwnerCap versions (they changed after PTB3)
  // -----------------------------------------------------------------------
  console.log("\n--- Refreshing OwnerCap versions ---");
  // Wait for indexer
  await new Promise((r) => setTimeout(r, 1000));

  // Re-read cap objects for fresh versions
  const freshGateCapMap: Record<string, OwnerCapRef> = {};
  for (const [gateId, cap] of gateCapMap.entries()) {
    const obj = await client.getObject({ id: cap.id, options: { showType: true } });
    freshGateCapMap[gateId] = {
      id: obj.data!.objectId,
      version: obj.data!.version!,
      digest: obj.data!.digest!,
    };
  }
  const freshTurretCapMap: Record<string, OwnerCapRef> = {};
  for (const [turretId, cap] of turretCapMap.entries()) {
    const obj = await client.getObject({ id: cap.id, options: { showType: true } });
    freshTurretCapMap[turretId] = {
      id: obj.data!.objectId,
      version: obj.data!.version!,
      digest: obj.data!.digest!,
    };
  }

  // -----------------------------------------------------------------------
  // Save topology
  // -----------------------------------------------------------------------
  const topology = {
    characterId,
    networkNodeId,
    gate1Id,
    gate2Id,
    turret1Id,
    turret2Id,
    gateCapMapping: freshGateCapMap,
    turretCapMapping: freshTurretCapMap,
    worldPkg: W,
    ccPkg: CC,
    adminAddress: adminAddr,
    ccAdminCap: IDS.ccAdminCap,
    ccExtensionConfig: IDS.ccExtensionConfig,
    energyConfig: IDS.energyConfig,
    adminAcl: IDS.adminAcl,
  };
  writeFileSync(TOPOLOGY_FILE, JSON.stringify(topology, null, 2));
  console.log(`\n✅ Topology saved to topology.json`);
  console.log("   Run: npm run full-test\n");
}

// ---------------------------------------------------------------------------
// OwnerCap discovery
// ---------------------------------------------------------------------------

interface OwnerCapRef {
  id: string;
  version: string;
  digest: string;
}

async function discoverOwnerCaps(
  characterId: string
): Promise<{ gate: OwnerCapRef[]; turret: OwnerCapRef[] }> {
  const gate: OwnerCapRef[] = [];
  const turret: OwnerCapRef[] = [];

  let cursor: string | null | undefined = undefined;
  let hasNext = true;

  while (hasNext) {
    const response = await client.getOwnedObjects({
      owner: characterId,
      options: { showType: true },
      cursor: cursor ?? undefined,
    });

    for (const item of response.data) {
      const type = item.data?.type ?? "";
      const ref: OwnerCapRef = {
        id: item.data?.objectId ?? "",
        version: item.data?.version ?? "",
        digest: item.data?.digest ?? "",
      };

      if (type.includes("OwnerCap") && type.includes("gate::Gate")) {
        gate.push(ref);
      } else if (
        type.includes("OwnerCap") &&
        type.includes("turret::Turret")
      ) {
        turret.push(ref);
      }
    }

    hasNext = response.hasNextPage;
    cursor = response.nextCursor;
  }

  return { gate, turret };
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
