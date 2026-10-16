# MAPPING: 原典の規則と avoid-ai-slop-ja の対応表

自作の対応表。蒸留版 (`references/*.md`) は「原典に何が書いてあるか」の地図に限り、こちらは「原典の規則が
`avoid-ai-slop-ja` のどこに入っているか / 入っていないか」を持つ。蒸留版と違い、**原典の SHA ではなく
`avoid-ai-slop-ja` 側の変更で古くなる**ので鮮度チェックには乗らない。

見直すタイミング:

- `avoid-ai-slop-ja` の SKILL.md / references を直したとき (取り込み候補を反映したときを含む)
- 対応表を持つ原典 (`stop-ai-slop-jp` / `textlint-rule-preset-ja-technical-writing`) を再蒸留したとき

作成時点: 2026-10-16 (`stop-ai-slop-jp` `e09d327` / `textlint-rule-preset-ja-technical-writing` `5e73caa` と照合)。

## stop-ai-slop-jp → avoid-ai-slop-ja

`avoid-ai-slop-ja` は原典の大原則・5 軸採点・構造/語彙の大半を英語見出しの散文スキルに組み替え、**文書種別による抑制**と **over-fix (過剰修正) への歯止め**を独自に足したもの。対照は `avoid-ai-slop-ja` 側の各ファイル を本 clone と突き合わせた結果。

| avoid-ai-slop-ja 側 | 原典の対応箇所 | 独自に足された・変えられた部分 |
|---|---|---|
| SKILL.md 冒頭〜§ When not to run | SKILL.md § 大原則 (3 問はほぼそのまま) | 3 問を 5 軸の前倒しと位置づけ衝突時は 5 軸優先 / formal 文書では「書き手 = 組織の立場」/ 体験の捏造禁止 (以上 § First principle) / 検出器が当てにならないという前提 (冒頭) / Quick path / When not to run / 1 文書 1 回まで (いずれも原典に無い) |
| SKILL.md § Process | SKILL.md § 修正の優先順位 | 順序が別物: 文書種別 → 採点 → banlist → 構文 → ムラ → 書き直し。原典の「立場 → 主体 → 構造 → 語彙 → 記号」の優先順位リストは書かれていない。ただし「語彙・記号だけ直しても効かない、先に書き手を戻す」趣旨は § First principle ("vocabulary/symbol fixes won't help — restore the author first") に大原則側から入っている |
| references/scoring.md | SKILL.md § 採点 (5 軸・35/50) | 35 以上でも重大な構文 slop は直す / 低い・高いの列 / 「立場 ≠ 無根拠な断言」/ 段落あたり 1 つの固有名・数値 / 採点例 2 本。音読の測り方はクイックチェック冒頭の転用 |
| references/banlist.md | references/phrases.md § 1・2・3 (横文字メタファーのみ)・4 (強い評価+根拠なし、三段ヘッジ → Tier 3「Necessary hedges (1 まで)」)・5・7・8 | **3 段 Tier (常時禁止 / 原則回避 / 文脈次第) は独自**。原典は頻度で判定する。便利語 (課題 / 活用 / 推進…)、冗長語尾「〜することができます」、根拠なし強評価の「ゲームチェンジャー」は原典に無い追加。全角ダッシュを「挿入用法のみ 1 回まで」と緩め、装飾絵文字は逆に常時禁止へ締めた |
| references/syntax-patterns.md | references/structures.md § 1-1・1-3 (→ 1)、3-1 (→ 2)、2-1・2-2 (→ 3)、3-2 (→ 4)、3-4 (→ 5)、3-5 (→ 6)、4-4 (→ 7)、4-5 (→ 8)、3-3 (→ 9)、5-2・5-3 (→ 10) | 組織・人主語は false agency ではないという注記 / 中身のある要点見出しは命題型でも可 / 「件数ではなく修正時間で測る」のように実質的な選択なら「XではなくY」の否定形のまま残してよい (原典 § 2-1 も違いを具体的に書く対比は認めるが、否定で並べる形は避けよとする) / ❌/✅ を図解にも適用 |
| references/variance.md | references/structures.md § 4-1 (ムラ 5 種)・4-2・4-5 | 文書種別の予算内でのみ / 停止条件 (ブリーフィング等で誤字・毒を足し始めたら止める、強引な一言が全段落に付いたら新しいテンプレ) |
| references/rewrite-examples.md | 対応なし (examples.md の 17 例は 1 本も移していない) | 5 例すべて独自 (ブリーフィング・セキュリティ題材)。各例に over-fix 欄を持つのは原典に無い型 |
| references/document-types.md | 対応なし | 全体が独自。原典は個人記事前提で文書種別の規定を持たない。毒・誤字・カジュアル一人称を formal 文書で除外し、「わざとの誤字運用は避ける」とする |

原典にあって `avoid-ai-slop-ja` のどこにも無いもの (grep で確認): 体験の壮大化と必殺技造語による壮大化 (structures.md § 1-2。語彙だけは banlist Tier 2 に一部残る)、劇的な断片化 (§ 2-3)、体験→引用→抽象化テンプレ (§ 4-3)、全方位肯定 (§ 6-1。採点の「両論併記」と書き換え例 D に痕跡のみ)、形容詞・心情への「」(SKILL.md ルール 13)、中黒並列 (ルール 14)、過剰なカタカナ表と英語固有名詞の律儀さ (phrases.md § 3)、結論回避・三段ヘッジ・曖昧な断言・弱い否定の各リスト (§ 4。結論回避は例 D にのみ)、根拠なし副詞・「すぎる」・(笑) の頻度上限 (§ 6)、全角に紛れた半角スペース (§ 8)、そして語彙は「撒くな、全部消す必要はない」という頻度原則。翻訳調動詞と必殺技造語も一部の語が抜けている (例: 対比をなしている・捉える・論じる、虚飾・禁欲的・冷徹)。

## textlint-rule-preset-ja-technical-writing → avoid-ai-slop-ja

**原典は LLM・生成文・AI に一切言及しない** (README.md / CHANGELOG.md を検索して確認)。以下は原典の規則を `avoid-ai-slop-ja` の項目に当てた対応で、原典の主張ではない。

| preset ルール | avoid-ai-slop-ja 側 | 関係 |
|---|---|---|
| `ja-no-redundant-expression` (することができる) | references/banlist.md Tier 2「冗長語尾」 | 同じ例。preset は機械検出できる |
| `ja-no-weak-phrase` | references/banlist.md Tier 3「Necessary hedges (1 まで)」・syntax-patterns.md §10 | preset は技術文書で全面禁止、avoid-ai-slop-ja は本物の不確実性なら 1 回まで許容 |
| `no-exclamation-question-mark` | syntax-patterns.md §8「問いを混ぜる」・variance.md「question where natural」 | 技術文書では衝突する |
| `no-mix-dearu-desumasu` | syntax-patterns.md §8「断定・体言止めを混ぜる」 | ですます本文に「だ/である」を混ぜると preset 既定で違反 |
| `sentence-length` / `max-ten` | syntax-patterns.md §9「一文圧縮」・variance.md「文長のムラ」 | avoid-ai-slop-ja は定性のみ。preset が数値上限を与える |
| `no-doubled-joshi` の処方 (強調語「実際に」を削る) | banlist.md / syntax-patterns.md の削減方針 | 方向は同じ |
