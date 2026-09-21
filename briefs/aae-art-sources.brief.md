# AAE portal decoration — verified PD/CC0 Romantic-era image sources

Handed to aae-core (jobcore pane) by the margin-conductor research task. Verified 2026-09-21:
every direct URL below returned HTTP 200 image/jpeg at probe time. No assets downloaded;
vendor each file locally into `app/static/` yourself (localhost-only rule = no remote fetch at runtime).

## Verified set (direct URLs + rights + attribution)

1. **Barend Cornelis Koekkoek, Winter Landscape, Holland, 1833**
   The Met, accession 87.15.30 (object 436826) · Public Domain, Met Open Access (CC0)
   - Record: https://www.metmuseum.org/art/collection/search/436826
   - Direct: https://images.metmuseum.org/CRDImages/ep/original/DP143197.jpg
   - Attribution: B. C. Koekkoek, “Winter Landscape, Holland”, 1833, The Metropolitan Museum of Art, 87.15.30; public domain (Met Open Access, CC0).

2. **Caspar David Friedrich, Two Men Contemplating the Moon, ca. 1825–30**
   The Met, accession 2000.51 (object 438417) · Public Domain, Met Open Access (CC0)
   - Record: https://www.metmuseum.org/art/collection/search/438417
   - Direct: https://images.metmuseum.org/CRDImages/ep/original/DP-31997-001-NEW.jpg
   - Attribution: C. D. Friedrich, “Two Men Contemplating the Moon”, ca. 1825–30, The Metropolitan Museum of Art, 2000.51; public domain (Met Open Access, CC0).

3. **John Constable, Cloud Study, 1821**
   Yale Center for British Art, accession B1981.25.155 (catalog tms:666) · Public Domain (CC0, per record)
   - Record: https://collections.britishart.yale.edu/catalog/tms:666
   - IIIF manifest: https://manifests.collections.yale.edu/ycba/obj/666
   - Direct (IIIF, resize any width via `/full/,W/0/default.jpg`):
     https://images.collections.yale.edu/iiif/2/ycba:eec1f2a3-1b04-4d67-98d7-cfe3a81b8255/full/,600/0/default.jpg
   - Attribution: John Constable, “Cloud Study”, 1821, Yale Center for British Art, Paul Mellon Collection, B1981.25.155; Public Domain (CC0).

4. **J. M. W. Turner, Dort, or Dordrecht: The Dort Packet-Boat from Rotterdam Becalmed, 1818**
   YCBA, accession B1977.14.77 (catalog tms:34) · Public Domain (CC0, per record)
   - Record: https://collections.britishart.yale.edu/catalog/tms:34
   - IIIF manifest: https://manifests.collections.yale.edu/ycba/obj/34
   - Direct (IIIF): https://images.collections.yale.edu/iiif/2/ycba:03512ed2-3a43-4e84-af7b-7fd7cda3663a/full/,600/0/default.jpg
   - Attribution: J. M. W. Turner, “Dort, or Dordrecht …” 1818, Yale Center for British Art, Paul Mellon Collection, B1977.14.77; Public Domain (CC0).

5. **Caspar David Friedrich, After the Storm, 1817**
   SMK Copenhagen, accession KMS8817 · Public Domain, CC0 (SMK Open; Commons license field CC0)
   - Record: https://open.smk.dk/en/artwork/image/KMS8817
   - Commons page: https://commons.wikimedia.org/wiki/File:Caspar_David_Friedrich,_Efter_stormen,_1817,_KMS8817.jpg
   - Direct (Commons CDN, resolved via API):
     https://upload.wikimedia.org/wikipedia/commons/3/3a/Caspar_David_Friedrich%2C_Efter_stormen%2C_1817%2C_KMS8817.jpg
   - Attribution: C. D. Friedrich, “After the Storm”, 1817, Statens Museum for Kunst, KMS8817; CC0.

6. **KOEKKOEK, Forest Scene (Wodan's Oaks), 1848** — *Rijksmuseum record only; direct CDN URL is behind their “Download image” endpoint, so pull from the record page.*
   - Record: https://www.rijksmuseum.nl/en/collection/SK-A-1546
   - License: Rijksmuseum CC0 · Attribution: B. C. Koekkoek, “Forest Scene (Wodan's Oaks)”, 1848, Rijksmuseum, SK-A-1546; CC0.

## Notes / caveats
- SMK’s own IIIF host (iiif.smk.dk) was unreachable from this network; use the Commons CDN URL above (bypasses museum image-terms issues; painting PD).
- Rijksmuseum IIIF image API guesses returned 404; record page is the authoritative download source.
- Do NOT use National Gallery London’s *Rain, Steam and Speed* images — museum terms are restrictive (CC BY-NC-ND 4.0). OK only via PD-Art reproductions on Commons if ever needed.

## Recommended placements (decorative only, from portal review)
- **PII gate vignette band** (ghosted, ≤12% opacity, fades into `--panel`): Koekkoek #1 (winter stillness).
- **Tab detail strip** under the six tabs (thin horizontal band): Constable #3 (cloud band reads perfectly in a strip).
- **Empty states** (no live openings / no record yet): Turner #4 (packet boat = journey motif).
- **Ornament / footer motif**: Friedrich #5 or #2 (moon contemplation).
- **Full-bleed alternative**: Koekkoek #6 when downloaded from Rijksmuseum record.

## Guardrails (keep the integration honest)
- All images decorative: `aria-hidden="true"`, `role="presentation"`, empty alt (background `div`s — no alt text).
- Serve locally from `/static`; never fetch remote at runtime (privacy, localhost-only).
- Sepia/duotone via CSS `filter: sepia(...)`, keep contrast (no text over art), print-safe, static (no motion → `prefers-reduced-motion` unaffected).
- No per-card thumbnails in Opportunities/Fit; hierarchy must come from headings/folio numerals, not images.
- Put attribution/license in a source-code comment at the asset reference, not as visible UI text.