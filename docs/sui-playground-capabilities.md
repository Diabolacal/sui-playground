# Sui Playground Capabilities — EVE Frontier Chain-Side Testing

> **Last updated:** 2026-02-15
> **Audience:** LLM-driven "vibe coders" who need to understand what agents can realistically build and test in this playground.
> **Repo:** `sui-playground` (private sandbox — do not push without operator approval)

---

## 1. Mental Model: EVE Frontier Architecture vs This Playground

EVE Frontier is a space MMO built on a hybrid architecture. Not all layers are accessible here.

### The Full Stack (in production)

```
┌──────────────────────────────────────────────────────────────┐
│  Carbon Client (game UI, 3D rendering, player input)         │  ← NOT here
├──────────────────────────────────────────────────────────────┤
│  Game Server (authoritative world state, physics, spawning)  │  ← NOT here
├──────────────────────────────────────────────────────────────┤
│  Off-chain Services                                          │  ← NOT here
│  - FusionAuth (OAuth/identity)                               │
│  - Enoki (zkLogin proofs)                                    │
│  - Server-signed location/proximity proofs                   │
│  - Item bridge (game ↔ chain minting authority)              │
├──────────────────────────────────────────────────────────────┤
│  ZK Proof Layer (client-side, verifiable on-chain)           │  ← PARTIALLY HERE
│  - Groth16 location/distance attestation (PoC)               │
│  - Poseidon Merkle commitments + Ed25519 binding             │
├──────────────────────────────────────────────────────────────┤
│  On-chain: Sui L1 (Move smart contracts)                     │  ← THIS IS US
│  - World contracts (gate, storage unit, network node, etc.)  │
│  - Builder extensions (custom logic for smart structures)    │
│  - Characters, items, killmails, access control              │
└──────────────────────────────────────────────────────────────┘
```

### Where This Playground Sits

This playground provides a **local Sui devnet** (via Docker) with:
- The full `world-contracts` package (17 Move modules across assemblies, primitives, access control, crypto, and registry — the production game contracts)
- A Groth16 ZK proof-of-concept ([`eve-frontier-proximity-zk-poc`](../vendor/eve-frontier-proximity-zk-poc/)) for privacy-preserving location and distance attestation
- Scaffold templates for writing builder extensions (`gate`, `storage_unit`, `tokens`)
- Three pre-funded accounts (`ADMIN`, `PLAYER_A`, `PLAYER_B`)
- A persistent keystore volume
- Network switching (local ↔ testnet)

**You can:** publish, upgrade, call, inspect, and compose Move packages. You can model ownership, access control, structure lifecycle, and extension behavior — everything that lives on-chain. You can also generate and verify Groth16 ZK proofs for location/distance attestation entirely locally (after installing the ZK toolchain — see §7.2 Prerequisites).

**You cannot:** spawn real in-game entities, simulate the Carbon client, bridge items from the game server, or authenticate via FusionAuth/Enoki without internet access and credentials.

---

## 2. What We Can Do Locally (Capabilities)

### 2.1 Local Devnet Lifecycle

| Action | How |
|--------|-----|
| **Start devnet** | `cd vendor/builder-scaffold/docker && docker compose run --rm sui-local` |
| **Stop devnet** | Exit the container (`exit` / Ctrl+D) |
| **Clean reset** | Delete `workspace-data/`, remove volume: `docker volume rm docker_sui-keystore` |
| **Verify env** | Inside container: `sui client active-env` → `"local"` |
| **Check balances** | `sui client gas` |
| **List accounts** | `sui client addresses` |

On first run, the entrypoint:
1. Starts `sui start --with-faucet --force-regenesis`
2. Creates 3 ed25519 keypairs (ADMIN, PLAYER_A, PLAYER_B)
3. Funds all 3 from the local faucet
4. Writes `.env.sui` to `workspace-data/`

Subsequent runs reuse persisted keys (Docker named volume `sui-keystore`).

**Reference:** [docs/sui-playground.md](sui-playground.md) — quickstart guide
**Scripts:** [vendor/builder-scaffold/docker/scripts/](../vendor/builder-scaffold/docker/scripts/) — `entrypoint.sh`, `setup-local.sh`, `common.sh`

### 2.2 Build & Publish Move Packages

Inside the container:
```bash
cd /workspace/contracts/<package>
sui move build -e local
sui client publish -e local --gas-budget 100000000 --json
```

The `-e local` flag is **required** to avoid chain ID mismatch after fresh genesis.

Available scaffold packages (at `/workspace/contracts/`):
- `gate/` — Smart Gate extension template (one empty `jump_through_gate()` function)
- `storage_unit/` — Smart Storage Unit extension template (one empty `template()` function)
- `tokens/` — Token creation template (one empty `template()` function)
- `hello_world/` — Empty placeholder

These are intentionally minimal starting points. The real logic lives in `world-contracts`.

### 2.3 Inspect Objects & Events

```bash
sui client object <OBJECT_ID>                   # Read any object
sui client objects --address <ADDRESS>           # List owned objects
sui client call --package <PKG> --module <MOD> --function <FN> --args ... --gas-budget 100000000
sui client events --package <PKG>               # Query events
```

### 2.4 Network Switching

Inside the container:
```bash
./scripts/switch-network.sh testnet   # Switch to testnet (requires .env.testnet)
./scripts/switch-network.sh local     # Switch back to local devnet
```

**Reference:** [vendor/builder-scaffold/docker/scripts/switch-network.sh](../vendor/builder-scaffold/docker/scripts/switch-network.sh)

---

## 3. What We Cannot Do Locally (Limitations)

### 3.1 Hard Blockers (No Workaround)

| Missing Capability | Why | Impact |
|--------------------|-----|--------|
| **Carbon client** | Proprietary CCP game client; not distributable | Cannot see in-game effects of on-chain changes |
| **Game server** | Authoritative world state; controls entity spawning, physics, combat | On-chain objects exist but have no in-game representation |
| **FusionAuth** | EVE Frontier's OAuth provider (`auth.evefrontier.com`) | No zkLogin authentication without credentials |
| **Enoki API** | Mysten Labs' zkLogin proof service | No zkLogin address derivation or ZK proof generation without API key |

### 3.2 Soft Blockers (Workaround Available)

| Missing Capability | Workaround |
|--------------------|------------|
| **Server-signed location proofs** | Register a local keypair as "server address" in `ServerAddressRegistry`, then sign your own Ed25519 proofs matching the `LocationProofMessage` format. The TS script at [vendor/world-contracts/ts-scripts/location/generate-test-signature.ts](../vendor/world-contracts/ts-scripts/location/generate-test-signature.ts) shows how. |
| **Sponsored transactions** | Add your admin address to `AdminACL` as a sponsor. Several world-contracts functions require `verify_sponsor(admin_acl, ctx)` — this checks that the transaction's gas sponsor is in the ACL. |
| **Item minting ("game → chain")** | Call `game_item_to_chain_inventory()` with a sponsored transaction. This is the game server's item bridge, but locally you control both the admin and the sponsor. |
| **Distance proofs for gate linking** | The `link_gates()` function validates distance via server-signed proofs. Generate matching proofs locally using the same keypair registered as the server. |

### 3.3 What "Spawning" Means

In EVE Frontier production:
1. The **game server** decides to instantiate a structure at a location
2. It calls the **admin-gated** `anchor()` function to create the on-chain object
3. The `OwnerCap` is created and transferred to the player's `Character` object
4. The Carbon client renders the structure in 3D space

Locally, you can do steps 2–3 (you control the admin key), but step 1 (game server decision) and step 4 (3D rendering) don't exist. Your on-chain objects are real Sui objects — they just have no visual representation.

---

## 4. Smart Structure Capabilities (world-contracts Deep Dive)

The world-contracts package ([vendor/world-contracts/contracts/world/](../vendor/world-contracts/contracts/world/)) contains the full EVE Frontier game contracts. Here's what each structure type provides:

### 4.1 Smart Gate

**Module:** [vendor/world-contracts/contracts/world/sources/assemblies/gate.move](../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) (718 lines)
**On-chain object:** `Gate` (shared) — fields: `id`, `key`, `owner_cap_id`, `type_id`, `linked_gate_id`, `status`, `location`, `energy_source_id`, `extension`

**Ownership:** `OwnerCap<Gate>` — a capability object held by a `Character` object (transfer-to-object pattern using Sui `Receiving`).

#### Operations

| Operation | Function | Who Can Call | Prerequisites |
|-----------|----------|-------------|---------------|
| Create (anchor) | `anchor()` | Admin (AdminCap) | Character + NetworkNode + ObjectRegistry |
| Share | `share_gate()` | Admin | Gate must be address-owned |
| Go online | `online()` | Owner (OwnerCap) | NetworkNode + EnergyConfig (energy reservation) |
| Go offline | `offline()` | Owner | Energy released |
| Link two gates | `link_gates()` | Owner of both | Both online + GateConfig distance check + server-signed distance proof |
| Unlink | `unlink_gates()` | Owner of both | — |
| Jump (default) | `jump()` | Any player | Both online + linked + no extension + sponsor in AdminACL |
| Jump (with permit) | `jump_with_permit()` | Any player | Valid `JumpPermit` + sponsor in AdminACL |
| Register extension | `authorize_extension<Auth>()` | Owner | Registers a witness type for custom logic |
| Issue jump permit | `issue_jump_permit<Auth>()` | Extension code | Extension witness required |
| Destroy (unanchor) | `unanchor()` | Admin | Must be unlinked + offline |

#### Extension Pattern (Builder Moddability)
This is the core "builder" mechanism:
1. Gate owner calls `authorize_extension<Auth>()` with a custom witness type
2. When an extension is configured, the default `jump()` is **blocked** — only `jump_with_permit()` works
3. The extension contract issues `JumpPermit` objects via `issue_jump_permit<Auth>()` with its witness
4. Jump permits have configurable expiry (timestamp-based)

**Example extensions** (in [vendor/world-contracts/contracts/extension_examples/](../vendor/world-contracts/contracts/extension_examples/)):
- **Tribe-based access** ([gate.move](../vendor/world-contracts/contracts/extension_examples/sources/gate.move)) — only characters of a specific tribe get permits
- **Tribe permit via shared config** ([tribe_permit.move](../vendor/world-contracts/contracts/extension_examples/sources/tribe_permit.move)) — same but using dynamic-field config
- **Corpse bounty** ([corpse_gate_bounty.move](../vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move)) — deposit a corpse item to receive a jump permit

**Events:** `GateCreatedEvent`, `JumpEvent`, `StatusChangedEvent`

**What's missing for "in-game deployment":** The game server must call `anchor()` with real location hashes and connect the gate to a real `NetworkNode`. Linking requires server-signed distance proofs. Locally, you can do all of this by controlling admin + generating your own proofs.

### 4.2 Smart Storage Unit (SSU)

**Module:** [vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move](../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) (796 lines)
**On-chain object:** `StorageUnit` (shared) — fields: `id`, `key`, `owner_cap_id`, `type_id`, `status`, `location`, `inventory_keys`, `energy_source_id`, `metadata`, `extension`

**Ownership:** `OwnerCap<StorageUnit>` held by `Character`.

#### Operations

| Operation | Function | Who Can Call | Prerequisites |
|-----------|----------|-------------|---------------|
| Create (anchor) | `anchor()` | Admin | Character + NetworkNode + ObjectRegistry |
| Share | `share_storage_unit()` | Admin | — |
| Go online/offline | `online()` / `offline()` | Owner | NetworkNode + EnergyConfig |
| Mint items (game → chain) | `game_item_to_chain_inventory()` | Owner | Sponsored tx + character address match |
| Burn items (chain → game) | `chain_item_to_game()` | Owner | OwnerCap + proximity proof + server registry |
| Deposit (extension) | `deposit_item<Auth>()` | Extension | Auth witness + online |
| Withdraw (extension) | `withdraw_item<Auth>()` | Extension | Auth witness |
| Deposit (owner direct) | `deposit_by_owner()` | Owner | OwnerCap + proximity proof + same location |
| Withdraw (owner direct) | `withdraw_by_owner()` | Owner | OwnerCap + proximity proof |
| Register extension | `authorize_extension<Auth>()` | Owner | — |
| Destroy (unanchor) | `unanchor()` | Admin | Burns all inventory |

**Inventory model:** Dynamic fields keyed by `OwnerCap ID`. Each inventory uses `VecMap<u64, Item>`. Ephemeral inventories are created per-character on first `game_item_to_chain` call.

**Item struct:** `Item { id, tenant, type_id, item_id, volume, quantity, location }` — has `key` + `store` abilities.

**Events:** `StorageUnitCreatedEvent`, `ItemMintedEvent`, `ItemBurnedEvent`, `ItemDepositedEvent`, `ItemWithdrawnEvent`, `StatusChangedEvent`

**What's missing locally:** Owner-direct deposit/withdraw and chain-to-game burning require server-signed proximity proofs. Workaround: register a local keypair as server address and sign your own proofs.

### 4.3 Network Node (NWN)

**Module:** [vendor/world-contracts/contracts/world/sources/network_node/network_node.move](../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) (532 lines)
**On-chain object:** `NetworkNode` (shared) — fields: `id`, `key`, `owner_cap_id`, `type_id`, `status`, `location`, `fuel`, `energy_source`, `connected_assembly_ids`

**Role:** Energy provider for all connected assemblies. Must be fueled and online for assemblies to go online.

#### Operations

| Operation | Function | Who Can Call | Prerequisites |
|-----------|----------|-------------|---------------|
| Create (anchor) | `anchor()` | Admin | Character + ObjectRegistry |
| Share | `share_network_node()` | Admin | — |
| Go online | `online()` | Owner | Clock (for fuel timing) |
| Go offline | `offline()` | Owner | Returns `OfflineAssemblies` hot potato |
| Deposit fuel | `deposit_fuel()` | Owner | Sponsored tx |
| Withdraw fuel | `withdraw_fuel()` | Owner | Sponsored tx |
| Connect assemblies | `connect_assemblies()` | Admin | Returns `UpdateEnergySources` hot potato |
| Destroy (unanchor) | `unanchor()` | Admin | Returns `HandleOrphanedAssemblies` hot potato |

**Hot-potato pattern:** `offline()` and `unanchor()` return structs with no `drop` ability. The caller **must** process every connected assembly in the same transaction (call `offline_connected_assembly()` or `offline_orphaned_assembly()` for each). This enforces atomic state transitions.

**Events:** `NetworkNodeCreatedEvent`, `FuelEvent`, `StatusChangedEvent`

### 4.4 Smart Turret / Defense

**Not present.** No dedicated turret module exists in the world-contracts codebase. The `Killmail` module tracks PvP kills with a `LossType` enum (`SHIP`, `STRUCTURE`), but turret-specific logic is absent. The architecture docs mention turrets only in the context of future location obfuscation benefits.

### 4.5 Generic Assembly

**Module:** [vendor/world-contracts/contracts/world/sources/assemblies/assembly.move](../vendor/world-contracts/contracts/world/sources/assemblies/assembly.move)
**On-chain object:** `Assembly` (shared) — a simpler base structure without extensions, inventory, or linking. Used as the foundation type.

### 4.6 Character

**Module:** [vendor/world-contracts/contracts/world/sources/character/character.move](../vendor/world-contracts/contracts/world/sources/character/character.move)
**On-chain object:** `Character` (shared) — represents a player. Key fields: `key` (TenantItemId), `tribe_id`, `character_address`, `owner_cap_id`

**Key detail:** Characters hold `OwnerCap` objects via transfer-to-object. A character can "borrow" its OwnerCap to perform operations (`borrow_owner_cap<T>()` → hot-potato `ReturnOwnerCapReceipt` pattern).

**Events:** `CharacterCreatedEvent`

### 4.7 Killmail

**Module:** [vendor/world-contracts/contracts/world/sources/killmail/killmail.move](../vendor/world-contracts/contracts/world/sources/killmail/killmail.move)
**On-chain object:** `Killmail` (shared) — immutable PvP kill record. Created by admin only.

### 4.8 Supporting Primitives

| Module | Path | Purpose |
|--------|------|---------|
| `inventory` | [inventory.move](../vendor/world-contracts/contracts/world/sources/primitives/inventory.move) | Item storage with capacity management |
| `fuel` | [fuel.move](../vendor/world-contracts/contracts/world/sources/primitives/fuel.move) | Fuel consumption model (burn rate, efficiency) |
| `energy` | [energy.move](../vendor/world-contracts/contracts/world/sources/primitives/energy.move) | Energy production/reservation for assemblies |
| `location` | [location.move](../vendor/world-contracts/contracts/world/sources/primitives/location.move) | Privacy-preserving location verification (hashed coords + server proofs) |
| `status` | [status.move](../vendor/world-contracts/contracts/world/sources/primitives/status.move) | Assembly lifecycle states (NULL → OFFLINE → ONLINE) |
| `metadata` | [metadata.move](../vendor/world-contracts/contracts/world/sources/primitives/metadata.move) | Name/description/URL for assemblies |
| `in_game_id` | [in_game_id.move](../vendor/world-contracts/contracts/world/sources/primitives/in_game_id.move) | Deterministic ID derivation (TenantItemId) |
| `object_registry` | [object_registry.move](../vendor/world-contracts/contracts/world/sources/registry/object_registry.move) | Deterministic object ID generation |
| `sig_verify` | [sig_verify.move](../vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move) | Ed25519 signature verification for off-chain proofs |

### 4.9 Access Control Model

**Module:** [vendor/world-contracts/contracts/world/sources/access/access_control.move](../vendor/world-contracts/contracts/world/sources/access/access_control.move)

Three-tier capability hierarchy:

```
GovernorCap          (created on init; held by deployer)
  └─► AdminCap      (created by Governor; mid-level admin)
       └─► OwnerCap<T>  (created by Admin; per-object ownership — "KeyCard")
```

Supporting shared objects:
- `AdminACL` — tracks authorized gas sponsors
- `ServerAddressRegistry` — tracks authorized server addresses for sig verification

**Events:** `OwnerCapCreatedEvent`, `OwnerCapTransferred`

**Locally:** If you publish the world-contracts package to your local devnet, the deploying address receives `GovernorCap`, giving you full control of the capability hierarchy — you can create `AdminCap`s and `OwnerCap`s at will.

---

## 5. evevault: What It Enables (and What It Doesn't)

**Package:** [vendor/evevault/](../vendor/evevault/) — a monorepo (Turborepo + Bun) containing a zkLogin wallet for EVE Frontier.

### 5.1 What It IS

A **Sui zkLogin wallet** that:
1. Authenticates users via EVE Frontier's FusionAuth (OAuth/OIDC)
2. Derives Sui addresses from OAuth JWTs using Mysten Labs' Enoki zkLogin
3. Manages ephemeral signing keypairs (Ed25519 for Chrome extension, Secp256r1 for web via WebCrypto)
4. Implements the **Sui Wallet Standard** so dApps can discover and connect to it
5. Signs transactions and messages using zkLogin proofs
6. Supports multi-network switching (devnet, testnet) with per-network session state
7. Ships as a **Chrome MV3 browser extension** + **web app** companion

### 5.2 Key Components

| Component | Path | Purpose |
|-----------|------|---------|
| Chrome extension | [apps/extension/](../vendor/evevault/apps/extension/) | WXT-based MV3 extension with Wallet Standard |
| Web app | [apps/web/](../vendor/evevault/apps/web/) | Vite + React web wallet (backup/alternative) |
| Shared library | [packages/shared/](../vendor/evevault/packages/shared/) | Auth, wallet, Sui client, stores, components, hooks |
| JWT vend proxy | [services/](../vendor/evevault/services/) | Temporary Bun server proxying FusionAuth API (deprecated) |

### 5.3 What Can Be Tested Locally

| What | How |
|------|-----|
| Unit tests | `bun run test:run` — all utility, store, hook tests pass with mocked deps |
| E2E balance test | Playwright with mocked localStorage + mocked Sui RPC |
| Shared library build | `bun run typecheck && bun run build` |
| Component rendering | React Testing Library with jsdom |
| Store logic | Zustand stores with mocked storage adapters |
| Encryption/decryption | AES key derivation, SHA-256, PIN-based vault lock/unlock |

### 5.4 What Requires External Services

| Dependency | What Needs It | Why |
|------------|---------------|-----|
| **FusionAuth** (`auth.evefrontier.com`) | All login/auth flows | OAuth provider — no credentials = no login |
| **Enoki API** (`api.enoki.mystenlabs.com`) | zkLogin address derivation + ZK proofs | External prover service with API key |
| **Chrome browser** | Extension sideloading, `chrome.storage`, offscreen API | Extension-specific features |

### 5.5 What It Does NOT Provide

- **No Move contracts** — evevault is purely client-side (TypeScript/React)
- **No game state integration** — it maps identity but doesn't interact with world-contracts directly
- **No local zkLogin** — zkLogin proof generation depends on Enoki (external). Even with a local devnet, you can't generate valid zkLogin proofs without internet + API key
- **No character creation** — evevault maps `OAuth identity → Sui address`, but creating a `Character` object on-chain is a separate operation in world-contracts

### 5.6 Relevance to This Playground

evevault is **reference architecture** for understanding how EVE Frontier maps real player identities to Sui addresses. For local testing, you don't need evevault — you use direct keypairs from `.env.sui`. But understanding its auth flow is valuable if you're designing dApps or extensions that need to know how players authenticate.

---

## 6. builder-scaffold: What It Provides

**Package:** [vendor/builder-scaffold/](../vendor/builder-scaffold/) — the primary development environment.

### 6.1 Docker Environment (Production-Quality)

The Docker setup is the most complete component:

| File | Purpose |
|------|---------|
| [docker/compose.yml](../vendor/builder-scaffold/docker/compose.yml) | Single `sui-local` service with 5 volume mounts |
| [docker/Dockerfile](../vendor/builder-scaffold/docker/Dockerfile) | Ubuntu 24.04 + Node.js 24 + Sui CLI via `suiup` |
| [docker/scripts/entrypoint.sh](../vendor/builder-scaffold/docker/scripts/entrypoint.sh) | Container entrypoint — setup + start node |
| [docker/scripts/setup-local.sh](../vendor/builder-scaffold/docker/scripts/setup-local.sh) | First-run: create 3 keypairs, start node, fund accounts |
| [docker/scripts/common.sh](../vendor/builder-scaffold/docker/scripts/common.sh) | Shared utils: node start, faucet, PID management |
| [docker/scripts/switch-network.sh](../vendor/builder-scaffold/docker/scripts/switch-network.sh) | Switch between local ↔ testnet |

**Volume mounts:**
- `sui-keystore` (named volume) → `/root/.sui` — keystore persistence
- `./workspace-data` (bind mount) → `/workspace/data` — `.env.sui`, PID file
- `../move-contracts` → `/workspace/contracts` — edit on host, build in container
- `../ts-scripts` → `/workspace/ts-scripts` — edit on host, run in container

### 6.2 Scaffold Move Packages

Minimal templates at [move-contracts/](../vendor/builder-scaffold/move-contracts/):

| Package | Module | Function | Status |
|---------|--------|----------|--------|
| `gate` | `gate::gate` | `jump_through_gate()` | Empty stub — template for gate extensions |
| `storage_unit` | `storage_unit::storage_unit` | `template()` | Empty stub |
| `tokens` | `tokens::tokens` | `template()` | Empty stub |
| `hello_world` | — | — | Empty directory |

All tests are commented out. These are **starting points**, not working implementations.

### 6.3 zkLogin Interactive CLI

**Path:** [vendor/builder-scaffold/zklogin/zkLoginTransaction.ts](../vendor/builder-scaffold/zklogin/zkLoginTransaction.ts) (308 lines)

A complete working example of the EVE Frontier zkLogin flow:
1. Generate ephemeral Ed25519 keypair + nonce
2. Open OAuth URL (`test.auth.evefrontier.com`)
3. User logs in, copies `id_token` from redirect
4. Derive zkLogin address from JWT + salt
5. Fetch ZK proof from MystenLabs prover (`prover-dev.mystenlabs.com`)
6. Enter interactive transaction loop (sign + submit via zkLogin)

**Targets devnet** (not local). Requires internet for both OAuth and ZK prover.

**Dependencies:** `@mysten/sui`, `axios`, `jwt-decode`

### 6.4 Placeholders (Not Present)

| Directory | Status |
|-----------|--------|
| `ts-scripts/` | Readme only — no actual scripts |
| `rust-scripts/` | Readme only — no Rust code |
| `dapps/` | Readme only — no dApp code |
| `setup-world/` | Readme only — links to world-contracts but no automation |
| `docs/local-setup-for-mac.md` | Empty |
| `docs/local-setup-for-windows.md` | Empty |

---

## 7. ZK / Proximity Proof / Data Obfuscation: Is It Useful Here?

### 7.1 What's Already In The Repo (world-contracts)

**Location module** ([vendor/world-contracts/contracts/world/sources/primitives/location.move](../vendor/world-contracts/contracts/world/sources/primitives/location.move)):
- Locations are stored as **hashed coordinates** (privacy-preserving)
- `verify_proximity()` — checks if two locations are within range using server-signed Ed25519 proofs
- `verify_distance()` — validates distance between two points (used by gate linking)
- `verify_same_location()` — checks if an entity and a structure share the same location hash

**Signature verification** ([vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move](../vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move)):
- Ed25519 signature verification
- `verify_signature(message, signature, expected_address) → bool`
- `derive_address_from_public_key()` — derives Sui address from Ed25519 pubkey

**zkLogin in builder-scaffold** ([vendor/builder-scaffold/zklogin/](../vendor/builder-scaffold/zklogin/)):
- Full JS/TS example of zkLogin flow against EVE Frontier's OAuth
- Uses MystenLabs prover (external service)

### 7.2 eve-frontier-proximity-zk-poc (Groth16 PoC)

**Repo:** [vendor/eve-frontier-proximity-zk-poc/](../vendor/eve-frontier-proximity-zk-poc/) — by CCP Games (EVE Frontier)
**Pinned commit:** `4078e70`

This is a **working proof-of-concept** demonstrating a trustless alternative to server-signed proximity proofs — using client-generated Groth16 zero-knowledge proofs verified on-chain via `sui::groth16`. It is a standalone package — it does **not** import world-contracts — but uses the same spatial model (solar system, x/y/z coordinates, Ed25519 signing).

#### Architecture: Three Layers

```
┌─────────────────────────────────────────────────────────────┐
│  POD Layer — EDDSA-Poseidon signed attestation data          │
│  (Provable Object Datatypes: structured, signed claims)      │
├─────────────────────────────────────────────────────────────┤
│  Poseidon Merkle Tree — Unified hashing (on-chain + off)     │
│  Fields: objectId, solarSystem, x, y, z, timestamp, etc.     │
├─────────────────────────────────────────────────────────────┤
│  ZK Circuit Layer — Groth16 circuits (circom 2.2.0)          │
│  Verified on Sui via sui::groth16 (BN254 curve)              │
└─────────────────────────────────────────────────────────────┘
```

#### Two Circuits

**Location Attestation** ([location-attestation.circom](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/location-attestation/location-attestation.circom)):
- ~2,359 constraints; ~320ms proof generation
- Public inputs (3): `merkleRoot`, `coordinatesHash` (Poseidon(x,y,z,salt)), `signatureAndKeyHash`
- Private witness: raw x/y/z coordinates, salt, timestamp, Merkle siblings
- Proves: "I know coordinates whose Poseidon hash commits to this root, signed by an authorized key" — without revealing coordinates

**Distance Attestation** ([distance-attestation.circom](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/distance-attestation/distance-attestation.circom)):
- ~1,010 constraints; ~250ms proof generation
- Public inputs (5 + 1 output): two location Merkle roots, two coordinates hashes, distance² (squared Manhattan distance); outputs `maxTimestamp`
- Private witness: both sets of raw coordinates + salts, timestamps
- Proves: "The squared Manhattan distance between these two committed locations equals D" — without revealing either location

#### Move Modules (11 files)

| Module | File | Purpose |
|--------|------|---------|
| `location_attestation` | [sources/attestations/location_attestation.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move) | Groth16 verification + Merkle inclusion + Ed25519 sig check |
| `distance_attestation` | [sources/attestations/distance_attestation.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move) | Groth16 distance verify + location data cross-check |
| `object_registry` | [sources/registries/object_registry.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move) | Shared registry storing `LocationData` + `DistanceData` per object |
| `fixed_object` | [sources/assemblies/fixed_object.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/fixed_object.move) | Fixed-location objects (structures, stations) |
| `dynamic_object` | [sources/assemblies/dynamic_object.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/assemblies/dynamic_object.move) | Moving objects (ships, characters) |
| `location` | [sources/primitives/location.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/location.move) | `LocationData`, `LocationType` structs |
| `distance` | [sources/primitives/distance.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/distance.move) | `DistanceData` wrapper |
| `authority` | [sources/primitives/authority.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/authority.move) | `AdminCap`, `OwnerCap`, `ApprovedSigners` |
| `inventory` | [sources/primitives/inventory.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/primitives/inventory.move) | Mock transfer delegating to distance verification |
| `merkle_verify` | [sources/crypto/merkle/merkle_verify.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/crypto/merkle/merkle_verify.move) | On-chain Poseidon Merkle multiproof verification |
| `leaf_hash` | [sources/crypto/merkle/leaf_hash.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/crypto/merkle/leaf_hash.move) | Poseidon leaf hash (u64, bytes, address variants) |

**Key Sui framework dependencies:** `sui::groth16` (BN254 proof verification), `sui::poseidon` (`poseidon_bn254()`), `sui::ed25519`, `sui::derived_object`.

#### Key On-Chain Verification Functions

```move
// Location: verify a Groth16 proof + Merkle inclusions + Ed25519 signature
public fun verify_location_attestation(
    verification_data: &LocationAttestationData,
    vkey_bytes: vector<u8>,
    proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>
): LocationAttestationPublicData

// Distance: verify Groth16 proof + cross-check against stored LocationData
public fun verify_distance_attestation(
    object_id1: address, object_id2: address,
    vkey_bytes: vector<u8>, proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>,
    registry: &mut ObjectRegistry
)
```

Verification results (Merkle roots, coordinates hashes, distance², timestamps) are stored in `ObjectRegistry` as `LocationData` and `DistanceData`. Once proven between two fixed objects, distance is stored and reusable.

#### How It Relates to world-contracts

| Aspect | world-contracts (production) | ZK PoC (this repo) |
|--------|------------------------------|---------------------|
| Location storage | Hashed coordinates in `Location` struct | `LocationData` with Merkle root + coordinates hash |
| Proximity verification | `verify_proximity()` — Ed25519 server-signed proof | `verify_location_attestation()` — client-generated Groth16 proof |
| Distance verification | `verify_distance()` — server-signed proof | `verify_distance_attestation()` — client-generated Groth16 proof |
| Trust model | Trusted server signs all proofs | Reduced trust: client generates proof locally, but initial data attestation (POD) still requires an authorized signer |
| Privacy model | Coords hidden from chain (only hashes stored) | Same — plus the prover never reveals coords to a server either |
| Integration | Used by `link_gates()`, `deposit_by_owner()`, etc. | Standalone — no bridge to world-contracts yet |
| Shared patterns | `derived_object` for deterministic IDs, Ed25519 sig verify | Same Sui framework primitives |

**Key insight:** The ZK PoC **complements** the server-signed scheme — it doesn't replace it within world-contracts. A production integration would require bridging the PoC's `LocationData`/`DistanceData` into world-contracts' `Location` module, which does not exist yet.

#### Prerequisites to Run Locally

| Requirement | Purpose |
|-------------|---------|
| Node.js v20+ | Runtime for proof generation and tests |
| pnpm | Package manager |
| Rust (stable) | Builds the vkey-to-Arkworks serializer tool |
| circom compiler (v2.2.0+) | Compiles `.circom` → `.wasm` + `.r1cs` circuit artifacts |
| Sui CLI | Local devnet, package publishing |
| ~70 MB download | Powers of Tau ceremony file (Hermez, one-time) |

**Setup sequence:**
```bash
cd vendor/eve-frontier-proximity-zk-poc
pnpm install
pnpm generate-auth-key && pnpm generate-ed25519-key
pnpm circuit:fetch-ptau:on-chain       # Download ptau (~70MB, one-time)
pnpm circuit:compile:on-chain          # Compile circuits → wasm + zkey
pnpm move:test:generate:proof          # Generate test proof data for Move tests
pnpm move:build && pnpm move:test      # Build + run Move unit tests
pnpm test                              # Full JS/TS integration tests (starts local devnet)
```

**Trusted setup note:** The PoC uses a single-contribution Phase 2 ceremony (random entropy from `crypto.randomBytes(32)`). This is fine for testing but a production deployment would need a proper multi-party ceremony.

#### Devnet Topology

The ZK PoC's integration tests start their own native `sui start --with-faucet --force-regenesis` process on `http://127.0.0.1:9000` (hardcoded in [testSetup.ts](../vendor/eve-frontier-proximity-zk-poc/test/on-chain/integration/shared/testSetup.ts)). Builder-scaffold's Docker devnet also uses port 9000 internally, but since the compose file doesn't publish port 9000 to the host, **the two don't conflict by default**.

| Approach | Port | How it starts | Coexistence |
|----------|------|---------------|-------------|
| ZK PoC (`pnpm test`) | `127.0.0.1:9000` (native) | Auto-starts via `pnpm sui:localnet:start` if not running | Conflicts with Docker if Docker publishes port 9000 |
| builder-scaffold Docker | `127.0.0.1:9000` (inside container) | `docker compose run --rm sui-local` | Container-isolated; no host port binding by default |

**Recommended default:** Run the ZK PoC's native localnet for its own integration tests, and use builder-scaffold's Docker devnet separately for world-contracts work. Don't run both simultaneously if you've modified Docker to publish port 9000.

The ZK PoC has no `.env.example` — the RPC URL is hardcoded with no env-var override. Network selection for `pnpm move:publish` is via a `--network=` CLI flag (`localnet|devnet|testnet|mainnet`), but the test infrastructure only targets localnet.

#### Performance

| Metric | Location Circuit | Distance Circuit |
|--------|-----------------|------------------|
| Constraints | ~2,359 | ~1,010 |
| Proof generation | ~320ms | ~250ms |
| Public inputs | 3 (within Sui's 8-input limit) | 5 + 1 output (at Sui's limit) |

> Constraint counts and proof generation times are from the upstream README (commit `4078e70`). Actual proof times vary by hardware — these are indicative, not benchmarked.

### 7.3 What ZK Capabilities Are Now Available

| Capability | Status | What It Would Test |
|------------|--------|-----------------------|
| **Private location attestation** | **Available** (ZK PoC) | Prove location membership without revealing coordinates; Groth16 verified on-chain |
| **Private distance attestation** | **Available** (ZK PoC) | Prove squared Manhattan distance between two committed locations; Groth16 verified on-chain |
| **Poseidon Merkle commitments** | **Available** (ZK PoC) | Structured data commitment using on-chain `sui::poseidon` |
| **Server-signed proximity proofs** | **Available** (world-contracts) | Exercise the production code path by assuming a local signing authority |
| **Range proofs** | Not present | Prove "quantity ≥ N" without revealing exact amount — would need a new circuit |
| **ZK identity** | External dependency | zkLogin works but requires Enoki API (internet) |

### 7.4 What's Realistic vs Speculative

**Realistic (can exercise on local devnet today):**
- **Mock server-signed proofs** (world-contracts path) — generate an Ed25519 keypair, register it as "server address", sign `LocationProofMessage` structs, feed them to `link_gates()` / `deposit_by_owner()`. This exercises the exact production code path. It is not "simulation" — you are assuming the server's signing authority locally.
- **Generate and verify Groth16 location proofs** (ZK PoC path) — compile circuits, generate coordinates + salt, produce a proof in ~320ms, verify it on local devnet via `sui::groth16`. Fully local at runtime — no external services during proof generation or verification (one-time setup requires downloading ~70MB ptau file and installing circom + Rust).
- **Generate and verify Groth16 distance proofs** (ZK PoC path) — same, with two locations. Store verified distance in `ObjectRegistry`.
- **Poseidon Merkle tree operations** — build Merkle trees from POD entries, verify multiproofs on-chain.

**Would need new work (days, not weeks):**
- Bridge ZK PoC's `LocationData` into world-contracts' `Location` module so that `link_gates()` accepts a Groth16 proof instead of a server-signed proof. This requires modifying world-contracts, which is a vendor submodule — you'd fork or wrap it.
- Build a custom circuit for range proofs ("my inventory has ≥ N items").

**Speculative (significant effort):**
- Decentralized oracles for game state attestation — fundamentally different architecture.
- Full ZK identity without Enoki — would need a custom prover infrastructure.

### 7.5 Recommendation: Two Paths

**Path A — Fastest (mock server proofs, no new deps):**
1. Generate an Ed25519 keypair locally
2. Register it as a "server address" in `ServerAddressRegistry`
3. Sign `LocationProofMessage` structs with it
4. Use those proofs in `link_gates()`, `deposit_by_owner()`, `withdraw_by_owner()`

This exercises the production code path. You are not simulating a server — you are assuming its signing authority. The privacy model is the same as production: coordinates are hashed before going on-chain; the "server" (you) vouches for proximity.

**Path B — ZK PoC (requires circom + Rust + setup; fully local once set up):**
1. Install circom, compile circuits, download ptau, build vkey serializer
2. Generate location attestation data (POD + Merkle tree + Ed25519 signature)
3. Produce Groth16 proofs (~320ms per location, ~250ms per distance)
4. Publish the ZK PoC's Move package to local devnet
5. Verify proofs on-chain — the chain validates the math without seeing coordinates

This is the **reduced-trust** path: the prover never reveals coordinates to anyone, and the chain verifies the proof cryptographically. An authorized signer is still needed to attest the initial data (POD), but verification itself is trustless. It's more setup than Path A but demonstrates a genuinely different privacy model.

**Recommended starting point:** Path A (mocking server proofs) for immediate world-contracts integration testing. Then Path B (ZK PoC) as a standalone experiment to understand the Groth16 verification flow — it doesn't yet bridge into world-contracts but exercises the same spatial concepts.

---

## 8. Practical "Next Experiments" (Agent-Executable)

### Experiment 1: Deploy World Contracts to Local Devnet

**Touches:** `vendor/world-contracts/contracts/world/`
**Steps:**
1. Start devnet container
2. Inside container: `cd /workspace/contracts` — you'll need to copy or symlink the world-contracts package
3. `sui move build` the world package
4. `sui client publish --gas-budget 500000000 --json`
5. Extract `GovernorCap` ID, shared object IDs from publish output
**Success:** Package ID printed; `GovernorCap` owned by ADMIN address; shared objects (`AdminACL`, `ServerAddressRegistry`, `FuelConfig`, `EnergyConfig`, `GateConfig`, `ObjectRegistry`) visible via `sui client objects`.

### Experiment 2: Create a Character Object

**Touches:** `world::character`, `world::access`
**Steps:**
1. After deploying world contracts, extract shared object IDs
2. Create `AdminCap` using `GovernorCap`: call `access::create_admin_cap()`
3. Create Character for PLAYER_A: call `character::create_character()` with PLAYER_A's address
4. Share the character: call `character::share_character()`
**Success:** `Character` object visible as shared; `character_address` matches PLAYER_A.

### Experiment 3: Create and Online a Network Node

**Touches:** `world::network_node`, `world::fuel`, `world::energy`
**Steps:**
1. Configure fuel efficiency: `fuel::set_fuel_efficiency()`
2. Configure energy requirements: `energy::set_energy_config()`
3. Anchor a NetworkNode: `network_node::anchor()`
4. Share it: `network_node::share_network_node()`
5. Deposit fuel: `network_node::deposit_fuel()` (sponsored tx — add admin to ACL first)
6. Bring online: `network_node::online()`
**Success:** NetworkNode status changes to ONLINE; fuel state tracked.

### Experiment 4: Deploy a Smart Gate

**Touches:** `world::gate`, `world::network_node`, `world::energy`
**Steps:**
1. Anchor a Gate connected to the NetworkNode: `gate::anchor()`
2. Share it: `gate::share_gate()`
3. Create `OwnerCap<Gate>` for the character: `access::create_owner_cap()`
4. Transfer OwnerCap to character
5. Bring gate online: `gate::online()`
**Success:** Gate object exists with status ONLINE; has `owner_cap_id` linking to the player's character.

### Experiment 5: Link Two Gates & Execute a Jump

**Touches:** `world::gate`, `world::location`, `world::sig_verify`
**Steps:**
1. Deploy two gates (repeat Experiment 4 twice with different location hashes)
2. Register a local keypair as server address: `access::register_server_address()`
3. Sign a distance proof locally (use `generate-test-signature.ts` as reference)
4. Configure max distance: `gate::set_max_distance()`
5. Link gates: `gate::link_gates()` with both OwnerCaps + distance proof
6. Add admin to sponsor ACL: `access::add_sponsor_to_acl()`
7. Execute jump: `gate::jump()` as a sponsored transaction
**Success:** `JumpEvent` emitted with source/destination gate IDs and character.

### Experiment 6: Write a Custom Gate Extension

**Touches:** `move-contracts/gate/` (scaffold), world-contracts extension pattern
**Steps:**
1. In the scaffold `gate` package, add a dependency on the deployed world-contracts package
2. Implement a custom witness type (e.g., `struct MyAuth has drop {}`)
3. Write a `issue_my_permit()` function that calls `gate::issue_jump_permit<MyAuth>()`
4. Add custom logic (e.g., check tribe, check time, check payment)
5. Publish the extension package
6. Call `gate::authorize_extension<MyAuth>()` on an existing gate
7. Test `jump_with_permit()` with your custom permits
**Success:** Default `jump()` is blocked; only your extension can issue permits.

### Experiment 7: Mint Items into a Storage Unit

**Touches:** `world::storage_unit`, `world::inventory`
**Steps:**
1. Anchor and share a StorageUnit (like Experiment 4)
2. Bring it online
3. Call `game_item_to_chain_inventory()` as a sponsored tx to mint items
4. Inspect the StorageUnit's inventory via `sui client object`
**Success:** Items appear in the StorageUnit's inventory with correct type_id, quantity, volume.

### Experiment 8: Test Access Control Hierarchy

**Touches:** `world::access`
**Steps:**
1. With GovernorCap, create AdminCap for PLAYER_B
2. With AdminCap, attempt to create OwnerCap for an object PLAYER_B doesn't own
3. Transfer OwnerCap between addresses
4. Test `borrow_owner_cap` / `return_owner_cap` hot-potato pattern
5. Test unauthorized operations (wrong cap, wrong address)
**Success:** Authorized operations succeed; unauthorized operations abort with correct error codes.

### Experiment 9: Create a Killmail

**Touches:** `world::killmail`
**Steps:**
1. Call `killmail::create_killmail()` with admin cap
2. Inspect the killmail object
**Success:** Immutable shared `Killmail` object with all combat data fields populated; `KillmailCreatedEvent` emitted.

### Experiment 10: Assume Server Signing Authority End-to-End

**Touches:** `world::location`, `world::sig_verify`, TypeScript tooling
**Steps:**
1. Generate an Ed25519 keypair in TypeScript
2. Register the public key's derived address in `ServerAddressRegistry`
3. Construct a `LocationProofMessage` (BCS-encoded)
4. Sign it with the keypair
5. Use the proof in `deposit_by_owner()` on a StorageUnit
6. Verify the operation succeeds on local devnet
**Success:** The entire server-signed proof path works locally. You are not simulating the server — you are assuming its signing authority with a local keypair.

### Experiment 11: Compile ZK Circuits & Run Move Tests (ZK PoC)

**Touches:** `vendor/eve-frontier-proximity-zk-poc/` (read + run tests; do not modify)
**Prerequisites:** Node.js v20+, pnpm, Rust (stable), circom compiler
**Steps:**
1. `cd vendor/eve-frontier-proximity-zk-poc && pnpm install`
2. `pnpm generate-auth-key && pnpm generate-ed25519-key` — creates keypairs in `.env` (gitignored)
3. `pnpm circuit:fetch-ptau:on-chain` — downloads Powers of Tau (~70MB, one-time)
4. `pnpm circuit:compile:on-chain` — compiles circom → wasm + zkey artifacts
5. `pnpm move:test:generate:proof` — generates test proof vectors for Move tests
6. `pnpm move:build && pnpm move:test` — builds and runs Move unit tests with real Groth16 proofs
**Success:** All Move tests pass, confirming that `sui::groth16` verification works for both location and distance attestation circuits. ~2,359 constraints (location) and ~1,010 constraints (distance) verified on-chain.

### Experiment 12: Full ZK Location + Distance Flow on Local Devnet (ZK PoC)

**Touches:** `vendor/eve-frontier-proximity-zk-poc/` (read + run integration tests; do not modify)
**Prerequisites:** Same as Experiment 11 + local Sui devnet running
**Steps:**
1. Complete Experiment 11 (circuits compiled, Move package built)
2. `pnpm test` — runs the full integration test suite, which:
   - Starts a local Sui network
   - Publishes the ZK PoC Move package
   - Creates FixedObject and DynamicObject on-chain
   - Generates location attestation proofs (~320ms each)
   - Verifies proofs on-chain via `sui::groth16`
   - Generates distance attestation proof between two locations (~250ms)
   - Verifies distance on-chain and stores `DistanceData` in `ObjectRegistry`
   - Exercises the `inventory::transfer` flow gated by distance verification
**Success:** Integration tests pass. `LocationData` and `DistanceData` stored on-chain. Events emitted (`FixedObjectCreatedEvent`, `LocationUpdatedEvent`). Demonstrates privacy-preserving proximity verification on local devnet — proof verification is trustless, though initial data attestation still requires an authorized signer (managed via `ApprovedSigners`).

---

## 9. Appendix: Key Files and Entrypoints

### World Contracts — Move Modules

| Module | Path |
|--------|------|
| World init (GovernorCap) | [vendor/world-contracts/contracts/world/sources/world.move](../vendor/world-contracts/contracts/world/sources/world.move) |
| Access control (Governor/Admin/Owner caps) | [vendor/world-contracts/contracts/world/sources/access/access_control.move](../vendor/world-contracts/contracts/world/sources/access/access_control.move) |
| Character | [vendor/world-contracts/contracts/world/sources/character/character.move](../vendor/world-contracts/contracts/world/sources/character/character.move) |
| Assembly (base) | [vendor/world-contracts/contracts/world/sources/assemblies/assembly.move](../vendor/world-contracts/contracts/world/sources/assemblies/assembly.move) |
| Gate | [vendor/world-contracts/contracts/world/sources/assemblies/gate.move](../vendor/world-contracts/contracts/world/sources/assemblies/gate.move) |
| Storage Unit | [vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move](../vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move) |
| Network Node | [vendor/world-contracts/contracts/world/sources/network_node/network_node.move](../vendor/world-contracts/contracts/world/sources/network_node/network_node.move) |
| Inventory & Item | [vendor/world-contracts/contracts/world/sources/primitives/inventory.move](../vendor/world-contracts/contracts/world/sources/primitives/inventory.move) |
| Fuel | [vendor/world-contracts/contracts/world/sources/primitives/fuel.move](../vendor/world-contracts/contracts/world/sources/primitives/fuel.move) |
| Energy | [vendor/world-contracts/contracts/world/sources/primitives/energy.move](../vendor/world-contracts/contracts/world/sources/primitives/energy.move) |
| Location (hashed + proofs) | [vendor/world-contracts/contracts/world/sources/primitives/location.move](../vendor/world-contracts/contracts/world/sources/primitives/location.move) |
| Status lifecycle | [vendor/world-contracts/contracts/world/sources/primitives/status.move](../vendor/world-contracts/contracts/world/sources/primitives/status.move) |
| Metadata | [vendor/world-contracts/contracts/world/sources/primitives/metadata.move](../vendor/world-contracts/contracts/world/sources/primitives/metadata.move) |
| In-game ID (TenantItemId) | [vendor/world-contracts/contracts/world/sources/primitives/in_game_id.move](../vendor/world-contracts/contracts/world/sources/primitives/in_game_id.move) |
| Object Registry | [vendor/world-contracts/contracts/world/sources/registry/object_registry.move](../vendor/world-contracts/contracts/world/sources/registry/object_registry.move) |
| Signature verification | [vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move](../vendor/world-contracts/contracts/world/sources/crypto/sig_verify.move) |
| Killmail | [vendor/world-contracts/contracts/world/sources/killmail/killmail.move](../vendor/world-contracts/contracts/world/sources/killmail/killmail.move) |

### Extension Examples

| Module | Path |
|--------|------|
| Shared config + dynamic fields | [vendor/world-contracts/contracts/extension_examples/sources/config.move](../vendor/world-contracts/contracts/extension_examples/sources/config.move) |
| Gate extension (tribe-based) | [vendor/world-contracts/contracts/extension_examples/sources/gate.move](../vendor/world-contracts/contracts/extension_examples/sources/gate.move) |
| Tribe permit (shared config) | [vendor/world-contracts/contracts/extension_examples/sources/tribe_permit.move](../vendor/world-contracts/contracts/extension_examples/sources/tribe_permit.move) |
| Corpse gate bounty | [vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move](../vendor/world-contracts/contracts/extension_examples/sources/corpse_gate_bounty.move) |

### Builder Scaffold

| File | Purpose |
|------|---------|
| Docker compose | [vendor/builder-scaffold/docker/compose.yml](../vendor/builder-scaffold/docker/compose.yml) |
| Dockerfile | [vendor/builder-scaffold/docker/Dockerfile](../vendor/builder-scaffold/docker/Dockerfile) |
| Entrypoint | [vendor/builder-scaffold/docker/scripts/entrypoint.sh](../vendor/builder-scaffold/docker/scripts/entrypoint.sh) |
| Setup (first run) | [vendor/builder-scaffold/docker/scripts/setup-local.sh](../vendor/builder-scaffold/docker/scripts/setup-local.sh) |
| Network switcher | [vendor/builder-scaffold/docker/scripts/switch-network.sh](../vendor/builder-scaffold/docker/scripts/switch-network.sh) |
| Gate scaffold | [vendor/builder-scaffold/move-contracts/gate/sources/gate.move](../vendor/builder-scaffold/move-contracts/gate/sources/gate.move) |
| Storage unit scaffold | [vendor/builder-scaffold/move-contracts/storage_unit/sources/storage_unit.move](../vendor/builder-scaffold/move-contracts/storage_unit/sources/storage_unit.move) |
| zkLogin CLI | [vendor/builder-scaffold/zklogin/zkLoginTransaction.ts](../vendor/builder-scaffold/zklogin/zkLoginTransaction.ts) |

### World Contracts — TypeScript Scripts

| Script | npm command | Purpose |
|--------|------------|---------|
| Setup access | [ts-scripts/access/setup-access.ts](../vendor/world-contracts/ts-scripts/access/setup-access.ts) | `setup-access` — create AdminCap, register server, add sponsor |
| Create character | [ts-scripts/character/create-character.ts](../vendor/world-contracts/ts-scripts/character/create-character.ts) | `create-character` — creates 2 characters |
| Create NWN | [ts-scripts/network-node/create-nwn.ts](../vendor/world-contracts/ts-scripts/network-node/create-nwn.ts) | `create-nwn` — anchor a network node |
| Create gates | [ts-scripts/gate/create-gates.ts](../vendor/world-contracts/ts-scripts/gate/create-gates.ts) | `create-gates` — anchor 2 gates |
| Create SSU | [ts-scripts/storage-unit/create-storage-unit.ts](../vendor/world-contracts/ts-scripts/storage-unit/create-storage-unit.ts) | `create-storage-unit` — anchor a storage unit |
| Link gates | [ts-scripts/gate/link-gates.ts](../vendor/world-contracts/ts-scripts/gate/link-gates.ts) | `link-gates` — link 2 gates |
| Jump | [ts-scripts/gate/jump.ts](../vendor/world-contracts/ts-scripts/gate/jump.ts) | `jump` — execute a jump |
| Game → chain items | [ts-scripts/storage-unit/game-item-to-chain.ts](../vendor/world-contracts/ts-scripts/storage-unit/game-item-to-chain.ts) | `game-item-to-chain` — mint items |
| Configure fuel/energy | [ts-scripts/network-node/configure-fuel-energy.ts](../vendor/world-contracts/ts-scripts/network-node/configure-fuel-energy.ts) | `configure-fuel-energy` — set efficiency |
| Test signatures | [ts-scripts/location/generate-test-signature.ts](../vendor/world-contracts/ts-scripts/location/generate-test-signature.ts) | Generate test location proofs |
| Extract object IDs | [ts-scripts/utils/extract-object-ids.ts](../vendor/world-contracts/ts-scripts/utils/extract-object-ids.ts) | `extract-object-ids` — parse publish output |

### Playground Docs

| File | Purpose |
|------|---------|
| Quickstart | [docs/sui-playground.md](sui-playground.md) |
| This document | [docs/sui-playground-capabilities.md](sui-playground-capabilities.md) |
| Docs index | [docs/README.md](README.md) |
| Workspace abstract | [docs/WORKSPACE_ABSTRACT.md](WORKSPACE_ABSTRACT.md) |

### ZK Proximity PoC

| File | Purpose |
|------|---------|
| README | [vendor/eve-frontier-proximity-zk-poc/README.md](../vendor/eve-frontier-proximity-zk-poc/README.md) |
| Location circuit | [src/on-chain/circuits/location-attestation/location-attestation.circom](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/location-attestation/location-attestation.circom) |
| Distance circuit | [src/on-chain/circuits/distance-attestation/distance-attestation.circom](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/circuits/distance-attestation/distance-attestation.circom) |
| Location verification (Move) | [move/world/sources/attestations/location_attestation.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/location_attestation.move) |
| Distance verification (Move) | [move/world/sources/attestations/distance_attestation.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/attestations/distance_attestation.move) |
| Object registry (Move) | [move/world/sources/registries/object_registry.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/registries/object_registry.move) |
| Merkle verify (Move) | [move/world/sources/crypto/merkle/merkle_verify.move](../vendor/eve-frontier-proximity-zk-poc/move/world/sources/crypto/merkle/merkle_verify.move) |
| Location proof gen (TS) | [src/on-chain/proofs/utils/generateLocationProof.ts](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/proofs/utils/generateLocationProof.ts) |
| Distance proof gen (TS) | [src/on-chain/proofs/utils/generateDistanceProof.ts](../vendor/eve-frontier-proximity-zk-poc/src/on-chain/proofs/utils/generateDistanceProof.ts) |
| Integration tests | [test/on-chain/integration/](../vendor/eve-frontier-proximity-zk-poc/test/on-chain/integration/) |
| POD + Merkle utils | [src/shared/merkle/](../vendor/eve-frontier-proximity-zk-poc/src/shared/merkle/) |
| Key generation scripts | [scripts/generateAuthKey.ts](../vendor/eve-frontier-proximity-zk-poc/scripts/generateAuthKey.ts), [scripts/generateEd25519Key.ts](../vendor/eve-frontier-proximity-zk-poc/scripts/generateEd25519Key.ts) |

### Architecture Reference

| File | Purpose |
|------|---------|
| World contracts architecture | [vendor/world-contracts/docs/architechture.md](../vendor/world-contracts/docs/architechture.md) |
| World contracts deploy script | [vendor/world-contracts/scripts/deploy.sh](../vendor/world-contracts/scripts/deploy.sh) |
| World contracts env template | [vendor/world-contracts/env.example](../vendor/world-contracts/env.example) |
| evevault implementation | [vendor/evevault/docs/IMPLEMENTATION.md](../vendor/evevault/docs/IMPLEMENTATION.md) |
| evevault ADR | [vendor/evevault/docs/adr/001-hybrid-monorepo-structure.md](../vendor/evevault/docs/adr/001-hybrid-monorepo-structure.md) |
