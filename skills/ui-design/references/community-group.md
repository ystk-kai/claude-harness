---
source: https://github.com/design-tokens/community-group
distilled_commit: 16c902d9327c18290e956a21130c445f1b88c40f
distilled_at: 2026-08-03
---

# Design Tokens Community Group (DTCG) 仕様 蒸留版

W3C Design Tokens Community Group の公式リポジトリ。design token の交換フォーマットを定める技術仕様 (ReSpec ソース) と、その JSON Schema を持つ。用途は **UI 生成時に DESIGN.md / theme 定義 / トークンファイルを書くときの標準語彙と形式の典拠**。「色をどう書くか」「typography をどう構造化するか」「別名をどう張るか」を、ツール固有の方言ではなく仕様の語彙で決めるために引く。

## Contents

- まず押さえる
- 型の索引
- 機構・章の索引
- 蒸留の範囲外

## まず押さえる

1. **stable 版は `2025.10` (2025-10-28)**。README.md の Versions 表で `2025.10` のみ status が Stable、first / second / third-editors-draft は Draft、`preview` は Experimental。表に「tools can use the date as a version number to signify compliance」と明記があるので、生成物に版を書くなら `2025.10` を使う (README.md)。

2. **リポジトリの `technical-reports/` は「drafts にデプロイされる編集中ソース」**。`technical-reports/format/index.html` の respecConfig は `specStatus: 'CG-DRAFT'` / `isPreview: true` で、`latestVersion` が `https://www.designtokens.org/TR/2025.10/format/` を指す。main への merge は `/TR/drafts/` に自動デプロイされ、ビルド出力は `gh-pages` ブランチにある (technical-reports/README.md)。**公開済み 2025.10 の HTML スナップショットは main に無い** (`www/public/TR/2025.10/` は画像 1 枚のみ)。一方 `schemas/src/2025.10/` は 2025.10 版として明示的にバージョン付けされており、型や制約の**機械可読な正**はこちら。

3. **3 モジュール構成**: Format (`technical-reports/format/`)・Color (`technical-reports/color/`)・Resolver (`technical-reports/resolver/`)。各 `index.html` の `data-include` が章順の正で、Format は terminology → file-format → design-token → groups → aliases → types → composite-types の順。

4. **ファイルは JSON**。MIME は `application/design-tokens+json` を SHOULD (`application/json` でも可、ツールは両方サポート必須)、拡張子は `.tokens` / `.tokens.json` を推奨 (technical-reports/format/file-format.md)。仕様本文の例は先頭に `"$schema": "https://www.designtokens.org/schemas/2025.10/format.json"` を書くが、`$schema` 自体は仕様の一部ではない (schemas/src/2025.10/format.json の `$comment`: "$schema is not part of the official DTCG specification")。

5. **token と group を分けるのは `$value` の有無だけ**。`$value` を持つ object が token (親 object の key が token 名)、持たない object が group。両方を兼ねる構造は invalid でツールはエラーにする。`$value` は token の唯一の必須プロパティ (technical-reports/format/design-token.md「Name and value」, technical-reports/format/groups.md「Group Structure」)。

6. **token の追加プロパティは `$description` / `$type` / `$extensions` / `$deprecated`** (すべて任意)。`$description` は plain JSON string。`$extensions` はベンダー固有データ置き場で、キーは reverse domain name 記法推奨、**理解できない拡張データもツールは保存時に保持しなければならない**。`$deprecated` は `true` / 説明文の string / `false` (親の既定を打ち消す) (technical-reports/format/design-token.md)。

7. **`$type` は推測されない。決まらなければ token は invalid**。解決の優先順は (1) token 自身の `$type` → (2) 解決後の group の `$type` → (3) 親 group を上に辿って最も近い `$type` → (4) 決まらず invalid。値が参照なら参照先の解決型を採る。`Tools MUST NOT attempt to guess the type of a token by inspecting the contents of its value` (technical-reports/format/design-token.md「Type」, technical-reports/format/types.md, technical-reports/format/groups.md「Type Inheritance」)。`$type` の値は case-sensitive。

8. **命名制約**: token / group 名は `$` で始めてはならない (仕様プロパティの予約接頭辞)。加えて alias 構文のため `{` `}` `.` を**名前のどこにも**使えない。名前は case-sensitive で大小のみ違う名前は valid だが、変換出力で衝突するためツールは警告してよい。schema の正規表現は `^[^${}.][^{}.]*$` (technical-reports/format/design-token.md「Character restrictions」, schemas/src/2025.10/format.json の `tokenOrGroupName`)。

9. **group のプロパティは `$description` / `$type` / `$extends` / `$deprecated` / `$extensions`**。group は「任意のまとめ」でしかなく、`tools SHOULD NOT use them to infer the type or purpose of design tokens`。group 自身に代表値を持たせたいときは予約名 `$root` を使い、参照は `{color.accent.$root}` と書く (`{color.accent}` は group を指すので無効な token 参照) (technical-reports/format/groups.md)。

10. **参照は 2 系統ある**。中括弧 `{group.token}` は **token 全体のみ**を対象とし、暗黙に `/$value` を付けて解決する。JSON Pointer は `$ref` プロパティで書き (`"$ref": "#/colors/blue/$value/components/0"`)、任意の文書位置・配列要素・サブプロパティに届く。**ツールは両方の実装が MUST**。中括弧では配列 index にアクセスできない。alias の連鎖は可 (explicit な値まで辿る)、循環参照は禁止でチェーン全体をエラーにする (technical-reports/format/aliases.md)。

11. **`$extends` は group 継承で、JSON Schema の `$ref` の糖衣**。token を参照してはならない。group 内の解決順は local token → `$root` → `$extends` 由来 (上書きされていなければ) → nested group 再帰。`$extends` の循環も検出必須 (technical-reports/format/groups.md「Extending Groups」「Processing Rules」)。

12. **型は 13 個で全部**。`schemas/src/2025.10/format/tokenType.json` の enum が正: `color` `dimension` `fontFamily` `fontWeight` `duration` `cubicBezier` `number` `strokeStyle` `border` `transition` `shadow` `gradient` `typography`。**`string` 型は存在しない** (`schemas/src/2025.10/format/values/color.json` の `$comment` が "no string token type exists in the specification" と明言。ただし technical-reports/format/groups.md の型継承の例には `"$type": "string"` が現れるので、本文の例より schema enum を信じる)。opacity / percentage / font style / file は未定義で、technical-reports/format/types.md の「Additional types」に検討中として挙がっているだけ。

13. **色の値は hex 文字列ではなく object**。`colorSpace` (必須) と `components` (必須、要素は数値または `"none"`)、任意で `alpha` (0〜1、省略時 1) と `hex` (6 桁 CSS hex の fallback。alpha と衝突しないよう 8 桁は不可)。`"none"` は「その成分が該当しない」を `0` と区別するためのもので、補間結果が変わりうる (technical-reports/color/color-type.md)。

14. **composite type の sub-value は「明示値」か「同じ型の token への参照」のどちらでも書ける**。`shadow` と `gradient` は配列を取れ、配列要素も参照可 (参照は単一値に解決され、flatten も配列展開もしない)。group と composite token の違いは「group は任意で外側、composite token は sub-value 名と型が仕様で固定された 1 個の token (ゆえに他 token から参照できる)」(technical-reports/format/composite-types.md)。

15. **light/dark やサイズ別のテーマ切替は Format ではなく Resolver モジュールの担当**。Format 側にモード概念は無い。Resolver 文書は root に `version` (`2025.10` 必須) / `sets` / `modifiers` / `resolutionOrder` を持ち、`modifiers.<name>.contexts` に `light` / `dark` / `darkHighContrast` などを列挙する。拡張子は `.resolver.json` 推奨。組み合わせ爆発を避けるための重複排除機構という位置付け (technical-reports/resolver/introduction.md, syntax.md, filetype.md)。

## 型の索引

値の書式は原典が正。パスは `technical-reports/` 配下、schema は `schemas/src/2025.10/format/` 配下。

| `$type` | 原典 (セクション) | 値の形 (一行) |
|---|---|---|
| `color` | color/color-type.md「Format」/ values/color.json | `{colorSpace, components[], alpha?, hex?}`。colorSpace は 14 種の enum |
| `dimension` | format/types.md「Dimension」/ values/dimension.json | `{value: number, unit: "px" \| "rem"}`。`value` が 0 でも `unit` は必須 |
| `fontFamily` | format/types.md「Font family」/ values/fontFamily.json | 単一フォント名の string、または優先順の string 配列 |
| `fontWeight` | format/types.md「Font weight」/ values/fontWeight.json | 1〜1000 の数値、または定義済み string (`thin`/`hairline` … `extra-black`/`ultra-black`)。範囲外・他文字列は reject |
| `duration` | format/types.md「Duration」/ values/duration.json | `{value: number, unit: "ms" \| "s"}` |
| `cubicBezier` | format/types.md「Cubic Bézier」/ values/cubicBezier.json | 4 数値 `[P1x, P1y, P2x, P2y]`。x は 0〜1、y は無制限 |
| `number` | format/types.md「Number」/ values/number.json | JSON number。unitless な lineHeight や gradient の stop 位置に使う |
| `strokeStyle` | format/composite-types.md「Stroke style」/ values/strokeStyle.json | string (`solid` `dashed` `dotted` `double` `groove` `ridge` `outset` `inset`) か `{dashArray[], lineCap}` のいずれか。両者は相互排他で片方は他方で表現できない |
| `border` | format/composite-types.md「Border」/ values/border.json | `{color, width, style}` (それぞれ color / dimension / strokeStyle 値または参照) |
| `transition` | format/composite-types.md「Transition」/ values/transition.json | `{duration, delay, timingFunction}` (duration / duration / cubicBezier) |
| `shadow` | format/composite-types.md「Shadow」/ values/shadow.json | `{color, offsetX, offsetY, blur, spread, inset?}`。単一 object か、object と参照の混在配列 |
| `gradient` | format/composite-types.md「Gradient」/ values/gradient.json | stop の配列。各 stop は `{color, position}`、position は 0〜1 にクランプ。端の stop が無ければ最寄り色を延長。**グラデーションの種類 (linear/radial) は仕様外** |
| `typography` | format/composite-types.md「Typography」/ values/typography.json | `{fontFamily, fontSize, fontWeight, letterSpacing, lineHeight}`。`lineHeight` は number で `fontSize` の倍数として解釈 |

**`colorSpace` の enum (14)**: `srgb` `srgb-linear` `hsl` `hwb` `lab` `lch` `oklab` `oklch` `display-p3` `a98-rgb` `prophoto-rgb` `rec2020` `xyz-d65` `xyz-d50` (schemas/src/2025.10/format/values/color.json)。成分レンジは色空間ごとに違う — RGB 系と XYZ 系は 3 成分すべて 0〜1、`hsl`/`hwb` は hue が 0 以上 360 未満で残り 2 つが 0〜100、`lab`/`lch` は lightness が 0〜100、`oklab`/`oklch` は lightness が 0〜1、a/b は無制限、chroma は 0 以上 (同 schema の `allOf`、および technical-reports/color/color-type.md の色空間別テーブル)。

## 機構・章の索引

| トピック | 原典パス (セクション) | 一行説明 |
|---|---|---|
| 用語定義 | technical-reports/format/terminology.md | token / design tool / translation tool / documentation tool / type / group / alias / composite token の定義。仕様文中の `[=design tool=]` 等はここを参照 |
| ファイル形式・MIME・拡張子 | technical-reports/format/file-format.md | JSON 採用理由、`application/design-tokens+json`、`.tokens` / `.tokens.json` |
| token の必須/任意プロパティ | technical-reports/format/design-token.md | `$value` 必須、`$description` / `$type` / `$extensions` / `$deprecated`、名前の文字制限 |
| group 構造・`$root`・`$extends` | technical-reports/format/groups.md | group 判定、group プロパティ表、根 token、継承、空 group、解決順、型継承の優先順位、循環検出 |
| alias と JSON Pointer | technical-reports/format/aliases.md | 中括弧と `$ref` の使い分け表、解決アルゴリズム、連鎖・循環、プロパティ単位参照 (色成分・dimension の unit・typography の一部だけ共有する例) |
| 単純型の一覧と検証 | technical-reports/format/types.md | 7 つの非 composite 型の値書式と Validation。末尾に未定義型 (font style / percentage / file) の検討メモ |
| composite type | technical-reports/format/composite-types.md | composite の定義、配列内 alias の 4 原則、group との違い、6 つの composite 型 |
| 色の値形式 | technical-reports/color/color-type.md | `$value` object の 4 プロパティ、`none` キーワード、色空間別の成分レンジ表 |
| 色の周辺概念 | technical-reports/color/overview.md, color-terminology.md, gamut-mapping.md, interpolation.md | CSS Color 4 を下敷きにする旨、gamut mapping / 補間はアルゴリズムをツール裁量とし、変換後の検証を勧める (数行の短い章) |
| トークン命名の考え方 | technical-reports/color/token-naming.md | Base / Alias / Component の 3 層分類と、descriptive vs numerical 命名の pros/cons。DESIGN.md の階層設計の根拠に使える |
| theme / mode の切替 | technical-reports/resolver/syntax.md, introduction.md | `sets` / `modifiers.contexts` / `resolutionOrder`、後勝ちマージ、modifier は他 modifier を参照禁止 |
| resolver の入出力と結合 | technical-reports/resolver/inputs.md, resolution-logic.md, bundling.md, conformance.md | 入力検証・base set の平坦化・modifier 適用・衝突解決の手順、単一ファイルへの bundle、適合要件 |
| JSON Schema (機械可読な正) | schemas/src/2025.10/format.json, format/token.json, format/group.json, format/tokenType.json, format/values/*.json (13 型ぶん) | 型 enum・名前パターン・参照パターン・各値の制約。`schemas/README.md` に bundle 手順と版追加手順。Resolver 側は schemas/src/2025.10/resolver.json と resolver/{set,modifier,resolutionOrder}.json |

## 蒸留の範囲外

- **CG の運営文書**: CHARTER.md (スコープ・成果物・意思決定)、CODE_OF_CONDUCT.md、CONTRIBUTING.md、README.md の参加企業一覧。仕様の内容判断には不要。
- **議事録**: `meeting-notes/` は 2019 年の 3 ファイルだけで、実質の議論は README.md がリンクする Google Docs と Discord にある。歴史的経緯を追うとき以外は開かない。
- **過去の draft (first / second / third-editors-draft)**: main には HTML スナップショットが無く、公開版は designtokens.org と `gh-pages` ブランチにある。古い形式 (hex 文字列の色値など) を混ぜる事故を避けるため、実装の参照には使わない。
- **サイト実装**: `www/` (Astro プロジェクト。`www/src/` のコンポーネント・`TokenPlayground`・ブログ、`www/public/` の資産) と `netlify.toml` / `.github/workflows/`。仕様本文は含まれない。
- **ReSpec の記法自体**: `technical-reports/*/index.html` の respecConfig、`data-include`、`<aside class="example">` / `<div class="issue">` / `[[RFC8259]]` 形式の参照。読み方は technical-reports/README.md と https://respec.org/docs/ 。
- **リポジトリの開発環境**: `package.json` / `pnpm-workspace.yaml` / `cspell/` / `.husky/` / `.devcontainer/` / `schemas/scripts/bundle.ts`。仕様を読むだけなら不要。
- **ツール実装 (Style Dictionary / Tokens Studio / Figma 等) での使い方**: この仕様には無い。各ツールのドキュメントを見る。仕様側にあるのは「ツールが何を MUST/SHOULD 満たすか」だけ。
- **未解決の設計論点**: 原典の `<div class="issue">` に issue 番号付きで残る (strokeStyle=98, border=99, shadow=100, gradient=101, typography=102, transition=103, fontFamily=53)。ここを踏む設計をするなら GitHub の該当 issue を直接読む。
