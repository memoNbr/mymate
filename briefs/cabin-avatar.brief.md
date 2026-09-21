# CABIN DRAW - CONTINUE (cabin-avatar)

## Captain intent (verbatim)
"I like to continue implementing cabin draw ... I also want to get this realistic
drawing but empty interior for now. we fill it later. maybe it is realistic
drawing of black white porshe. If it is not possible to draw or implement black
white porshe then we need to talk on other options."

## What to do
Continue the cabin drawing in `cabin-agent-sim` (the avatar/cabin renderer). The
cabin is a Porsche (Cayenne) - the whole point right now is the LOOK.

Targets, in order:
1. Realistic drawing of the cabin interior, EMPTY for now (no furniture, no
   occupant fixtures to fill later). Empty = bare sculpted surfaces only.
2. Black/white (monochrome) Porsche look - this is the DEFAULT TRY.
3. If a true black+white / monochrome Porsche render is NOT achievable with the
   current stack, do NOT fake it and do NOT silently draw something else.
   STOP and report 2-3 concrete options (e.g. toon/monochrome shader, silhouette
   render, simplified line-art sheet, or a different renderer) so the captain can
   pick. "We need to talk on other options" is the captain's explicit fallback.

## Constraints
- Do the work in `C:\Users\Win11 Pro\Memo\cabin-agent-sim`.
- Keep the avatar agent loop running (perceive->reason->act, trust survey) - the
  interior LOOK changes, not the cognitive loop.
- Whatever you draw must actually render. If you can, build it (node/npm build 
  or whatever the repo uses) so it's not just source-level.
- Do not redesign the whole app; this is an incremental visual pass on the cabin.
- Do not destroy the seat/agent-mount infrastructure - those are needed later
  when the captain wants to fill the interior.
- Monochrome-first: try hard for black/white. Red/GTS accents are NOT wanted
  right now unless they are a tiny hairline accent.

## Proof of done (put in final reply)
- the file(s) you changed in cabin-agent-sim,
- a one-line "what the cabin NOW looks like (empty interior, black/white?)",
- whether black/white Porsche rendering was possible: yes|no + why not (if no),
- build/verify command you ran + it passed: yes|no.

## After
Commit to git in cabin-agent-sim (`git add -A && git commit`), leave the pane
idle, and report back to the captain with the "proof of done" block.
