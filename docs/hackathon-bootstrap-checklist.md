# Hackathon Bootstrap Checklist (March 11)

This checklist ensures the hackathon submission repo starts with zero prior Git history and contains only the intended template files from SUI Playground. Follow each section in order on hackathon day.

---

## Pre-Start Sanity Check

- [ ] Confirm hackathon start time (UTC) and that it has passed
- [ ] Confirm no code has been written in the submission repo
- [ ] Confirm SUI Playground repo is up-to-date and pushed (`git status` clean, `git push` current)
- [ ] Confirm which project idea from `docs/hackathon-ideas-grounded.md` you are building

---

## Folder Snapshot Process

- [ ] Copy SUI Playground folder to a new folder (e.g. `civilizationcontrol-hackathon`)
- [ ] Delete `.git/` directory in the new folder
- [ ] Remove `vendor/` directory entirely (submodules will be re-added cleanly)
- [ ] Remove `notes/` directory (sandbox-only artifacts)
- [ ] Remove `docs/working_memory/` if present
- [ ] Remove any Docker state folders (`workspace-data/`, volume artifacts)
- [ ] Verify no `.env`, `.env.sui`, `sui.keystore`, or secret files exist
- [ ] Remove any files not intended for the submission (e.g. `docs/player-value-ux-analysis.md`, `docs/hackathon-inspiration-research.md`, sandbox docs)

---

## Initialize Fresh Repo

- [ ] `git init`
- [ ] Create new GitHub repo (private or public as hackathon rules require):
  ```
  gh repo create <repo-name> --private --source=. --remote=origin
  ```
- [ ] Verify remote: `git remote -v`
- [ ] Re-add submodules cleanly (only those needed for the project):
  ```
  git submodule add https://github.com/evefrontier/builder-scaffold.git vendor/builder-scaffold
  git submodule add https://github.com/evefrontier/world-contracts.git vendor/world-contracts
  ```
- [ ] Add others only if needed (e.g. `eve-frontier-proximity-zk-poc` for ZK projects)
- [ ] Verify submodule status: `git submodule status`

---

## First Commit

- [ ] Stage only intended files: `git add .`
- [ ] Review staged files: `git diff --cached --stat`
- [ ] Confirm no sandbox artifacts, secrets, or unintended files are staged
- [ ] Commit:
  ```
  git commit -m "chore: initialize hackathon repository"
  ```
- [ ] Verify commit timestamp is on or after March 11:
  ```
  git log -1 --format="%ci"
  ```
- [ ] Push: `git push -u origin main`

---

## Final Verification

- [ ] Check GitHub commit history — should show exactly one commit
- [ ] Confirm no commits exist prior to March 11
- [ ] Confirm no unintended files (secrets, sandbox notes, Docker state) are in the repo
- [ ] Confirm submodules are correctly linked (not embedded as regular files)
- [ ] Confirm repo visibility matches hackathon requirements (private/public)
