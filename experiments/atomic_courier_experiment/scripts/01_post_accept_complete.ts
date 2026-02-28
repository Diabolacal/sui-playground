/**
 * Test 01: Post → Accept → Complete (Happy Path)
 *
 * Creator (ADMIN) posts a job with reward, courier (PLAYER_A) accepts with
 * collateral, creator confirms delivery, courier receives reward + collateral.
 *
 * Usage (inside container):
 *   NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx scripts/01_post_accept_complete.ts
 */

import { Transaction } from "@mysten/sui/transactions";
import {
  PKG,
  CLOCK,
  ADMIN_PRIVATE_KEY,
  PLAYER_A_PRIVATE_KEY,
  getKeypair,
  signAndExecute,
  getBalance,
  printGas,
  findEvent,
  findCreatedByType,
  getChainTimeMs,
} from "./utils";

const REWARD_AMOUNT = 50_000_000; // 0.05 SUI
const COLLATERAL_REQUIRED = 100_000_000; // 0.1 SUI
const DEADLINE_OFFSET_MS = 600_000; // 10 minutes from now

async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  TEST 01: Post → Accept → Complete (Happy Path)");
  console.log("═══════════════════════════════════════════════════\n");

  const creatorKp = getKeypair(ADMIN_PRIVATE_KEY);
  const courierKp = getKeypair(PLAYER_A_PRIVATE_KEY);
  const creatorAddr = creatorKp.toSuiAddress();
  const courierAddr = courierKp.toSuiAddress();

  console.log(`Creator: ${creatorAddr}`);
  console.log(`Courier: ${courierAddr}\n`);

  // ── Record initial balances ──
  const creatorBalBefore = await getBalance(creatorAddr);
  const courierBalBefore = await getBalance(courierAddr);
  console.log(`Balances BEFORE:`);
  console.log(`  Creator: ${creatorBalBefore} MIST (${Number(creatorBalBefore) / 1e9} SUI)`);
  console.log(`  Courier: ${courierBalBefore} MIST (${Number(courierBalBefore) / 1e9} SUI)\n`);

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

  // ── Step 2: Accept Job ──
  console.log("── Step 2: Accept Job (courier deposits collateral) ──");
  {
    const tx = new Transaction();
    const [collateralCoin] = tx.splitCoins(tx.gas, [COLLATERAL_REQUIRED]);

    tx.moveCall({
      target: `${PKG}::courier_escrow::accept_job`,
      arguments: [
        tx.object(jobId),
        collateralCoin,
        tx.object(CLOCK),
      ],
    });

    const res = await signAndExecute(tx, courierKp, "Accept Job");
    printGas(res);

    const acceptEvent = findEvent(res, "JobAcceptedEvent");
    console.log("  JobAcceptedEvent:", JSON.stringify(acceptEvent?.parsedJson, null, 2));

    const receipt = findCreatedByType(res, "JobReceipt");
    console.log(`  JobReceipt ID: ${receipt?.objectId}\n`);
  }

  // ── Step 3: Complete Job ──
  console.log("── Step 3: Complete Job (creator confirms delivery) ──");
  {
    const tx = new Transaction();

    tx.moveCall({
      target: `${PKG}::courier_escrow::complete_job`,
      arguments: [
        tx.object(jobId),
      ],
    });

    const res = await signAndExecute(tx, creatorKp, "Complete Job");
    printGas(res);

    const completeEvent = findEvent(res, "JobCompletedEvent");
    console.log("  JobCompletedEvent:", JSON.stringify(completeEvent?.parsedJson, null, 2));
  }

  // ── Record final balances ──
  const creatorBalAfter = await getBalance(creatorAddr);
  const courierBalAfter = await getBalance(courierAddr);
  console.log(`\nBalances AFTER:`);
  console.log(`  Creator: ${creatorBalAfter} MIST (${Number(creatorBalAfter) / 1e9} SUI)`);
  console.log(`  Courier: ${courierBalAfter} MIST (${Number(courierBalAfter) / 1e9} SUI)`);

  console.log(`\nBalance DELTAS:`);
  const creatorDelta = creatorBalAfter - creatorBalBefore;
  const courierDelta = courierBalAfter - courierBalBefore;
  console.log(`  Creator: ${creatorDelta} MIST (expected: -reward - gas ≈ -${REWARD_AMOUNT})`);
  console.log(`  Courier: ${courierDelta} MIST (expected: +reward - gas ≈ +${REWARD_AMOUNT})`);

  console.log(`\n═══════════════════════════════════════════════════`);
  console.log(`  ✓ TEST 01 PASSED — Happy path validated`);
  console.log(`═══════════════════════════════════════════════════\n`);
}

main().catch((e) => {
  console.error("\n✗ TEST 01 FAILED:", e.message || e);
  process.exit(1);
});
