---
description: "Sui Move conventions for CivilizationControl hackathon workspace"
applyTo: "**/*.move"
---

# Move Code — Workspace Conventions

> **Revalidate against latest world-contracts on hackathon test server (March 11+).**
> These are agent guardrails, not canonical truth. Authority hierarchy:
> `vendor/world-contracts` code > SUI docs > spec.md > this file.

## Core Rules

- **Never assume function signatures.** Always verify against the current `vendor/world-contracts` commit before generating call sites. Signatures and auth requirements change between releases.
- **Extension witness must be `public(package)`, not `public`.** The `x_auth()` function that mints your Auth witness type must use `public(package)` to prevent external packages from forging it. Verify the pattern against current `builder-scaffold` before scaffolding.
- **Dynamic fields: use typed key structs, not strings.** Define explicit `has copy, drop, store` key structs (e.g., `TollConfigKey`) rather than raw `vector<u8>` or `String` keys. This prevents key collisions and aids discoverability.
- **Hot-potato discipline: borrow and return in the same PTB.** If world-contracts uses a borrow/return pattern for capabilities (e.g., `borrow_owner_cap` / `return_owner_cap`), the borrowed object must be returned in the same transaction. Verify current function names before generating call sites.
- **MoveAbort emits no events.** Do not rely on events for proof-of-execution in flows that may abort. Use transaction digest + effects as the evidence path. See `docs/ptb/proof-extraction-moveabort.md`.
- **Prefer explicit error codes.** Define errors with `#[error(code = N)]` and descriptive `vector<u8>` messages. Keep codes sequential within each module.

## Structure & Style

- **Module organization:** Errors → Structs → Events → `init` → Public → View → Admin → Package → Private → Test.
- **Naming:** modules `snake_case`, structs `PascalCase`, errors prefixed `E` (e.g., `ENotAuthorized`), constants `SCREAMING_SNAKE_CASE`.
- **Abilities:** Event structs need `copy, drop`. Capability structs need `key` (owned) or `key` (shared). Witness/auth types need only `drop`.
- **Comments:** Doc-comment every public function. Annotate non-obvious patterns (witness, hot-potato, swap_or_fill).

## Auth & Access Control (verify against current world-contracts)

> These patterns were observed in a prior world-contracts version. Confirm each
> claim in the deployed contracts before coding against them.

- **Three-tier capability pattern:** World-contracts uses GovernorCap → AdminACL → OwnerCap<T>. Verify the current hierarchy and which functions require which tier.
- **Sponsor fallback:** Verify whether `verify_sponsor` falls back to `ctx.sender()` when no sponsor is present — if so, self-sponsorship may work without dual-sign when the sender is in AdminACL.
- **Permit issuance auth:** Verify what auth `issue_jump_permit` requires (extension witness only? AdminACL? OwnerCap?). Do not add auth dependencies beyond what the function signature demands.
- **Jump auth:** Verify whether `jump_with_permit` requires AdminACL sponsorship and dual-sign.
- **Extension replacement:** Verify whether `authorize_extension` silently replaces an existing extension (swap_or_fill) and whether any event is emitted.

## Minimal Surface Area

- Prefer `public(package)` over `public` for state-mutating primitives.
- Add the smallest possible function surface. Compose from existing world-contracts primitives and assemblies.
- One responsibility per function. Split config reads from config writes.
