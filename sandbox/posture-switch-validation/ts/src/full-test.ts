/**
 * Full end-to-end test: setup + posture switch round-trip.
 *
 * 1. Run setup (topology provisioning)
 * 2. Verify BUSINESS baseline
 * 3. Switch to DEFENSE (single PTB attempted first)
 * 4. Verify DEFENSE state
 * 5. Switch back to BUSINESS
 * 6. Verify BUSINESS state
 * 7. Print summary report
 */
import { writeFileSync, existsSync, readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

import {
  client,
  getAdminKeypair,
  queryEvents,
} from "./utils.js";

import {
  postureSwitch_SinglePTB,
  postureSwitch_MultiTx,
  verifyPosture,
} from "./posture-switch.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TOPOLOGY_FILE = resolve(__dirname, "../topology.json");
const RESULTS_FILE = resolve(__dirname, "../results.json");

interface TestResult {
  step: string;
  strategy: "A_SINGLE_PTB" | "B_MULTI_TX";
  success: boolean;
  digest: string | string[];
  txCount: number;
  latencyMs: number;
  events: any[];
  error?: string;
  verification: any;
}

async function main() {
  console.log("================================================================");
  console.log("  CivilizationControl Posture-Switch — Full Validation Test");
  console.log("================================================================\n");

  // -----------------------------------------------------------------------
  // Step 0: Setup (if topology doesn't exist)
  // -----------------------------------------------------------------------
  if (!existsSync(TOPOLOGY_FILE)) {
    console.log("--- Step 0: Running setup.ts ---\n");
    execSync("npx tsx src/setup.ts", {
      cwd: resolve(__dirname, ".."),
      stdio: "inherit",
    });
  } else {
    console.log("--- Step 0: topology.json exists — skipping setup ---\n");
  }

  const topo = JSON.parse(readFileSync(TOPOLOGY_FILE, "utf-8"));
  const keypair = getAdminKeypair();
  const results: TestResult[] = [];

  // -----------------------------------------------------------------------
  // Step 1: Verify BUSINESS baseline
  // -----------------------------------------------------------------------
  console.log("--- Step 1: Verify BUSINESS Baseline ---");
  const baseline = await verifyPosture(topo, "BUSINESS");
  console.log(`  Posture: ${baseline.postureMode}`);
  console.log(`  Defense config: ${baseline.hasDefenseConfig}`);
  console.log(`  Business config: ${baseline.hasBusinessConfig}`);
  console.log(`  Turrets: [${baseline.turretStatuses.join(", ")}]`);
  console.log(`  Baseline OK: ${baseline.pass}\n`);

  // -----------------------------------------------------------------------
  // Step 2: Switch to DEFENSE — attempt Strategy A
  // -----------------------------------------------------------------------
  console.log("--- Step 2: Switch BUSINESS → DEFENSE ---");
  console.log("  Attempting Strategy A (Single PTB)...");
  const defenseA = await postureSwitch_SinglePTB(topo, keypair, "DEFENSE");

  let defenseResult: TestResult;
  if (defenseA.success) {
    console.log(`  ✅ Strategy A succeeded: ${defenseA.latencyMs}ms\n`);
    const v = await verifyPosture(topo, "DEFENSE");
    defenseResult = {
      step: "BUSINESS→DEFENSE",
      strategy: "A_SINGLE_PTB",
      success: defenseA.success && v.pass,
      digest: defenseA.digest,
      txCount: 1,
      latencyMs: defenseA.latencyMs,
      events: defenseA.events,
      verification: v,
    };
  } else {
    console.log(`  ❌ Strategy A failed: ${defenseA.error}`);
    console.log("  Attempting Strategy B (Multi-TX)...\n");
    const defenseB = await postureSwitch_MultiTx(topo, keypair, "DEFENSE");
    const v = await verifyPosture(topo, "DEFENSE");
    defenseResult = {
      step: "BUSINESS→DEFENSE",
      strategy: "B_MULTI_TX",
      success: defenseB.success && v.pass,
      digest: defenseB.digests,
      txCount: defenseB.txCount,
      latencyMs: defenseB.latencyMs,
      events: defenseB.events,
      error: defenseB.errors.join("; ") || undefined,
      verification: v,
    };
    console.log(
      `  ${defenseResult.success ? "✅" : "❌"} Strategy B: ${defenseB.txCount} txs, ${defenseB.latencyMs}ms\n`
    );
  }
  results.push(defenseResult);
  printVerification(defenseResult.verification);

  // -----------------------------------------------------------------------
  // Step 3: Verify DEFENSE state
  // -----------------------------------------------------------------------
  console.log("\n--- Step 3: Verify DEFENSE State ---");
  const defenseV = await verifyPosture(topo, "DEFENSE");
  console.log(`  Posture: ${defenseV.postureMode}`);
  console.log(`  Defense config: ${defenseV.hasDefenseConfig}`);
  console.log(`  Business config: ${defenseV.hasBusinessConfig}`);
  console.log(`  Turrets: [${defenseV.turretStatuses.join(", ")}]`);
  console.log(`  PASS: ${defenseV.pass}\n`);

  // -----------------------------------------------------------------------
  // Step 4: Switch back to BUSINESS — attempt Strategy A
  // -----------------------------------------------------------------------
  console.log("--- Step 4: Switch DEFENSE → BUSINESS ---");
  console.log("  Attempting Strategy A (Single PTB)...");
  const businessA = await postureSwitch_SinglePTB(topo, keypair, "BUSINESS");

  let businessResult: TestResult;
  if (businessA.success) {
    console.log(`  ✅ Strategy A succeeded: ${businessA.latencyMs}ms\n`);
    const v = await verifyPosture(topo, "BUSINESS");
    businessResult = {
      step: "DEFENSE→BUSINESS",
      strategy: "A_SINGLE_PTB",
      success: businessA.success && v.pass,
      digest: businessA.digest,
      txCount: 1,
      latencyMs: businessA.latencyMs,
      events: businessA.events,
      verification: v,
    };
  } else {
    console.log(`  ❌ Strategy A failed: ${businessA.error}`);
    console.log("  Attempting Strategy B (Multi-TX)...\n");
    const businessB = await postureSwitch_MultiTx(topo, keypair, "BUSINESS");
    const v = await verifyPosture(topo, "BUSINESS");
    businessResult = {
      step: "DEFENSE→BUSINESS",
      strategy: "B_MULTI_TX",
      success: businessB.success && v.pass,
      digest: businessB.digests,
      txCount: businessB.txCount,
      latencyMs: businessB.latencyMs,
      events: businessB.events,
      error: businessB.errors.join("; ") || undefined,
      verification: v,
    };
    console.log(
      `  ${businessResult.success ? "✅" : "❌"} Strategy B: ${businessB.txCount} txs, ${businessB.latencyMs}ms\n`
    );
  }
  results.push(businessResult);
  printVerification(businessResult.verification);

  // -----------------------------------------------------------------------
  // Summary
  // -----------------------------------------------------------------------
  console.log("\n================================================================");
  console.log("  SUMMARY");
  console.log("================================================================");
  for (const r of results) {
    console.log(
      `  ${r.step}: ${r.success ? "✅ PASS" : "❌ FAIL"} | ` +
      `Strategy ${r.strategy} | ${r.txCount} tx(s) | ${r.latencyMs}ms`
    );
  }
  console.log("================================================================\n");

  // Save results
  writeFileSync(RESULTS_FILE, JSON.stringify(results, null, 2));
  console.log(`Results saved to results.json\n`);

  // Query all PostureChangedEvent and StatusChangedEvent for evidence
  console.log("--- Evidence: On-Chain Events ---");
  const W = topo.worldPkg;
  const CC = topo.ccPkg;
  try {
    const postureEvents = await queryEvents(
      `${CC}::posture::PostureChangedEvent`,
      20
    );
    console.log(`  PostureChangedEvent (${postureEvents.length}):`);
    for (const e of postureEvents) {
      console.log(`    ${JSON.stringify(e.parsedJson)}`);
    }
  } catch (e) {
    console.log(`  PostureChangedEvent query error: ${e}`);
  }

  try {
    const statusEvents = await queryEvents(
      `${W}::status::StatusChangedEvent`,
      20
    );
    console.log(`  StatusChangedEvent (${statusEvents.length}):`);
    for (const e of statusEvents) {
      console.log(`    ${JSON.stringify(e.parsedJson)}`);
    }
  } catch (e) {
    console.log(`  StatusChangedEvent query error: ${e}`);
  }
}

function printVerification(v: any) {
  console.log(`  Verification:`);
  console.log(`    Posture mode:    ${v.postureMode}`);
  console.log(`    Defense config:  ${v.hasDefenseConfig}`);
  console.log(`    Business config: ${v.hasBusinessConfig}`);
  console.log(`    Turrets:         [${v.turretStatuses.join(", ")}]`);
  console.log(`    PASS:            ${v.pass}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
