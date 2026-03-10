# The Shadow Broker Protocol — Demo Beat Sheet

**Retention:** Prep-only

## Format Requirements

- **Type:** Pre-recorded screencast, 3:00 ±5s
- **Resolution:** 1080p 60fps, dark UI theme (game-aesthetic, not SaaS)
- **Audio:** Voiceover narration + UI sound design (subtle clicks, confirmation tones)
- **Wallets:** Two browser profiles — "OPERATIVE-7" (seller) and "REDFALL" (buyer)
- **Network:** Sui Testnet (or localnet with pre-funded addresses)
- **Pre-flight:** All dependencies cached, Walrus aggregator verified reachable, Seal key servers healthy

## Emotional Arc

```
Tension:  ░░▓▓▓▓████▓▓▓████████████████████████████████░░
          Upload  List  TEASER  Browse  Purchase  DECRYPT+PLAY
          (setup) (stakes)(want+)(tension)(commit)  (payoff)
```

The demo builds **anticipation through denial** — but the teaser breaks the denial just enough to make it unbearable. The buyer hears two seconds of real intercepted audio. Voices. Urgency. Then silence. They know what's behind the paywall. That knowledge makes the purchase agonizing and the decrypt+play cathartic. Everything before the teaser is setup. Everything after it is consequence.

---

## Act 1: The Upload (0:00 – 0:48)

**Screen:** Shadow Broker dApp — Upload Intel view. Dark UI, spy-thriller aesthetic.

| Beat | Time | Visual | Technical Detail |
|------|------|--------|-----------------|
| 1.1 | 0:00 | Title card: "The Shadow Broker Protocol" | 3s fade-in, tagline: "Trustless intelligence for a lawless frontier" |
| 1.2 | 0:03 | OPERATIVE-7 wallet connected, Upload Intel panel visible | `useDAppKit()` wallet connection, address shown truncated |
| 1.3 | 0:07 | Narration: "An operative has intercepted alliance comms. A recording of rival leaders planning an ambush." | Show .wav file in system, ~2m15s duration |
| 1.4 | 0:12 | Spy drags audio file into upload zone | Client generates random AES-256-GCM key |
| 1.5 | 0:15 | Progress bar: "Extracting preview…" | Web Audio API: `AudioContext.decodeAudioData()` → `AudioBuffer` → slice first 2 seconds → encode to WAV blob. This is the unencrypted teaser clip. |
| 1.6 | 0:18 | Narration: "A two-second teaser. Just enough to prove the content is real." | Teaser clip shown as small waveform thumbnail in the upload form |
| 1.7 | 0:21 | Progress bar: "Uploading teaser…" | `@mysten/walrus` SDK: `uploadBlob(teaserClipBytes)` → returns `teaserBlobId` (unencrypted, publicly readable) |
| 1.8 | 0:24 | Progress bar: "Encrypting and uploading intel…" | `crypto.subtle.encrypt()` AES-256-GCM on full audio → `@mysten/walrus` `uploadBlob(encryptedAudioBytes)` → returns `blobId` |
| 1.9 | 0:30 | Progress bar: "Sealing encryption key…" | `@mysten/seal` SDK: `SealClient.encrypt({...})` — Seal-encrypts the AES key with policy: "owner of IntelObject NFT" |
| 1.10 | 0:35 | Progress bar: "Minting IntelObject…" | PTB calls `shadow_broker::intel::mint_intel()` — creates IntelObject NFT containing: `blob_id`, `teaser_blob_id`, `encrypted_key`, metadata (`file_type: "audio/wav"`, `duration_seconds: 135`, `file_size_bytes`, `description`) |
| 1.11 | 0:42 | IntelObject appears in wallet inventory. Metadata card visible: audio icon, 2m15s, file size, teaser badge. | Sui explorer link briefly shown for mint tx |
| 1.12 | 0:48 | Narration: "The intel is sealed. Only the holder can unlock it." | Pause beat — let it land |

**Envelope encryption flow (shown as subtle diagram overlay at 0:24):**
```
Audio .wav → First 2 seconds → teaser clip → Walrus (teaserBlobId) [unencrypted]
Audio .wav → AES-256-GCM encrypt → encrypted blob → Walrus (blobId)
AES key → Seal encrypt (policy: IntelObject owner) → encrypted_key → on-chain
```

## Act 2: The Listing (0:48 – 1:30)

**Screen:** Shadow Broker dApp — List Intel view.

| Beat | Time | Visual | Technical Detail |
|------|------|--------|-----------------|
| 2.1 | 0:48 | Spy clicks "List for Sale" on the IntelObject card | Navigate to listing form |
| 2.2 | 0:53 | Spy sets price: 500,000 units. Confirms listing. | Single PTB combining `shadow_broker::intel::update_encrypted_key()` + `shadow_broker::marketplace::list()` — one transaction transfers IntelObject into a shared `Listing` object with price field |
| 2.3 | 1:02 | Listing confirmation. Marketplace view shows the new listing. | Listing object ID shown, IntelObject now owned by Listing (wrapped or dynamic field) |
| 2.4 | 1:08 | Camera lingers on listing card: "INTERCEPTED COMMS — Audio, 2m15s — 500,000 units." A small ▶ Play Preview button glows on the card with a waveform indicator beside it. | Metadata visible: file type, duration, description. Teaser button is public — anyone can play it. |
| 2.5 | 1:14 | OPERATIVE-7 clicks "Play Preview" on their own listing. Two seconds of scratchy, radio-filtered voices play through the speakers. Static. Urgency. Then silence. | Client fetches `teaserBlobId` from Walrus (unencrypted), decodes via `AudioContext.decodeAudioData()`, plays through `AudioBufferSourceNode`. Waveform visualization pulses for 2 seconds. |
| 2.6 | 1:20 | Narration: "Two seconds. Just enough to hear something real. Not enough to know why it matters." | Camera holds on the silent waveform. The teaser has ended. |
| 2.7 | 1:27 | Transition: wallet disconnect animation | Setup for buyer wallet switch |

## Act 3: The Purchase (1:30 – 2:25)

**Screen:** Shadow Broker dApp — Marketplace browse view. Second browser profile.

| Beat | Time | Visual | Technical Detail |
|------|------|--------|-----------------|
| 3.1 | 1:30 | REDFALL wallet connects. Marketplace loads. | Different browser profile, different address. Balance visible. |
| 3.2 | 1:37 | Buyer browses listings, clicks into the intercepted comms listing | Listing detail view: metadata, price, seller address (truncated). ▶ Play Preview button visible. |
| 3.3 | 1:42 | Narration: "The listing says audio. Two minutes fifteen. Alliance comms." | Buyer is reading the metadata. Scanning. |
| 3.4 | 1:47 | Buyer clicks ▶ Play Preview. The 2-second teaser plays. Camera holds tight on the waveform visualization. Scratchy voices, urgency, static. Two seconds. Then silence. | Same teaser fetch: Walrus `readBlob(teaserBlobId)` → decode → play. No decryption needed — teaser is public. |
| 3.5 | 1:52 | Narration: "Two seconds of intercepted comms. Voices. Urgency. That's all you get. The rest costs five hundred thousand." | This is the PEAK tension moment. Proof of life. The buyer knows the content is real audio — but can't access the substance without paying. |
| 3.6 | 1:58 | Buyer clicks "Purchase" | Single PTB constructed with 3 commands: |
| | | | 1. `SplitCoins(gas, [500_000])` — exact amount from buyer balance |
| | | | 2. `TransferObjects([coin], seller_address)` — payment to seller |
| | | | 3. `marketplace::purchase_listing()` — transfers IntelObject to buyer |
| 3.7 | 2:08 | Transaction confirmation. Full-screen moment. | Show Sui explorer: all 3 effects in one tx digest. Atomic. |
| 3.8 | 2:14 | IntelObject now in buyer's wallet. Listing removed from marketplace. | UI updates: "Your Intel" section shows the new asset |
| 3.9 | 2:20 | Narration: "Coins left. Intelligence arrived. One transaction." | No embellishment. Let the mechanics speak. |

## Act 4: The Reveal (2:25 – 3:00)

**Screen:** Shadow Broker dApp — Intel Detail view. THIS IS THE MOMENT.

| Beat | Time | Visual | Technical Detail |
|------|------|--------|-----------------|
| 4.1 | 2:25 | Buyer views IntelObject detail. A "Decrypt & Play" button pulses subtly. | Button is gated — only appears because connected wallet owns the NFT |
| 4.2 | 2:30 | Buyer clicks "Decrypt & Play" | Decryption sequence initiates: |
| | | | 1. `SessionKey` created via `@mysten/seal` (user signs once) |
| | | | 2. PTB built calling `seal_approve` in the Move access policy module |
| | | | 3. Seal key servers call `dry_run_transaction_block` to verify NFT ownership |
| | | | 4. Key servers release derived key shares → client combines → AES key recovered |
| 4.3 | 2:36 | Progress: "Verifying ownership… Recovering key… Fetching intel…" | 5. `@mysten/walrus` `readBlob(blobId)` fetches encrypted audio |
| | | | 6. Client AES-GCM decrypts with recovered key |
| 4.4 | 2:42 | **Audio waveform appears. Sound plays.** Alliance leaders' voices fill the room. The same voices from the teaser — but now the full conversation unfolds. | `new AudioContext()`, `decodeAudioData()`, waveform canvas visualization |
| 4.5 | 2:48 | Brief overlay appears while audio continues: "Preview: 2 seconds (public) / Full recording: 2:15 (decrypted)" | Reinforces the mechanic visually. The teaser was the hook. This is the substance. |
| 4.6 | 2:52 | Camera holds on waveform + audio playing. No UI interaction. Let the moment breathe. | The payoff. Raw intelligence, decrypted, playing. |
| 4.7 | 2:56 | Audio fades. Text overlay: **"Zero trust. Zero middlemen. The intelligence speaks for itself."** | 4s hold on closing card |

---

## Audio Asset

**Teaser clip (first 2 seconds):**
- MUST be the first 2 seconds of the same recording (proving continuity with the full file)
- Contains the most evocative fragment — the opening line of comms, a static burst, voice identification
- Suggested teaser content: "[static burst] ...Bravo fleet, hold at the gate—" [cut]
- The teaser is a HOOK. It must make the buyer NEED to hear the rest.

**Full recording (30–45 seconds scripted, presented as 2m15s in metadata):**

**Option A (recommended):** Record a scripted "alliance planning session" voiceover:
- Two voices, radio-filter effect, discussing fleet positioning and ambush timing
- Full recording opens with the same words as the teaser, then continues: "[static burst] ...Bravo fleet, hold at the gate. When they jump through, we collapse. No one gets out."
- Post-process: add static, compression, walkie-talkie aesthetic

**Option B (fallback):** Royalty-free dramatic audio clip — military radio chatter or sci-fi comms. Sources: freesound.org (CC0), Pixabay audio library. Pre-extract a 2-second teaser from the chosen clip.

**Requirement:** Full file must be ≤5 MB (Walrus upload speed matters for demo pacing). WAV preferred for waveform fidelity; MP3 acceptable. Teaser clip will be tiny (~50 KB for 2 seconds of WAV).

## Fallback Plans

| Risk | Mitigation |
|------|-----------|
| Walrus upload slow (>5s) | Pre-upload both blobs before recording. Show upload UX but skip the wait. Blob IDs hardcoded in demo env. |
| Seal key server timeout | Retry with alternate key server (8+ testnet providers). Pre-warm session key before clicking Decrypt. |
| Walrus read slow on decrypt | Pre-cache encrypted blob in browser storage. Fetch happens instantly from cache. |
| Audio decode fails | Pre-decode and cache `AudioBuffer`. Decrypt step reveals cached audio. |
| Sui testnet congestion | Record against localnet. Alternatively, pre-execute txs and replay explorer views. |
| Wallet popup interrupts flow | Pre-approve site in both wallet profiles. Use auto-approve for testnet. |
| Teaser extraction fails | Pre-extract teaser clip before recording. Hardcode `teaserBlobId`. |

## Key Move Modules Referenced

- `shadow_broker::intel` — `mint_intel()`, `update_encrypted_key()`, IntelObject struct (`blob_id`, `teaser_blob_id`, `encrypted_key`, metadata)
- `shadow_broker::marketplace` — `list()`, `purchase_listing()`, Listing struct
- `shadow_broker::seal_policy` — `seal_approve()` (Seal access policy: owner-of-IntelObject check)

## Recording Checklist

- [ ] Both wallet profiles funded on target network
- [ ] Walrus aggregator endpoint verified reachable
- [ ] Seal key server health check passes
- [ ] Full audio asset prepared and tested (≤5 MB, plays correctly)
- [ ] Teaser audio clip extracted and tested (2 seconds, plays correctly, unencrypted)
- [ ] Teaser playback works on listing card (marketplace view)
- [ ] UI dark theme applied, no browser bookmarks/extensions visible
- [ ] Screen resolution set to 1080p, font scaling verified readable
- [ ] Narration script rehearsed, timed to 3:00
- [ ] Fallback blobs/txs pre-staged if live recording
