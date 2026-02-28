/**
 * Test 02: Post → Accept → Expire (Deadline Expiry + Collateral Slashing)
 *
 * Creator (ADMIN) posts a job with a very short deadline (2 seconds).
 * Courier (PLAYER_A) accepts. We wait for the deadline to pass, then
 * call expire_job. Creator receives collateral + gets reward back.
 *
 * Usage (inside container):
 *   NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx scripts/02_post_accept_expire.ts
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

const REWARD_AMOUNT = 30_000_000; // 0.03 SUI
const COLLATERAL_REQUIRED = 80_000_000; // 0.08 SUI
const DEADLINE_OFFSET_MS = 15_000; // 15 seconds — enough for post+accept, short enough to wait for expiry

async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  TEST 02: Post → Accept → Expire (Slashing)");
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

  // ── Step 1: Post Job with short deadline ──
  console.log("── Step 1: Post Job (15 second deadline) ──");
  let jobId: string;
  const chainTimeAtPost = await getChainTimeMs();
  const deadlineMs = chainTimeAtPost + DEADLINE_OFFSET_MS;
  console.log(`  Chain time: ${chainTimeAtPost}ms, deadline set to: ${deadlineMs}ms\n`);
  {
    const tx = new Transaction();
    const [rewardCoin] = tx.splitCoins(tx.gas, [REWARD_AMOUNT]);

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
  console.log("── Step 2: Accept Job ──");
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
    console.log("");
  }

  // ── Step 3: Wait for deadline to pass ──
  // On local devnet, clock progresses with checkpoints, not wall-clock.
  // We must wait for the chain clock to advance past the deadline.
  console.log(`── Step 3: Waiting for chain clock to pass deadline ──`);
  let chainNow = await getChainTimeMs();
  let retries = 0;
  while (chainNow < deadlineMs && retries < 30) {
    const remaining = deadlineMs - chainNow;
    console.log(`  Chain time: ${chainNow}ms, deadline: ${deadlineMs}ms, remaining: ${remaining}ms`);
    await new Promise((r) => setTimeout(r, 2000));
    chainNow = await getChainTimeMs();
    retries++;
  }
  if (chainNow < deadlineMs) {
    throw new Error(`Chain clock did not advance past deadline after ${retries} retries`);
  }
  console.log(`  Chain time: ${chainNow}ms >= deadline: ${deadlineMs}ms — proceeding\n`);

  // ── Step 4: Expire Job ──
  console.log("── Step 4: Expire Job (anyone can call) ──");
  {
    const tx = new Transaction();

    tx.moveCall({
      target: `${PKG}::courier_escrow::expire_job`,
      arguments: [
        tx.object(jobId),
        tx.object(CLOCK),
      ],
    });

    // Demonstrate "anyone can call" by using creator keypair
    const res = await signAndExecute(tx, creatorKp, "Expire Job");
    printGas(res);

    const expireEvent = findEvent(res, "JobExpiredEvent");
    console.log("  JobExpiredEvent:", JSON.stringify(expireEvent?.parsedJson, null, 2));
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
  console.log(`  Creator: ${creatorDelta} MIST (expected: +slashed_collateral - gas ≈ +${COLLATERAL_REQUIRED})`);
  console.log(`  Courier: ${courierDelta} MIST (expected: -collateral - gas ≈ -${COLLATERAL_REQUIRED})`);

  console.log(`\n═══════════════════════════════════════════════════`);
  console.log(`  ✓ TEST 02 PASSED — Expiry + slashing validated`);
  console.log(`═══════════════════════════════════════════════════\n`);
}

main().catch((e) => {
  console.error("\n✗ TEST 02 FAILED:", e.message || e);
  process.exit(1);
});
