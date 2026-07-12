# Rewrite examples — bad / fixed / over-fixed

Each shows the slop, a fix, and an over-correction to avoid. The over-fix matters: anti-slop has its own failure mode.

## A. Briefing intro

- ✗ slop:「近年、AI 技術の進化により、セキュリティの重要性がますます高まっています。本記事では、その本質に迫ります。」(定型出だし・便利語・本質・メタ宣言)
- ✓ fix:「公開モデルでも数千件規模の脆弱性発見が現実になった。守りの軸は『見つける』から『検証して直す』へ移る。」(立場・具体・主体)
- ⚠ over-fix:「正直、もう手で守るとか無理ゲーw 結局みんな詰んでる。」(briefing に不適切な毒・カジュアル → document-types 違反)

## B. False agency

- ✗「データが課題を浮き彫りにしている。」
- ✓「ログを数えると、未封じ込めの KEV 該当資産が 12 件あった。」
- ⚠ over-fix:「俺がログ見たらマジでヤバい数字出てきて震えた。」(SNS なら可、技術文書では不可)

## C. False contrast / 命題見出し

- ✗ H2「Claude Security は単なる SAST ではない。革命だ。」
- ✓ H2「Claude Security の処理範囲」/ 本文「SAST が拾えない認可・業務ロジックの欠陥を検出できる。」
- ⚠ over-fix: 見出しを全部そっけない体言句にして、要点が一切立たない（メリハリ消失）。substantive な要点見出しは残してよい。

## D. Hedging ritual

- ✗「ケースバイケースであり、一概には言えませんが、状況に応じて判断することが重要です。」
- ✓「差分中心なら 1 MR 約 0.5 ドルで回る。全体スキャンを毎回やると跳ねるので頻度で絞る。」
- ⚠ over-fix:「絶対にこれが正解。例外なし。」(本物の不確実性を握りつぶす無根拠断言)

## E. Rhythm / endings

- ✗ 全文「〜です。〜です。〜できます。」
- ✓ 「ここが要。あとは運用次第だ。毎朝の確認を 30 分削れた。」(長短・語尾を混ぜる)
- ⚠ over-fix: 体言止めと短文を連打して、ぶつ切りで読みにくい。

## 使い方

直したら scoring.md で再採点し、banlist.md / syntax-patterns.md を走査。over-fix 欄に当てはまっていないか（毒の入れすぎ・メリハリ消失・無根拠断言・ぶつ切り）を最後に確認する。
