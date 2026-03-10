# The Shadow Broker Protocol — Technical Architecture

**Retention:** Prep-only

> Architecture reference for an LLM coding agent building the Shadow Broker Protocol during an 8–12 hour hackathon sprint. Optimized for density: explicit package names, function signatures, struct definitions, and verified SDK coordinates.

---

## 1. System Overview

The Shadow Broker Protocol is a trustless intelligence marketplace for EVE Frontier on Sui. Spies upload encrypted audio intelligence; buyers purchase the NFT and decrypt it client-side.

**Components:**
1. **Move contracts** — `intel_object` (NFT) + `marketplace` (listings/purchases)
2. **React frontend** — Upload, Browse, Purchase, Decrypt flows
3. **Walrus integration** — Off-chain encrypted blob storage (audio files) + unencrypted teaser clips
4. **Seal integration** — Client-side threshold encryption of AES keys

**Data flow (text diagram):**

```
SPY FLOW:
  Spy records audio
    → AES-encrypt audio locally (browser)
    → Upload encrypted blob to Walrus → blobId
    → Extract 2-second teaser clip from original audio (unencrypted)
    → Upload teaser clip to Walrus (unencrypted) → teaserBlobId
    → TX1: intel_object::mint(blobId, emptyKey, metadata, teaserBlobId) → IntelObject NFT
    → Client: Seal encrypt AES key using IntelObject ID
    → TX2: intel_object::update_encrypted_key(encryptedKey) + marketplace::list(price) in one PTB

BUYER FLOW:
  Buyer browses marketplace
    → Play 2-second teaser audio from Walrus (public, unencrypted) — proof of life
    → PTB: marketplace::purchase(Listing, Coin<SUI>) → IntelObject transferred to buyer
    → Create SessionKey via @mysten/seal
    → Build seal_approve PTB (proves ownership of IntelObject)
    → SealClient.decrypt(encryptedKey) → AES key
    → Fetch encrypted blob from Walrus via blobId
    → AES-decrypt audio → playback via Web Audio API
```

---

## 2. Move Smart Contracts

**Package name:** `ShadowBroker`
**Named address:** `shadow_broker = "0x0"`
**Estimated total:** ~180–230 LoC across 2 modules.

### Module 1: `intel_object.move` (~100 LoC)

```move
module shadow_broker::intel_object;

use std::string::String;
use std::option::Option;
use sui::event;

// === Errors ===

#[error]
const ENotOwner: vector<u8> = b"Caller does not own this IntelObject";

#[error]
const EKeyAlreadySet: vector<u8> = b"Encrypted key can only be set once";

// === Structs ===

/// The NFT representing a piece of encrypted intelligence.
public struct IntelObject has key, store {
    id: UID,
    blob_id: String,              // Walrus blob identifier (encrypted audio)
    encrypted_key: vector<u8>,    // Seal-encrypted AES key (envelope encryption)
    file_type: String,            // MIME type: "audio/mp3", "audio/wav", "audio/ogg"
    duration_seconds: u64,
    file_size_bytes: u64,
    description: String,
    creator: address,
    teaser_blob_id: Option<String>, // Optional unencrypted 2-second audio preview on Walrus
}

// === Events ===

public struct IntelMintedEvent has copy, drop {
    intel_id: address,
    blob_id: String,
    creator: address,
    has_teaser: bool,
}

// === Public Functions ===

/// Mint a new IntelObject. Returns the object (composable — caller transfers or wraps).
/// The `encrypted_key` is typically empty at mint time; set via `update_encrypted_key`
/// after Seal encryption completes client-side.
public fun mint(
    blob_id: String,
    encrypted_key: vector<u8>,
    file_type: String,
    duration_seconds: u64,
    file_size_bytes: u64,
    description: String,
    teaser_blob_id: Option<String>,
    ctx: &mut TxContext,
): IntelObject {
    let intel = IntelObject {
        id: object::new(ctx),
        blob_id,
        encrypted_key,
        file_type,
        duration_seconds,
        file_size_bytes,
        description,
        creator: ctx.sender(),
        teaser_blob_id,
    };
    event::emit(IntelMintedEvent {
        intel_id: intel.id.to_address(),
        blob_id: intel.blob_id,
        creator: intel.creator,
        has_teaser: intel.teaser_blob_id.is_some(),
    });
    intel
}

/// Update the encrypted key after Seal encryption. Creator-only, one-time.
public fun update_encrypted_key(
    self: &mut IntelObject,
    encrypted_key: vector<u8>,
    ctx: &TxContext,
) {
    assert!(ctx.sender() == self.creator, ENotOwner);
    assert!(self.encrypted_key.is_empty(), EKeyAlreadySet);
    self.encrypted_key = encrypted_key;
}

// === Seal Access Policy ===

/// Seal calls this to verify the caller is authorized to decrypt.
/// The `id` parameter encodes the IntelObject's Sui object address.
/// Seal key servers call this function in a dry-run PTB to verify access.
///
/// Reference: https://seal-docs.wal.app/ExamplePatterns (Private data pattern)
/// Reference: https://github.com/MystenLabs/seal/blob/main/move/patterns/sources/private_data.move
entry fun seal_approve(id: vector<u8>, self: &IntelObject, ctx: &TxContext) {
    let parsed_id = object::id_from_bytes(id);
    assert!(parsed_id == object::id(self), ENotOwner);
    // Ownership is implicitly proven: the sender must own `self` to pass it
    // as a reference in the PTB. No additional check needed beyond ID match.
}

// === View Functions ===

public fun blob_id(self: &IntelObject): &String { &self.blob_id }
public fun encrypted_key(self: &IntelObject): &vector<u8> { &self.encrypted_key }
public fun file_type(self: &IntelObject): &String { &self.file_type }
public fun duration_seconds(self: &IntelObject): u64 { self.duration_seconds }
public fun file_size_bytes(self: &IntelObject): u64 { self.file_size_bytes }
public fun description(self: &IntelObject): &String { &self.description }
public fun creator(self: &IntelObject): address { self.creator }
public fun teaser_blob_id(self: &IntelObject): &Option<String> { &self.teaser_blob_id }
```

### Module 2: `marketplace.move` (~100 LoC)

```move
module shadow_broker::marketplace;

use sui::coin::Coin;
use sui::sui::SUI;
use sui::event;
use shadow_broker::intel_object::IntelObject;

// === Errors ===

#[error]
const EWrongPayment: vector<u8> = b"Payment does not match listing price";

#[error]
const ENotSeller: vector<u8> = b"Only the seller can delist";

// === Structs ===

/// A marketplace listing wrapping an IntelObject.
/// Shared object so any buyer can purchase.
public struct Listing has key {
    id: UID,
    intel: Option<IntelObject>,
    price: u64,
    seller: address,
}

// === Events ===

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

// === Public Functions ===

/// Seller lists an IntelObject for sale. Creates a shared Listing.
public fun list(
    intel: IntelObject,
    price: u64,
    ctx: &mut TxContext,
) {
    let seller = ctx.sender();
    let listing = Listing {
        id: object::new(ctx),
        intel: option::some(intel),
        price,
        seller,
    };
    event::emit(ListingCreatedEvent {
        listing_id: listing.id.to_address(),
        seller,
        price,
    });
    transfer::share_object(listing);
}

/// Buyer purchases a listing. Atomic: coin to seller, IntelObject to buyer.
/// Caller must pass exact Coin<SUI> matching listing price.
public fun purchase(
    listing: &mut Listing,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
): IntelObject {
    assert!(payment.value() == listing.price, EWrongPayment);
    transfer::public_transfer(payment, listing.seller);
    event::emit(PurchaseEvent {
        listing_id: listing.id.to_address(),
        buyer: ctx.sender(),
        seller: listing.seller,
        price: listing.price,
    });
    listing.intel.extract()
}

/// Seller reclaims an unsold IntelObject.
public fun delist(
    listing: &mut Listing,
    ctx: &TxContext,
): IntelObject {
    assert!(ctx.sender() == listing.seller, ENotSeller);
    listing.intel.extract()
}

// === View Functions ===

public fun price(self: &Listing): u64 { self.price }
public fun seller(self: &Listing): address { self.seller }
public fun has_intel(self: &Listing): bool { self.intel.is_some() }
```

---

## 3. Seal Access Policy Design

**Pattern:** Private data (owner-only decryption).

**How it works:**
1. During encryption, the `id` parameter passed to `SealClient.encrypt()` is the IntelObject's Sui object address (as bytes).
2. During decryption, Seal key servers execute a dry-run PTB calling `seal_approve(id, intel_object_ref)`.
3. The dry-run succeeds only if the transaction sender can provide a valid reference to the IntelObject — which requires ownership.
4. On success, key servers return threshold-derived key material; the client reconstructs the AES key.

**Key design decisions:**
- The `seal_approve` function is `entry` (not `public`) — it's only called by Seal's dry-run PTB, never composed.
- The `id` parameter is `vector<u8>` (Seal convention), parsed to `ID` via `object::id_from_bytes`.
- After purchase, the buyer now owns the IntelObject → `seal_approve` succeeds for them, and fails for the (former) seller.

**Seal package ID for `seal_approve` PTB (testnet):**
- Obtain from `@mysten/seal` SDK — the `SealClient` constructor takes the package ID.

**References:**
- Pattern docs: https://seal-docs.wal.app/ExamplePatterns
- Move source: https://github.com/MystenLabs/seal/blob/main/move/patterns/sources/private_data.move
- SDK usage: https://seal-docs.wal.app/UsingSeal#encryption

---

## 4. Frontend Architecture

**Stack:** React 18+ · TypeScript · @mysten/dapp-kit-react · @mysten/seal · @mysten/walrus · Tailwind CSS

**Package imports (correct as of March 2026):**

```typescript
// Wallet connection — use dapp-kit-react, NOT deprecated dapp-kit
import { useDAppKit } from '@mysten/dapp-kit-react';

// Sui client — use SuiJsonRpcClient, NOT deprecated SuiClient
import { SuiJsonRpcClient } from '@mysten/sui/jsonRpc';

// Transactions — use Transaction, NOT deprecated TransactionBlock
import { Transaction } from '@mysten/sui/transactions';

// Seal — standalone threshold encryption
import { SealClient, SessionKey, getAllowlistedKeyServers } from '@mysten/seal';

// Walrus — blob storage
import { WalrusClient } from '@mysten/walrus';
```

### Pages

| Page | Route | Purpose |
|------|-------|---------|
| Upload | `/upload` | Spy records/uploads audio, encrypts, mints IntelObject, lists on marketplace |
| Marketplace | `/` | Browse active listings, view metadata, play teasers, purchase |
| My Intel | `/intel` | View owned IntelObjects, decrypt and play audio |

### Key Hooks

**`useWalrusUpload()`**
```typescript
function useWalrusUpload() {
  const walrus = new WalrusClient();

  async function upload(data: Uint8Array): Promise<string> {
    const { blobId } = await walrus.writeBlob(data, { epochs: 5 });
    return blobId;
  }

  async function download(blobId: string): Promise<Uint8Array> {
    return walrus.readBlob(blobId);
  }

  return { upload, download };
}
```

**`useTeaserPlayback()`**
```typescript
function useTeaserPlayback() {
  const { download } = useWalrusUpload();

  async function playTeaser(teaserBlobId: string): Promise<void> {
    const teaserBytes = await download(teaserBlobId);
    const blob = new Blob([teaserBytes], { type: 'audio/wav' });
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audio.play();
    audio.onended = () => URL.revokeObjectURL(url);
  }

  return { playTeaser };
}
```

**`useTeaserExtract()` (implementation note)**
```typescript
// Teaser extraction: crop first 2 seconds of audio using Web Audio API
// AudioContext.decodeAudioData → slice AudioBuffer → encode to WAV
// Implementation: ~30 lines of AudioBuffer slicing utility
```

**`useSealEncrypt()`**
```typescript
function useSealEncrypt() {
  const sealClient = new SealClient({
    suiClient: new SuiJsonRpcClient({ url: 'https://fullnode.testnet.sui.io:443' }),
    serverObjectIds: [
      '0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75',
      '0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8',
    ],
    verifyKeyServers: false, // testnet open-mode
  });

  async function encryptKey(
    aesKey: Uint8Array,
    intelObjectId: string, // Sui object address of the IntelObject
    packageId: string,     // Published package ID of shadow_broker
  ): Promise<Uint8Array> {
    const policyObjectId = intelObjectId; // The IntelObject IS the policy anchor
    const { encryptedObject } = await sealClient.encrypt({
      threshold: 2,
      packageId,
      id: policyObjectId,
      data: aesKey,
    });
    return encryptedObject;
  }

  return { sealClient, encryptKey };
}
```

**`useSealDecrypt()`**
```typescript
function useSealDecrypt() {
  const { sealClient } = useSealEncrypt();
  const { signTransaction } = useDAppKit();

  async function decryptKey(
    encryptedKey: Uint8Array,
    intelObjectId: string,
    packageId: string,
  ): Promise<Uint8Array> {
    const sessionKey = new SessionKey({
      address: /* wallet address */,
      packageId,
      ttlMin: 10,
    });

    // Sign the session key with the wallet
    await sessionKey.setPersonalMessage(signTransaction);

    const decrypted = await sealClient.decrypt({
      data: encryptedKey,
      sessionKey,
      txBytes: buildSealApproveTx(intelObjectId, packageId),
    });
    return decrypted;
  }

  return { decryptKey };
}

// Helper: build the PTB that Seal key servers dry-run to verify ownership
function buildSealApproveTx(
  intelObjectId: string,
  packageId: string,
): Uint8Array {
  const tx = new Transaction();
  tx.moveCall({
    target: `${packageId}::intel_object::seal_approve`,
    arguments: [
      tx.pure.vector('u8', /* intelObjectId as bytes */),
      tx.object(intelObjectId),
    ],
  });
  return tx.build();
}
```

**Audio playback (after decryption):**
```typescript
function playDecryptedAudio(decryptedBytes: Uint8Array, mimeType: string) {
  const blob = new Blob([decryptedBytes], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const audio = new Audio(url);
  audio.play();
  audio.onended = () => URL.revokeObjectURL(url);
}
```

---

## 5. PTB Composition

### TX1: Mint IntelObject (Seller)

The seller mints the IntelObject with an empty `encrypted_key`. The Seal encryption step requires the object's address, which isn't known until after mint.

```typescript
async function mintIntel(
  packageId: string,
  blobId: string,
  teaserBlobId: string | null,
  fileType: string,
  durationSeconds: number,
  fileSizeBytes: number,
  description: string,
) {
  const tx = new Transaction();
  const [intel] = tx.moveCall({
    target: `${packageId}::intel_object::mint`,
    arguments: [
      tx.pure.string(blobId),
      tx.pure.vector('u8', []), // empty encrypted_key — set after Seal encrypt
      tx.pure.string(fileType),
      tx.pure.u64(durationSeconds),
      tx.pure.u64(fileSizeBytes),
      tx.pure.string(description),
      teaserBlobId
        ? tx.pure.option('string', teaserBlobId)
        : tx.pure.option('string', null),
    ],
  });
  tx.transferObjects([intel], tx.pure.address(/* sender */));
  return tx;
}
```

### TX2: Update Key + List (Seller — Single PTB)

After Seal encryption completes client-side, the seller updates the encrypted key and lists the IntelObject in one PTB. In Sui PTBs, an object used as `&mut` in one command can be used by-value in a subsequent command within the same transaction.

```typescript
async function updateKeyAndList(
  packageId: string,
  intelObjectId: string,
  encryptedKey: Uint8Array,
  priceInMist: number,
) {
  const tx = new Transaction();

  // Step 1: Update encrypted key (mutable borrow)
  tx.moveCall({
    target: `${packageId}::intel_object::update_encrypted_key`,
    arguments: [
      tx.object(intelObjectId),
      tx.pure.vector('u8', Array.from(encryptedKey)),
    ],
  });

  // Step 2: List on marketplace (consumes IntelObject by value)
  // In Sui PTBs, an object used as &mut in one command can be
  // used by-value in a subsequent command within the same PTB.
  tx.moveCall({
    target: `${packageId}::marketplace::list`,
    arguments: [
      tx.object(intelObjectId),
      tx.pure.u64(priceInMist),
    ],
  });

  return tx;
}
```

This reduces the seller flow from 3 transactions to 2.

### Purchase (Buyer)

```typescript
async function purchaseListing(
  packageId: string,
  listingId: string,
  priceInMist: number,
) {
  const tx = new Transaction();

  // Split exact payment from gas coin
  const [coin] = tx.splitCoins(tx.gas, [tx.pure.u64(priceInMist)]);

  // Purchase: coin to seller, IntelObject returned
  const [intel] = tx.moveCall({
    target: `${packageId}::marketplace::purchase`,
    arguments: [
      tx.object(listingId),
      coin,
    ],
  });

  // Transfer IntelObject to buyer (self)
  tx.transferObjects([intel], tx.pure.address(/* buyer address */));

  return tx;
}
```

### Decrypt (Client-Side Only — No On-Chain Tx)

1. Create `SessionKey` with `@mysten/seal` (TTL 10 min).
2. Build a PTB calling `seal_approve` with the IntelObject ID — this is passed to Seal, not submitted on-chain.
3. `SealClient.decrypt()` sends the PTB to key servers; they dry-run it to verify ownership.
4. Client receives threshold key shares → reconstructs AES key.
5. Fetch encrypted blob from Walrus via `blobId`.
6. AES-decrypt the audio → `Blob` URL → `<audio>` playback.

---

## 6. Chicken-and-Egg Resolution (Seal Encryption vs. Mint Order)

The IntelObject address is needed for Seal encryption, but the address isn't known until after mint.

**Solution — 2-Transaction Flow:**

1. **TX1:** `mint()` with empty `encrypted_key` → IntelObject created → get its object ID from transaction effects.
2. **Client-side:** Seal encrypt the AES key using the now-known IntelObject address as the policy anchor.
3. **TX2:** `update_encrypted_key(encryptedKey)` + `marketplace::list(price)` in a single PTB.

This is clean and robust. The `update_encrypted_key()` function enforces creator-only access and one-time-only semantics via `EKeyAlreadySet`. No fragile ID prediction needed.

---

## 7. Build Sequence (8–12 Hour Sprint)

| Hours | Phase | Deliverables |
|-------|-------|-------------|
| 0–2 | Move contracts | `intel_object.move`, `marketplace.move`, `Move.toml`, build passes, basic tests |
| 2–4 | Frontend scaffold | React app, wallet connection via `@mysten/dapp-kit-react`, routing, Tailwind |
| 4–6 | Walrus integration | `useWalrusUpload` hook, AES encrypt/decrypt utility, upload flow, teaser extraction utility |
| 6–8 | Seal integration | `useSealEncrypt`/`useSealDecrypt` hooks, envelope encryption pipeline |
| 8–10 | Marketplace UI | Browse listings (query shared Listing objects), teaser playback, purchase PTB, audio playback |
| 10–12 | Demo & polish | Record demo video, error states, loading indicators, README |

**Critical path:** Seal integration (hours 6–8) is the highest-risk segment. If Seal key servers are unreliable, fall back to demo with pre-encrypted test data.

**Parallel work:** Move contracts and frontend scaffold can be developed in parallel (hours 0–4).

---

## 8. SDK Recon Notes (Verified Findings)

### @mysten/seal v1.1.0

- **npm:** `@mysten/seal` — 246 kB, 52 files, Apache-2.0
- **Documentation:** https://seal-docs.wal.app/ (NOT docs.sui.io)
- **WARNING:** The page at `docs.sui.io/guides/developer/nautilus/seal` describes Nautilus/TEE enclave secret management — a DIFFERENT use case. Always use `seal-docs.wal.app`.
- **API surface:** `SealClient`, `SessionKey`, `encrypt()`, `decrypt()`
- **Access policies:** Defined in Move via `seal_approve*` entry functions
- **Testnet key servers (open-mode, free):**
  ```
  0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75
  0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8
  ```
  8+ additional providers listed at https://seal-docs.wal.app/Pricing#verified-key-servers
- **Documented patterns:** Private data, Allowlist, Subscription, Time-lock, NFT-gated, Voting
- **Envelope encryption (recommended):** AES-encrypt content → store on Walrus, Seal-encrypt AES key → store in IntelObject
- **Pattern source code:** https://github.com/MystenLabs/seal/tree/main/move/patterns/sources

### @mysten/walrus

- **npm:** `@mysten/walrus` — published by Mysten Labs
- **Documentation:** https://docs.wal.app/ and https://sdk.mystenlabs.com/walrus
- **Browser-compatible:** HTTP API to public aggregators, no local daemon required
- **Core API:** `writeBlob(data) → { blobId }`, `readBlob(blobId) → Uint8Array`
- **Networks:** Walrus Testnet live, Walrus Mainnet live
- **Example app:** `walrus-sdk-relay-example-app`

### Sui TypeScript SDK (March 2026)

- **Correct:** `@mysten/sui` (v2.x)
- **BANNED:** `@mysten/sui.js` (dead), `SuiClient` from `@mysten/sui/client` (deprecated Feb 28 2026)
- **Use:** `SuiJsonRpcClient` from `@mysten/sui/jsonRpc`
- **Use:** `Transaction` from `@mysten/sui/transactions` (NOT `TransactionBlock`)
- **Use:** `decodeSuiPrivateKey` field `scheme` (NOT `schema`)

---

## 9. SSU Integration Decision

**Decision: Standalone marketplace. No world-contracts dependency.**

Rationale:
- Real SSU integration requires importing world-contracts (~50+ modules), handling Auth type params, ItemType registration, and AdminACL/OwnerCap patterns. Estimated cost: 4–6 additional hours.
- IntelObject is a unique encrypted NFT — it doesn't fit the SSU inventory model (fungible items with parent_id constraints).
- The project's value is the Mysten Trinity (Sui + Seal + Walrus), not world-contracts integration. SSU would muddy the narrative.
- Thematic naming adopted instead: "Dead Drop" (listing), "Dead Drop Network" (marketplace) for EVE flavor without the dependency.

---

## 10. Known Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Seal key server latency/downtime | High | Retry with alternate server; cache `SessionKey` for TTL window; pre-create session keys |
| Walrus upload failures | Medium | Audio files are small (2–5 MB), well within limits; retry with exponential backoff |
| "Fake intel" uploads (garbage data) | Low | Metadata fields (duration, file size) are self-reported; teaser clip provides proof-of-life for buyers; future: reputation system, staking |
| AES key rotation after purchase | Low | Not needed — one key per blob, immutable after mint |
| Listing object becomes "dead" after purchase | Low | `intel` field becomes `none`; frontend filters by `has_intel()` |
| Teaser extraction quality | Low | AudioBuffer slicing is well-documented Web Audio API; 2-second clip is trivial |
| SSU/TradePost integration with custom NFT types | N/A | Out of scope — standalone marketplace contract avoids world-contracts dependency |
