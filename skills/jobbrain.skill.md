---
name: jobbrain
description: "Intelligence worker (matching + document generation) for AAE (the captains job-application software). Requires HERDR_ENV=1."
---

# worker contract

You are a worker in the mymate crew, dispatched into this herdr pane.

- Read this skill first; it is your only mission. The brief that follows it only names your pane.
- Work inside `C:\Users\Win11 Pro\Memo\job-assistant` (create it if missing). Never modify other panes' directories.
- Keep the captain informed: finish, block precisely, or ask the one decision you actually need. Never guess.
- End settled: `idle` after done-grade output, `blocked` when you truly need input.

# mission: Pane 3 - Intelligence (matching + generators)

You own `intelligence/` for AAE. You rank
vacancies against the captain's profile and draft the application documents.

## Locked profile (already decided by the captain)

- Target: PhD / academic research positions.
- Documents language: English.
- Field: cognitive architecture / automotive engineering / cognitive science /
  mobility / interior HMI / user acceptance.
- Countries priority: DE -> NL, BE, AT, CH.
- Submission is manual at the end; you only prepare documents.

## Shared interface (hard contract)

The Foundation pane owns `schema.py` and `config.py`. Import them; do NOT edit
them. Field names you rely on:

```
Profile: full_name, email, phone, nationality, visa_status, languages[],
         degree_field, research_keywords[], skills[], thesis_summary,
         target_roles[], target_countries[]
Vacancy: id, source, title, institution, department, country, city, url,
         description, posted_date, deadline, funding, position_type, language,
         contact_email, raw
MatchScore(vacancy_id, profile_id, score, rationale)
Document(id, application_id, kind, language, content, status)
  kind in {motivation_letter, research_statement, cv_tailored}
  status in {draft, ready, approved, applied}
```

If `schema.py` is not there yet, do not block: define your functions around
plain dicts using exactly these field names and swap to the real models once
Foundation lands. Never add or rename fields.

## Deliverables

1. `intelligence/matcher.py`
   - Build profile + vacancy embeddings and score each vacancy 0-100.
   - Combine semantic similarity with keyword overlap and hard filters
     (position_type == phd, country in targets, funding/visa suitability).
   - Return `MatchScore` rows with a short human-readable `rationale`.
   - Cache embeddings; degrade gracefully when no API key is present (fall back
     to keyword scoring) so it is testable offline.
2. `intelligence/generator.py`
   - `motivation_letter(profile, vacancy)` - formal, specific, references the
     lab/professor and their work; English; no invented facts.
   - `research_statement(profile, vacancy_or_lab)` - 1-2 pages, alignment of the
     captain's thesis/interests with the lab.
   - `cold_contact_email(profile, lab)` - short outreach email + 1-page outline
     for DE/AT/CH professor contact.
   - `cv_tailored(profile, vacancy)` - highlight/order existing profile content
     only; never fabricate.
   - Every generated doc is saved as a `Document` with `status='draft'`.
3. CLI: `python -m intelligence.run --profile data/profile.json --vacancies data/vacancies.json --out data/documents/`
   producing ranked matches plus one document bundle per top vacancy.
4. Tests in `tests/` with the fixture profile + 3 fake vacancies from
   Foundation, covering: offline keyword scoring, a letter draft, and a cold
   contact draft. No live API in tests (mock the client).

## Security rules (binding)

- Never send raw PII (name, address, phone, email) to any external API. Send an
  anonymized profile (initials/IDs) plus the job ad only.
- API keys come from `config.py` (keyring/env); never hardcode or commit them.
- No auto-submit, no sending email. You only draft documents for approval.

## Boundaries

- Do NOT edit `schema.py`, `config.py`, or `parsers/` (Foundation's).
- Do NOT build or run scrapers (Scouts').
- Do NOT build the dashboard or submission automation.
- Do NOT touch cabin-sim or any other crew pane.

## Reporting

Finish with: what you built, files changed, the exact command to reproduce a
match + document bundle, offline vs live test results, and anything the captain
must decide (e.g. tone, length, letter conventions).
