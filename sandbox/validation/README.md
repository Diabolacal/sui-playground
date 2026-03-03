# Sandbox Validation

> **⚠️ NON-SUBMISSION CODE** — This directory contains prototype Move modules
> used to validate CivilizationControl feasibility on local Sui devnet.
>
> **DO NOT copy any code from this directory to the hackathon submission repo.**
> Reimplement from scratch on March 11 using the patterns documented in
> `docs/operations/march-11-reimplementation-checklist.md`.

## Modules

### `trade_post_validation/`
Validates cross-address atomic buy via shared Listing object + Coin transfer.
Proves the Sui-level PTB composition mechanics for TradePost.

### `gate_toll_validation/`
Validates coin-based toll + tribe filter via dynamic field rules on a shared
GateConfig object. Proves the rule composition pattern for GateControl.

## How to Run

```bash
# From inside the Docker container:
cd /workspace/sandbox/<module>
sui move build -e local
sui client publish -e local --gas-budget 100000000 --json
```

## What These Do NOT Validate

- SSU extension-based `withdraw_item<Auth>` (requires world-contracts dependency)
- `issue_jump_permit` / `jump_with_permit` on actual Gate objects
- AdminACL sponsored transactions

> **v0.0.15 update:** AdminACL removed from owner-path SSU operations (`deposit_by_owner`, `withdraw_by_owner`, `update_energy_source_connected_*`). AdminACL sponsorship still required for `jump`, `jump_with_permit`, `deposit_fuel`, `game_item_to_chain_inventory`.
- Character/tribe mechanics from world-contracts
- NetworkNode / energy / fuel infrastructure chain

These are validated by:
- World-contracts unit tests (read-only reference in `vendor/world-contracts/`)
- Code analysis documented in the validation report
