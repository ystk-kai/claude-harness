---
tracking: review
reviewed_at: 2026-10-22
review_interval_days: 90
---
# 配色の彩度補正 — くすみ・ベージュへの偏りを外す

このスキルの生成規律 (`hallmark`) をそのまま当てると、ライトテーマの地色はクリーム・ベージュに、
アクセントは中彩度に寄る。a11y 検査で比が足りないときも、彩度を削って通す方向に流れやすい。
配色を決めるとき・コントラストを直すときは、hallmark の color 規則と色の gate より**先に**この文書を当てる。

確度: **[原典]** hallmark clone (`distilled_commit` は `hallmark.md` の frontmatter) で確認 /
**[計算]** OKLab→sRGB 変換 (Ottosson の式) と WCAG 2.x の相対輝度で算出。`scripts/chroma-check.py` で再現できる /
**[批評]** `avoid-ai-slop-design` の web-ui.md が出典付きで挙げる tell。

## 偏りの出どころ

- **[原典] ライト地色の約半数が暖色クリーム**。`site/css/tokens.css` のライト地色 17 個 (Lumen の day を含む) のうち 8 個が H 30〜95・C 0.010 以上 (Specimen, Garden, Newsprint, Riso, Bloom, Editorial, Carnival, Hum)。シグナルが無いときの既定ジャンル editorial (`references/genres/editorial.md` の 12 テーマ、うちライト 11) では 6 個
- **[原典] 見本と導出規則が暖色に偏る**。`references/color.md` のライト例は warm-oat (H 80) の 1 本だけ。`references/custom-theme.md` § B.2 は bright/airy と archival/editorial の vibe に warm-tinted の地を割り当て、cool-tinted は technical/clinical だけ。§ G.1 の作例はクリーム地 + テラコッタ
- **[原典] 彩度と使用量の上限**。custom の accent は C 0.12〜0.20 に clamp、ユーザー指定が無ければ 0.12〜0.16 ("mid-saturation; saturation comes from contrast against neutral, not from chroma"、§ B.1)。accent は viewport の 3% 以下 (`color.md` § Principles)、5% 超の塗りは gate 23 で落ちる。playful ジャンルは accent C 0.16 以下 (`genres/playful.md`、Hum だけ例外)。neutral は C 0.005〜0.015 (`color.md`。custom では地 0.020・グレー 0.018 まで)。結果として、画面のほぼ全面が低彩度になる
- **[原典] 純白の禁止**。`color.md` § Bans と gate 7 は `#fff` の地を禁じ、地色を anchor の色相へ寄せる。anchor が暖色なら地はクリームになる。原典の中でも揺れがあり、gate 7・22 は modern-minimal だけ緩め (`genres/modern-minimal.md`)、§ B.2 は ink・accent・グレーが彩度を持てば `#fff` を許す
- **[批評] 題材と無関係に同じ palette が選ばれることが tell**。cream/beige + serif + terracotta は「新世代の AI 既定値」として反復されている (`avoid-ai-slop-design/references/web-ui.md` § 色・グラデーション)。hallmark の既定に従うと、題材を問わずこの配色に寄る

## 地色の決め方 (ライトテーマ)

- 既定は **C 0.006 以下の白** (`#fff` も可)。色相は anchor に寄せてよい。彩度は accent と面の色で持たせる
- 暖色クリーム (H 30〜95 かつ C 0.010 以上) は、題材に紙・印刷物・食・工芸・老舗といった根拠があるときだけ使い、その根拠を hallmark の preview block (Theme 行) に 1 行で書く。根拠が書けなければ C 0.006 以下に戻す
- 「ベージュ禁止」を別の固定既定に置き換えない。直近の生成と同じ配色なら hallmark の 3 軸 (paper band / display style / accent hue) のどれかを動かす

## 彩度の決め方

- 配色の前に、brief から**鮮やかさ**を 1 語で決める: 抑制 / 標準 / 鮮明。抑制は brief に落ち着き・高級・業務の長時間利用などの明示があるときだけで、無指定なら標準
- accent の C: 標準は「0.15 か、その L で sRGB が取れる最大 C の 7 割」の高い方以上。鮮明は最大 C の 9 割以上。hallmark の 0.12〜0.16 の帯や playful の 0.16 上限には縛られない (白地 4.5:1 の L で、0.16 は赤・紫・マゼンタの最大 C の 6〜7 割)
- 色相は brief と anchor から選ぶ。文字色にできるかどうかで色相を選ばない (青・紫への寄りは別の既定値になる)
- 主要 CTA 1 つを accent で塗るのは hallmark でも許されている (`custom-theme.md` § B.7)。鮮明ではさらにセクション帯・大きな面に accent を使ってよいが、これは gate 23 (5%) を意図的に外すことになる
- 標準以上なら、ライトテーマの画面に C 0.15 以上の色が少なくとも 1 役割 (accent か面) ある状態を確認する
- hallmark の gate で落ちる箇所 (7 の `#fff`、22 の彩度 0 のグレー、23 の 5% 超、genre の彩度上限) は、この文書に従った結果なら直さず、stamp の gates 欄に `gates: 7,23 waived (color-chroma)` のように番号を残す

## a11y を彩度でなく明度で満たす

- **比が足りないとき動かすのは L**。色相を保ち、新しい L で取れる最大近くまで C を保つ [計算: 白地で H 145・L 55% の緑は C 0.173→0 で 4.52→4.85:1 と上がる。黄・緑系で彩度が削られやすいのはこのため。同じ幅は L を 1.5% 下げる (L 53.5%・C 0.168 で 4.81:1) だけで得られ、C はほぼ保てる。赤 H 35・L 58% は C 0.20→0 で 4.71→4.28:1 と逆に下がる]。`chroma-check.py` が候補を出す
- **[計算] 白地で比を満たす最も明るい L と、そこで取れる最大 C** (sRGB。script の候補は「比を満たす中で C が最大の L」なので、紫などでは表より暗く鮮やかな値が出る):

  | 色相 (H) | 4.5:1 (本文) の L / 最大 C | 例 | 3:1 (大きい文字・非テキスト) の L / 最大 C | 例 |
  |---|---|---|---|---|
  | 赤 25 | 59.5% / 0.241 | `#ed0027` | 69.0% / 0.199 | `#ff5c58` |
  | 橙 50 | 58.0% / 0.153 | `#bf5900` | 68.5% / 0.181 | `#ee7000` |
  | 黄 95 | 56.5% / 0.116 | `#8b7400` | 66.5% / 0.137 | `#ae9200` |
  | 緑 145 | 55.0% / 0.173 | `#008a23` | 64.5% / 0.203 | `#00ab2e` |
  | 青緑 190 | 55.5% / 0.096 | `#00857f` | 65.5% / 0.113 | `#00a6a0` |
  | 青 255 | 57.0% / 0.188 | `#0075e2` | 67.0% / 0.178 | `#3d95ff` |
  | 紫 295 | 59.5% / 0.249 | `#8f4bff` | 68.5% / 0.187 | `#a47dff` |
  | マゼンタ 340 | 60.0% / 0.261 | `#da00af` | 70.0% / 0.263 | `#ff3fd0` |

- **黄 95 と青緑 190 は本文の文字色にすると C が 0.12 未満に落ちるので、面に回す**。最大彩度の明るい面 (黄 `#ffd600` など) に ink (L 18%) を載せれば 13:1 を超える [計算]。文字色は別の役割の色から取る
- **非テキストは 3:1** (WCAG 2.2 SC 1.4.11)。枠線・アイコン・フォーカスリングまで本文と同じ 4.5:1 に合わせて暗く・くすませない
- **[計算] クリーム地はそれだけで比を約 1 割削る**。白地でちょうど 4.5:1 の色は、地 `oklch(96% 0.018 80)` の上で 4.0:1 前後に落ちる。クリーム地を選ぶと文字色をさらに暗くする必要が生じ、くすみの原因が重なる
- 修正後、各色の C が修正前から 0.03 以上下がっていたら、L の調整で済まなかったかを `chroma-check.py` で確かめ直す

## 使い方

```
python3 ~/.claude/skills/ui-design/scripts/chroma-check.py "58 0.16 35" "#ffffff"
# ratio 4.61:1 ... fg C 0.160 / sRGB 最大 0.204
# 同じ H で比を満たし C が最大の候補: oklch(59.0% 0.207 35) #dd3800
# → hallmark 作例のテラコッタ (C 0.16) は同じ比のまま C 0.207 まで上げられる
```

第 1 引数は L を動かして探す色、第 2 引数は固定する色。面の色を決めるときは面を第 1 引数、ink を第 2 引数にする。

## 範囲外

- チャートの系列色・連続/発散パレット → built-in の `dataviz`
- APCA の Lc 値 → hallmark `references/slop-test.md` の Contrast gate。この文書は WCAG 2.x の比だけで計算している
- Display P3 など sRGB より広い色域の最大彩度。表と script は sRGB に限る

## 棚卸しの当たり先

- hallmark のテーマ集計と色の規則 → hallmark の再蒸留時に `site/css/tokens.css`、`references/color.md`、`custom-theme.md` § B、`slop-test.md` gate 7・22・23、`genres/*.md` の彩度規則を見直す (テーマ追加で比率が変わる)
- cream/beige が tell とされている状況 → `avoid-ai-slop-design/references/web-ui.md` の出典
- WCAG のコントラスト定義 → https://www.w3.org/TR/WCAG22/#contrast-minimum , https://www.w3.org/TR/WCAG22/#non-text-contrast
- OKLab の変換式 → https://bottosson.github.io/posts/oklab/
