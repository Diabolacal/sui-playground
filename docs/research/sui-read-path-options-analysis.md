# Sui Blockchain Read-Path Options Analysis — Hackathon Demo

**Retention:** Prep-only

> **Generated:** 2026-03-05 UTC
> **Source:** Derived from Sui official docs (docs.sui.io), EVE Frontier builder docs (docs.evefrontier.com), workspace local docs, web research
> **Non-canonical; may become stale.** Verify against primary sources before relying on specifics.
>
> **Purpose:** Structured analysis of Sui read-path infrastructure for CivilizationControl hackathon demo (March 11 deadline)

---

## A) suix_queryEvents JSON-RPC

### Request/Response Format

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_queryEvents",
  "params": [
    { "MoveEventType": "0xPKG::gate::JumpEvent" },
    null,
    10,
    false
  ]
}
```

Parameters (positional):
1. **EventFilter** — filter object (see below)
2. **cursor** — opaque cursor from previous response (`null` for first page)
3. **limit** — max events per page (integer)
4. **descending** — `true` for newest-first, `false` for oldest-first (boolean)

**Response:**
```json
{
  "result": {
    "data": [
      {
        "id": { "txDigest": "...", "eventSeq": "0" },
        "packageId": "0x...",
        "transactionModule": "gate",
        "sender": "0x...",
        "type": "0xPKG::gate::JumpEvent",
        "parsedJson": { "source_gate_id": "0x...", "character_id": "0x...", ... },
        "bcs": "...",
        "timestampMs": "1709654321000"
      }
    ],
    "nextCursor": { "txDigest": "...", "eventSeq": "0" },
    "hasNextPage": true
  }
}
```

### Filtering Capabilities

| Filter | Format | Description |
|--------|--------|-------------|
| `All` | `{"All": []}` | All events (no filter) |
| `Transaction` | `{"Transaction": "digest"}` | Events from a specific tx |
| `MoveModule` | `{"MoveModule": {"package": "0x...", "module": "gate"}}` | Events emitted from a specific module |
| `MoveEventModule` | `{"MoveEventModule": {"package": "0x...", "module": "gate"}}` | Events defined in a specific module |
| `MoveEventType` | `{"MoveEventType": "0x...::gate::JumpEvent"}` | Events of a specific struct type |
| `Sender` | `{"Sender": "0x..."}` | Events from a specific sender address |
| `TimeRange` | `{"TimeRange": {"startTime": ms, "endTime": ms}}` | Events in a time window |
| `Any` | `{"Any": [filter1, filter2, ...]}` | OR composition of filters |

### Cursor Pagination

- Cursor-based, NOT block-range based (unlike Ethereum's `eth_getLogs`)
- Cursor is opaque — obtained from `nextCursor` in previous response
- Pass `null` cursor for first page
- `hasNextPage` indicates more results available
- Consistent pagination window: ~1 hour (per Sui GraphQL docs; JSON-RPC similar)
- Track cursor between polls to avoid re-fetching

### Known Limitations

1. **No field-level filtering** — Cannot query "all JumpEvents for gate X". Must fetch ALL events of a type and filter client-side by gate ID
2. **TimeRange filter is deprecated** — Sui recommends cursor-based pagination instead. TimeRange still works on JSON-RPC but not available in GraphQL
3. **No compound AND filters** — Only `Any` (OR) composition is available. Cannot combine MoveEventType AND Sender in a single query
4. **Pruning behavior** — Events are indexed by full nodes and subject to retention/pruning. Retention window depends on the RPC provider's configuration (typically 30-90 days on public endpoints, could be shorter)
5. **Failed transactions emit NO events** — MoveAbort discards all events. Only tx digest + abort code survive
6. **Events are NOT on-chain objects** — They are ephemeral, emitted during execution, indexed by full nodes. No Merkle proof of event inclusion
7. **JSON-RPC is officially deprecated** — Migration to GraphQL or gRPC required by July 2026. Still functional for now

### Public RPC Compatibility

- **Works on public Sui full node endpoints** (e.g., `https://fullnode.mainnet.sui.io:443`)
- Public endpoints are rate-limited and "not meant for production-grade use" per Sui docs
- For hackathon demo (single user): well within rate limits (~6 queries per 10s polling cycle)
- For production (500+ users): requires dedicated RPC or caching proxy

### Hackathon Viability: **HIGH**

This is the **recommended MVP approach**. Zero infrastructure required — just HTTP POST from browser. Proven pattern documented in builder-scaffold and EVE Frontier official docs.

---

## B) Sui GraphQL API

### Current Availability

| Network | Endpoint | Status |
|---------|----------|--------|
| **Mainnet** | `https://graphql.mainnet.sui.io/graphql` | Available (public good, rate-limited) |
| **Testnet** | `https://graphql.testnet.sui.io/graphql` | Available (public good, rate-limited) |
| **Devnet** | `https://graphql.devnet.sui.io/graphql` | Available |
| **Localnet** | Not available by default | Requires self-hosted indexer stack |
| **Custom** | Self-hosted via `sui-indexer-alt-graphql` | Requires Postgres + indexer + consistent store |
| **EVE Frontier hackathon server** | **Unknown** | Must validate March 11 |

### Event Query Capabilities

GraphQL supports event queries via the `events` connection on `Query`:

```graphql
query {
  events(
    filter: {
      emittingModule: "0xPKG::gate"
      eventType: "0xPKG::gate::JumpEvent"
      sender: "0x..."
    }
    first: 10
    after: "cursor..."
  ) {
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      sendingModule { name }
      type { repr }
      sender { address }
      timestamp
      json
      bcs
    }
  }
}
```

**Event filters available in GraphQL:**
- `emittingModule` — filter by package::module
- `eventType` — filter by full event struct type
- `sender` — filter by sender address
- `transactionDigest` — filter by specific tx
- **No field-level filtering** (same limitation as JSON-RPC)
- **No native time-range filter** — use cursor pagination with checkpoint scoping

### Object Query Capabilities

GraphQL object queries are significantly richer than JSON-RPC:
- Fetch objects by address, type, owner
- Nested dynamic field lookups in a single query (major advantage)
- Time-travel queries via checkpoint scoping
- Batch fetch with pagination
- Live object set queries (objects by owner kind + type)

### Rate Limits & Access Restrictions

- Public endpoints (mainnet, testnet) are rate-limited per minute
- Query complexity limits: max depth, max nodes, max output nodes, max payload size
- Rich queries (paginated object/event/tx queries) have a per-request limit (`maxRichQueries`)
- "Not meant for production-grade use" — Sui Foundation public good
- Third-party RPC providers offer dedicated GraphQL endpoints with higher limits

### Could It Replace suix_queryEvents?

**Yes, for most use cases.** GraphQL is the intended successor. Advantages:
- Single request can fetch events + related objects (fewer round trips)
- Checkpoint-scoped queries for consistent reads
- Richer filtering on transactions (by function, affected object, affected address)
- Better pagination with `before`/`after`/`first`/`last`

**Caveats:**
- Availability on EVE Frontier hackathon server is unconfirmed
- GraphQL requires the full indexer stack behind it (Postgres + indexer + consistent store)
- JSON-RPC `suix_queryEvents` works against any full node without additional infrastructure
- Currently in beta — schema may change

### Retention

| Data Source | Query Types | Retention |
|-------------|-------------|-----------|
| Consistent store | Object ownership, balances, dynamic fields | ~1 hour |
| Database store | Transactions, events, checkpoints | ~30-90 days |
| Archival service | Point lookups (tx by digest, object by ID+version) | Indefinite (if configured) |

### Example Event Query

```graphql
query RecentJumpEvents {
  events(
    filter: {
      eventType: "0xPKG::gate::JumpEvent"
    }
    last: 20
  ) {
    pageInfo {
      hasPreviousPage
      startCursor
    }
    nodes {
      timestamp
      json
      sendingModule { name }
      sender { address }
    }
  }
}
```

### Hackathon Viability: **MEDIUM**

Worth attempting as a Day 1 validation (15 min test). If the hackathon RPC exposes a GraphQL endpoint, it provides richer queries. But don't depend on it — `suix_queryEvents` is the safer fallback.

---

## C) suix_subscribeEvent WebSocket

### Availability

- **Protocol:** JSON-RPC over WebSocket
- **Endpoint pattern:** `ws://<fullnode>:443/websocket` or `wss://<fullnode>/websocket`
- **Public endpoint availability:** **Varies by provider.** Not all public full nodes expose WebSocket endpoints
- **Sui official public nodes:** WebSocket support is inconsistent — some providers enable it, others don't
- **Localnet:** Available (Sui local node exposes WS by default)
- **EVE Frontier hackathon server:** **Unknown — must validate March 11**

### Request Format

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "suix_subscribeEvent",
  "params": [
    { "MoveEventType": "0xPKG::gate::JumpEvent" }
  ]
}
```

Uses the same EventFilter syntax as `suix_queryEvents`. Returns a subscription ID. Events are pushed as they occur.

### Reliability for Demo

| Aspect | Assessment |
|--------|-----------|
| **Latency** | Near-real-time (sub-second after finality) — best UX of any option |
| **Connection stability** | WebSocket connections can drop. Requires reconnection logic + cursor catch-up |
| **Missed events** | If connection drops, events during the gap are lost. Must combine with polling backfill |
| **Browser support** | Native WebSocket API, but CORS/TLS can be tricky depending on endpoint |
| **Demo risk** | MEDIUM-HIGH — if the hackathon endpoint doesn't support WS, the entire mechanism fails |

### Known Issues

1. **JSON-RPC deprecation** applies to WebSocket subscriptions too — expected to be replaced by GraphQL subscriptions
2. **No reconnection/replay** built-in — if connection drops, you must poll to catch up
3. **Single-event-type per subscription** — need one WS subscription per event type you're monitoring
4. **Memory pressure** — high-volume event types (e.g., all JumpEvents network-wide) could overwhelm the client

### Hackathon Viability: **LOW (stretch goal)**

The read-path validation doc already flags this as a stretch goal. Polling with `suix_queryEvents` at 10s intervals provides sufficient "real-time" feel for a demo. WebSocket adds complexity and fragility without proportional demo benefit.

---

## D) Self-Hosted Indexer Options

### Option D1: Sui Official Indexer Stack (`sui-indexer-alt`)

**Components required:**
- `sui-indexer-alt` — Rust binary that reads checkpoints and writes to Postgres
- `sui-indexer-alt-consistent-store` — RocksDB-based store for live object queries
- `sui-indexer-alt-graphql` — GraphQL server reading from Postgres + consistent store
- PostgreSQL database (Postgres-compatible, e.g., vanilla Postgres or AlloyDB)
- Full node or remote checkpoint store access

**Resource Requirements:**
| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| Indexer | 2 cores/instance | 4 GB/instance | — |
| Consistent store | 8 cores | 32 GB | RocksDB (variable) |
| GraphQL server | 2 cores/instance | 4 GB/instance | — |
| Postgres DB | 6 cores | 48 GB | 30-day: ~2 TB; 90-day: ~3.2 TB |

**Setup Complexity:** Very high. Multiple services, Postgres schema, checkpoint bootstrapping (days for mainnet backfill from genesis), configuration TOML files.

**Estimated Setup Time:** 2-4 days minimum for a production deployment. Not viable for hackathon.

**Operational Complexity:** High — monitoring, pruning, backup, schema migrations.

### Option D2: Custom Event Ingestor (Poll + Store)

**Pattern:** A lightweight Node.js/Deno service that:
1. Polls `suix_queryEvents` every 10s for monitored event types
2. Stores events in SQLite/Postgres with structure ID indexing
3. Caches object state with TTL
4. Serves filtered results via simple REST API

**Components:**
- Node.js/Deno runtime
- SQLite (file-based, zero config) or Postgres (if >7 day retention needed)
- ~200 lines of code

**Resource Requirements:**
- CPU: <1 core
- Memory: <512 MB
- Storage: <100 MB for SQLite (last 7 days of events for a small deployment)

**Setup Complexity:** Low-Moderate. No external schemas, no checkpoint streaming, no Rust compilation.

**Estimated Setup Time:** 4-6 hours for a working implementation.

**Operational Complexity:** Low — single process, simple monitoring via `/health` endpoint.

**This is Option B from the read-path architecture validation doc.** The thin backend pattern.

### Option D3: Lightweight Polling Cache (Browser-Only + IndexedDB)

**Pattern:** No backend at all. Browser directly polls `suix_queryEvents`, caches results in IndexedDB.

**Components:**
- Browser app only
- IndexedDB for event cache persistence across page reloads
- In-memory cursor tracking

**Resource Requirements:** Zero server-side.

**Setup Complexity:** Lowest possible.

**Estimated Setup Time:** 2-3 hours (event polling + IndexedDB cache is <150 lines).

**Operational Complexity:** Zero — no server to maintain.

**Limitations:**
- No cross-session aggregation (each browser is independent)
- Rate limits apply per browser instance (fine for demo, not for 500 users)
- Events older than RPC retention window are lost

### Comparison Matrix

| Option | Setup Time | Server Cost | Max Users | Historical Data | Hackathon Viable |
|--------|-----------|-------------|-----------|-----------------|-----------------|
| D1: Official indexer | 2-4 days | $200+/mo | Unlimited | Full history | **NO** |
| D2: Custom ingestor | 4-6 hours | $5-20/mo VPS | 500+ | 7-day rolling | **YES (Stillness)** |
| D3: Browser-only cache | 2-3 hours | $0 | 1-10 | Session only | **YES (Demo MVP)** |

---

## E) EVE Frontier Specific

### Does EVE Frontier Run Any Public Indexer or GraphQL Endpoint?

**No.** Based on comprehensive workspace analysis:

- **No CCP/EVE Frontier event indexing service exists.** Only confirmed CCP APIs:
  - Sponsored transaction API: `api.{tier}.tech.evefrontier.com/transactions/sponsored/...`
  - Auth server: `auth.evefrontier.com`
- **No GraphQL endpoint** provided by EVE Frontier
- **No gRPC streaming service** from EVE Frontier
- The event surface doc explicitly states: "No event indexer or streaming service exists in the EVE Frontier builder ecosystem"

### What Does builder-scaffold Provide for Data Reads?

The `vendor/builder-scaffold/` provides:

1. **TS scripts with inline event extraction** — `executeTransactionBlock({ showEvents: true })` + `extractEvent<T>()` helper. This only captures events from YOUR OWN transactions (synchronous, no historical)
2. **React dApp starter** (`vendor/builder-scaffold/dapps/`) — uses `@evefrontier/dapp-kit` with basic assembly info queries and wallet status components
3. **No event polling code** — zero implementation of `suix_queryEvents` anywhere in builder-scaffold
4. **No historical event query code** — the only event consumption is synchronous post-tx extraction

### Any dapp-kit Utilities for Event Queries?

Based on `@evefrontier/dapp-kit` (version ^0.1.0, docs at `http://sui-docs.evefrontier.com/`):

- **No dedicated event query utilities.** The dapp-kit focuses on:
  - Wallet connection (Sui Wallet Standard)
  - Transaction building and signing
  - Sponsored transaction flow  
  - Assembly info queries (by object ID)
- **No `getCharacterByAddress()` equivalent confirmed** — SDK docs incomplete
- **Underlying client:** Uses `@mysten/dapp-kit-react` which provides standard Sui RPC access. Event queries would go through the underlying `SuiClient`/`SuiJsonRpcClient`/`SuiGrpcClient` directly

### EVE Vault GraphQL Usage

`vendor/evevault/` includes:
- `SuiGraphQLClient` — but used only for **transaction history** (balance changes), NOT for event queries
- `SuiGrpcClient` — for standard RPC operations (build tx, get objects), no event-specific gRPC

---

## Structured Assessment

### 1. Capabilities and Limitations Summary

| Approach | Event Query | Object Query | Field Filter | Time Range | Historical | Real-time |
|----------|------------|-------------|-------------|-----------|-----------|----------|
| `suix_queryEvents` | Full (by type, module, sender, tx) | No | No | Deprecated filter exists | Cursor-based, pruned | Polling only |
| GraphQL API | Full (richer filters) | Yes (nested, dynamic fields) | No | Via checkpoint scoping | 30-90 day retention | Polling only |
| WebSocket | Push events by type | No | No | No (live only) | No | Yes |
| Official indexer | Full (SQL queries) | Full | Yes (SQL WHERE) | Yes | Configurable retention | Via GraphQL |
| Custom ingestor | Via polling upstream | Via caching | Yes (your DB schema) | Yes (your schema) | Your retention policy | Polling |
| Browser-only | Via polling | Via polling | Client-side JS | Client-side JS | Session only | Polling |

### 2. Setup Complexity (Hours to Implement)

| Approach | Setup Hours | Code Complexity | Dependencies |
|----------|------------|----------------|-------------|
| `suix_queryEvents` polling | **2-3 hours** | ~100-150 lines TS | None (HTTP POST) |
| GraphQL event queries | **3-4 hours** | ~150-200 lines TS | GraphQL client lib |
| WebSocket subscription | **4-6 hours** | ~200-300 lines TS (reconnection, backfill) | WebSocket API |
| Official indexer stack | **48-96 hours** | Complex infra | Rust, Postgres, RocksDB, checkpoint store |
| Custom ingestor backend | **4-6 hours** | ~200 lines Node/Deno | SQLite or Postgres |
| Browser-only + IndexedDB | **2-3 hours** | ~100-150 lines TS | None |

### 3. Suitability for Hackathon Demo (March 11 Deadline)

| Approach | Demo Suitability | Why |
|----------|-----------------|-----|
| `suix_queryEvents` polling | **EXCELLENT** | Zero infra, works on any Sui RPC, 10s polling feels real-time for demo |
| GraphQL event queries | **GOOD** (if available) | Richer queries, but availability on hackathon RPC unconfirmed |
| WebSocket subscription | **POOR** | Fragile, unconfirmed availability, adds complexity without proportional demo value |
| Official indexer | **NOT VIABLE** | 2-4 day setup competes with feature development time |
| Custom ingestor | **GOOD (for Stillness)** | Worth building post-demo if >10 concurrent users expected |
| Browser-only + IndexedDB | **EXCELLENT** | Zero cost, zero ops, perfect for single-user demo |

### 4. Risk Factors

| Approach | Primary Risks |
|----------|---------------|
| `suix_queryEvents` | RPC pruning loses old events; no field-level filter requires client-side filtering; JSON-RPC deprecated (but functional until July 2026) |
| GraphQL | May not be available on hackathon endpoint; beta API could have schema changes; requires indexer backend |
| WebSocket | Connection drops with no replay; availability varies by provider; deprecated alongside JSON-RPC |
| Official indexer | Resource overkill; multi-day setup; requires Postgres expertise; storage costs |
| Custom ingestor | Additional deployment surface (VPS); must handle cursor state persistence; polling delay |
| Browser-only | No cross-browser aggregation; IndexedDB eviction risk; rate limits at scale |

### 5. Recommendation for Hackathon MVP

#### Primary Path: Browser-Only Polling with `suix_queryEvents`

**This is the clear winner for the hackathon demo.** Rationale:

1. **Zero infrastructure** — eliminates deployment risk entirely
2. **Proven pattern** — documented in EVE Frontier builder docs with exact curl examples
3. **Sufficient for single-user demo** — 10s polling with cursor tracking provides "real-time" feel
4. **~2-3 hours to implement** — polling loop + cursor management + client-side filtering
5. **Real on-chain data** — every event shown in the demo has a verifiable tx digest

**Implementation pattern:**
```typescript
// Polling loop (every 10 seconds)
let cursor: string | null = null;

async function pollEvents(eventType: string) {
  const response = await client.queryEvents({
    query: { MoveEventType: eventType },
    cursor,
    limit: 50,
    order: 'ascending'
  });
  
  if (response.data.length > 0) {
    cursor = response.nextCursor;
    // Filter client-side by owned gate/SSU IDs
    const relevant = response.data.filter(e => 
      ownedStructureIds.has(e.parsedJson.source_gate_id)
    );
    appendToSignalFeed(relevant);
  }
}
```

#### Day 1 Validation Steps (March 11)

| # | Test | Time | Fallback |
|---|------|------|----------|
| 1 | `suix_queryEvents` with `MoveEventType` filter works on hackathon RPC | 15 min | Fatal if fails — Signal Feed dead |
| 2 | GraphQL endpoint exists at hackathon RPC | 15 min | Use JSON-RPC only |
| 3 | WebSocket endpoint exists | 15 min | Stay with polling |
| 4 | Event retention window > 1 hour | 15 min | Events survive demo session |
| 5 | Character resolution via `CharacterCreatedEvent` | 30 min | Manual ID fallback |

#### Stillness Upgrade Path (Post-Demo)

If the submission reaches Stillness deployment with >10 concurrent users, deploy **Option D2 (Custom Ingestor)**:
- Node.js/Deno cache proxy on a $5/mo VPS
- Single source of RPC queries regardless of user count
- Pre-computed revenue aggregates
- Character resolution cache
- 4-6 hours implementation
- REST API: `/structures`, `/events`, `/revenue`, `/health`

---

## Key Takeaways

1. **Sui is NOT Ethereum.** No `eth_getLogs` block-range scan. No field-level event filtering. No events from failed transactions. Cursor-based pagination only.
2. **JSON-RPC is deprecated but functional.** `suix_queryEvents` works today and will work through July 2026. Use it for the hackathon.
3. **GraphQL is the future** but requires indexer infrastructure behind it. Public endpoints exist for mainnet/testnet but hackathon server availability is unknown.
4. **No EVE Frontier event infrastructure exists.** Builders are on their own for event consumption. The only pattern in the ecosystem is synchronous tx-inline extraction.
5. **Browser-only polling is the correct hackathon architecture.** Zero deployment risk, minimal code, real on-chain data. Upgrade to thin backend only if scale demands it.
6. **A read provider abstraction layer insulates the UI from transport changes.** JSON-RPC deprecation (July 2026), potential GraphQL migration, and scaling to a backend proxy are all deployment-time provider swaps — not UI rewrites. The same abstraction enables a synthetic Demo Provider for repeatable demo recording and post-launch showcase. See [Read Provider Abstraction](../architecture/read-provider-abstraction.md).

---

*Analysis performed: 2026-03-05. Sources: docs.sui.io (GraphQL RPC, Using Events, Indexer Stack Setup, Custom Indexing Framework), docs.evefrontier.com (Interfacing with the World), workspace local docs (read-path-architecture-validation.md, world-contracts-event-surface.md, sui-documentation-reference-map.md, evefrontier-builder-docs-map.md).*
