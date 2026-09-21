AAE SCOUTS - LIVE MATCH HUNT (finder support).

CAPTAIN: finder only surfaces CURRENT live matches, never the past/dead ones. You are the scouts: you HUNT. aae-core builds the UI, you feed it real, fresh, live vacancies.

DO (work in C:\Users\Win11 Pro\Memo\job-assistant):
1. RE-AUDIT every vacancy URL in data/vacancies.json RIGHT NOW using your existing tooling (tools/url_audit.py) so we have a FRESH signal, not the old audit. For each URL record: http_status (200/403/404/timed-out/unreachable), live=yes/no, and if a search engine/render needed it, note the channel.
2. Produce data/vacancies.json with a per-vacancy field: "live": true|false and "audited_at": ISO8601. KEEP all 16 rows (don't delete data) but mark them.
3. RANK only the LIVE ones as candidates. Move the dead ones into a clearly-marked "previously matched / expired" grouping (they stay in the file, they just never rank as "current").
4. If fewer than ~4 vacancies are live, that proves the audit is the problem - DO NOT silently pad with fake/dead URLs. Instead: find NEW current vacancies from the same trusted sources (euraxess, academictransfer, ETH jobs, etc.) that are REAL and LIVE (200). You have url_audit + scraper tooling; use it. Target: dominate PhD, industry acceptable. Find as many as are genuinely live.
5. Sanity: every URL you return as "live" must have been hit with a 200 (or verified reachable) - no exceptions)Skip. If you cannot reach a source at all, leave it out and say so.

PROOF (final reply):
- fresh audit summary: total, live count, dead count (with statuses),
- vacancies.json updated: live flags + audited_at + ranking, committed?,
- if you added NEW live vacancies: list them (title + URL + 200),
- build/test command + passed,
- files changed.

Commit to git. Leave pane idle.
