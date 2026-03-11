# Shadow Broker Protocol — Validation Evidence

**Retention:** Prep-only

**Date:** 2026-03-11
**Network:** Local devnet (Move Phase 1) / Sui Testnet + Walrus Testnet + Seal Testnet (Phases 2–4)
**Sui CLI version:** 1.66.1-bac3f508b83b-dirty
**Active address:** `0xacff13b0630890ac9de62c57ec542de7cad8778aec1fe24f9db19f2457ad54b1`
**Validation scripts:** `sandbox/shadow-broker-validation/ts-scripts/` (on-chain-smoke.ts, walrus-smoke.ts, seal-smoke.ts, e2e-smoke.ts)
**Validation plan:** `docs/operations/shadow-broker-validation-plan.md` (all 5 phases COMPLETED)

---

## Summary

All 5 validation phases passed. The Shadow Broker Protocol's technical stack — Move contracts, Walrus blob storage, and Seal threshold encryption — is proven working end-to-end. This document captures the evidence and SDK patterns needed to build the hackathon submission without re-running validation.

---

## Move Layer (Phase 1 — Local Devnet)

- **Package published (local):** `0x2966ff1c877047b4d0eb434e66b493051036348ef8517d250c9d766c2c395372`
- **Unit tests:** 9/9 PASS
- **On-chain smoke (local):**
  - Mint: digest `HWnPbF2jFRnJeic5uDFjDnmQQ3gDeKVfdrhF57AW6YrR`
  - List: digest `WaEjzDftPyM3S3Qr5mtaDcuiwTzjr3SqcSf3xG2nCTe`
  - Purchase: digest `DhRiLMCTHYzYaJLEwMkbTm65dzWUyGuTJhLXPhzncE9`
  - IntelObject recovery: PASS

## Walrus Layer (Phase 2 — Testnet)

- **Upload 1 (encrypted blob):** blobId = `AuP6ajVZ0N-xFNR5C4fMrW0sFz5fr7bdYACeoTweFhw`, 1024 bytes
- **Upload 2 (teaser):** blobId = `W8wNRij8_k_4EkighLgv9Z72J-iPjNhxE4DzB9ANc9c`, 100 bytes
- **Download + verify:** PASS (byte-for-byte match for both blobs)
- **WAL exchange:** 0.5 SUI → ~500M WAL via `wal_exchange::exchange_all_for_wal`

## Seal Layer (Phase 3 — Testnet)

- **Package published (testnet):** `0xce7be48d01f8d176adebb7dc59ee09ef8d4b67f93946cfcf1c8ab570932c75a8`
- **UpgradeCap:** `0x4003e8f2e177ba5d19baa35783faa104f4238a542d85e9ccf3cb0d45a4a84fce`
- **Key servers:** `0x73d05d62c18d9374e3ea529e8e0ed6161da1a141a94d3f76ae3fe4e99356db75`, `0xf5d14a81a982144ae441cd7d64b09027f116a468bd36e7eca494f750591623c8`
- **Encrypt:** 380 bytes, PASS
- **Decrypt:** 32 bytes recovered, matches original AES key, PASS
- **Critical finding:** `tx.build({ client, onlyTransactionKind: true })` is required for decrypt PTB — full TransactionData BCS causes "Invalid PTB: Invalid BCS" from key servers

## End-to-End Pipeline (Phase 4 — Testnet)

**13/13 steps PASS — 70.2s total**

| Step | Name | Status | Duration |
|------|------|--------|----------|
| 1 | Generate AES key + audio | PASS | 0ms |
| 2 | AES-GCM encrypt audio | PASS | 3ms |
| 3 | Upload encrypted audio to Walrus | PASS | 22,721ms |
| 4 | Upload teaser to Walrus | PASS | 19,029ms |
| 5 | Mint IntelObject | PASS | 1,238ms |
| 6 | Seal encrypt AES key | PASS | 937ms |
| 7 | Update encrypted_key on-chain | PASS | 1,368ms |
| 8 | List on marketplace | PASS | 1,288ms |
| 9 | Purchase listing | PASS | 1,113ms |
| 10 | Download teaser + verify | PASS | 6,511ms |
| 11 | Seal decrypt AES key | PASS | 1,681ms |
| 12 | Download encrypted audio | PASS | 5,991ms |
| 13 | AES-GCM decrypt + verify | PASS | 12ms |

**E2E IntelObject:** `0x4541ba83a53746cd539e0a5ff0a035613fdf76fe28bbb3a5cbd28150551df620`
**E2E Listing:** `0x2b7ac80cb552bec81ef918d475b39cf53ca379d2467cd9d91b0546a60d03794c`

## Blockers Discovered

None — all phases passed. Key learnings documented below.

## SDK Notes (for hackathon build)

### WalrusClient
- **Constructor:** `new WalrusClient({ network: 'testnet', suiClient, packageConfig: TESTNET_WALRUS_PACKAGE_CONFIG })`
- **Upload:** `walrus.writeBlob({ blob, deletable: true, epochs: 3, signer: keypair })` → `{ blobId }`
- **Download:** `walrus.getBlob({ blobId })` → `blob.asFile().bytes()` → `Uint8Array`
- **WAL tokens required:** Exchange SUI→WAL via `wal_exchange::exchange_all_for_wal`
- **Latency:** ~20s per upload for small blobs (testnet)

### SealClient
- **Constructor:** `new SealClient({ suiClient, serverConfigs: [{ objectId, weight }], verifyKeyServers: false })`
- NOT `serverObjectIds` — the original spec is outdated
- **Encrypt:** `sealClient.encrypt({ threshold: 2, packageId, id: idHex, data })` — `id` must be hex string (object address without `0x` prefix)
- **Decrypt PTB:** `tx.build({ client: suiClient, onlyTransactionKind: true })` — CRITICAL, do NOT use default `build()` which produces full TransactionData BCS
- **SessionKey:** `new SessionKey({ address, packageId, ttlMin })` → `keypair.signPersonalMessage(sessionKey.getPersonalMessage())` → `sessionKey.setPersonalMessageSignature(signature)`
- **Latency:** ~1-2s for decrypt (key server round-trip)

### Keypair Loading (from Sui keystore)
- Load from `~/.sui/sui_config/sui.keystore` (JSON array of base64 strings)
- `Buffer.from(entry, 'base64')` → skip byte 0 (scheme flag) → `Ed25519Keypair.fromSecretKey(bytes.subarray(1))`
- Do NOT use `decodeSuiPrivateKey` with raw keystore entries

### Object Content Reading
- `suiClient.getObject({ id, options: { showContent: true } })` → `.data.content.fields` for JSON
- `suiClient.core.getObject({ objectId, include: { content: true } })` returns BCS bytes, not parsed JSON

### AES-GCM Pattern
- 12-byte IV prepended to ciphertext: `[iv | ciphertext]`
- `webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['encrypt'|'decrypt'])`
- Combined blob = iv + ciphertext for simple storage on Walrus
