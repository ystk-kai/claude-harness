---
tracking: review
reviewed_at: 2026-10-19
review_interval_days: 180
---
# Syntax patterns — detect & fix

These catch "generated-ness" deeper than vocabulary. Make each a review question.
Fix in this order: **立場 → false agency → 構造 (§2–7, 11) → 語彙 (banlist) → 記号**. Fixing only vocabulary and symbols leaves the smell.
When revising someone else's text, every fix below is bounded by the revise-mode rules in SKILL.md (no new facts, no confidence change, meaning check at the end).

## 1. False agency（無生物主語）

Fix only two kinds: **an inanimate subject given feelings or intent**, and **a human judgment written as the action of an abstract noun**.
- ✗「課題が浮き彫りになる」「文化が醸成される」→ ✓ name who did what — **only if the text or material says who**. If it doesn't, don't invent an actor; leave it or ask.
- ✗「データが課題を浮き彫りにしている」→ ✓「ログを数えると、未封じ込めの資産が 12 件あった」(the count must exist in the material)
- 大きな主語も同類: ✗「多くのエンジニアが」→ ✓ the actual scope you can back up.
- Keep: a tool's objective function (「ガイドラインがチームに変化を促す」), a paper's 「〜ことを示している」 when citing evidence, and organizations/people as subjects (「Anthropic が示した」— the actor is real).

## 2. 命題型 H2（断定見出しの押し付け）

Each heading carries a thesis → reads like a string of tiny TED talks.
- New writing: conclusion headings are fine — but don't give every heading the same shape, and never make a heading more confident than its body.
- Revising: rewrite at most 2–3 headings. A pile-up of identical thesis headings is the target, not thesis headings as such. Guides and references prefer short names (名詞句).
- ✗「○○もまた同じ方向を指している」→ ✓「○○の話」/「○○の分界」

## 3. 打ち消し・偽の対句（Not X. It's Y. / 「XではなくY」）

Three kinds, three treatments:
- **Pre-emptive denial** of a belief nobody stated (「〜すれば自動的に〜わけではない」) → delete the sentence — unless the next sentence stops making sense without it.
- **「A は B ではない。C だ」** where only C matters → join into the affirmative sentence.
- **Negation that narrows meaning**, corrects a common misreading, or warns → keep. 「件数ではなく修正時間で測る」is a real choice.
- 「Aでない。Bでもない。Cだ」: if readers are likely to assume A or B, keep the negation in one sentence; if a preceding question named both, 「どちらでもない。」is enough; if the negation only adds punch, keep just「Cだ」.
- 「A ではなく、B でもある」stays as one sentence.
- Density check: 「ではなく／だけでなく」3+ times, or 4+ sentence-final negations, in one document → suspect overuse.

## 4. フック→反転の出だし

- ✗「ChatGPTで誰でも記事が書ける。しかし——」→ ✓ 控えめに始める「最近、手で書く方が早い気がする」
- 煽り出し→逆張りのテンプレを避ける。

## 5. メタ構造宣言

- 「以下の 3 つの観点から説明します」: if the stated number matches the items, merge it into one sentence with the content; in a long explanation where it guides the reader, keep it.
- If the number doesn't match the items, don't add or drop items to fit — ask the writer.
- ✗「それぞれ順に見ていきましょう」「ここからが本題です」(no information) → delete.

## 6. ❌/✅ 比較（スライド調 bad-then-good）

- ✗ bad例→good例の対カードを並べる → ✓ 地の文で展開。(図解でも「言い換え」だけの対比は避け、関係/閾値/境界を足す)

## 7. 並列の形を中身に合わせる

- Don't manufacture 「3つのポイント」. In new writing, if 2 or 1 suffice, use that. Three parallel blocks in a row → switch form.
- When revising, don't add or remove items just to change a count.
- The reverse also applies: 3+ coordinate items buried in a long sentence → open them into a list. Decorative bullets that carry one thought → fold back into prose.

## 8. 文末の単調

- Keep one style: 敬体 (です／ます) or 常体 (だ／である) throughout; don't mix them to create variety. Technical-writing lint (`no-mix-dearu-desumasu`) flags the mix as an error.
- Vary through sentence length and construction, not by inserting 体言止め or questions as a device. No questions in technical docs.
- When revising, sentence endings alone are not a reason to edit a sentence that reads naturally.
- Don't string together sentences under ~10 characters. Evaluation-only fragments (「速い。軽い。安い。」) are ad copy — fix them.

## 9. 一文圧縮（Wikipedia 調）

- 年代・人名・評価を 1 文に詰め込まない。確度の低い情報は伝聞で「およそ N 日で設計されたらしい」。

## 10. 儀式化した保険・遠い話者

- 各節末の「個人の見解ですが」を 1 記事 1〜2 回に。
- ✗「現代社会では重要だ」→ ✓「最近気になる」/「この環境では効く」。

## 11. 型としての構造 slop

- **体験の壮大化**: a routine experience framed as a 設計／装置／境地 (and 必殺技造語) → describe what happened at its actual size.
- **劇的な断片化**: 「シンプル。それだけ。それが本質。」— staccato fragments as a climax → one plain sentence. (This is also why §8 does not prescribe short sentences.)
- **体験→引用→抽象化** run three times in a row (anecdote, famous quote, lesson) → break the template; keep the parts that carry information.
- **全方位肯定**: 「それぞれに独自の強みがあり」— praising every option to avoid a position → say which fits when, or say plainly that you can't tell.

## 12. 読解負荷（構文）

- **二重否定**: fold into an affirmative **without flipping its truth value**. 「招かないとは言えない」=「招くことがある」, not「招かない」. Check the folded sentence against the original before keeping it.
- **係り受け**: long pre-noun modifiers → split into a following clause. 「の」at most twice in a row. Make an ambiguous dependency unique with a comma or word order.
- **間を作るだけの読点**: a comma right after a short subject / object / topic (「は」「が」「を」「も」「では」「とは」) that separates nothing (「回覧板は、木曜の朝に回します」) → remove the comma only; keep word order and predicate. Keep it after a long subject or clause, where another actor follows the topic, before an insertion, between listed items, and where removing it changes what the clause attaches to (「店長は、慌てて逃げた客を追いかけた」).
- **数値の目安 (技術文書)**: 1 文 100 字 (厳しめなら 90)、読点 1 文 3 個、漢字の連続 6 字 (`textlint-rule-preset-ja-technical-writing` の既定値)。超えたら分割・語順・かな書きを検討する目安で、AI らしさの指標ではない。固有名詞の漢字連続は除く。
- **名詞化**: verbal nouns doing the work of a verb (「〜の実施を行う」) → back to the verb.
- **段落内の言い換え反復**: restating the same point, or re-summarizing right after describing → cut only the repeats that add no information. If unsure, keep.

## 13. 読み手が取れない言い回し

Signs: re-naming something already named, personification, word-for-word English, mismatched collocations, engineer slang, nominalized actions, metaphors whose content can't be seen.
- Test by translating back to English, or by rewriting as a plain verb sentence; if the meaning won't come through, replace with ordinary words.
- **成り立たない比喩**: a metaphor that reads smoothly but falls apart when you extract just subject and predicate (「眠気が定規になる」), or whose verb doesn't fit the subject (「嵐がそっと耳打ちした」). In technical and business docs, write what actually happens. In essays, keep a metaphor if a reader can guess what it means, or if the next sentence explains it. If your fix comes out as 「〜がただ黙って〜していた」, keep the original instead.
- If you can't narrow it to one reading, don't guess — list the candidate readings and ask the writer.
