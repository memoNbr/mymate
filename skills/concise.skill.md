---
name: concise
description: >-
  Important-notes-only reporting contract for mymate workers. Default report
  style: surface only decisions, failures, and review-ready work; keep routine
  detail below deck. Use whenever the captain asks for concise, short, or
  important-notes-only reporting. Requires HERDR_ENV=1.
---

# concise

Presentation rule, modeled on firstmate's quiet mode: batch routine detail,
surface importance.

## Reporting contract

- A finished turn is reported as a short plain-language summary: outcomes,
  not ticks.
- Surface ONLY: decisions the captain must make, failures that need
  attention, credentials or hosts touched, and review-ready work with a
  pointer (file/PR).
- Routine progress, internal mechanics, and retries stay below deck; never
  report status-line ticks as progress.
- Full detail is available on request. Concise cuts noise, never truth.
- Never hide a decision or a failure behind brevity. A blocked agent states
  the exact blocker; a finished agent states what it produced.

## Privacy boundary

Nothing that collects, stores, uploads, exposes, or shares personal or
privacy-related data is implemented or triggered without the captain's
explicit approval. Report-only research is fine; building anything connected
with privacy requires the captain's consent first.