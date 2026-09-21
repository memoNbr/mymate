# AAE Wizard — rebuild spec (captain-approved, conductor drives)

Owner: cabin-conductor / w1:pC. Do NOT ask for permission mid-build — you have
full perms; build unattended end-to-end. Do NOT create stub panes. This is a
single-pane continuous build. Only stop to report on real errors.

## Goal

Turn the existing job-assistant FastAPI app into a clean 4-step application
wizard the captain can click through in a browser. No external deps, no build
step, localhost onlychersShare. Reuse what already exists — do not re-invent
the matcher or the live-audit.

## Existing plumbing (use it)

- FastAPI app:      C:\Users\Win11 Pro\Memo\job-assistant\app\main.py
- Static UI:        C:\Users\Win11 Pro\Memo\job-assistant\app\static\
                      (index.html + app.js + styles.css — already renders the
                      vacancies/matches/profile board; keep that board, ADD the
                      wizard view on top — do not delete working views)
- Live audit tool:  C:\Users\Win11 Pro\Memo\job-assistant\tools\live_hunt.py
                      (re-audits EVERY stored vacancy URL, marks live 200 vs
                      dead 403/404, only counts 200-verified as current)
- Matcher:          C:\Users\Win11 Pro\Memo\job-assistant\intelligence\matcher.py
- Vacancy rows:     job-assistant\data\vacancies.json
                      fields: title, source, country, position_type, url,
                      http_status, live, audited_at, title, description
- Profile cache:    data/profile.json (courses, skills, languages, education,
                      publications, target roles, target countries)

## The 4 steps (captain's exact wording, follow it literally)

1. INPUT — a form where the captain (or "others", i.e. any user) provides docs:
   - CV / resume upload AND
   - transcript upload
   Both optional-but-one-required. Accept any file (pdf/txt/docx/pdf),
   store in job-assistant\data\documents\. If no new file given, fall back to
   existing data/profile.json profile. Show what parsed out of the docs
   (a short identity summary line) before moving on.

2. MATCHES — show up to 10 possible positions (PhD AND industry — the captain
   wants both "phd and industry related jobs"):
   - Rank by the existing matcher scores.
   - ONLY list rows whose URL is **live/200-verified** (use live_hunt's audit
     result). NEVER show a dead 403/404/None row as a candidate — dead rows
     may appear greyed "previously matched" but must be visually distinct.
   - A "regenerate" button that runs a second (different) hunt batch so the
     captain sees a fresh second patch of candidates.
   - Each candidate card: title, source, country, short description, the live
     badge, and the vacancy URL.

3. SELECT + GENERATE — after picking ONE position (card click):
   - A box to type extra instructions (captain's words / notes for the LLM).
   - Buttons: "Generate Motivation Letter" and/or "Generate Research
     Statement" (generate one or both).
   - The generation is local; if no LLM key is configured, produce a strong
     deterministic draft from the profile + vacancy description + instructions
     (never fake an LLM call). If a Gemini key IS present in
     job-assistant\config.py (gemini_api_key), use it for a real generation.
   - Show the generated letter/statement in an editable textarea.

4. OUTPUT / APPLY — the final page presents, all together:
   - The chosen vacancy (title + live link),
   - The motivation letter (editable),
   - The research statement if generated,
   - The application route: if the vacancy page has a direct URL → show
     "Open application page" button; if it's an email-based application →
     show the email (mailto) link. Detect both.

Navigation: captain must be able to go BACK and FORWARD through all 4 steps
freely without losing entered/selected state. Implement as a slide-in wizard
(AJAX, client-side state object kept in JS; server endpoints stateless GET/POST
for each step's data).

## Server endpoints to add (keep existing /api/* intact)

- POST /api/applications/documents   (accept uploads, parse, return summary+profile)
- POST /api/applications/generate    (body: vacancy_id, mode=letter|research,
                                       instructions, profile) -> {text, used_model}
- GET  /api/applications/apply-url?url=..  (detect mailto vs http for a vacancy)
- Keep: /api/vacancies, /api/matches, /api/profile, /health

## Non-negotiables

- Zero phishing/fake rows: "live" candidates MUST come from live_hunt-audited
  200 rows, not fabricated.
- CORS/local origin only; bind 127.0.0.1.
- No new requirements.txt deps for the wizard (reuse fastapi, starlette json).
- After build: run the app, curl the 4 endpoints, and verify the static page
  loads. Then report: the localhost URL, how many candidates each step shows,
  and which candidates are live vs previously-matched.

## Done means

All 4 steps visible on http://127.0.0.1:8000, back/forward works, live-only
candidate list confirmed against the audit, generation returns a real document
(mode-letter and mode-research), apply-url returns http vs mailto correctly.
Report done with those six facts only.
