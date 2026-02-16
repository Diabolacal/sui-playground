# Sui Playground — Local Devnet Quickstart

**Retention:** Carry-forward

Agent-friendly reference for running a local Sui devnet in this sandbox repo.

## Prerequisites

- Docker Desktop running (with Compose v2)
- No host-side Sui CLI needed — everything runs inside the container

## Start Local Devnet

```bash
# From repo root:
cd vendor/builder-scaffold/docker
docker compose run --rm sui-local
```

This starts an interactive shell inside a container with:
- A local Sui validator node on `http://127.0.0.1:9000`
- Three funded accounts (ADMIN, PLAYER_A, PLAYER_B)
- Move contracts mounted at `/workspace/contracts`
- Keys persisted in `sui-keystore` Docker volume across runs

The `--rm` flag auto-removes the container on exit. Keys survive via the named volume.

## Verify Environment (inside container)

```bash
sui client active-env           # Should print: local
sui client gas                  # Should show SUI balance
sui client addresses            # Lists ADMIN, PLAYER_A, PLAYER_B
```

## Build & Publish a Move Package (inside container)

```bash
# Build (use -e local to avoid chain ID mismatch on fresh genesis)
sui move build -e local

# Publish
sui client publish -e local --gas-budget 100000000 --json
```

### Example: gate package

```bash
cd /workspace/contracts/gate
sui move build -e local
sui client publish -e local --gas-budget 100000000 --json
```

## Troubleshooting

| Problem | Fix |
|---|---|
| Chain ID mismatch on `sui move build` | Add `-e local` flag — fresh genesis assigns a random chain ID that differs from `Move.toml` |
| `Move.lock` has stale chain data | Delete `Move.lock` and rebuild: `rm Move.lock && sui move build -e local` |
| Container won't start | Ensure Docker Desktop is running; check `docker compose version` |
| Port 9000 conflict | Stop other Sui nodes or containers using that port |
| Stale keys after resetting | Remove the Docker volume: `docker volume rm docker_sui-keystore` |

## Generated / Ephemeral Files

These appear during local work but must **never** be committed:

| File / Path | Handling |
|---|---|
| `vendor/builder-scaffold/docker/workspace-data/` | Ephemeral local state (`.env.sui` with keys + addresses). Auto-excluded via `vendor/builder-scaffold/.git/info/exclude` |
| `Move.lock` (in any contract dir) | Regenerated on build; restore from git if accidentally modified |
| `Published.toml` | Local publish record; ignore or exclude locally |

## Where to Log Outputs

- **Local smoketest results:** `notes/sui-local-smoketest.md` (untracked, local-only)
- `notes/` is gitignored — safe for addresses, transaction digests, private observations
- **Never** put private keys, `suiprivkey` strings, or raw addresses in tracked files

## Boundaries (Critical)

- `vendor/*` is **read-only** — never modify, add, or commit files inside submodules
- Use `vendor/<name>/.git/info/exclude` for local-only ignores (not committed to submodule)
- Always verify `sui client active-env` before running transactions
- Treat `~/.sui/`, keystore volumes, and `.env.sui` as secrets
- This repo is a private sandbox — **do not push** without explicit operator approval

## Related Files

| File | Purpose |
|---|---|
| `AGENTS.md` | Agent guardrails (auto-loaded by VS Code) |
| `.github/copilot-instructions.md` | Authoritative operational rules |
| `vendor/builder-scaffold/docker/compose.yml` | Docker Compose entrypoint |
| `vendor/builder-scaffold/docker/scripts/entrypoint.sh` | Container bootstrap script |
| `notes/sui-local-smoketest.md` | Local-only smoketest log (untracked) |
