# Shadow Broker Protocol — Validation Plan

**Retention:** Prep-only  
**Created:** 2026-03-11  
**Purpose:** Step-by-step instructions for a fresh agent to validate the Shadow Broker Protocol end-to-end on local devnet. This is the source of truth for the validation session.

---

## Context for the Executing Agent

You are validating the **Shadow Broker Protocol** — a cryptographic intelligence marketplace that uses Sui Move, Walrus (blob storage), and Seal (threshold encryption) to solve the Fair Exchange Problem. The full specs live in:

- [shadow-broker-product-vision.md](../strategy/shadow-broker-protocol/shadow-broker-product-vision.md) — Product rationale and data flow
- [shadow-broker-technical-architecture.md](../strategy/shadow-broker-protocol/shadow-broker-technical-architecture.md) — Move contracts, PTB composition, SDK patterns
- [shadow-broker-demo-beat-sheet.md](../strategy/shadow-broker-protocol/shadow-broker-demo-beat-sheet.md) — Demo script with proof moments

**What "validation" means here:** We are NOT building the hackathon submission. We are writing minimal feasibility code in `sandbox/` to prove each technical layer works independently, then together. This is pre-hackathon sandbox validation — the same pattern used for CivilizationControl (see `sandbox/validation/ssu_extension_test/` for precedent).

**Authority hierarchy:** `vendor/world-contracts` code > SUI docs > `.github/instructions/move.instructions.md` > this plan.

---

## Pre-Requisites

Before starting any validation step:

1. Verify local Sui devnet is running: `sui client active-env` should show `local` (or whichever env you're using). If unsure, read `docs/architecture/sui-playground.md` for local devnet setup.
2. Verify you have SUI gas: `sui client gas` — you need coins for publishing and transactions.
3. **Do NOT use testnet or mainnet.** All validation happens on local devnet.
4. **Known testing quirk:** `sui move test` can fail when `active-env` name matches a `[environments]` key in `Move.toml` but chain hashes disagree across deps. If tests fail with environment errors, switch to an env not present in any `Move.toml` (e.g., `sui client switch --env testnet`) before running `sui move test`. See repo memory on this issue.

---

## Phase 1: Move Contract Compilation & Unit Tests (~1 hour)

**Goal:** Prove `intel_object.move` and `marketplace.move` compile, and basic Move-level logic works.

### Step 1.1: Scaffold the package

Create `sandbox/shadow-broker-validation/` with this structure:

```
sandbox/shadow-broker-validation/
├── Move.toml
├── sources/
│   ├── intel_object.move
│   └── marketplace.move
└── tests/
    └── shadow_broker_tests.move
```

**Move.toml** — minimal, no world-contracts dependency (Shadow Broker is standalone):

```toml
[package]
name = "ShadowBrokerValidation"
edition = "2024.beta"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/testnet" }

[addresses]
shadow_broker = "0x0"
```

### Step 1.2: Write intel_object.move

Implement the module from the technical architecture spec. Key requirements:

```move
module shadow_broker::intel_object;

// Errors
const ENotCreator: u64 = 0;

// Core struct
public struct IntelObject has key, store {
    id: UID,
    blob_id: String,
    encrypted_key: vector<u8>,
    file_type: String,
    duration_seconds: u64,
    file_size_bytes: u64,
    description: String,
    creator: address,
    teaser_blob_id: Option<String>,
}

// Event
public struct IntelMintedEvent has copy, drop {
    intel_id: address,
    blob_id: String,
    creator: address,
    has_teaser: bool,
}
```

Functions to implement:
- `mint(...)` — creates IntelObject, emits IntelMintedEvent, returns the object (NOT transfer — caller decides)
- `update_encrypted_key(&mut self, encrypted_key, ctx)` — creator-only guard via `assert!(self.creator == ctx.sender(), ENotCreator)`
- `seal_approve(id: vector<u8>, self: &IntelObject, ctx: &TxContext)` — entry function for Seal policy verification. Must assert `id` matches `object::id_to_bytes(&object::id(self))`. This is how Seal key servers verify NFT ownership.
- View functions: `blob_id()`, `encrypted_key()`, `file_type()`, `duration_seconds()`, `file_size_bytes()`, `description()`, `creator()`, `teaser_blob_id()`

### Step 1.3: Write marketplace.move

```move
module shadow_broker::marketplace;

// Errors
const EWrongPayment: u64 = 0;
const ENotSeller: u64 = 1;
const ENoIntel: u64 = 2;

// Core struct — shared object (created by list())
public struct Listing has key {
    id: UID,
    intel: Option<IntelObject>,
    price: u64,
    seller: address,
}

// Events
public struct ListingCreatedEvent has copy, drop {
    listing_id: address,
    seller: address,
    price: u64,
}

public struct PurchaseEvent has copy, drop {
    listing_id: address,
    buyer: address,
    seller: address,
    price: u64,
}
```

Functions:
- `list(intel: IntelObject, price: u64, ctx)` — wraps intel in `Option::some`, creates shared Listing via `transfer::share_object`, emits ListingCreatedEvent
- `purchase(listing: &mut Listing, payment: Coin<SUI>, ctx)` — asserts `coin::value(&payment) == listing.price`, asserts `listing.intel.is_some()`, extracts intel from Option, transfers payment to seller, returns IntelObject to caller
- `delist(listing: &mut Listing, ctx)` — seller-only, extracts and returns IntelObject
- View: `price()`, `seller()`, `has_intel()`

### Step 1.4: Write unit tests

In `tests/shadow_broker_tests.move`, write `#[test_only]` tests:

1. **test_mint_and_read** — mint an IntelObject, verify all fields match, verify event emission
2. **test_update_encrypted_key** — mint, update key, verify new key stored
3. **test_update_encrypted_key_wrong_caller** — should abort with ENotCreator
4. **test_list_and_purchase** — mint → list → purchase with correct payment → verify buyer gets IntelObject, seller gets coin
5. **test_purchase_wrong_amount** — should abort with EWrongPayment
6. **test_delist** — mint → list → delist → verify seller gets IntelObject back
7. **test_delist_wrong_caller** — should abort with ENotSeller

### Step 1.5: Build and test

```bash
sui move build --path sandbox/shadow-broker-validation
sui move test --path sandbox/shadow-broker-validation
```

**Success criteria:** All tests pass. Build succeeds. This validates the Move layer independently of Walrus/Seal.

### Step 1.6: Publish to local devnet

```bash
sui client publish --path sandbox/shadow-broker-validation
```

**Record the output.** Save the published package ID and any created object IDs to `notes/sbp-publish-output.json`. You'll need the package ID for Seal integration.

### Step 1.7: On-chain smoke test

Using `sui client call` or a quick TS script:
1. Call `intel_object::mint(...)` with test data — blob_id = "test-blob-123", empty encrypted_key, etc.
2. Verify the IntelObject is in your wallet: `sui client objects`
3. Call `marketplace::list(...)` with the IntelObject and price = 1000
4. Verify a shared Listing object exists
5. Call `marketplace::purchase(...)` from the same wallet (for smoke test, buyer = seller is fine) with correct coin
6. Verify IntelObject returned to wallet, Listing intel is now `none`

**Log all tx digests to `notes/sbp-validation-evidence.md`.**

---

## Phase 2: Walrus SDK Validation (~1 hour)

**Goal:** Prove we can upload and download blobs via the Walrus SDK against Walrus testnet.

### Step 2.1: Set up TS script environment

Create `sandbox/shadow-broker-validation/ts-scripts/` with a minimal Node/Bun setup:

```
sandbox/shadow-broker-validation/ts-scripts/
├── package.json
├── tsconfig.json
└── walrus-smoke.ts
```

**package.json dependencies** (use exact versions known to work):

```json
{
  "private": true,
  "type": "module",
  "dependencies": {
    "@mysten/walrus": "latest",
    "@mysten/sui": "^2.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "tsx": "^4.0.0"
  }
}
```

### Step 2.2: Write walrus-smoke.ts

Test the three operations Shadow Broker needs:

1. **Upload a test blob** — create a small Uint8Array (e.g., 1KB of random bytes), upload via `walrus.writeBlob()`, capture the returned `blobId`
2. **Download the same blob** — `walrus.readBlob(blobId)`, verify content matches what was uploaded (byte-for-byte comparison)
3. **Upload a second blob** (simulating teaser) — smaller payload, separate blobId

**Important WalrusClient instantiation:** Check the `@mysten/walrus` docs or package exports for the correct constructor. The SDK may require a network parameter or aggregator URL. If `new WalrusClient()` doesn't work out of the box, check:
- `WalrusClient({ network: 'testnet' })` 
- The docs at https://sdk.mystenlabs.com/walrus for constructor options
- The package README in node_modules/@mysten/walrus

**Note:** Walrus runs on its own network (testnet/mainnet), separate from Sui devnet. The upload/download will hit Walrus testnet public aggregators even while your Sui client points to local devnet. This is expected and correct.

### Step 2.3: Run and verify

```bash
cd sandbox/shadow-broker-validation/ts-scripts
npm install
npx tsx walrus-smoke.ts
```

**Success criteria:**
- Upload returns a `blobId` string
- Download returns the exact bytes that were uploaded
- Both operations complete in <10 seconds

**If Walrus SDK constructor fails:** This is a known risk area. Check npm package exports, try alternate constructor patterns, check if there's a REST API fallback. Document whatever works in `notes/sbp-validation-evidence.md`.

---

## Phase 3: Seal SDK Validation (~2 hours)

**Goal:** Prove we can encrypt a payload with Seal (anchored to a Sui object) and decrypt it with the same wallet.

This is the **highest risk** phase. The Seal SDK has not been tested in this workspace before.

### Step 3.1: Create seal-smoke.ts

Add to `ts-scripts/`:

```
sandbox/shadow-broker-validation/ts-scripts/
├── seal-smoke.ts
```

**Dependencies to add:**

```json
{
  "@mysten/seal": "latest"
}
```

### Step 3.2: Understand the Seal encrypt/decrypt flow

From the technical architecture:

**Encrypt (seller side):**
```typescript
import { SealClient } from '@mysten/seal';
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';

const sealClient = new SealClient({
  suiClient: new SuiJsonRpcClient({ url: '<sui-rpc-url>' }),
  serverObjectIds: [
    // Testnet key server object IDs from seal-docs.wal.app
    '0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75',
    '0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8',
  ],
  verifyKeyServers: false, // Required for testnet open-mode
});

const { encryptedObject } = await sealClient.encrypt({
  threshold: 2,
  packageId: '<your-published-package-id>',
  id: '<intel-object-id>',  // The IntelObject's Sui object address
  data: aesKeyBytes,         // Uint8Array of the AES key to protect
});
```

**Decrypt (buyer side — same wallet for validation):**
```typescript
import { SessionKey } from '@mysten/seal';
import { Transaction } from '@mysten/sui/transactions';

// 1. Create session key
const sessionKey = new SessionKey({
  address: walletAddress,
  packageId: '<your-published-package-id>',
  ttlMin: 10,
});

// 2. Sign session key (requires wallet signing capability)
// For CLI validation, you may need to use Ed25519Keypair from @mysten/sui/keypairs/ed25519

// 3. Build seal_approve PTB
const tx = new Transaction();
tx.moveCall({
  target: `<packageId>::intel_object::seal_approve`,
  arguments: [
    tx.pure.vector('u8', /* intelObjectId bytes */),
    tx.object(intelObjectId),
  ],
});

// 4. Decrypt
const decrypted = await sealClient.decrypt({
  data: encryptedObject,
  sessionKey,
  txBytes: await tx.build({ client: suiClient }),
});
```

### Step 3.3: Critical implementation notes

1. **Seal key servers are on Sui TESTNET**, not local devnet. This is a fundamental constraint. The `seal_approve` dry-run happens against the network where the key servers exist. You have two options:
   - **Option A (preferred):** Publish `shadow_broker` package to Sui testnet (costs testnet SUI, faucet available). Then Seal encrypt/decrypt can work against the published testnet objects.
   - **Option B (partial):** Test encrypt-only on local devnet (Seal encrypt doesn't need key servers — it's pure client-side crypto). Decrypt requires key servers to dry-run `seal_approve`, so decrypt WILL need testnet.

2. **For validation, Option A is recommended.** Publish to testnet, mint an IntelObject there, then test the full encrypt → decrypt cycle. Record all testnet object IDs.

3. **Keypair for signing:** For CLI-based validation (no browser wallet), use:
   ```typescript
   import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
   import { decodeSuiPrivateKey } from '@mysten/sui/cryptography';
   
   // Load from sui client config (DO NOT hardcode secrets)
   // Use environment variable or read from sui keystore
   const keypair = Ed25519Keypair.fromSecretKey(/* ... */);
   ```
   **WARNING:** Never log, commit, or echo the private key. Load it from env or the Sui keystore file.

4. **If SealClient constructor differs from spec:** The SDK is v1.1.0 and may have slightly different constructor options than documented. Check:
   - Package exports: `import { SealClient } from '@mysten/seal'`
   - Constructor parameters from TypeScript types
   - Docs at seal-docs.wal.app/GettingStarted

### Step 3.4: Encrypt-only smoke test (works on any network)

Even if testnet deployment is problematic, you can test encryption in isolation:

```typescript
// Generate random AES key
const aesKey = crypto.getRandomValues(new Uint8Array(32));

// Encrypt (pure client-side — no network call)
const encrypted = await sealClient.encrypt({
  threshold: 2,
  packageId: '0xSOME_PACKAGE_ID', // Can be any valid-looking address for encrypt
  id: '0xSOME_OBJECT_ID',
  data: aesKey,
});

console.log('Encrypted length:', encrypted.encryptedObject.length);
```

If encrypt returns a Uint8Array, the Seal client-side crypto works. Decrypt is the part that needs key servers.

### Step 3.5: Success criteria

- **Minimum viable:** `sealClient.encrypt()` returns an `encryptedObject` (Uint8Array) without throwing
- **Full validation:** encrypt → publish to testnet → mint IntelObject → `sealClient.decrypt()` returns original AES key bytes
- **Document everything** in `notes/sbp-validation-evidence.md`

---

## Phase 4: Envelope Encryption End-to-End (~1.5 hours)

**Goal:** Wire all three layers together. This is the full pipeline that the hackathon demo depends on.

### Step 4.1: Create e2e-smoke.ts

This script simulates the **complete seller → buyer flow** (using a single keypair for simplicity):

```
1. Generate random AES-256 key
2. Create test "audio" payload (random bytes, ~10KB)
3. AES-GCM encrypt the audio payload
4. Upload encrypted audio to Walrus → get blobId
5. Upload a "teaser" (first 100 bytes, unencrypted) to Walrus → get teaserBlobId
6. Publish shadow_broker package (or use already-published ID)
7. Mint IntelObject with blobId, empty encrypted_key, teaserBlobId
8. Seal-encrypt the AES key anchored to IntelObject's ID
9. Update IntelObject's encrypted_key with Seal output
10. List IntelObject on marketplace
11. Purchase listing (same wallet for validation)
12. Download teaser from Walrus → verify matches original first 100 bytes
13. Seal-decrypt the encrypted_key → recover AES key
14. Download encrypted audio from Walrus
15. AES-GCM decrypt → verify matches original audio payload
```

### Step 4.2: AES-GCM utilities

Use Node.js `crypto` module (or Web Crypto API polyfill):

```typescript
import { webcrypto } from 'crypto';

async function aesEncrypt(key: Uint8Array, plaintext: Uint8Array): Promise<{ ciphertext: Uint8Array, iv: Uint8Array }> {
  const iv = webcrypto.getRandomValues(new Uint8Array(12));
  const cryptoKey = await webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['encrypt']);
  const encrypted = await webcrypto.subtle.encrypt({ name: 'AES-GCM', iv }, cryptoKey, plaintext);
  return { ciphertext: new Uint8Array(encrypted), iv };
}

async function aesDecrypt(key: Uint8Array, ciphertext: Uint8Array, iv: Uint8Array): Promise<Uint8Array> {
  const cryptoKey = await webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['decrypt']);
  const decrypted = await webcrypto.subtle.decrypt({ name: 'AES-GCM', iv }, cryptoKey, ciphertext);
  return new Uint8Array(decrypted);
}
```

**Important:** The IV must be stored alongside the ciphertext (prepend it, or store as a separate field). For validation, prepending the 12-byte IV to the ciphertext blob is simplest.

### Step 4.3: Success criteria

- End-to-end: original payload bytes === decrypted payload bytes
- All intermediate artifacts logged (blobIds, object IDs, tx digests)
- Timing captured for each phase (upload, encrypt, decrypt, download)

### Step 4.4: If full E2E fails

Document exactly which step fails and the error. Likely failure points:
- **Seal decrypt** — if key servers can't reach your `seal_approve` function (network mismatch, wrong packageId)
- **Walrus upload** — if SDK constructor needs specific configuration not yet discovered
- **AES encrypt/decrypt** — lowest risk, standard Web Crypto

Partial success is still valuable. Each layer validated independently de-risks the hackathon build. Log partial results.

---

## Phase 5: Evidence Collection & Documentation (~30 min)

### Step 5.1: Log all evidence

Create/update `notes/sbp-validation-evidence.md` with:

```markdown
# Shadow Broker Protocol — Validation Evidence

**Date:** 2026-03-11
**Network:** Local devnet (Move) / Walrus testnet / Seal testnet
**Sui CLI version:** [output of `sui --version`]

## Move Layer
- Package published: [tx digest]
- Published package ID: [address]
- IntelObject minted: [tx digest] → object ID: [address]
- Listing created: [tx digest] → object ID: [address]
- Purchase completed: [tx digest]
- All unit tests: [PASS/FAIL count]

## Walrus Layer
- Upload 1 (encrypted blob): blobId = [value], size = [bytes], time = [ms]
- Upload 2 (teaser): blobId = [value], size = [bytes], time = [ms]
- Download verified: [PASS/FAIL]

## Seal Layer
- Encrypt: [PASS/FAIL], encrypted length = [bytes]
- Decrypt: [PASS/FAIL], recovered key matches = [yes/no]
- Key servers used: [object IDs]
- Network: [testnet/other]

## End-to-End Pipeline
- Full flow: [PASS/FAIL]
- Total time: [seconds]
- Failure point (if any): [step number and error]

## Blockers Discovered
- [List any]

## SDK Notes (for hackathon build)
- WalrusClient constructor: [what actually works]
- SealClient constructor: [what actually works]
- Any API differences from spec: [list]
```

### Step 5.2: Update decision log

Append a decision log entry to `docs/decision-log.md`:

```markdown
## 2026-03-11 — Shadow Broker Protocol validation
- Goal: Validate Move contracts + Walrus + Seal SDK integration end-to-end
- Files: sandbox/shadow-broker-validation/
- Diff: ~400-600 LoC (Move + TS validation scripts)
- Risk: Medium (new SDK surface, no prior on-chain validation)
- Gates: build ✅|❌ test ✅|❌ walrus ✅|❌ seal ✅|❌ e2e ✅|❌
- Follow-ups: Port validated patterns to hackathon submission repo
```

---

## Kill Criteria & Fallbacks

| Phase | Kill Trigger | Fallback |
|-------|-------------|----------|
| Phase 1 (Move) | Package won't compile | Fix errors — Move surface is simple (~200 LoC). This should not fail. |
| Phase 2 (Walrus) | SDK constructor incompatible or testnet unreachable | Try direct HTTP aggregator API (docs.wal.app lists REST endpoints). Document what works. |
| Phase 3 (Seal) | Encrypt fails | Check SDK version, constructor params, try alternate imports. If fundamentally broken, document and flag for hackathon Day 1. |
| Phase 3 (Seal) | Decrypt fails (key server unreachable) | Validate encrypt-only. Decrypt requires testnet deployment — can defer to hackathon build if testnet publish is blocked. |
| Phase 4 (E2E) | Pipeline fails at Seal step | Ship partial validation: Move ✅ + Walrus ✅ + Seal encrypt-only ✅. Full decrypt deferred. Still de-risks 70% of the build. |

---

## Files This Validation Will Create

```
sandbox/shadow-broker-validation/
├── Move.toml
├── sources/
│   ├── intel_object.move
│   └── marketplace.move
├── tests/
│   └── shadow_broker_tests.move
└── ts-scripts/
    ├── package.json
    ├── tsconfig.json
    ├── walrus-smoke.ts
    ├── seal-smoke.ts
    └── e2e-smoke.ts

notes/
├── sbp-publish-output.json
└── sbp-validation-evidence.md
```

---

## Summary for Executing Agent

**Priority order:** Phase 1 (Move) → Phase 2 (Walrus) → Phase 3 (Seal) → Phase 4 (E2E) → Phase 5 (Evidence)

**If time runs short:** Phase 1 + Phase 2 are the minimum. Phase 3 encrypt-only is the next priority. Full E2E is stretch.

**What matters most:** Discovering SDK constructor patterns and documenting them. The Move contracts are low-risk. The SDK integration is where unknown-unknowns live. Every SDK call you successfully execute saves 30+ minutes during the hackathon build.

**Do not skip evidence logging.** Every tx digest, blobId, and object ID you capture is ammunition for the hackathon. Write it down as you go, not at the end.
