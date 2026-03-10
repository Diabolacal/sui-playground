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

- **Module organization:** Use `// === Section ===` headers. Order: Errors → Structs → Events → `init` → Public → View → Admin → Package → Private → Test.
- **One core object per module.** Shared primitives go in a `primitives/` subdirectory. If a module exceeds ~500 lines, extract helper logic.
- **Package naming:** `PascalCase` in `Move.toml` (`name = "CivilizationControl"`), `snake_case` for named address (`civilization_control = "0x0"`).
- **Always commit `Move.lock`.** Ensures reproducible builds.
- **Include a `README.md`** in the package root explaining purpose, key objects, and deployment instructions.

### Naming

- **Modules:** `snake_case` (`gate_extension`, `toll_collector`)
- **Structs:** `PascalCase` (`Gate`, `JumpPermit`)
- **Capabilities:** `PascalCase` + `Cap` suffix (`AdminCap`, `OwnerCap`)
- **Events:** `PascalCase` + `Event` suffix, prefer past tense (`TollCollectedEvent`, `CharacterCreatedEvent`)
- **DF key structs:** `PascalCase` + `Key` suffix (`TribeRuleKey`, `CoinTollKey`)
- **Errors:** `EPascalCase` (`ENotAuthorized`, `EGateNotOnline`)
- **Constants:** `SCREAMING_SNAKE_CASE` (`MAX_NAME_LENGTH`)
- **Functions:** `snake_case` (`issue_jump_permit`)
- **Getters:** field name directly — no `get_` prefix. Use `_mut` suffix for mutable variants (`name()`, `details_mut()`)

### Abilities

- **Ability order:** always `key, copy, drop, store` (this canonical order).
- Event structs need `copy, drop`.
- Capability structs need `key` (owned objects) or `key` (shared objects).
- Witness/auth types need only `drop`.

### Comments

- Use `///` for doc comments on public functions and structs (rendered by tooling).
- Use `//` for internal implementation notes.
- Do NOT use JavaDoc-style `/** */` — Move tooling doesn't support it.
- Doc-comment every public function. Annotate non-obvious patterns (witness, hot-potato, swap_or_fill).

### Modern Move Idioms (Move 2024)

- Use struct method syntax: `ctx.sender()` not `tx_context::sender(ctx)`.
- Use `b"hello".to_string()` not `std::string::utf8(b"hello")`.
- Use `id.delete()` not `object::delete(id)`.
- Use vector literals `vector[1, 2, 3]` not `vector::empty()` + `push_back`.
- Use `public fun` (composable) or `entry fun` (non-composable) — **never `public entry fun`**.

## Composability

- **Return objects, don't self-transfer.** Let the PTB handle `transfer::transfer`. This enables composability.
- **Exact Coin arguments** — prefer `fun f(payment: Coin<SUI>)` over `fun f(payment: &mut Coin<SUI>, amount: u64)`.
- **Collection sizing:** `vector` for ≤1000 items. Beyond that, use `Table`, `Bag`, or `ObjectTable`. Never allow unbounded vector growth.
- **Capability parameter position:** the primary object goes first, capability second — `fun set(account: &mut Account, _: &AdminCap, ...)`.

## Tests

- Place tests in the `tests/` directory (not uploaded on-chain). Mirror source structure.
- Test module name: `<module>_tests` (e.g., `gate_extension_tests`).
- Use `#[test_only]` module annotation.
- **Do NOT prefix test functions with `test_`** in `_tests` modules — describe the behavior: `toll_collection_charges_correct_amount()`.
- Merge test attributes: `#[test, expected_failure(abort_code = ENotAuthorized)]`.
- Use `tx_context::dummy()` for simple tests; `test_scenario` only for multi-tx/multi-sender.
- Use `assert_eq!` (prints both values on failure). Don't use abort codes in `assert!` in tests.
- Use `sui::test_utils::destroy` as a cleanup sink instead of custom `destroy_for_testing`.

## Auth & Access Control (verify against current world-contracts)

> These patterns were observed in a prior world-contracts version. Confirm each
> claim in the deployed contracts before coding against them.

- **Three-tier capability pattern:** World-contracts uses GovernorCap → AdminACL → OwnerCap<T>. Verify the current hierarchy and which functions require which tier.
- **Sponsor fallback:** Verify whether `verify_sponsor` falls back to `ctx.sender()` when no sponsor is present — if so, self-sponsorship may work without dual-sign when the sender is in AdminACL.
- **Permit issuance auth:** Verify what auth `issue_jump_permit` requires (extension witness only? AdminACL? OwnerCap?). Do not add auth dependencies beyond what the function signature demands.
- **Jump auth:** Verify whether `jump_with_permit` requires AdminACL sponsorship and dual-sign.
- **Extension replacement:** All three assembly types (Gate, SSU, Turret) use the same `authorize_extension<Auth>/swap_or_fill` pattern. Verify whether `authorize_extension` silently replaces an existing extension and whether any event is emitted.
- **Turret closed-world constraint:** Turret extension `get_target_priority_list` has a fixed signature (`turret, character, candidates_bcs, receipt`). Extensions cannot access external objects (e.g., ExtensionConfig, dynamic fields). All targeting logic must derive from candidate BCS data alone. Default turret behavior already excludes same-tribe non-aggressors.

## Minimal Surface Area

- Prefer `public(package)` over `public` for state-mutating primitives.
- Add the smallest possible function surface. Compose from existing world-contracts primitives and assemblies.
- One responsibility per function. Split config reads from config writes.

## Common Code Smells

| Smell | Fix |
|-------|-----|
| `public entry fun` | Use `public fun` or `entry fun` separately |
| Self-transfers inside functions | Return the object; let PTB handle transfers |
| Unbounded `vector` from user input | Use `Table`/`Bag` for dynamic collections |
| Address arrays for access control | Use capability objects instead |
| Raw `vector<u8>` string keys for DFs | Use typed key structs with `copy, drop, store` |
| `assert!(condition, 0)` in tests | Use `assert!(condition)` or `assert_eq!` |
| `test_scenario` for single-tx tests | Use `tx_context::dummy()` instead |
