/**
 * Shared utilities for CivilizationControl posture-switch validation.
 *
 * Loads .env, creates SuiClient + keypair, and provides typed constants.
 */
import { SuiClient } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction } from "@mysten/sui/transactions";
import { execSync } from "child_process";
import { config } from "dotenv";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, "../.env") });

// ---------------------------------------------------------------------------
// Environment helpers
// ---------------------------------------------------------------------------
function env(key: string): string {
  const v = process.env[key];
  if (!v) throw new Error(`Missing env var: ${key}`);
  return v;
}

// ---------------------------------------------------------------------------
// IDs from .env
// ---------------------------------------------------------------------------
export const IDS = {
  worldPkg: env("WORLD_PACKAGE_ID"),
  governorCap: env("GOVERNOR_CAP_ID"),
  serverAddressRegistry: env("SERVER_ADDRESS_REGISTRY_ID"),
  adminAcl: env("ADMIN_ACL_ID"),
  objectRegistry: env("OBJECT_REGISTRY_ID"),
  energyConfig: env("ENERGY_CONFIG_ID"),
  fuelConfig: env("FUEL_CONFIG_ID"),
  gateConfig: env("GATE_CONFIG_ID"),
  ccPkg: env("CC_PACKAGE_ID"),
  ccAdminCap: env("CC_ADMIN_CAP_ID"),
  ccExtensionConfig: env("CC_EXTENSION_CONFIG_ID"),
  adminAddress: env("ADMIN_ADDRESS"),
} as const;

// ---------------------------------------------------------------------------
// Client + Keypair
// ---------------------------------------------------------------------------
export const client = new SuiClient({ url: "http://127.0.0.1:9000" });

/**
 * Retrieve the active keypair from the local Sui keystore.
 * Uses `sui keytool export` to get the private key, then constructs keypair.
 */
export function getAdminKeypair(): Ed25519Keypair {
  // Get the private key for the active address via sui keytool
  const raw = execSync(
    `sui keytool export --key-identity ${IDS.adminAddress} --json 2>&1`,
    { encoding: "utf-8" }
  );
  // Parse the JSON output to find the key
  const jsonStart = raw.indexOf("{");
  if (jsonStart === -1) {
    throw new Error(`Could not parse keytool output: ${raw}`);
  }
  const parsed = JSON.parse(raw.substring(jsonStart));
  const exportedKey: string = parsed.exportedPrivateKey || parsed.key?.privateBase64Key;
  if (!exportedKey) {
    throw new Error(`Could not extract private key from keytool output`);
  }
  return Ed25519Keypair.fromSecretKey(exportedKey);
}

// ---------------------------------------------------------------------------
// Transaction execution
// ---------------------------------------------------------------------------
export async function executeTransaction(
  tx: Transaction,
  keypair: Ed25519Keypair,
  label: string
): Promise<{
  digest: string;
  success: boolean;
  effects: any;
  events: any[];
  objectChanges: any[];
  error?: string;
}> {
  const start = Date.now();
  try {
    const result = await client.signAndExecuteTransaction({
      signer: keypair,
      transaction: tx,
      options: {
        showEffects: true,
        showEvents: true,
        showObjectChanges: true,
      },
    });
    const elapsed = Date.now() - start;
    const success = result.effects?.status?.status === "success";
    console.log(
      `  [${label}] ${success ? "✅" : "❌"} digest=${result.digest} (${elapsed}ms)`
    );
    if (!success) {
      console.log(`    Error: ${JSON.stringify(result.effects?.status)}`);
    }
    // Wait for the transaction to be fully indexed before returning
    if (result.digest) {
      await client.waitForTransaction({ digest: result.digest });
    }
    return {
      digest: result.digest,
      success,
      effects: result.effects,
      events: result.events ?? [],
      objectChanges: (result as any).objectChanges ?? [],
      error: success ? undefined : JSON.stringify(result.effects?.status),
    };
  } catch (e: any) {
    const elapsed = Date.now() - start;
    console.log(`  [${label}] ❌ EXCEPTION (${elapsed}ms): ${e.message}`);
    return {
      digest: "",
      success: false,
      effects: null,
      events: [],
      objectChanges: [],
      error: e.message,
    };
  }
}

// ---------------------------------------------------------------------------
// Object state queries
// ---------------------------------------------------------------------------

/** Read fields of a shared object. */
export async function getObjectFields(objectId: string): Promise<any> {
  const obj = await client.getObject({
    id: objectId,
    options: { showContent: true },
  });
  if (obj.data?.content?.dataType === "moveObject") {
    return obj.data.content.fields;
  }
  return null;
}

/** Query events by type. */
export async function queryEvents(
  eventType: string,
  limit: number = 10
): Promise<any[]> {
  const result = await client.queryEvents({
    query: { MoveEventType: eventType },
    order: "descending",
    limit,
  });
  return result.data;
}

/** Read dynamic field value. */
export async function getDynamicField(
  parentId: string,
  dfType: string,
  dfName: any
): Promise<any> {
  const result = await client.getDynamicFieldObject({
    parentId,
    name: { type: dfType, value: dfName },
  });
  if (result.data?.content?.dataType === "moveObject") {
    return result.data.content.fields;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Posture type alias for readability
// ---------------------------------------------------------------------------
export type PostureMode = "BUSINESS" | "DEFENSE";
export const BUSINESS = 0;
export const DEFENSE = 1;
