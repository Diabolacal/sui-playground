# Hackathon Rules Digest

**Retention:** Prep-only

> Practical extract from the [full rules source](hackathon-event-rules-source.md).
> Source: <https://evefrontier.com/en/eve-froniter-hackathon-event-rules>
> Published: 12 February 2026 | Captured: 2026-02-16

---

## Key Dates & Deadlines

| Event | Date |
|-------|------|
| Hackathon opens | Announcement date (TBD — "when the announcement is made") |
| Hackathon closes | **31 March 2026, 23:59 UTC** |
| Player voting deadline | **15 April 2026** |
| Winners announced | On Twitch ([twitch.tv/ccp](https://www.twitch.tv/ccp)) |
| Winner response window | 14 days after notification email |
| Stillness deployment bonus | Within 14 days after Hackathon Conclusion |

---

## Planning vs Building Rules

### What is allowed before the hackathon start date
- Research, ideation, design documents, architecture planning
- Learning Sui / Move / EVE Frontier systems
- Setting up tooling, dev environments, CI/CD
- Reading CCP Materials and official docs

### What is NOT allowed before the hackathon start date
- **No code development.** "Your Entry must be developed on or after the Hackathon start date" (Section 5)
- No pre-existing code submitted as your Entry
- No reuse of code from other hackathons or prior projects as your core Entry

---

## Eligibility

- **Age:** 18+ at time of entry
- **Regions:** US (50 states + DC), Canada (excl. Quebec), EEA, UK
- **Excluded:** Quebec, OFAC-sanctioned countries (Cuba, Crimea, DPRK, Iran, Syria), CCP employees/families
- **VPN prohibition:** Must not use VPN to circumvent geographic restrictions
- **Team size:** Max 5 members per team; no multi-team participation

---

## Repo Hygiene & Submission Requirements

### Submission mechanics
- Register via **Deepsurge** (one account per team)
- All Entries must be developed and posted on **GitHub**
- Submit a hyperlink to your team's GitHub repository + any materials/design drawings
- Entry procedure from the hackathon announcement is incorporated by reference

### Clean repo rules
- Entry must be your own original work
- Must not violate any law or third-party IP/privacy rights
- Must have all necessary consents/approvals/licenses
- Entry must not be a security, commodity, or regulated financial instrument
- Entry must not confer ownership rights, equity stakes, revenue shares, or voting rights

### Post-submission
- Late entries (after 31 March 2026 23:59 UTC) are **automatically disqualified**
- No other methods of entry accepted besides the official process

---

## Judging Criteria

### Best Entry (main prizes — 1st, 2nd, 3rd)
Judged by a panel of 3 qualified judges + 25% player vote weighting:

| Criterion | Focus |
|-----------|-------|
| **Concept & Feasibility** | Core idea, problem solved, adoption potential |
| **Mod Design** | System design quality (not one-off feature) |
| **Concept Implementation** | How well concept/design translated to working mod |
| **Player Utility** | Meaningfully changes how players operate |
| **EVE Frontier Relevance & Vibe** | Natural extension of EVE Frontier |
| **Creativity & Originality** | Bold, novel, uniquely "Frontier" |
| **UX & Usability** | Intuitive and usable in real play |
| **Visual Presentation & Demo** | Clarity and confidence of presentation |
| **OPTIONAL BONUS: Stillness Deployment** | Deployed and operational in Stillness within 14 days post-hackathon |

### Player Vote
- 25% of overall "Best Entry" score
- 1 vote per player via Deepsurge
- Deadline: 15 April 2026
- Fraud/vote-buying → disqualification

### Bonus Prize Categories

| Category | What wins |
|----------|-----------|
| **Most Utility** | Materially changes how players survive, coordinate, explore, or compete |
| **Best Technical Implementation** | Clean architecture, smart use of Frontier systems, scalability, robustness |
| **Most Creative** | Novel ideas, clever reinterpretations, bold system concepts |
| **Weirdest Idea** | Visually striking, surprising, meme-worthy, strange directions |
| **Best Live Frontier Integration** | Deployed and functioning in Stillness with real players |

---

## Prizes Summary

| Place | Cash | SUI Tokens | Fanfest | Sui Basecamp | EVE Points |
|-------|------|------------|---------|--------------|------------|
| **1st** | $15,000 | $10,000 | 5 passes + flights/hotel (≤$25k total) | 5 tickets | 60,000 |
| **2nd** | $7,500 | $5,000 | — | 5 tickets | 30,000 |
| **3rd** | $5,000 | $2,500 | — | 3 tickets | 20,000 |
| **Each Bonus** | $5,000 | $1,000 | — | 2 tickets | 20,000 |

- All team members also receive: Ascended Founder Access + Primal Tribe Pack
- Cash/tokens split equally among team members via wire/wallet transfer
- An entry may win **max 1 prize**
- Prizes are non-transferable; winners responsible for taxes

---

## IP & Licensing

- CCP owns all EVE Frontier IP ("CCP Materials")
- You get a **limited, revocable, non-exclusive license** to use CCP Materials for creating your Entry
- By submitting, you grant CCP an **irrevocable, royalty-free, worldwide license** to use your Entry in perpetuity
- You waive moral rights to the extent permitted by law
- Submission is voluntary, not confidential, no compensation expectation beyond prizes

---

## Agent Compliance Checklist

### What agents must NOT do
- [ ] **Do not generate code before the hackathon start date** that will be submitted as part of the Entry
- [ ] **Do not reuse code** from other hackathons or pre-existing projects as the core Entry
- [ ] **Do not create entries that function as securities**, financial instruments, or equity/revenue-share tokens
- [ ] **Do not include code/content** that violates third-party IP, privacy, or applicable laws
- [ ] **Do not automate vote solicitation**, vote buying, or any fraudulent voting activity
- [ ] **Do not commit secrets** (wallet keys, mnemonics) — standard guardrail, also relevant to Deepsurge registration

### What is safe for agents to do
- [x] Research, architecture docs, design planning (before and during hackathon)
- [x] Set up tooling, dev environments, CI/CD pipelines
- [x] Generate code **on or after the hackathon start date** for Entry development
- [x] Deploy to Stillness for the bonus criteria (within 14 days post-close)
- [x] Prepare demo materials and documentation

### In-game browser constraints (2026-02-28)
- The in-game embedded browser (Chromium 122 CEF) provides portrait viewport (~787×1198) and dark mode preference
- **No Sui Wallet Standard in-game** — only EVM wallet (EIP-6963 "EVE Frontier Wallet"). DApp users are read-only in-game.
- UX designs targeting "Best Live Frontier Integration" or "UX & Usability" criteria must account for portrait-first layout and read-only in-game mode
- Live Frontier integration requires HTTPS hosting, portrait-responsive layout, and either read-only mode or Sui wallet relay (unconfirmed) from the embedded browser
- Full reference: [In-Game DApp Browser Surface](../architecture/in-game-dapp-surface.md)

### When to consult this document
- Before starting any code generation that will be part of the Entry → verify hackathon has started
- Before creating token/financial mechanics → verify no security/equity characteristics
- Before submission → verify all repo hygiene requirements met
- When evaluating idea fit → cross-reference judging criteria weights
- When planning bonus prize strategy → check Stillness deployment timeline
- When designing in-game DApp surface → verify portrait-first layout and wallet constraints

---

## Quick Reference: Critical Constraints

1. **Code start date:** On or after hackathon announcement (not before)
2. **Submission deadline:** 31 March 2026, 23:59 UTC — hard cutoff
3. **Max team size:** 5 members, no multi-team
4. **Submission platform:** GitHub repo + Deepsurge registration
5. **One prize max** per eligible Entry
6. **Player vote = 25%** of Best Entry score
7. **Stillness deployment bonus** window: 14 days after hackathon close
8. **Original work only** — no copied/reused hackathon code

---

## Submission Artifacts (Observed via Deepsurge UI)

> **Source:** Manually observed in the Deepsurge submission form (2026-02-16). Not programmatically verified — the Deepsurge submission flow is behind authentication and rendered client-side.

The Deepsurge submission form requests:

- **GitHub repository link** — the primary deliverable; must contain all Entry code
- **Website link** — optional; if the Entry has a hosted frontend or dashboard
- **Demo video link** — e.g., YouTube; a recorded demonstration of the Entry in action

### Implication for Demo Strategy

The demo video field strongly implies that **judges will evaluate a pre-recorded video**, not a live streamed demonstration. This changes several strategic assumptions:

| Assumption | Old (live demo) | Updated (recorded video) |
|------------|-----------------|-------------------------|
| Runtime fragility | High penalty — crash during live demo is catastrophic | Low penalty — re-recordable; only final take matters |
| Narrative control | Limited — live Q&A and audience reactions shape flow | Full control — scripted, edited, captioned |
| Presentation polish | Constrained by live execution speed and nerves | Can use B-roll, overlays, captions, post-editing |
| Time management | Strict (3-5 min slot assumption) | Flexible within video length norms (2-5 min recommended) |
| "Wow moment" delivery | Must land in real-time | Can be timed, replayed, and highlighted with annotations |
| Core functionality requirement | **Unchanged** — must demonstrate real, working implementation | **Unchanged** — real on-chain transactions, not mockups |

**Key takeaway:** The shift to recorded demo increases the importance of **storytelling, visual clarity, and narrative arc** while reducing the penalty for **runtime instability or complex flows that might stumble in live execution**. Core functionality must still be real and demonstrable — a recorded demo is not permission to fake capabilities.
