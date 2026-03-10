# The Shadow Broker Protocol — Product Vision

**Retention:** Prep-only

## Document Purpose

This document is the authoritative product vision for **The Shadow Broker Protocol**, a hackathon sprint entry for the EVE Frontier Hackathon on Sui. It is written for an LLM coding agent that will implement the project in an 8–12 hour sprint. Every architectural choice, SDK reference, and scope boundary is specified precisely to minimize ambiguity during implementation.

---

## Problem Statement

EVE Online/Frontier gameplay is defined by information asymmetry. Corporate espionage — stealing jump-route maps, alliance comms recordings, fleet staging intel, structural blueprints — is not a bug; it is the game's most celebrated metagame. Spies who acquire valuable intelligence need a way to sell it.

This is the **Fair Exchange Problem**, a well-known cryptographic challenge:

1. **Spy sends data first → Buyer doesn't pay.** The spy has no leverage after disclosure.
2. **Buyer pays first → Spy sends fake data.** The buyer has no recourse after payment.
3. **Escrow via trusted third party → Trust bottleneck.** The escrow agent can collude, leak, or disappear.

No existing EVE Frontier tool solves this. Discord DMs and in-game chat are the current medium of exchange — entirely trust-based, zero cryptographic guarantees.

---

## Solution Architecture

The Shadow Broker Protocol solves the Fair Exchange Problem using three Mysten Labs technologies in a single atomic workflow.

### The Mysten Labs Trinity

| Layer | Technology | Role | Package / Docs |
|-------|-----------|------|----------------|
| **Storage** | Walrus | Decentralized content-addressable blob storage. The spy uploads the encrypted intelligence file to Walrus (returns `blobId`) and a **2-second unencrypted audio teaser** as a separate blob (returns `teaserBlobId`). The teaser is public proof-of-life — buyers can hear a sample before committing funds. | `@mysten/walrus` on npm. Browser-compatible HTTP API to public aggregators. ~2–3 API calls: `uploadBlob() → blobId`, `readBlob(blobId) → data`. Docs: docs.wal.app |
| **Encryption** | Seal | Threshold encryption with on-chain access policies. The spy Seal-encrypts the AES key such that only the holder of a specific `IntelObject` NFT can request decryption keys from the Seal key server network. The teaser clip is NOT encrypted — it remains publicly playable. | `@mysten/seal` v1.1.0 on npm. Client-side SDK. NO infrastructure required — Mysten hosts free open-mode key servers on testnet. Docs: seal-docs.wal.app |
| **Exchange** | Sui PTB | Programmable Transaction Block enabling atomic swap. Buyer sends `Coin<SUI>` and receives the `IntelObject` NFT in a single transaction. Ownership transfers atomically — no intermediate state where either party can cheat. | `@mysten/sui` (Transaction from `@mysten/sui/transactions`). PTB composition via `tx.moveCall()` + `tx.transferObjects()`. |

### Data Flow (Step-by-Step)

```
SPY WORKFLOW:
1.  Spy has intelligence file (e.g., enemy_fleet_comms.mp3)
2a. Spy AES-encrypts file locally → encrypted_blob
2b. Spy extracts 2-second teaser clip from original audio (unencrypted)
2c. Spy uploads teaser clip to Walrus → teaserBlobId
3.  Spy uploads encrypted_blob to Walrus → blobId
4.  Spy Seal-encrypts the AES key with policy:
    "Only wallet holding IntelObject<ID> can decrypt"
5.  Spy mints IntelObject NFT on Sui (TX1):
    - metadata: { file_type, file_size, duration, description,
                   blob_id, sealed_key, teaser_blob_id }
6.  Spy updates sealed key + lists for sale at price P (TX2):
    - PTB: update_key() + list() in a single transaction

BUYER WORKFLOW:
7a. Buyer browses listings, inspects metadata
7b. Buyer plays 2-second teaser audio (public, unencrypted from Walrus) — proof of life
8.  Buyer executes PTB:
    - Input: Coin<SUI> (amount P)
    - Atomic: coin → spy, IntelObject → buyer
9.  Buyer now owns IntelObject
10. Buyer calls SealClient.decrypt() with IntelObject ownership proof
11. Seal key servers verify on-chain ownership, return threshold key shares
12. Buyer reconstructs AES key, downloads blob from Walrus, decrypts
13. Buyer has plaintext intelligence file
```

### Envelope Encryption Pattern (Recommended)

Per Seal documentation best practice (seal-docs.wal.app § Performance Recommendations):

- AES-encrypt the content locally (fast, arbitrary size)
- Upload AES-encrypted content to Walrus (blob storage handles large files)
- Seal-encrypt only the AES key (small payload, fast threshold encryption)
- Store the sealed AES key + Walrus blobId in the IntelObject NFT metadata
- Upload a short **unencrypted teaser clip** to Walrus separately — public proof-of-life

This avoids Seal processing large files, keeps the on-chain footprint minimal, and gives buyers audible evidence before purchase.

### Move Contract Surface (Minimal)

```move
module shadow_broker::intel {
    /// Core NFT representing a piece of intelligence
    struct IntelObject has key, store {
        id: UID,
        seller: address,
        blob_id: String,                    // Walrus blob reference (encrypted)
        sealed_key: vector<u8>,             // Seal-encrypted AES key
        teaser_blob_id: Option<String>,     // Walrus blob reference (unencrypted 2s preview)
        file_type: String,                  // e.g., "audio/wav", "image/png"
        file_size: u64,                     // bytes
        description: String,                // seller-provided summary
        price_mist: u64,                    // listing price in MIST
    }

    /// Atomic purchase: buyer sends coin, receives IntelObject
    public fun purchase(
        listing: IntelObject,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    );

    /// Mint IntelObject (TX1 of 2-TX seller flow)
    public fun mint(
        blob_id: String,
        file_type: String,
        file_size: u64,
        description: String,
        teaser_blob_id: Option<String>,
        price_mist: u64,
        ctx: &mut TxContext,
    ): IntelObject;

    /// Set sealed key after Seal encryption completes (TX2, composed in PTB with list)
    public fun update_key(
        intel: &mut IntelObject,
        sealed_key: vector<u8>,
    );
}
```

The seller flow is a **2-transaction sequence**: TX1 mints the IntelObject (before the Seal policy ID is known), TX2 updates the sealed key and lists for sale in a single PTB. This decouples minting from encryption and keeps each transaction simple.

---

## Core Value Proposition

**For the first time in EVE Frontier, spies can sell stolen intelligence with cryptographic delivery guarantees, audible proof-of-life, and zero trusted intermediaries.**

The buyer is guaranteed to receive real encrypted content and the ability to decrypt it. The spy is guaranteed payment before the buyer gains access. The teaser gives buyers audible confidence before they commit a single MIST. Neither party can cheat the other. No escrow agent, no Discord trust, no reputation requirement.

---

## The Fair Exchange Guarantee

The protocol provides a **cryptographic delivery guarantee**, not a truthfulness guarantee. Specifically:

| Property | Guaranteed? | Mechanism |
|----------|------------|-----------|
| Buyer receives encrypted content | Yes | Walrus blob is immutable and content-addressed; blobId is in NFT metadata |
| Buyer can decrypt after purchase | Yes | Seal policy grants decryption to IntelObject owner; ownership transferred atomically in PTB |
| Payment is atomic with delivery | Yes | PTB executes coin transfer and NFT transfer in single transaction; all-or-nothing |
| Spy receives payment | Yes | Coin transfer is part of the same atomic PTB |
| Content has proof-of-life | **Partial** | 2-second unencrypted teaser provides audible evidence; not a full verification |
| Content is genuine/truthful | **No** | Content is opaque encrypted bytes; Seal guarantees delivery, not truth |

### The Sealed Envelope Analogy

Buying intelligence through the Shadow Broker Protocol is like buying a sealed envelope at auction — but the auctioneer lets you hold it to your ear and listen for two seconds. You hear voices. You hear urgency. You can't make out the words yet. But you know it's real.

You are **guaranteed to receive the envelope** and **guaranteed you can open it**. You are **not guaranteed** the full contents are what the seller claims. But those two seconds of intercepted comms? They change the calculation entirely.

---

## Known Limitations & Mitigations

### L1: Content Truthfulness (Fundamental)

**Limitation:** Seller can upload fabricated content. A "recording of enemy fleet comms" could be silence, rickroll, or random noise.

**Mitigations (MVP):**
- **Audio teaser (2-second unencrypted preview):** Seller provides a short unencrypted sample alongside the encrypted payload. The buyer can listen before purchasing, dramatically reducing the "is this real?" uncertainty. This isn't a cryptographic guarantee of truthfulness, but it provides audible proof-of-life that the content is genuine audio of the described type.
- Metadata fields on IntelObject: `file_type`, `file_size`, `description` — buyer can assess plausibility before purchase
- Low-value listings reduce risk exposure per transaction

**Mitigations (Future Work):**
- On-chain seller reputation score (successful sales / disputes)
- Buyer review system (post-purchase rating stored as dynamic field)
- Staking mechanism: seller bonds collateral, slashed on dispute

### L2: Content Legality / Moderation

**Limitation:** Decentralized storage + encryption means content cannot be moderated pre-sale.

**Mitigation:** This is a hackathon demo. Content moderation is explicitly out of scope. The protocol is a technology demonstration, not a production marketplace.

### L3: Seal Key Server Availability

**Limitation:** Seal decryption depends on Mysten-hosted testnet key servers being online.

**Mitigation:** Mysten operates 8+ testnet key servers (seal-docs.wal.app § Verified Key Servers). For a hackathon demo, this is sufficient. Production would require self-hosted or decentralized key server infrastructure.

### L4: Single-Use vs. Resale

**Limitation:** Once decrypted, the buyer can redistribute the plaintext. The IntelObject NFT can also be resold, granting the next buyer decryption access.

**Mitigation:** This mirrors real-world intelligence markets — information, once known, can be shared. The protocol guarantees the *first* exchange is fair. Resale and information leakage are gameplay dynamics, not protocol bugs.

---

## Target Prize Categories

### Primary: Most Creative (Weight: High)

The Shadow Broker Protocol scores highest on creativity because:
- Novel application of Seal threshold encryption to a gameplay problem
- Directly maps to EVE's most iconic metagame (espionage)
- First project to combine all three Mysten technologies (Sui + Walrus + Seal)
- The audio teaser mechanic — hear two seconds of stolen comms before you buy — is viscerally compelling and demo-unforgettable

### Backup: Best Technical Implementation

Strong technical story:
- Envelope encryption pattern (AES + Seal + Walrus)
- Atomic swap via PTB (no escrow contract needed)
- 2-TX seller flow with PTB composition (mint → update_key + list)
- Minimal Move contract surface (< 100 lines)
- Clean SDK integration across three packages

### Scoring Estimate

Weighted total: **~7.5 / 10** on the 8-criterion hackathon rubric. Strongest axes: Creativity (9), Use of Sui Features (9), Fun Factor (9). Weakest: Potential for Real-World Application (5) — the sealed-envelope limitation caps long-term marketplace viability without reputation infrastructure. The teaser mechanic and atomic PTB composition strengthen both "Fun Factor" and "Use of Sui Features" — the moment a buyer hears intercepted comms is the single most memorable beat in the demo.

---

## Competitive Differentiation

### Portfolio Uniqueness

The Shadow Broker Protocol is the **only project in the portfolio** integrating the full Mysten Labs technology suite:

| Technology | Shadow Broker | CivilizationControl | Fortune Gauntlet | Flappy Frontier | Cargo Bond |
|-----------|:---:|:---:|:---:|:---:|:---:|
| Sui Move | Yes | Yes | Yes | Yes | Yes |
| Walrus | **Yes** | No | No | No | No |
| Seal | **Yes** | No | No | No | No |

No other entry touches Walrus or Seal. This maximizes coverage of the "Use of Sui Features" judging criterion and demonstrates ecosystem breadth that judges won't see from any other submission in the portfolio.

### Hackathon-Wide Differentiation

Most hackathon entries will build DeFi tools, game UIs, or smart contract utilities. A **cryptographic intelligence marketplace** — directly tied to EVE's espionage lore — stands out on the "Fun Factor" and "Creative Use" axes. The demo narrative ("watch a spy sell stolen fleet comms to a rival alliance") is immediately gripping.

The audio teaser mechanic is a UX innovation that no other "encrypted content sale" project is likely to implement. The moment the buyer hears two seconds of intercepted comms — just enough to know it's real, not enough to know why it matters — is the single most memorable moment in the demo.

### Technical Simplicity as Advantage

The Move contract is intentionally minimal (< 100 lines). The complexity lives in the SDK integration layer (TypeScript), not on-chain. This means:
- Faster implementation (8–12 hour sprint feasible)
- Fewer on-chain failure modes
- Demo can focus on the UX flow, not contract debugging
- Judges see clean, readable code

---

## Implementation Scope (Sprint Boundaries)

### In Scope (MVP)
- Move contract: `IntelObject` struct, `mint`, `update_key`, `purchase`
- TypeScript CLI or minimal web UI: upload → encrypt → list → buy → decrypt flow
- Audio teaser extraction (2-second clip from source audio, unencrypted Walrus upload)
- PTB optimization: 2-transaction seller flow (TX1: mint, TX2: update key + list in single PTB)
- Walrus integration: upload/download via `@mysten/walrus`
- Seal integration: encrypt/decrypt via `@mysten/seal`
- Demo scenario: spy uploads audio file, buyer hears teaser, purchases, and decrypts

### Out of Scope
- Reputation system, reviews, disputes
- Content moderation
- Multi-asset listings (single file per IntelObject)
- Production key server infrastructure
- Marketplace UI (browse/search/filter) — CLI or single-page demo sufficient
- EVE Frontier world-contracts / SSU integration (standalone marketplace — see Technical Architecture § SSU Integration Decision for rationale)
