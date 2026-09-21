# AAE Wizard v2 — 5-section rewrite (clean)

Owner: job-assistant repo at C:\Users\Win11 Pro\Memo\job-assistant. App: app/main.py (FastAPI, uvicorn 127.0.0.1:8000), UI: app/static/{index.html,app.js,styles.css}. Data: data/vacancies.json (live = http_status 200 only), intelligence/generator.py (deterministic local).

Non-negotiables: localhost-only, no new deps without captain OK, no fake rows, keep /health + existing endpoints working, back/forward keeps state.

## §1 Documents input (clean start)
- Upload CV + transcript. "Add more" button allows N transcripts.
- "Delete my information" button: wipes stored profile (clean/new start), confirmed before delete.

## §2 Fresh match API (LLM reasoning)
- Fresh endpoint returning PhD matches with per-match reasoning text (LLM when key configured, else deterministic fallback — never fake).

## §3 Browse 20/page, choose ONE
- List 20 positions per page, bottom pager (prev/next), examine each.
- Single-select: exactly one job chosen. Choice persists across steps.

## §4 Documents + chat + PDF
- Motivation letter + research statement (only if research chosen in §3) + application email written for the chosen job.
- Chat box: interactive instructions to the bot (rewrite, new motivation, new research).
- Download motivation and/or research statement as PDF.

## §5 Apply (user sends)
- Final page: application portal link OR responsible email for the chosen job. User sends themselves; app only presents.

## Done means
uvicorn restarted on 127.0.0.1:8000; curl each new endpoint + static page; 86 existing tests still pass; report: URL, counts per section, live-vs-dead.
