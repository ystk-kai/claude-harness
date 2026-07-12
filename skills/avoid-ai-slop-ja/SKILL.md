---
name: avoid-ai-slop-ja
description: Review and rewrite Japanese (and JP-EN mixed) prose to remove "AI slop" — over-smooth uniform tone, generic buzzwords, weak agency, ritual hedging, false contrasts, propositional headings, and other generated-text tells. Use when writing, editing, reviewing, or scoring Japanese articles, memos, briefings, docs, release notes, social posts, or public-facing copy, or when asked to make text "less AI-ish / 人間が書いたように".
---

# Avoid AI slop (Japanese prose)

AI-slop prose is surface-polished but hollow and uniform. Detectors are unreliable (human raters do no better than chance), so this skill is a manual review/rewrite method, not a detector. The knowledge base is self-contained in `references/`. Method adapted from `iKora128/stop-ai-slop-jp`.

The cardinal rule: **edge (variation, bluntness, a stance) is a means to break uniformity, not a goal.** Don't trade AI-uniform for an "anti-AI template". And always filter techniques by document type (a security briefing is not a personal blog).

## First principle — suspect the absent writer (書き手の不在)

The root cause of "AI smell" is the **absent writer**: no one is behind the text taking a position. Before and after writing, answer three questions (大原則, from stop-ai-slop-jp):

1. 自分は何を「○○だ」と引き受けているか（取っている立場）
2. 反証可能な具体的主張があるか
3. 同じテーマの平均的な記事と何が違うか

If you can't answer these, vocabulary/symbol fixes won't help — restore the author first. This is the highest-leverage move, especially for personal/opinion writing. The 3 questions are the front-loaded 立場/具体 axes of the full score; if they conflict with the full 5-axis result, the full score wins. In **formal** docs "the writer" = the organization's position — show humanity through concrete facts/numbers, not first person or snark, and never fabricate experience to fill the gap.

**Quick path (light use):** short pieces or drafts → answer the 3 questions, then scan Tier-1 banlist + false agency + false contrast (catches most slop in minutes). Anything published, formal, or high-stakes → run the full 6-step process below.

## Process (run in order)

1. **Decide the document type** — it sets how much variation / bluntness is allowed. See `references/document-types.md`.
2. **Score 5 axes** (立場・リズム・主体性・具体性・削減), 1–10 each. Below 35/50 → rewrite; at 35+ still fix any critical syntax slop. See `references/scoring.md`.
3. **Scan the banlist** (3 tiers: always-ban / avoid-by-default / context-OK). See `references/banlist.md`.
4. **Check syntax patterns** (false agency, propositional H2, false contrast "XではなくY", hook-then-reversal, meta-structure announcements, ❌/✅ slides, triple-parallels, monotone sentence endings). See `references/syntax-patterns.md`.
5. **Keep deliberate ムラ** (variation in length / density / tone / conclusion / detail) within what the doc type allows. See `references/variance.md`.
6. **Rewrite**, then re-check 削減 (cut filler) and 具体性 (names/numbers/examples). Study `references/rewrite-examples.md` — including the over-corrected examples.

## Quick checklist

- [ ] Document type identified; bluntness/variation budget set accordingly.
- [ ] No always-ban items (装飾絵文字 / 全角ダッシュ乱用 / `**` residue / 根拠なし強評価).
- [ ] No inanimate subject performing judgment/intent (false agency).
- [ ] No empty "XではなくY" / propositional-heading pile-up / meta-structure openers.
- [ ] Sentence length and endings vary; not every paragraph lands the same way.
- [ ] Every key claim is anchored to a name / number / example; a stance is taken with a stated basis (≠ unfounded assertion).
- [ ] 5-axis self-score ≥ 35/50 and no critical syntax slop remains.
