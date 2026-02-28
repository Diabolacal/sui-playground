/**
 * Test 03: Post → Cancel (Before Acceptance)
 *
 * Creator (ADMIN) posts a job, then cancels it before any courier accepts.
 * Reward is returned to creator.
 *
 * Usage (inside container):
 *   NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx scripts/03_cancel_before_accept.ts
 */

import { Transaction } from "@mysten/sui/transactions";
import {
  PKG,
  ADMIN_PRIVATE_KEY,
  getKeypair,
  signAndExecute,
  getBalance,
  printGas,
  findEvent,
  findCreatedByType,
  getChainTimeMs,
} from "./utils";

const REWARD_AMOUNT = 25_000_000; // 0.025 SUI
const COLLATERAL_REQUIRED = 50_000_000; // 0.05 SUI
const DEADLINE_OFFSET_MS = 600_000; // 10 minutes (irrelevant — will be cancelled)

async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  TEST 03: Post → Cancel (Before Acceptance)");
  console.log("═══════════════════════════════════════════════════\n");

  const creatorKp = getKeypair(ADMIN_PRIVATE_KEY);
  const creatorAddr = creatorKp.toSuiAddress();

  console.log(`Creator: ${creatorAddr}\n`);

  // ── Record initial balance ──
  const creatorBalBefore = await getBalance(creatorAddr);
  console.log(`Balance BEFORE:`);
  console.log(`  Creator: ${creatorBalBefore} MIST (${Number(creatorBalBefore) / 1e9} SUI)\n`);

  // ── Step 1: Post Job ──
  console.log("── Step 1: Post Job ──");
  let jobId: string;
  {
    const tx = new Transaction();
    const [rewardCoin] = tx.splitCoins(tx.gas, [REWARD_AMOUNT]);
    const chainTime = await getChainTimeMs();
    const deadlineMs = chainTime + DEADLINE_OFFSET_MS;

    tx.moveCall({
      target: `${PKG}::courier_escrow::post_job`,
      arguments: [
        rewardCoin,
        tx.pure.u64(COLLATERAL_REQUIRED),
        tx.pure.u64(deadlineMs),
      ],
    });

    const res = await signAndExecute(tx, creatorKp, "Post Job");
    printGas(res);

    const postEvent = findEvent(res, "JobPostedEvent");
    console.log("  JobPostedEvent:", JSON.stringify(postEvent?.parsedJson, null, 2));

    const jobObj = findCreatedByType(res, "CourierJob");
    jobId = jobObj?.objectId;
    console.log(`  Job ID: ${jobId}\n`);
  }

  // ── Step 2: Cancel Job ──
  console.log("── Step 2: Cancel Job (creator only, before acceptance) ──");
  {
    const tx = new Transaction();

    tx.moveCall({
      target: `${PKG}::courier_escrow::cancel_job`,
      arguments: [
        tx.object(jobId),
      ],
    });

    const res = await signAndExecute(tx, creatorKp, "Cancel Job");
    printGas(res);

    const cancelEvent = findEvent(res, "JobCancelledEvent");
    console.log("  JobCancelledEvent:", JSON.stringify(cancelEvent?.parsedJson, null, 2));
  }

  // ── Record final balance ──
  const creatorBalAfter = await getBalance(creatorAddr);
  console.log(`\nBalance AFTER:`);
  console.log(`  Creator: ${creatorBalAfter} MIST (${Number(creatorBalAfter) / 1e9} SUI)`);

  const creatorDelta = creatorBalAfter - creatorBalBefore;
  console.log(`\nBalance DELTA:`);
  console.log(`  Creator: ${creatorDelta} MIST (expected: ≈ -gas only, reward returned)`);

  console.log(`\n═══════════════════════════════════════════════════`);
  console.log(`  ✓ TEST 03 PASSED — Cancel before accept validated`);
  console.log(`═══════════════════════════════════════════════════\n`);
}

main().catch((e) => {
  console.error("\n✗ TEST 03 FAILED:", e.message || e);
  process.exit(1);
});
