# EVE Vault Signing Smoke Test

Binary integration test: Can EVE Vault connect via `@mysten/dapp-kit` and sign a trivial PTB?

## Status: SCAFFOLD READY — MANUAL BROWSER TEST REQUIRED

### Prerequisites

1. **EVE Vault Chrome extension** installed and configured:
   - Build from `vendor/evevault` (`bun install && bun run build:extension`)
   - Or download from [GitHub releases](https://github.com/evefrontier/evevault/releases/latest/download/eve-vault-chrome.zip)
   - Load unpacked at `chrome://extensions` → Developer Mode → Load unpacked
   - Sign in via FusionAuth OAuth flow in extension popup

2. **Local devnet** (optional for signing-only test):
   ```bash
   cd vendor/builder-scaffold/docker
   docker compose run --rm sui-local
   ```
   Note: Signing does not require executing on-chain. The wallet just needs to
   construct and sign the transaction bytes. A live RPC is needed only for gas
   estimation — if devnet is down, signing may still succeed depending on Vault
   behavior, or you can switch the network config to `devnet` (public Sui devnet).

### Run the Test

```bash
cd sandbox/evevault-signing-smoke
pnpm dev
```

Open `http://localhost:5173` in Chrome (with EVE Vault extension active).

### Test Steps

1. **Wallet Detection** — Page lists registered wallets. "Eve Vault" should appear with ✓.
2. **Connect** — Click "Connect Eve Vault". Extension popup should appear. Approve.
3. **Sign** — Click "Sign Empty PTB". Extension should prompt for signature approval.
4. **Evaluate** — Result section shows PASS/PARTIAL/FAIL with signature bytes.

### Expected Outcomes

| Result | Meaning |
|--------|---------|
| **PASS** | Vault connects, PTB constructed, signature returned. |
| **PARTIAL** | Vault detected/connects but signing fails (env-specific). |
| **FAIL** | Vault not detected or connection impossible. |

### Toolchain

- Node: v22.19.0
- pnpm: 10.16.1
- @mysten/dapp-kit: 1.0.3
- @mysten/sui: 2.4.0
- Vite: 7.3.1
- TypeScript: 5.9.3

### Verification Gates

- [x] TypeScript typecheck passes (`pnpm typecheck`)
- [x] Vite build succeeds (`pnpm build`)
- [ ] Manual browser test (requires EVE Vault Chrome extension)
