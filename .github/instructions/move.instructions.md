---
description: "Sui Move conventions for CivilizationControl hackathon workspace"
applyTo: "**/*.move"
---

# Move Code — Workspace Conventions

> **Revalidate against latest world-contracts on hackathon test server (March 11+).**
> These are agent guardrails, not canonical truth. Authority hierarchy:
> `vendor/world-contracts` code > SUI docs > spec.md > this file.

## Core Rules

- **Never assume function signatures.** Always verify against the current `vendor/world-contracts` commit before generating call sites. Signatures change between releases (e.g., `link_gates` gained AdminACL in v0.0.13).
- **Extension witness must be `public(package)`, not `public`.** The `x_auth()` function that mints your Auth witness type must use `public(package)` to prevent external packages from forging it. (`builder-scaffold` is correct; `extension_examples` is insecure.)
- **Dynamic fields: use typed key structs, not strings.** Define explicit `has copy, drop, store` key structs (e.g., `TollConfigKey`) rather than raw `vector<u8>` or `String` keys. This prevents key collisions and aids discoverability.
- **Hot-potato discipline: borrow and return in the same PTB.** `borrow_owner_cap<T>` returns an `OwnerCap` that must be returned via `return_owner_cap<T>` in the same transaction. Never store or transfer a borrowed cap.
- **MoveAbort emits no events.** Do not rely on events for proof-of-execution in flows that may abort. Use transaction digest + effects as the evidence path. See `docs/ptb/proof-extraction-moveabort.md`.
- **Prefer explicit error codes.** Define errors with `#[error(code = N)]` and descriptive `vector<u8>` messages. Keep codes sequential within each module.

## Structure & Style

- **Module organization:** Errors → Structs → Events → `init` → Public → View → Admin → Package → Private → Test.
- **Naming:** modules `snake_case`, structs `PascalCase`, errors prefixed `E` (e.g., `ENotAuthorized`), constants `SCREAMING_SNAKE_CASE`.
- **Abilities:** Event structs need `copy, drop`. Capability structs need `key` (owned) or `key` (shared). Witness/auth types need only `drop`.
- **Comments:** Doc-comment every public function. Annotate non-obvious patterns (witness, hot-potato, swap_or_fill).

## Auth & Access Control

- **Three-tier capability:** GovernorCap (deployer) → AdminACL (shared, sponsor addresses) → OwnerCap<T> (player, per-object).
- **`verify_sponsor` fallback:** When `tx_context::sponsor()` is `None`, it falls back to `ctx.sender()`. If sender is in AdminACL, non-sponsored tx succeeds — dual-sign is not always required.
- **`issue_jump_permit` is player-callable:** Requires only the extension Auth witness + both gates having matching extension. No AdminACL, no OwnerCap. Do not add unnecessary auth dependencies.
- **`jump_with_permit` requires AdminACL sponsorship.** This is the function that needs a sponsored transaction with dual-sign.
- **`authorize_extension` uses `swap_or_fill`:** It silently replaces any existing extension. No event is emitted for extension changes.

## Minimal Surface Area

- Prefer `public(package)` over `public` for state-mutating primitives.
- Add the smallest possible function surface. Compose from existing world-contracts primitives and assemblies.
- One responsibility per function. Split config reads from config writes.
