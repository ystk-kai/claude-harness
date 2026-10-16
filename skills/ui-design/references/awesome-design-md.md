---
source: https://github.com/voltagent/awesome-design-md
distilled_commit: 3b605329240ce735b510037cca322f1831fdd7f8
distilled_at: 2026-10-16
---

# awesome-design-md 蒸留版

実在サイトのデザイン言語を抽出した DESIGN.md 集 (84 件)。用途はハーネス設計ではなく、**UI 生成時にデザイン言語の雛形 DESIGN.md を選んでプロジェクトに置く**こと。使い方は「Copy a site's DESIGN.md into your project root → Tell your AI agent to use it」(README.md)。

## Contents

- まず押さえる
- 系統別索引
- 蒸留の範囲外

## まず押さえる

1. **DESIGN.md とは**: Google Stitch 発の概念で、AI エージェントが読む plain-text のデザインシステム文書。`AGENTS.md` が「どう作るか」なら `DESIGN.md` は「どう見えるべきか」を定義する (README.md の対比表)。Figma エクスポートや JSON スキーマ不要、プロジェクトルートに置くだけ。

2. **リポジトリ構造は完全フラット**: `design-md/<site-slug>/DESIGN.md` の 1 階層のみ。slug は小文字サイト名で、一部はドメイン形 (`linear.app`, `mistral.ai`, `x.ai`, `together.ai`, `opencode.ai`, `cal`)、レトロ系は年号付き (`dell-1996`, `nintendo-2001`)。カテゴリ分けはディレクトリではなく README.md の Collection 節にのみ存在する。

3. **各サイトディレクトリで読む価値があるのは DESIGN.md だけ**: 同居する `README.md` は getdesign.md へのリンクだけのスタブ。ルート README が言及する `preview.html` / `preview-dark.html` はこの git リポジトリには存在しない (getdesign.md サイト側のみ)。ディレクトリは 84 個で、`design-md/slack/` だけ README 未掲載 (DESIGN.md のみ、README.md すら無い)。

4. **DESIGN.md は二部構成だが、本文の章立ては 2 型ある**: 前半は YAML frontmatter (機械可読トークン: `version` / `name` / `description` / `colors` / `typography` / `rounded` / `spacing` / `components`。コンポーネント定義は `{colors.primary}` 形式のトークン参照)。後半の Markdown 本文は (a) 10 章型: Overview → Colors → Typography → Layout → Elevation & Depth → Shapes → Components → Do's and Don'ts → Responsive Behavior → Iteration Guide (例: design-md/stripe/DESIGN.md, design-md/linear.app/DESIGN.md) と、(b) Do's and Don'ts で終わる 8 章型 (Responsive Behavior と Iteration Guide の独立章が無い。全 84 件中 30 件超。c7c1bad で追加の 10 件はすべてこちら。例: design-md/oracle/DESIGN.md, design-md/sap/DESIGN.md)。8 章型でもレスポンシブ方針は Layout 節の中に書かれることがある (design-md/mydealz/DESIGN.md の "Responsive Strategy")。

5. **行数は 125〜882 行と幅がある**: 大半は 450〜900 行。最短は design-md/kraken/DESIGN.md (125 行)、最長は design-md/dji/DESIGN.md (882 行)。新しい 8 章型は frontmatter が長く、本文開始 (Overview) が 230〜520 行目あたりまで下がる。

6. **最速の要約は frontmatter の `description`**: 各ファイル冒頭の 1 段落にそのサイトのデザイン言語の核 (基調色・書体・アクセントの使い方) が凝縮されている。候補を絞ったら `head` で description だけ読み比べるのが効率的 (例: design-md/apple/DESIGN.md, design-md/oracle/DESIGN.md)。

7. **対象は主にマーケティングサイト/LP のデザイン言語**: 抽出元は home / pricing 等の公開ページで (design-md/stripe/DESIGN.md の Colors 節に "Source pages: home (`/`), `/payments`, `/pricing`" と明記)、components も `pricing-card` / `testimonial-card` / `cta-banner` などマーケ部品中心。ただし追加分には店舗・情報プロダクト寄りもある: dji は store product page を含み (design-md/dji/DESIGN.md "Source pages")、mydealz は "this is an information product, not a marketing page" と明言する高密度フィード (design-md/mydealz/DESIGN.md)。アプリのダッシュボード UI そのものの仕様集ではない点は変わらない。

8. **ガードレールは Do's and Don'ts (全ファイル共通) と Iteration Guide (10 章型のみ)**: 生成時の逸脱防止 (「アクセント色を増やすな」「影を足すな」「角丸を混ぜるな」等) が Do's and Don'ts に、反復修正の手順 (1 コンポーネントずつ・トークン名で参照・`npx @google/design.md lint DESIGN.md`) が Iteration Guide にある (design-md/stripe/DESIGN.md 末尾)。8 章型の Do's and Don'ts もトークン参照で具体的に書かれている (design-md/oracle/DESIGN.md: "one 40 × 4px gold bar is the whole ornament budget")。

9. **プロプライエタリフォントには代替指定がある**: 多くのサイトが独自書体 (Sohne, Linear Display, SoDoSans, 72 Brand Variable, arcadia 等) を使うため、Typography に "Note on Font Substitutes" 節があり、利用可能な代替と「どの性質を落とすと壊れるか」が示される (design-md/stripe/DESIGN.md, design-md/sap/DESIGN.md — 350 weight が load-bearing なので sub-400 の可変軸を持つ代替が要る、と明記)。

10. **frontmatter の `name` は 3 系統、本文に商標回避の変名が混ざる**: `<Site>-design-analysis` (多数)、`<変名>-Inspired-design-analysis` (例: "Stripi"、"Slacc"、"Supabaze")、`<Site> Analysis` (c7c1bad 追加分)。変名系は本文でも変名を使う (design-md/stripe/DESIGN.md の "Stripi's design language")。サイト名で grep するときは変名も考慮する。

11. **README のカテゴリは 10 系統 (ドメイン軸)**: AI & LLM Platforms / Developer Tools & IDEs / Backend, Database & DevOps / Productivity & SaaS / Design & Creative Tools / Fintech & Crypto / E-commerce & Retail / Media & Consumer Tech / Automotive / Retro Web。各エントリに一行のスタイル説明が付くので、README.md の Collection 節が実質の索引 (README.md)。

## 系統別索引

README のカテゴリは業種軸なので、選定にはスタイル軸で引き直した下表が実用的。パスはすべて `design-md/<slug>/DESIGN.md`。

| 系統 | 代表例 (原典パス) | 特徴 (一行) | こういう UI の起点に |
|---|---|---|---|
| ダーク×開発者ツール | design-md/linear.app/, design-md/vercel/, design-md/supabase/, design-md/warp/ | ほぼ黒のキャンバス+単一アクセント色+ヘアラインボーダー。linear.app は #010102 に lavender (#5e6ad2) 一点 | 開発者向け SaaS、CLI/インフラ製品の LP・ドキュメントサイト |
| ターミナル/モノクロ・ミニマル | design-md/ollama/, design-md/x.ai/, design-md/hashicorp/ | 装飾を排したモノクロ。ollama は terminal-first の簡素さ (本文は 10 章型で Footer 節まで持つ) | CLI ツール、技術ドキュメント、質実剛健なインフラ系 |
| ライト・クリーン/ミニマル | design-md/apple/, design-md/notion/, design-md/cal/, design-md/replicate/ | 白地+広い余白+抑制されたアクセント。apple は写真主導で "Action Blue (#0066cc) が唯一のインタラクティブ色" | プレミアム感のあるプロダクトサイト、静かな SaaS |
| エンタープライズ/抑制 | design-md/oracle/, design-md/sap/ | 色ではなくニュートラルの階調で構造を作る。oracle は 6 段の warm grey+charcoal のみの action+赤はワードマークだけ・影なし。sap は白地+2 灰+1 青、60px の灰バーで「アプリの枠」に見せる | 業務 SaaS のコーポレートサイト、B2B 製品ページ |
| グラデーション/カラフル | design-md/stripe/, design-md/cohere/, design-md/figma/, design-md/renault/, design-md/jobright/ | 華やかな色面。stripe は gradient mesh+Sohne weight 300+indigo pill CTA という厳格な規律付き (Do's and Don'ts が特に具体的)。jobright は spring-mint+黒 pill+condensed Titillium | フィンテック LP、クリエイティブツール、元気なスタートアップ LP |
| 写真/シネマティック主導 | design-md/nike/, design-md/tesla/, design-md/shopify/, design-md/airbnb/, design-md/dji/ | フルブリード写真+大型タイポ。UI は写真の額縁に徹する。dji は正方形タイルの製品写真+engineering blue の pill 一色、ストア部品 (option card・sticky purchase bar) まで含む | EC・リテール、ハードウェア製品、ブランドサイト |
| 高密度フィード/カタログ | design-md/mydealz/, design-md/1win/ | 余白を削った情報プロダクト。mydealz は cool-gray 地に白カードを積む deal feed+hot/cold 投票 pill。1win はほぼ黒地に緑 CTA と game-tile rail | 一覧・掲示板・カタログ型サービス、ゲーム/ベッティング系 |
| エディトリアル/メディア | design-md/wired/, design-md/theverge/, design-md/claude/, design-md/sanity/, design-md/aljazeera/, design-md/oura/ | 紙面的な密度と読み物設計。claude は warm terracotta。aljazeera は白い紙面+密な Roboto 見出し+orange 署名色+live red。oura は warm paper cream+editorial serif+earth tone に action blue 一点 | メディア・ニュースサイト、ブログ、コンテンツ主導の LP、ウェルネス系ブランド |
| ラグジュアリー (自動車系) | design-md/ferrari/, design-md/lamborghini/, design-md/bugatti/ | 漆黒+荘厳なディスプレイ書体+極端に節制されたアクセント (Ferrari Red, gold) | 高級ブランド、ポートフォリオ、演出重視のショーケース |
| フィンテック/信頼感 | design-md/coinbase/, design-md/mastercard/, design-md/wise/, design-md/revolut/, design-md/mercury/, design-md/nerdwallet/ | 信頼を演出するクリーンな配色 (青・緑) または精緻なダーク。mercury は ink-violet の夜と near-white の昼を 1 色の indigo pill でつなぎ、本文 360 の軽い weight。nerdwallet は deep spruce green+mint の階調、ほぼ直角の角・影なしで比較表が主役 | 金融・決済系、比較サイト、コンプライアンス感が必要なサービス |
| レトロ Web | design-md/dell-1996/, design-md/nintendo-2001/ | 90 年代〜Y2K の意匠を本気で再現。nintendo-2001 は「brushed-periwinkle の console chrome」 | 意図的なヴィンテージ UI、遊び心のある特設ページ |

**選定手順の目安**: (1) 作りたい UI の雰囲気から上表で系統を決める → (2) README.md の Collection 節の一行説明で候補を 2〜3 に絞る → (3) 各候補の frontmatter `description` を読み比べて決定 → (4) 選んだ DESIGN.md をプロジェクトルートにコピーし、生成時は Do's and Don'ts を制約として明示する。8 章型を選んだ場合はブレークポイント指示と反復手順が薄いので、Layout 節を確認し、不足分は生成側で補う。

## 蒸留の範囲外

- **各ファイルの具体的トークン値** (hex 全量、typography 階層の px/weight/tracking、spacing スケール): 原典 frontmatter (`colors:` / `typography:` / `spacing:` ブロック) を直接読む。
- **コンポーネント別の詳細スタイルと状態** (hover/pressed/focused、signature components): 原典本文の Components 節と frontmatter の `components:`。
- **ブレークポイントとレスポンシブ戦略の詳細**: 10 章型は Responsive Behavior 節 (Breakpoints 表・Touch Targets・Collapsing Strategy)、8 章型は Layout 節内の記述。
- **プレビュー画像・ダークモード見本**: リポジトリには無い。getdesign.md の各サイトページを見る。
- **Stitch DESIGN.md 仕様そのもの**: https://stitch.withgoogle.com/docs/design-md/specification/ (README.md からリンク)。
- **貢献手順**: CONTRIBUTING.md (PR 前に issue を立てる規約など)。
- **ここに挙げなかった約 45 サイト**: README.md の Collection 節が全件の一行説明付き一覧。系統の見当が付かないときはそこを通読する。
