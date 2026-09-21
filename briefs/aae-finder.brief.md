AAE FINDER PIVOT - not auto-apply, a finder. Captain intent is given below.

CAPTAIN (verbatim): "I like to turn AAE to finder for me rather than automatic application pipeline so a web application but online for now: input CV + transcript, and output motivation letter and research statement and if necessary other possible documents. while finding current matches not the past or dead matches. It is dominantly phd but industry also works. I dont want to chance anything drastically but it should have a good ui. you can also change to other free model since the ui is maybe made good with other free models. Also mostly python not java for the cabin sim. Also put effort to fix the issue from yesterday that gibberish outcome please."

DO THIS (in C:\Users\Win11 Pro\Memo\job-assistant - the FastAPI + static UI repo):
1. KEEP the FastAPI + static web app (main.py + app/static). NO big rewrite, NO framework switch.
2. REBRAND/PORT as a FINDER:
   - Input: CV + transcript (already have data/input/Dilek_CV_.pdf + transcripts).
   - Output: motivation letter, research statement, and other possible documents (cover letter / teaching statement / etc.) - EACH tailored per chosen target. The docs live in data/documents/ (already generated, 16 sets).
   - FINDING = rank + surface CURRENT live matches; do NOT auto-submit anywhere (remove/disable any auto-apply / auto-submit flow).
3. LIVE MATCHES ONLY:
   - Reuse the URL-audit knowledge (tools/url_audit.py output: only rows 1,2,3,13 were HTTP 200; rows 4-12 403 duplicate/docs; rows 14,15 None; row16 404). Mark a vacancy live/dead; EXCLUDE or clearly flag dead ones (greyed / "expired" badge); never let a dead URL rank as a top match.
   - Keep 16 vacancies but split them: LIVE (currently reachable) vs DEAD (archived/403/404). Ranking should only use live + clear flags, PhD-dominant, industry OK.
4. GOOD UI:
   - Clean dashboard: CV+transcript upload/load; matches list with live badges, match score, vacancy title + link + deadline (if field exists); a click-openable vacancy; a documents section per vacancy (motivation/research/etc.) with view/download.
   - Make it look professional. You may switch the model to a free one (gemini/grok free tiers, local) if it helps the UI - but it must stay local/offline-capable. NO external API key needed at runtime for the app logic.
5. FIX THE GIBBERISH OUTCOME:
   - The dashboard was producing gibberish text (random chars). Root cause suspected in the intelligence/generator output. Audit the document generation + UI rendering for anything that dumps raw/topk garbage; sanitize: only print well-formed text, strip control chars, cap lengths, never print raw model echo.
6. Tests must pass: pytest stays green.

PROOF (final reply):
- files changed,
- UI: what it now has (finder flow, live-badge, dead-flag, docs view),
- model used + is it free?,
- how gibberish was fixed,
- build/test command + passed: yes/no,
- the URL to open it,
- dead vs live vacancy counts it now shows.

Commit to git. Leave pane idle.
