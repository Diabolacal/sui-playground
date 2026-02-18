import {
  useWallets,
  useCurrentWallet,
  useCurrentAccount,
  useConnectWallet,
  useDisconnectWallet,
  useSignTransaction,
} from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { useState } from 'react';

interface SigningResult {
  status: 'PASS' | 'PARTIAL' | 'FAIL';
  message: string;
  details?: string;
  signatureBytes?: string;
}

export function App() {
  const wallets = useWallets();
  const { currentWallet, connectionStatus } = useCurrentWallet();
  const currentAccount = useCurrentAccount();
  const { mutate: connect } = useConnectWallet();
  const { mutate: disconnect } = useDisconnectWallet();
  const { mutateAsync: signTransaction } = useSignTransaction();

  const [signingResult, setSigningResult] = useState<SigningResult | null>(null);
  const [signing, setSigning] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);

  const log = (msg: string) => {
    const ts = new Date().toISOString().slice(11, 23);
    const entry = `[${ts}] ${msg}`;
    console.log(entry);
    setLogs((prev) => [...prev, entry]);
  };

  const eveVault = wallets.find(
    (w) => w.name === 'Eve Vault' || w.name.toLowerCase().includes('eve'),
  );

  const handleConnect = () => {
    if (!eveVault) {
      log('ERROR: Eve Vault wallet not detected in registered wallets.');
      log(`Available wallets: ${wallets.map((w) => w.name).join(', ') || '(none)'}`);
      setSigningResult({
        status: 'FAIL',
        message: 'Eve Vault wallet not detected.',
        details: `Registered wallets: ${wallets.map((w) => w.name).join(', ') || '(none)'}`,
      });
      return;
    }

    log(`Connecting to Eve Vault...`);
    connect(
      { wallet: eveVault },
      {
        onSuccess: () => log('Connected successfully.'),
        onError: (err) => {
          log(`Connection error: ${err.message}`);
          setSigningResult({
            status: 'PARTIAL',
            message: 'Wallet detected but connection failed.',
            details: err.message,
          });
        },
      },
    );
  };

  const handleSign = async () => {
    if (!currentAccount) {
      log('No account connected. Cannot sign.');
      return;
    }

    setSigning(true);
    setSigningResult(null);
    log('Constructing trivial PTB (empty transaction)...');

    try {
      const tx = new Transaction();
      // Empty transaction — no mutations, just a signable payload.
      // We set a gas budget but nothing will be executed.
      tx.setGasBudget(1_000_000);

      log('Requesting signature from Eve Vault...');

      const result = await signTransaction({
        transaction: tx,
      });

      const sigBytes = result.signature;
      const sigPreview = typeof sigBytes === 'string'
        ? sigBytes.slice(0, 64) + '...'
        : '(non-string signature)';

      log(`Signature received! Preview: ${sigPreview}`);
      log(`Transaction bytes length: ${result.bytes?.length ?? 'N/A'}`);

      setSigningResult({
        status: 'PASS',
        message: 'PTB signed successfully by Eve Vault.',
        signatureBytes: typeof sigBytes === 'string' ? sigBytes : JSON.stringify(sigBytes),
        details: `Bytes length: ${result.bytes?.length ?? 'unknown'}`,
      });
    } catch (err: unknown) {
      const error = err as Error;
      log(`Signing error: ${error.message}`);
      log(`Stack: ${error.stack ?? 'N/A'}`);

      setSigningResult({
        status: connectionStatus === 'connected' ? 'PARTIAL' : 'FAIL',
        message: `Signing failed: ${error.message}`,
        details: error.stack,
      });
    } finally {
      setSigning(false);
    }
  };

  return (
    <div style={{ fontFamily: 'monospace', padding: 24 }}>
      <h2>EVE Vault Signing Smoke Test</h2>

      <section>
        <h3>Wallet Detection</h3>
        <p>Registered wallets: {wallets.length}</p>
        <ul>
          {wallets.map((w) => (
            <li key={w.name}>
              {w.name} {w.name === 'Eve Vault' ? '✓ (target)' : ''}
            </li>
          ))}
        </ul>
        {wallets.length === 0 && (
          <p style={{ color: 'orange' }}>
            No wallets detected. Ensure EVE Vault Chrome extension is installed and enabled.
          </p>
        )}
      </section>

      <section>
        <h3>Connection</h3>
        <p>Status: {connectionStatus}</p>
        {currentAccount && <p>Address: {currentAccount.address}</p>}
        {connectionStatus !== 'connected' ? (
          <button onClick={handleConnect} disabled={!eveVault}>
            {eveVault ? 'Connect Eve Vault' : 'Eve Vault Not Detected'}
          </button>
        ) : (
          <button onClick={() => disconnect()}>Disconnect</button>
        )}
      </section>

      <section>
        <h3>Signing Probe</h3>
        <button
          onClick={handleSign}
          disabled={connectionStatus !== 'connected' || signing}
        >
          {signing ? 'Signing...' : 'Sign Empty PTB'}
        </button>
      </section>

      {signingResult && (
        <section
          style={{
            marginTop: 16,
            padding: 16,
            border: '2px solid',
            borderColor:
              signingResult.status === 'PASS'
                ? 'green'
                : signingResult.status === 'PARTIAL'
                  ? 'orange'
                  : 'red',
          }}
        >
          <h3>
            Result: {signingResult.status}
          </h3>
          <p>{signingResult.message}</p>
          {signingResult.details && (
            <pre style={{ whiteSpace: 'pre-wrap', fontSize: 12 }}>
              {signingResult.details}
            </pre>
          )}
          {signingResult.signatureBytes && (
            <details>
              <summary>Signature bytes</summary>
              <pre style={{ whiteSpace: 'pre-wrap', fontSize: 10, maxHeight: 200, overflow: 'auto' }}>
                {signingResult.signatureBytes}
              </pre>
            </details>
          )}
        </section>
      )}

      <section style={{ marginTop: 24 }}>
        <h3>Console Log</h3>
        <pre
          style={{
            background: '#111',
            color: '#0f0',
            padding: 12,
            maxHeight: 300,
            overflow: 'auto',
            fontSize: 12,
          }}
        >
          {logs.length > 0 ? logs.join('\n') : '(no activity yet)'}
        </pre>
      </section>
    </div>
  );
}
