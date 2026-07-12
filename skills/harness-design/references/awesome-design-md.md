---
source: https://github.com/voltagent/awesome-design-md
distilled_commit: 664b3e78fd1a298ba11973822da988483256d4b4
distilled_at: 2026-07-12
---

# awesome-design-md 蒸留版

実在サイトのデザイン言語を抽出した DESIGN.md 集 (73+ 件)。用途はハーネス設計ではなく、**UI 生成時にデザイン言語の雛形 DESIGN.md を選んでプロジェクトに置く**こと。使い方は「Copy a site's DESIGN.md into your project root → Tell your AI agent to use it」(README.md)。

## Contents

- まず押さえる
- 系統別索引
- 蒸留の範囲外

## まず押さえる

1. **DESIGN.md とは**: Google Stitch 発の概念で、AI エージェントが読む plain-text のデザインシステム文書。`AGENTS.md` が「どう作るか」なら `DESIGN.md` は「どう見えるべきか」を定義する (README.md の対比表)。Figma エクスポートや JSON スキーマ不要、プロジェクトルートに置くだけ。

2. **リポジトリ構造は完全フラット**: `design-md/<site-slug>/DESIGN.md` の 1 階層のみ。slug は小文字サイト名で、一部はドメイン形 (`linear.app`, `mistral.ai`, `x.ai`, `together.ai`, `opencode.ai`, `cal`)、レトロ系は年号付き (`dell-1996`, `nintendo-2001`)。カテゴリ分けはディレクトリではなく README.md の Collection 節にのみ存在する。

3. **各サイトディレクトリで読む価値があるのは DESIGN.md だけ**: 同居する `README.md` は getdesign.md へのリンクだけのスタブ。ルート README が言及する `preview.html` / `preview-dark.html` はこの git リポジトリには存在しない (getdesign.md サイト側のみ)。ディレクトリは 74 個あり、`design-md/slack/` だけ README 未掲載 (DESIGN.md のみ、README.md すら無い)。

4. **DESIGN.md は二部構成・450〜750 行**: 前半は YAML frontmatter (機械可読トークン: `description` / `colors` / `typography` / `rounded` / `spacing` / `components`。コンポーネント定義は `{colors.primary}` 形式のトークン参照で書かれる)。後半は Markdown 本文で、章立ては全ファイルほぼ共通: Overview → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts → Responsive Behavior → Iteration Guide (例: design-md/stripe/DESIGN.md, design-md/linear.app/DESIGN.md)。

5. **最速の要約は frontmatter の `description`**: 各ファイル冒頭の 1 段落にそのサイトのデザイン言語の核 (基調色 hex・書体・アクセントの使い方) が凝縮されている。候補を絞ったら `head` で description だけ読み比べるのが効率的 (例: design-md/apple/DESIGN.md, design-md/nintendo-2001/DESIGN.md)。

6. **対象はマーケティングサイト/LP のデザイン言語**: 抽出元は home / pricing 等の公開ページで (design-md/stripe/DESIGN.md の Colors 節に "Source pages: home (`/`), `/payments`, `/pricing`" と明記)、components も `pricing-card` / `testimonial-card` / `cta-banner` などマーケ部品中心。アプリのダッシュボード UI そのものの仕様集ではない点に注意して選ぶ。

7. **ガードレールは Do's and Don'ts と Iteration Guide**: 生成時の逸脱防止 (「アクセント色を増やすな」「この weight を超えるな」等) が Do's and Don'ts に、反復修正の手順 (1 コンポーネントずつ・トークン名で参照・`npx @google/design.md lint DESIGN.md`) が Iteration Guide にある (design-md/stripe/DESIGN.md 末尾)。

8. **プロプライエタリフォントには代替指定がある**: 多くのサイトが独自書体 (Sohne, Linear Display, SoDoSans 等) を使うため、各ファイルの Typography に "Note on Font Substitutes" 節があり、利用可能な代替が示される (design-md/stripe/DESIGN.md, design-md/ollama/DESIGN.md)。

9. **本文中は商標回避の変名が混ざる**: 例: stripe の Overview は "Stripi's design language"、slack の frontmatter は "Slacc-Inspired-design-analysis"。サイト名で grep するときは変名も考慮する (design-md/stripe/DESIGN.md, design-md/slack/DESIGN.md)。

10. **README のカテゴリは 10 系統 (ドメイン軸)**: AI & LLM Platforms / Developer Tools & IDEs / Backend, Database & DevOps / Productivity & SaaS / Design & Creative Tools / Fintech & Crypto / E-commerce & Retail / Media & Consumer Tech / Automotive / Retro Web。各エントリに一行のスタイル説明が付くので、README.md の Collection 節が実質の索引 (README.md)。

## 系統別索引

README のカテゴリは業種軸なので、選定にはスタイル軸で引き直した下表が実用的。パスはすべて `design-md/<slug>/DESIGN.md`。

| 系統 | 代表例 (原典パス) | 特徴 (一行) | こういう UI の起点に |
|---|---|---|---|
| ダーク×開発者ツール | design-md/linear.app/, design-md/vercel/, design-md/supabase/, design-md/warp/ | ほぼ黒のキャンバス+単一アクセント色+ヘアラインボーダー。linear.app は #010102 に lavender (#5e6ad2) 一点 | 開発者向け SaaS、CLI/インフラ製品の LP・ドキュメントサイト |
| ターミナル/モノクロ・ミニマル | design-md/ollama/, design-md/x.ai/, design-md/hashicorp/ | 装飾を排したモノクロ。ollama は terminal-first の簡素さ (本文構成は標準 10 章立てで Footer 節まで持つ) | CLI ツール、技術ドキュメント、質実剛健なインフラ系 |
| ライト・クリーン/ミニマル | design-md/apple/, design-md/notion/, design-md/cal/, design-md/replicate/ | 白地+広い余白+抑制されたアクセント。apple は写真主導で "Action Blue (#0066cc) が唯一のインタラクティブ色" | プレミアム感のあるプロダクトサイト、静かな SaaS |
| グラデーション/カラフル | design-md/stripe/, design-md/cohere/, design-md/figma/, design-md/renault/ | 華やかな色面。stripe は gradient mesh+Sohne weight 300+indigo pill CTA という厳格な規律付き (487 行、Do's and Don'ts が特に具体的) | フィンテック LP、クリエイティブツール、ブランド色の強いマーケサイト |
| 写真/シネマティック主導 | design-md/nike/, design-md/tesla/, design-md/shopify/, design-md/airbnb/ | フルブリード写真+大型タイポ。UI は写真の額縁に徹する | EC・リテール、ハードウェア製品、ブランドサイト |
| エディトリアル/メディア | design-md/wired/, design-md/theverge/, design-md/claude/, design-md/sanity/ | 紙面的な密度と読み物設計。claude は warm terracotta のエディトリアルレイアウト | メディアサイト、ブログ、コンテンツ主導の LP |
| ラグジュアリー (自動車系) | design-md/ferrari/, design-md/lamborghini/, design-md/bugatti/ | 漆黒+荘厳なディスプレイ書体+極端に節制されたアクセント (Ferrari Red, gold) | 高級ブランド、ポートフォリオ、演出重視のショーケース |
| フィンテック/信頼感 | design-md/coinbase/, design-md/mastercard/, design-md/wise/, design-md/revolut/ | 信頼を演出するクリーンな配色 (青・緑) または精緻なダーク | 金融・決済系、コンプライアンス感が必要なサービス |
| レトロ Web | design-md/dell-1996/, design-md/nintendo-2001/ | 90 年代〜Y2K の意匠を本気で再現。nintendo-2001 は「brushed-periwinkle の console chrome」で章立ても標準形 (649 行) | 意図的なヴィンテージ UI、遊び心のある特設ページ |

**選定手順の目安**: (1) 作りたい UI の雰囲気から上表で系統を決める → (2) README.md の Collection 節の一行説明で候補を 2〜3 に絞る → (3) 各候補の frontmatter `description` を読み比べて決定 → (4) 選んだ DESIGN.md をプロジェクトルートにコピーし、生成時は Do's and Don'ts を制約として明示する。

## 蒸留の範囲外

- **各ファイルの具体的トークン値** (hex 全量、typography 階層の px/weight/tracking、spacing スケール): 原典 frontmatter (`colors:` / `typography:` / `spacing:` ブロック) を直接読む。
- **コンポーネント別の詳細スタイルと状態** (hover/pressed/focused、signature components): 原典本文の Components 節と frontmatter の `components:`。
- **ブレークポイントとレスポンシブ戦略の詳細**: 原典の Responsive Behavior 節 (Breakpoints 表・Touch Targets・Collapsing Strategy)。
- **プレビュー画像・ダークモード見本**: リポジトリには無い。getdesign.md の各サイトページを見る。
- **Stitch DESIGN.md 仕様そのもの**: https://stitch.withgoogle.com/docs/design-md/specification/ (README.md からリンク)。
- **貢献手順**: CONTRIBUTING.md (PR 前に issue を立てる規約など)。
- **ここに挙げなかった約 50 サイト**: README.md の Collection 節が全 73 件の一行説明付き一覧。系統の見当が付かないときはそこを通読する。
