---
name: avoid-ai-slop-design
description: Review and fix "AI slop" in visual design — web UI, landing pages, slides, diagrams, and AI-generated images that look default-AI (purple-blue gradients, Inter-everywhere, identical feature-card grids, glassmorphism, emoji icons, uniform bullet rhythm, Midjourney default look). Use when designing or reviewing UI / pages / decks / figures / generated images, when asked to make a design "less AI-ish / AIっぽくない", or before shipping any AI-assisted visual artifact.
---

# Avoid AI slop (design)

Design slop is the statistical average of the training corpus: safe, symmetric, purple, interchangeable. No single tell proves anything — several co-occurring tells mark a design as *unintended*. The knowledge base is self-contained in `references/` (sources cited inline; measured research distinguished from designer folklore).

The cardinal rule (shared with `avoid-ai-slop-ja`): **breaking uniformity is a means, not a goal.** Don't swap the AI template for an "anti-AI template" — every visual decision should trace to content, brand, or audience. And fixing 記号 (purple gradients, Inter) without fixing 構造 (meaningless hierarchy, decoration without purpose) leaves the design just as hollow.

## Process (run in order)

1. **Identify the artifact type and its budget** — web UI / slide deck / diagram / image, plus the governing brand or design system. If a brand guide or design system exists, conformance to it outranks every technique below.
2. **Scan the tell catalogue for the type**:
   - Web UI: `references/web-ui.md` (color/gradient, typography, layout, motion, UI copy)
   - Slides & diagrams: `references/slides-diagrams.md` (uniform bullets, rigid layout, 図の文法エラー)
   - Images & illustration: `references/images.md` (durable vs dated tells — anatomy tells are decaying, physics tells persist)
3. **Separate 記号 from 構造** — list symbol-level fixes (palette, fonts, icons) and structure-level fixes (hierarchy matching importance, relationships made explicit, content-driven layout) independently. Both are required.
4. **Apply `references/prescriptions.md`** — constraints before generation (tokens, negative constraints, WCAG), content-connected decisions during design, separated evaluation after (5-second / first-click / one-variable comparison).
5. **Hand text to the sibling skill** — UI copy, slide prose, and Japanese body text go through `avoid-ai-slop-ja`; the two skills catch the same slop from the visual and verbal sides.

## Quick checklist

- [ ] Palette/fonts chosen for a reason traceable to brand or content — not indigo/purple-blue gradient, cream-beige, or Inter-by-default. Text contrast ≥ 4.5:1 (3:1 for large text)
- [ ] Real typographic hierarchy (role-based pairing, size + weight + spacing), not one family with weight changes
- [ ] No identical icon-tile feature-card grids, badge-pill reflexes, cardocalypse, or uniform radius/shadow everywhere; layout derived from actual content, visual weight matches importance
- [ ] Icons: one family, adopted for a reason; no emoji-as-icons; ✨ never means "AI" without a label
- [ ] Motion explains state, continuity, or attention — otherwise deleted
- [ ] Slides: type/color/icons unified across the deck, layout varies only at meaningful transitions; bullet rhythm broken on purpose
- [ ] Diagrams: one relationship type chosen (parallel / causal / sequence / comparison); every arrow and label verified; built as editable vector, not a single raster
- [ ] Images: default AI look actively steered away (art-direction prompt + references); no Japanese text baked in; light/shadow/reflection consistent
- [ ] Symbol fixes accompanied by structure fixes — if only the colors changed, it is still slop
