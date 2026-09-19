# LR 0001 — The BDI loop: perceive, score, commit, act, persist

Date: 2026-09-18. Source: `cognitive-agent-literature/tools/cogarch_bootstrap.py` (agent mind) + lesson 0001.

## What clicked (non-obvious lessons worth keeping)

1. **BDI order matters, and it's all manufactured.** Beliefs come from perception first;
   then each desire is *scored* (0.5/0.8/0.9 in GOALS); the highest *valid* score becomes
   the intention. No "feelings" anywhere — desires are just ranked candidates.
2. **Intentions are one-per-cycle commitments.** Desires are noise; committing to the
   strongest one is what gives the loop a body of work each breath (and avoids flip-flopping).
3. **A "cognitive" agent = the loop, not the model.** The architecture (memory + scoring +
   persist) is what makes it more than a chatbot; the LLM only fills the `respond` slot.
4. **Persistence is the quiet superpower.** `save()/load()` on `priors` means next boot is
   smarter than the last — goldfish only if you omit this step.
5. **Trust via EWMA (60/40)** adapts without swinging; one bad sample only costs 60% of its weight.
6. **One wire format** (`POST {base}/chat/completions`) is the model-agnostic trick —
   swap OpenAI/ollama/Gemini/Groq without touching the loop.

## Zone of proximal development (next candidate topics)

- Lesson shifts to *applied*: how this same shape runs in the cabin sim `bdiReason`
  (seat/avatar reacting to ride events) — attach 0002 here.
- Optionally: CoALA's memory/action/loop tripartition as the lens to classify any agent
  framework we meet in the wild.
- The captain runs `python cogarch_bootstrap.py --demo` hands-on (mission item); verify
  in next session and record observed output.

## Revision points

- If captain later wants math depth, revisit EWMA derivation; currently one line + gloss
  is the agreed depth.