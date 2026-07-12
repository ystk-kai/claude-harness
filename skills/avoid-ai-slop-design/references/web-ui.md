# Web UI の tell — 検出カタログ

AI 生成 Web UI を「AI っぽい」と感じさせるパターン。単独では証明にならず、複数の同時出現で「無意図」を疑う。確度: **[計測]** 定量研究 / **[批評]** デザイナーの一次記事 / **[通説]** 複数ソース一致だが未計測。

基準となる計測: Adrian Krebs が Show HN のランディングページ 1,590 件を DOM・計算スタイルで決定的にスコアリング。22% が heavy slop (4 パターン以上)、32% が mild、46% は clean — 「AI 利用 = slop」ではない。Anthropic 自身も無指定 LLM 出力の典型を「Inter + 白背景 + purple gradient」と説明している。

## 色・グラデーション

- **紫〜青グラデーション** — hero・CTA・見出し・背景 orb の purple-to-blue。Krebs は頻出の薄紫を "VibeCode Purple" と命名 [計測]
- **Tailwind indigo のデフォルト痕跡** — `#6366F1` (indigo-500) 付近のボタン・グラデ。Tailwind UI のプレースホルダ色がチュートリアル経由で corpus を占めた、という因果説明 [通説]
- **dark cyberpunk by default** — 文脈を問わず near-black + cyan/neon + colored glow + monospace で「tech 感」。本文グレーが WCAG AA を落としがちな点も tell [計測/批評]
- **gradient text** — 見出し・数値のグラデ文字。テキストは solid color に [批評]
- **新世代のデフォルト: cream/beige + serif + terracotta** — 「上品な AI 既定値」として既に反復されている。色そのものではなく「題材と無関係に同じ palette が選ばれる」ことが tell [批評]

## タイポグラフィ

- **Inter everywhere** — 見出し・本文・ラベル・ボタンを Inter または system font 一書体で通す。「他に typographic な選択がなければ、意図的にスタイルされていない強いシグナル」 [計測+批評]
- 流行書体の固定セットへの収束: Geist / Space Grotesk / Instrument Serif (+ Roboto)。「Inter の hero で 1 単語だけ serif italic」も定番 [計測]
- **平坦な階層** — 単一ファミリー + ウェイト差だけ。サイズ差が小さく全情報が同じ声量に見える [批評]
- **tracking-tight の乱用** と **eyebrow ラベルの反復** (hero H1 直上と各セクションの tiny uppercase tracked label) [計測]

## レイアウト・コンポーネント

- 中央寄せ SaaS hero + **H1 直上の badge pill** ("New" / "Introducing" chip) + 説明文 + CTA 2 つ [計測]
- **hero → 同寸 feature card 3 列** (icon + heading + short copy の複製)。内容が違ってもページのシルエットが同じになる [計測/批評]
- **カード上端/左端の colored border** — 「テキストにおける em-dash に相当する確実なサイン」 [計測]
- **Cardocalypse** — 余白や divider で足りる情報までカード化し、カード in カードで各階層に border/padding/shadow [批評]
- **Everything is round** — 入力欄からセクションまで 24px 超で丸め、全要素を同じ柔らかい blob にする [批評]
- 番号付き step (01/02/03) / stat banner row (大数値 ×3-4) / all-caps セクションラベル — 実際の順序・分類を表さない「意味を持たない構造記号」 [計測]
- **固定されたページ構文** — hero → metrics → feature grid → testimonials → pricing → CTA を内容と無関係に流用 [批評]
- **絵文字をアイコン代わりに** (✨🚀🔒 を nav や feature icon に)、または Lucide 系を角丸タイルに入れて見出し上に置く [計測/批評]
- **✨ sparkles** — AI 機能の記号として飽和。NN/g の調査では単独提示で誰も「AI」と解釈しなかった。使うならラベル必須 [計測]
- **shadcn/ui 素のまま** と **glassmorphism** (レイヤー関係を示す必要のない場所の半透明 + backdrop blur + 光る境界) が 2 大 CSS フィンガープリント [通説/批評]
- hairline border + 幅広 diffuse shadow の併用、全要素同一の radius・shadow (「opacity ちょうど 0.1」)・padding [批評]
- 左テキスト + 右に MacBook mockup / 3D オブジェクト / 浮遊するぼかし円 [通説]
- **意味のない motion** — 一律の scroll fade、button の bounce、icon の wiggle、hover での画像 scale/rotate。状態・連続性・注意誘導のどれも説明しない [批評]
- **業界別ステレオタイプの複製** — SaaS は Inter + floating dashboard、fintech は紫青グラデ、wellness は muted earth tones、security は navy + shield [批評]

## UI コピー (文章の slop は avoid-ai-slop-ja に委譲。ここは UI 固有分のみ)

- 汎用 SaaS 動詞: streamline / empower / supercharge / world-class / enterprise-grade
- 曖昧な野心系見出し: "Build the future of work" / "Your all-in-one platform" / "Scale without limits"
- 処方: 製品が文字通り何をするかを具体的な動詞と名詞で。「うちの代表が実際にこう言うか?」

## なぜ起きるか

指示が曖昧だとモデルは訓練データの「安全で万人受けする」高確率領域を選び、個別の判断を統計的平均で置き換える (distributional convergence)。AI 生成サイトが次の学習データになる自己強化ループも指摘される。なお「これらは AI 以前に人間も Tailwind/Bootstrap で量産していた」という反論も妥当で、パターンは「悪」ではなく「無意図」の指標として扱う。

## 出典

- https://www.adriankrebs.ch/blog/design-slop/ (1,590 件計測。checker: https://github.com/AdrianKrebs/ai-design-checker)
- https://impeccable.style/slop/ (Paul Bakaus。slop パターン 46 種)
- https://claude.com/blog/improving-frontend-design-through-skills / https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md (Anthropic)
- https://www.nngroup.com/articles/ai-sparkles-icon-problem/ (✨ の user research)
- https://pages.thefountaininstitute.com/posts/7-tells-that-a-ui-is-ai-generated
- https://arxiv.org/html/2603.13036 (Interrogating Design Homogenization in Web Vibe Coding)
- https://www.creativebloq.com/ai/everything-looks-the-same-now-what (業界別ステレオタイプ)
- https://dev.to/alanwest/why-every-ai-built-website-looks-the-same-blame-tailwinds-indigo-500-3h2p / https://prg.sh/ramblings/Why-Your-AI-Keeps-Building-the-Same-Purple-Gradient-Website
- https://www.developersdigest.tech/blog/ai-design-slop-and-how-to-spot-it / https://www.925studios.co/blog/ai-slop-web-design-guide / https://news.ycombinator.com/item?id=47864393
- 日本語: https://note.com/sakamototakuma/n/n0cf7bad2d9a8 / https://qiita.com/kenimo49/items/8aaa2bf0d25c704637ae / https://note.com/creat_himato/n/n47cae4a91381
