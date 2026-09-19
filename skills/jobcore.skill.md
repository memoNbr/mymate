---
name: jobcore
description: "Foundation & Profile worker for AAE (the captains job-application software). Requires HERDR_ENV=1."
---

# worker contract

You are a worker in the mymate crew, dispatched into this herdr pane.

- Read this skill first; it is your only mission. The brief that follows it only names your pane.
- Work inside `C:\Users\Win11 Pro\Memo\job-assistant` (create it if missing). Never modify other panes' directories.
- Keep the captain informed: finish, block precisely, or ask the one decision you actually need. Never guess.
- End settled: `idle` after done-grade output, `blocked` when you truly need input.

# mission: Pane 1 - Foundation & Profile

Build the foundation of a local-first **AAE**.
You own the data model, config, and CV/transcript parsing. Other panes build
scrapers and intelligence on top of your schema, so the interface below is a
hard contract - do not change it without telling the conductor.

## Locked profile (already decided by the captain)

| Decision | Choice |
|---|---|
| Target | PhD / academic research positions |
| Docs language | English |
| Eligibility | Non-EU, graduated, job-seeker visa; converts to a work permit on hire (eligible everywhere once hired) |
| Countries (priority) | DE -> NL, BE, AT, CH |
| Field | Cognitive architecture / automotive engineering / cognitive science / mobility / interior HMI / user acceptance |
| DE/AT/CH approach | Posted vacancies first, cold-contact proposals second |
| Submission | Auto-fill, hard pause before final Submit (captain clicks) |
| Scope | Local-first, structured to become a web app later |

## Deliverables

1. Repo scaffold at `C:\Users\Win11 Pro\Memo\job-assistant`:
   `config.py`, `schema.py`, `parsers/`, `app/main.py`, `requirements.txt`,
   `README.md`, `.gitignore`, `data/`, `tests/`. `git init` it.
2. `config.py` - document search paths, country filters `[DE,NL,BE,AT,CH]`,
   API keys from OS keyring/env (never inline), SQLite path `data/job_assistant.db`.
3. `schema.py` - SQLite models (plain sqlite3 or SQLAlchemy) with EXACTLY these
   entities/fields (this is the shared interface):
   - Profile(full_name, email, phone, nationality, visa_status, languages[],
     degree_field, research_keywords[], skills[], thesis_summary,
     target_roles[], target_countries[])
   - Education(profile_id, level, institution, program, start, end, gpa)
   - Publication(profile_id, title, venue, year, doi, url)
   - Vacancy(id, source, title, institution, department, country, city, url,
     description, posted_date, deadline, funding, position_type, language,
     contact_email, raw)
   - MatchScore(vacancy_id, profile_id, score, rationale)
   - Application(id, vacancy_id, status, created_at, updated_at)
   - Document(id, application_id, kind, language, content, status)
   - kind in {motivation_letter, research_statement, cv_tailored}
   - status in {draft, ready, approved, applied}
4. `parsers/resume_parser.py` - scan the captain's Desktop for CV and
   Bachelor/Master transcripts (`.pdf`, `.docx`), extract text with
   `pypdf`/`python-docx`, and structure it into the Profile schema. Use a
   deterministic local pass first; use Gemini only to normalize messy text.
5. Minimal FastAPI app in `app/main.py` with a `/health` endpoint and a
   `/profile` endpoint reading the parsed profile.
6. Sample fixture profile + 3 fake vacancies in `tests/fixtures/` and a `pytest`
   smoke test that builds the DB and inserts them.
7. `README.md` with setup/run steps.

## Security rules (binding)

- No raw PII (name, address, phone, email) is ever sent to an external API; send
  anonymized text only.
- Credentials only via OS keyring or env; never commit them.
- Read the captain's Desktop files read-only. Never modify user documents.
- No auto-submit anywhere in this app. Hard pause before any submit.

## Boundaries

- Do NOT build scrapers (Pane 2 owns `scrapers/`).
- Do NOT build matching/generation (Pane 3 owns `intelligence/`).
- Do NOT touch cabin-sim or any other crew pane.

## Reporting

Finish with: what you built, files/dirs changed, the exact command to run the
app, what you could not verify, and anything the captain must decide.
