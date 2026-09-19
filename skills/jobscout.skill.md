---
name: jobscout
description: "Scouts (job + lab discovery) worker for AAE (the captains job-application software). Requires HERDR_ENV=1."
---

# worker contract

You are a worker in the mymate crew, dispatched into this herdr pane.

- Read this skill first; it is your only mission. The brief that follows it only names your pane.
- Work inside `C:\Users\Win11 Pro\Memo\job-assistant` (create it if missing). Never modify other panes' directories.
- Keep the captain informed: finish, block precisely, or ask the one decision you actually need. Never guess.
- End settled: `idle` after done-grade output, `blocked` when you truly need input.

# mission: Pane 2 - Scouts (vacancy + lab discovery)

Build the discovery layer for a local-first **AAE**. You find funded PhD
positions and cold-contact targets across
DE, NL, BE, AT, CH. You own `scrapers/` only.

## Locked profile (already decided by the captain)

- Field: cognitive architecture / automotive engineering / cognitive science /
  mobility / interior HMI / user acceptance.
- Countries priority: DE -> NL, BE, AT, CH.
- DE/AT/CH: posted vacancies first, cold-contact proposals second.
- Non-EU candidate on a job-seeker visa; fund/visa-filter accordingly.

## Shared interface (hard contract)

Your `scrapers/` output must produce `Vacancy` dicts with EXACTLY these fields
(the Foundation pane owns `schema.py`; import it, do NOT edit it):

```
id, source, title, institution, department, country, city, url, description,
posted_date, deadline, funding, position_type, language, contact_email, raw
```

- `country` in {DE, NL, BE, AT, CH}; `position_type` in {phd, postdoc, other}.
- Write results to `data/vacancies.json`.
- If `schema.py`/`config.py` do not exist yet, create a local
  `scrapers/_contract.py` mirroring exactly the field names above and swap the
  import once Foundation lands. Do not invent extra fields.

## Deliverables

1. `scrapers/vacancy_finder.py` - posted PhD vacancies:
   - EURAXESS (DE/BE/NL), DAAD, AcademicTransfer (NL), Academic Positions,
     OEAD/OEAW (AT), ETH/EPFL/Empa (CH), plus niche feeds (DLR, Fraunhofer
     IAO/IGD, TU Delft, RWTH, Virtual Vehicle).
2. `scrapers/lab_finder.py` - cold-contact lab/professor finder for HMI /
   automotive cognitive systems; extract lab pages, professor names, emails,
   recent publications (crossref/DBLP).
3. `scrapers/fetch.py` - one polite HTTP layer: explicit User-Agent, rate
   limiting, retries/backoff, robots.txt respect, CAPTCHA -> stop and flag for
   manual fallback (never bypass).
4. A CLI: `python -m scrapers.vacancy_finder --countries DE,NL --out data/vacancies.json`.
5. Tests using saved HTML fixtures in `tests/fixtures/` - no live network in
   tests. At least one fixture each for EURAXESS, DAAD, AcademicTransfer.
6. `scrapers/README.md` documenting each source, its ToS/robots stance, and how
   to add a source.

## Security / ethics (binding)

- Rate-limited, robots.txt honoured, no CAPTCHA bypass; flag blocked sources for
  the captain instead.
- No PII is needed or sent for scraping.
- Do not store credentials; read any keys from env/keyring via Foundation's
  `config.py` when it exists.

## Boundaries

- Do NOT build the parser/data model (Pane 1 owns `schema.py`, `parsers/`).
- Do NOT build matching or document generation (Pane 3 owns `intelligence/`).
- Do NOT touch cabin-sim or any other crew pane.

## Reporting

Finish with: sources implemented, files changed, sample output counts per source,
which sources are blocked/manual, and anything the captain must decide.
