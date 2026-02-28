/**
 * Shared utilities for courier escrow test scripts.
 *
 * Usage (inside container):
 *   NODE_PATH=/workspace/world-contracts/node_modules pnpm exec tsx scripts/<script>.ts
 */

import { SuiJsonRpcClient } from "@mysten/sui/jsonRpc";
import { Transaction } from "@mysten/sui/transactions";
import { decodeSuiPrivateKey } from "@mysten/sui/cryptography";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

// ============================================================================
// CONFIGURATION — from the test-publish output
// ============================================================================

export const RPC_URL = "http://127.0.0.1:9000";
export const PKG = "0xec1e614ee9c83a2aeb72fe1250590f345b56e2503d68d39e13a78f031cd17d26";
export const CLOCK = "0x6";

// Keypairs (local devnet only — NOT secrets)
export const ADMIN_PRIVATE_KEY = "suiprivkey1qpfudud34mvygawwg80gl3t9tvu6r7nd8hypwf57zyh7a9s3uy7nsra0u8t";
export const PLAYER_A_PRIVATE_KEY = "suiprivkey1qpung9uajn3feau8sxmna5mssum0hmd6w9w54sgjgvnhgudstx5m62u40vz";

export const client = new SuiJsonRpcClient({ url: RPC_URL });

export function getKeypair(privKey: string): Ed25519Keypair {
  const { secretKey } = decodeSuiPrivateKey(privKey) as any;
  return Ed25519Keypair.fromSecretKey(secretKey);
}

export async function signAndExecute(
  tx: Transaction,
  keypair: Ed25519Keypair,
  label: string,
) {
  tx.setGasBudget(500_000_000);
  const result = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });
  const effects = (result as any).effects;
  if (effects?.status?.status !== "success") {
    console.error(`[FAIL] ${label}:`, JSON.stringify(effects?.status, null, 2));
    throw new Error(`${label} failed`);
  }
  console.log(`[OK] ${label} — digest: ${(result as any).digest}`);
  // Wait for state propagation on local devnet
  await new Promise((r) => setTimeout(r, 1500));
  return result as any;
}

export async function getBalance(address: string): Promise<bigint> {
  const coins = await client.getCoins({ owner: address, coinType: "0x2::sui::SUI" });
  let total = 0n;
  for (const c of coins.data) {
    total += BigInt(c.balance);
  }
  return total;
}

export function printGas(result: any) {
  const gas = result.effects?.gasUsed;
  if (!gas) return;
  const net =
    Number(gas.computationCost) +
    Number(gas.storageCost) -
    Number(gas.storageRebate);
  console.log(`  Gas — computation: ${gas.computationCost}, storage: ${gas.storageCost}, rebate: ${gas.storageRebate}, net: ${net}`);
}

export function findEvent(result: any, eventSubstring: string) {
  return (result.events || []).find((e: any) =>
    e.type?.includes(eventSubstring),
  );
}

export function findCreatedByType(result: any, typeSubstring: string) {
  return result.objectChanges?.find(
    (c: any) =>
      c.type === "created" && c.objectType?.includes(typeSubstring),
  );
}

/**
 * Get the on-chain Clock timestamp in milliseconds.
 * On local devnet, this can differ significantly from Date.now().
 */
export async function getChainTimeMs(): Promise<number> {
  const clockObj = await client.getObject({
    id: "0x6",
    options: { showContent: true },
  });
  const fields = (clockObj as any).data?.content?.fields;
  return Number(fields?.timestamp_ms || "0");
}
