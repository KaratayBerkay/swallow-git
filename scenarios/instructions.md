# Setup Instructions

To practise the scenarios in `step-thru/`, you need a Git repository to play with.

---

## Option 1 — Fork this repo (recommended)

1. Create a fork on **[GitHub](https://github.com/KaratayBerkay/swallow-git)** or **[Codeberg](https://codeberg.org)**.
2. Clone your fork:
   ```bash
   git clone <your-fork-url> swallow-git-practice
   cd swallow-git-practice
   ```
3. Start practising:
   ```bash
   cat scenarios/step-thru/phase-1/how2.md
   ```

---

## Option 2 — Create a fresh throwaway repo

If you want to experiment freely without affecting anything:

```bash
mkdir ~/git-practice && cd ~/git-practice
git init
echo "# My Practice Repo" > README.md
git add README.md && git commit -m "Initial commit"
```

Then open `phase-1/how2.md` and follow along.

---

## Option 3 — Use /tmp (no traces)

```bash
mkdir -p /tmp/git-scratch && cd /tmp/git-scratch
git init
# Follow any phase guide directly
```

Your `/tmp` disappears on reboot — great for throwaway experiments.

---

## How to use the phases

- Each `phase-N/how2.md` is a **self-guided tutorial** with setup, steps, and practice scenarios.
- Start at **Phase 1** (the core `add → commit → push` loop).
- Commands that set up a test repo are included at the top of each phase guide.
- Run every command in your terminal as you read.

---

## Quick start

```bash
# One-liner to begin Phase 1
mkdir -p /tmp/git-phase1 && cd /tmp/git-phase1 && git init && echo "hello" > README.md
# Open the guide in another terminal or cat it
cat <path-to-swallow-git>/scenarios/step-thru/phase-1/how2.md
```

Replace `<path-to-swallow-git>` with the actual path where you cloned or have the repo.
