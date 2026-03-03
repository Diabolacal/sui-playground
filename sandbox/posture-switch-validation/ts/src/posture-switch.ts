/**
 * Posture switch implementation — the "one click" entrypoint.
 *
 * Attempts Strategy A (single PTB) first.
 * If that fails, falls back to Strategy B (multi-tx orchestration).
 *
 * Usage:
 *   npx tsx src/posture-switch.ts DEFENSE
 *   npx tsx src/posture-switch.ts BUSINESS
 */
import { Transaction } from "@mysten/sui/transactions";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import {
  client,
  getAdminKeypair,
  executeTransaction,
  getObjectFields,
  queryEvents,
  PostureMode,
  BUSINESS,
  DEFENSE,
} from "./utils.js";
import { readFileSync, existsSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Load topology
// ---------------------------------------------------------------------------
interface OwnerCapRef {
  id: string;
  version: string;
  digest: string;
}
interface Topology {
  characterId: string;
  networkNodeId: string;
  gate1Id: string;
  gate2Id: string;
  turret1Id: string;
  turret2Id: string;
  gateCapMapping: Record<string, OwnerCapRef>;
  turretCapMapping: Record<string, OwnerCapRef>;
  worldPkg: string;
  ccPkg: string;
  adminAddress: string;
  ccAdminCap: string;
  ccExtensionConfig: string;
  energyConfig: string;
  adminAcl: string;
}

function loadTopology(): Topology {
  const f = resolve(__dirname, "../topology.json");
  if (!existsSync(f)) throw new Error("topology.json not found — run setup.ts first");
  return JSON.parse(readFileSync(f, "utf-8"));
}

// ---------------------------------------------------------------------------
// Pre-check: read current turret status from chain
// ---------------------------------------------------------------------------
async function getTurretStatus(turretId: string): Promise<string> {
  const fields = await getObjectFields(turretId);
  // status is nested: { type: "..::AssemblyStatus", fields: { status: { variant: "ONLINE"|"OFFLINE" } } }
  try {
    const status = fields?.status?.fields?.status;
    if (typeof status === "string") return status;
    // Enum variant representation
    if (status?.variant) return status.variant;
    // Could be { ONLINE: true } or similar
    return JSON.stringify(status);
  } catch {
    return "UNKNOWN";
  }
}

// ---------------------------------------------------------------------------
// Refresh a single OwnerCap ref (version/digest change after each tx)
// ---------------------------------------------------------------------------
async function refreshCapRef(capId: string): Promise<OwnerCapRef> {
  const obj = await client.getObject({
    id: capId,
    options: { showContent: true },
  });
  return {
    id: capId,
    version: obj.data?.version ?? "",
    digest: obj.data?.digest ?? "",
  };
}

// ===================================================================
// Strategy A: Single PTB
// ===================================================================
export async function postureSwitch_SinglePTB(
  topo: Topology,
  keypair: Ed25519Keypair,
  target: PostureMode
): Promise<{
  success: boolean;
  digest: string;
  events: any[];
  error?: string;
  latencyMs: number;
}> {
  const W = topo.worldPkg;
  const CC = topo.ccPkg;
  const targetMode = target === "DEFENSE" ? DEFENSE : BUSINESS;

  // Pre-check turret states to avoid abort from strict state guards
  const turretIds = [topo.turret1Id, topo.turret2Id];
  const turretStatuses = await Promise.all(turretIds.map(getTurretStatus));
  console.log(
    `  Pre-check turrets: [${turretStatuses.join(", ")}]`
  );

  const targetTurretAction = target === "DEFENSE" ? "online" : "offline";
  const turretsThatNeedToggle: number[] = [];
  for (let i = 0; i < turretIds.length; i++) {
    const current = turretStatuses[i].toUpperCase();
    if (target === "DEFENSE" && current !== "ONLINE") {
      turretsThatNeedToggle.push(i);
    } else if (target === "BUSINESS" && current !== "OFFLINE") {
      turretsThatNeedToggle.push(i);
    }
  }
  console.log(
    `  Turrets needing toggle to ${targetTurretAction}: [${turretsThatNeedToggle.join(", ")}]`
  );

  // Refresh turret OwnerCap refs from mapping (versions may have changed)
  // Build single PTB
  const tx = new Transaction();

  // --- Gate policy update ---
  // Set posture mode
  tx.moveCall({
    target: `${CC}::posture::set_posture`,
    arguments: [
      tx.object(topo.ccExtensionConfig),
      tx.object(topo.ccAdminCap),
      tx.pure.u8(targetMode),
    ],
  });

  if (target === "DEFENSE") {
    // Set tribe config for defense
    tx.moveCall({
      target: `${CC}::posture::set_tribe_config`,
      arguments: [
        tx.object(topo.ccExtensionConfig),
        tx.object(topo.ccAdminCap),
        tx.pure.u32(42), // tribe = 42 (matches our character)
        tx.pure.u64(300_000), // 5 min expiry
      ],
    });
    // Clear business config
    tx.moveCall({
      target: `${CC}::posture::clear_toll_config`,
      arguments: [
        tx.object(topo.ccExtensionConfig),
        tx.object(topo.ccAdminCap),
      ],
    });
  } else {
    // Set toll config for business
    tx.moveCall({
      target: `${CC}::posture::set_toll_config`,
      arguments: [
        tx.object(topo.ccExtensionConfig),
        tx.object(topo.ccAdminCap),
        tx.pure.u64(100),
      ],
    });
    // Clear defense config
    tx.moveCall({
      target: `${CC}::posture::clear_tribe_config`,
      arguments: [
        tx.object(topo.ccExtensionConfig),
        tx.object(topo.ccAdminCap),
      ],
    });
  }

  // --- Turret toggles ---
  for (const idx of turretsThatNeedToggle) {
    const turretId = turretIds[idx];
    const capEntry = topo.turretCapMapping[turretId];
    if (!capEntry) {
      console.log(`  ⚠️ No OwnerCap mapping for turret ${turretId}`);
      continue;
    }
    const cap = await refreshCapRef(capEntry.id);

    // Borrow OwnerCap<Turret> from Character
    const [ownerCap, receipt] = tx.moveCall({
      target: `${W}::character::borrow_owner_cap`,
      typeArguments: [`${W}::turret::Turret`],
      arguments: [
        tx.object(topo.characterId),
        tx.receivingRef({
          objectId: cap.id,
          version: cap.version,
          digest: cap.digest,
        }),
      ],
    });

    // Toggle turret online or offline
    tx.moveCall({
      target: `${W}::turret::${targetTurretAction}`,
      arguments: [
        tx.object(turretId),
        tx.object(topo.networkNodeId),
        tx.object(topo.energyConfig),
        ownerCap,
      ],
    });

    // Return OwnerCap
    tx.moveCall({
      target: `${W}::character::return_owner_cap`,
      typeArguments: [`${W}::turret::Turret`],
      arguments: [tx.object(topo.characterId), ownerCap, receipt],
    });
  }

  const start = Date.now();
  const r = await executeTransaction(tx, keypair, `single-ptb-${target}`);
  const latencyMs = Date.now() - start;

  return {
    success: r.success,
    digest: r.digest,
    events: r.events,
    error: r.error,
    latencyMs,
  };
}

// ===================================================================
// Strategy B: Multi-TX Orchestration
// ===================================================================
export async function postureSwitch_MultiTx(
  topo: Topology,
  keypair: Ed25519Keypair,
  target: PostureMode
): Promise<{
  success: boolean;
  digests: string[];
  events: any[];
  errors: string[];
  latencyMs: number;
  txCount: number;
}> {
  const W = topo.worldPkg;
  const CC = topo.ccPkg;
  const targetMode = target === "DEFENSE" ? DEFENSE : BUSINESS;
  const digests: string[] = [];
  const allEvents: any[] = [];
  const errors: string[] = [];
  const start = Date.now();

  // Step 1: Update gate policy (posture + config DFs)
  console.log("  [multi-tx] Step 1: Update gate policy...");
  {
    const tx = new Transaction();
    tx.moveCall({
      target: `${CC}::posture::set_posture`,
      arguments: [
        tx.object(topo.ccExtensionConfig),
        tx.object(topo.ccAdminCap),
        tx.pure.u8(targetMode),
      ],
    });
    if (target === "DEFENSE") {
      tx.moveCall({
        target: `${CC}::posture::set_tribe_config`,
        arguments: [
          tx.object(topo.ccExtensionConfig),
          tx.object(topo.ccAdminCap),
          tx.pure.u32(42),
          tx.pure.u64(300_000),
        ],
      });
      tx.moveCall({
        target: `${CC}::posture::clear_toll_config`,
        arguments: [
          tx.object(topo.ccExtensionConfig),
          tx.object(topo.ccAdminCap),
        ],
      });
    } else {
      tx.moveCall({
        target: `${CC}::posture::set_toll_config`,
        arguments: [
          tx.object(topo.ccExtensionConfig),
          tx.object(topo.ccAdminCap),
          tx.pure.u64(100),
        ],
      });
      tx.moveCall({
        target: `${CC}::posture::clear_tribe_config`,
        arguments: [
          tx.object(topo.ccExtensionConfig),
          tx.object(topo.ccAdminCap),
        ],
      });
    }
    const r = await executeTransaction(tx, keypair, "multi-step1-policy");
    digests.push(r.digest);
    allEvents.push(...r.events);
    if (!r.success) {
      errors.push(`Step 1 failed: ${r.error}`);
      return {
        success: false,
        digests,
        events: allEvents,
        errors,
        latencyMs: Date.now() - start,
        txCount: 1,
      };
    }
  }

  // Steps 2+: Toggle each turret individually
  const turretIds = [topo.turret1Id, topo.turret2Id];
  const turretStatuses = await Promise.all(turretIds.map(getTurretStatus));
  const targetTurretAction = target === "DEFENSE" ? "online" : "offline";

  for (let i = 0; i < turretIds.length; i++) {
    const current = turretStatuses[i].toUpperCase();
    const needsToggle =
      (target === "DEFENSE" && current !== "ONLINE") ||
      (target === "BUSINESS" && current !== "OFFLINE");

    if (!needsToggle) {
      console.log(
        `  [multi-tx] Step ${i + 2}: Turret ${i + 1} already ${current} — skip`
      );
      continue;
    }

    console.log(
      `  [multi-tx] Step ${i + 2}: Toggle turret ${i + 1} ${targetTurretAction}...`
    );

    // Refresh OwnerCap for this turret from mapping
    const capEntry = topo.turretCapMapping[turretIds[i]];
    if (!capEntry) {
      errors.push(`No OwnerCap mapping for turret ${i + 1}`);
      continue;
    }
    const cap = await refreshCapRef(capEntry.id);

    const tx = new Transaction();
    const [ownerCap, receipt] = tx.moveCall({
      target: `${W}::character::borrow_owner_cap`,
      typeArguments: [`${W}::turret::Turret`],
      arguments: [
        tx.object(topo.characterId),
        tx.receivingRef({
          objectId: cap.id,
          version: cap.version,
          digest: cap.digest,
        }),
      ],
    });

    tx.moveCall({
      target: `${W}::turret::${targetTurretAction}`,
      arguments: [
        tx.object(turretIds[i]),
        tx.object(topo.networkNodeId),
        tx.object(topo.energyConfig),
        ownerCap,
      ],
    });

    tx.moveCall({
      target: `${W}::character::return_owner_cap`,
      typeArguments: [`${W}::turret::Turret`],
      arguments: [tx.object(topo.characterId), ownerCap, receipt],
    });

    const r = await executeTransaction(
      tx,
      keypair,
      `multi-step${i + 2}-turret${i + 1}`
    );
    digests.push(r.digest);
    allEvents.push(...r.events);
    if (!r.success) {
      errors.push(`Step ${i + 2} (turret ${i + 1}) failed: ${r.error}`);
    }
  }

  return {
    success: errors.length === 0,
    digests,
    events: allEvents,
    errors,
    latencyMs: Date.now() - start,
    txCount: digests.length,
  };
}

// ===================================================================
// Verification: read final state
// ===================================================================
export async function verifyPosture(
  topo: Topology,
  expectedMode: PostureMode
): Promise<{
  postureMode: string;
  hasDefenseConfig: boolean;
  hasBusinessConfig: boolean;
  turretStatuses: string[];
  pass: boolean;
}> {
  // Read posture DF
  const W = topo.worldPkg;
  const CC = topo.ccPkg;

  // Use devInspect to call view functions
  const postureResult = await client.devInspectTransactionBlock({
    sender: topo.adminAddress,
    transactionBlock: (() => {
      const tx = new Transaction();
      tx.moveCall({
        target: `${CC}::posture::current_posture`,
        arguments: [tx.object(topo.ccExtensionConfig)],
      });
      return tx;
    })(),
  });

  let postureMode = "UNKNOWN";
  if (postureResult.results?.[0]?.returnValues?.[0]) {
    const bytes = postureResult.results[0].returnValues[0][0];
    const mode = typeof bytes === "object" ? bytes[0] : bytes;
    postureMode = mode === 0 ? "BUSINESS" : mode === 1 ? "DEFENSE" : `UNKNOWN(${mode})`;
  }

  // Check turret statuses
  const turretStatuses = await Promise.all(
    [topo.turret1Id, topo.turret2Id].map(getTurretStatus)
  );

  // Check DFs
  const hasDefenseResult = await client.devInspectTransactionBlock({
    sender: topo.adminAddress,
    transactionBlock: (() => {
      const tx = new Transaction();
      tx.moveCall({
        target: `${CC}::posture::has_defense_config`,
        arguments: [tx.object(topo.ccExtensionConfig)],
      });
      return tx;
    })(),
  });

  const hasBusinessResult = await client.devInspectTransactionBlock({
    sender: topo.adminAddress,
    transactionBlock: (() => {
      const tx = new Transaction();
      tx.moveCall({
        target: `${CC}::posture::has_business_config`,
        arguments: [tx.object(topo.ccExtensionConfig)],
      });
      return tx;
    })(),
  });

  let hasDefenseConfig = false;
  if (hasDefenseResult.results?.[0]?.returnValues?.[0]) {
    const b = hasDefenseResult.results[0].returnValues[0][0];
    hasDefenseConfig = (typeof b === "object" ? b[0] : b) === 1;
  }

  let hasBusinessConfig = false;
  if (hasBusinessResult.results?.[0]?.returnValues?.[0]) {
    const b = hasBusinessResult.results[0].returnValues[0][0];
    hasBusinessConfig = (typeof b === "object" ? b[0] : b) === 1;
  }

  const expectedTurret = expectedMode === "DEFENSE" ? "ONLINE" : "OFFLINE";
  const pass =
    postureMode === expectedMode &&
    (expectedMode === "DEFENSE" ? hasDefenseConfig && !hasBusinessConfig : !hasDefenseConfig && hasBusinessConfig) &&
    turretStatuses.every(
      (s) => s.toUpperCase() === expectedTurret
    );

  return { postureMode, hasDefenseConfig, hasBusinessConfig, turretStatuses, pass };
}

// ===================================================================
// CLI entrypoint
// ===================================================================
async function main() {
  const target = process.argv[2]?.toUpperCase() as PostureMode;
  if (target !== "DEFENSE" && target !== "BUSINESS") {
    console.log("Usage: npx tsx src/posture-switch.ts <DEFENSE|BUSINESS>");
    process.exit(1);
  }

  const topo = loadTopology();
  const keypair = getAdminKeypair();

  console.log(`\n=== Posture Switch → ${target} ===\n`);

  // Strategy A: single PTB
  console.log("--- Strategy A: Single PTB ---");
  const resultA = await postureSwitch_SinglePTB(topo, keypair, target);

  if (resultA.success) {
    console.log(
      `\n  ✅ Single PTB succeeded! digest=${resultA.digest} latency=${resultA.latencyMs}ms`
    );
    printEvents(resultA.events);
  } else {
    console.log(
      `\n  ❌ Single PTB failed: ${resultA.error}`
    );
    console.log("  Falling back to Strategy B (multi-tx)...\n");

    console.log("--- Strategy B: Multi-TX Orchestration ---");
    const resultB = await postureSwitch_MultiTx(topo, keypair, target);
    console.log(
      `\n  ${resultB.success ? "✅" : "❌"} Multi-TX: ${resultB.txCount} txs, latency=${resultB.latencyMs}ms`
    );
    if (resultB.errors.length > 0) {
      console.log(`  Errors: ${resultB.errors.join("; ")}`);
    }
    printEvents(resultB.events);
  }

  // Verify final state
  console.log("\n--- Verification ---");
  const v = await verifyPosture(topo, target);
  console.log(`  Posture mode:     ${v.postureMode}`);
  console.log(`  Defense config:   ${v.hasDefenseConfig}`);
  console.log(`  Business config:  ${v.hasBusinessConfig}`);
  console.log(`  Turret statuses:  [${v.turretStatuses.join(", ")}]`);
  console.log(`  PASS: ${v.pass}`);
}

function printEvents(events: any[]) {
  const relevant = events.filter(
    (e) =>
      e.type?.includes("PostureChangedEvent") ||
      e.type?.includes("StatusChangedEvent")
  );
  if (relevant.length > 0) {
    console.log("  Events:");
    for (const e of relevant) {
      console.log(`    ${e.type?.split("::")?.pop()}: ${JSON.stringify(e.parsedJson)}`);
    }
  }
}

// Only run CLI entrypoint when invoked directly
const isMain = process.argv[1]?.replace(/\\/g, "/").endsWith("posture-switch.ts") ||
  process.argv[1]?.replace(/\\/g, "/").endsWith("posture-switch.js");
if (isMain) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
