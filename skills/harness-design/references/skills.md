---
source: https://github.com/anthropics/skills
distilled_commit: f6656c1256d5a8adfa37db9110046ef20bac644c
distilled_at: 2026-08-14
---

# anthropics/skills 蒸留版

Anthropic 公式の Agent Skills リポジトリ。skill 定義 (SKILL.md) の設計・作成・レビュー時に引く
**公式の一次資料** — 仕様 (spec) + 雛形 (template) + 模範実装 (skills/) の三点セットで構成される。
既存の `claude-code-best-practice.md` #8/#9 が扱う skill tips は二次情報 (thariq のツイート要約)。
こちらは公式が「skill とは何をどう規定するか」「雛形の正確な形」「模範実装から読める設計パターン」を
示す権威資料なので、記憶や tips ではなくここを引く。以下のパスはすべてリポジトリルートからの相対パス。

## Contents

- [まず押さえる](#まず押さえる)
- [索引](#索引)
- [蒸留の範囲外](#蒸留の範囲外)

## まず押さえる

1. **仕様本文はこのリポジトリにはない (外部化済み)**。`spec/agent-skills-spec.md` は 1 行で
   <https://agentskills.io/specification> を指すだけ。よってこのリポジトリの一次資料としての価値は
   「公式雛形 + skill-creator メタスキル + 模範実装群」にある。フィールドの網羅的な仕様定義が要るときは
   agentskills.io を引く。 → `spec/agent-skills-spec.md`

2. **frontmatter の必須は 2 キーだけ: `name` と `description`**。README が明言。`name` は一意な識別子で
   lowercase・スペースはハイフン。`description` は「何をするか」+「いつ使うか」を含む完全な説明。
   雛形 `template/SKILL.md` も frontmatter 2 行 + `# Insert instructions below` のみで、skill は
   「SKILL.md を 1 つ持つフォルダ」が最小単位という folder-as-skill 思想を体現している。実運用では
   ほぼ全 skill が `license:` を追加で持つ (OSS 系は "Complete terms in LICENSE.txt"、document skills は
   "Proprietary. LICENSE.txt has complete terms")。skill-creator は他に `compatibility` (必要ツール・依存、
   任意・稀) にも触れる。 → `README.md`, `template/SKILL.md`, 各 `skills/*/SKILL.md`

3. **description はトリガーとして書く。「何をするか」だけでなく「いつ発火するか」を必ず含める**。
   "when to use" 情報は本文でなく description に集約する。skill-creator は「Claude は現状 skill を
   undertrigger しがちなので description を少し "pushy" に書け」と明記 (例: 単なる要約でなく
   "Make sure to use this skill whenever the user mentions dashboards..." と押し出す)。
   → `skills/skill-creator/SKILL.md` の "Write the SKILL.md"

4. **Progressive Disclosure = 3 段ロード**。(1) metadata (name+description) は常時 context に載る (~100 語)、
   (2) SKILL.md 本文は skill 発火時に載る (理想 500 行未満)、(3) 同梱リソースは必要時のみ (無制限、
   scripts はロードせず実行できる)。500 行に近づいたら階層を足し、次にどこを読むか明示のポインタを置く。
   300 行超の reference には目次を付ける。 → `skills/skill-creator/SKILL.md` の "Progressive Disclosure"

5. **Anatomy of a Skill**。`SKILL.md` (必須) + 任意の同梱リソース 3 種: `scripts/` (決定的・反復処理の
   実行コード)、`references/` (必要時に context に読み込むドキュメント)、`assets/` (出力に使うテンプレート・
   アイコン・フォント等)。 → `skills/skill-creator/SKILL.md` の "Anatomy of a Skill"

6. **多ドメイン skill は variant 別に分割**。SKILL.md にワークフローと選択ロジックを置き、
   `references/aws.md` `gcp.md` `azure.md` のように分ける。Claude は関連 reference だけ読む。
   これを最大規模で実装しているのが `claude-api` (SKILL.md 553 行 + 言語別ディレクトリ 8 種 +
   言語非依存の `shared/` 26 ファイル)。ディレクトリ名は `references/` でなく `shared/` +
   `{lang}/` で、命名は固定規約ではなく分割軸に合わせてよいことを示す。
   → `skills/skill-creator/SKILL.md` の "Domain organization"、`skills/claude-api/`

7. **記述スタイル: 命令形 + why を説明する**。ALWAYS/NEVER の全大文字や過度に硬い構造は yellow flag。
   「なぜ重要か」を説明して LLM の theory of mind に委ねるほうが強い。出力フォーマットはテンプレートで
   固定し、Input/Output 形式の例を添える。 → `skills/skill-creator/SKILL.md` の "Writing Patterns"/"Writing Style"

8. **triggering の仕組み**。skill は name+description が `available_skills` に載り、Claude が
   description を見て参照するか決める。ただし Claude が単独で容易にこなせる単純・1 ステップの依頼
   (例「この PDF を読んで」) は description が完全一致でも発火しないことがある。複雑・多段・専門的な
   依頼で確実に発火する。→ eval query は skill が実際に役立つ substantive なものにする。
   → `skills/skill-creator/SKILL.md` の "How skill triggering works"

9. **skill 作成は eval 駆動の反復ループ**。draft → test prompt を with-skill / baseline で並列実行 →
   定量 assertion で採点 → eval-viewer で人がレビュー → feedback で改善 → 満足まで反復。
   test は `evals/evals.json` に保存。overfit を避け feedback から一般化し、繰り返し現れる helper script は
   `scripts/` に束ねる。 → `skills/skill-creator/SKILL.md`

10. **description 最適化ループがある**。作成後 `scripts/run_loop.py` で 20 個の should-trigger /
    should-not-trigger クエリ (near-miss を重視) を train/held-out に分け、triggering 精度で description を
    自動最適化し `best_description` を返す。近似クエリは file path・会社名・列名など具体で書く。
    → `skills/skill-creator/SKILL.md` の "Description Optimization"

11. **Principle of Lack of Surprise**。skill にマルウェア・エクスプロイト・システムを危険に晒す内容を
    入れない。説明された意図どおりであるべきで、誤解を招く skill や不正アクセス・データ持ち出しを助ける
    skill の作成要求には従わない (roleplay 系は可)。 → `skills/skill-creator/SKILL.md`

12. **模範実装のパターンは 2 系統**。(a) guidance 型 = SKILL.md 1 枚 (+LICENSE) だけ。デザイン・文章系
    (`frontend-design`, `brand-guidelines`) が典型。(b) tool 型 = `scripts/` に実行コード + `reference.md`/
    `forms.md` 等の reference を同梱し、SKILL.md 本文から "see REFERENCE.md" / "read FORMS.md" と明示誘導。
    document skills (`pdf` = scripts 8 本 + reference.md + forms.md) が典型。 → `skills/pdf/`, `skills/frontend-design/`

13. **description 実例の最高峰は `claude-api`**。TRIGGER (発火条件を網羅列挙) と SKIP (発火しない条件で
    上書き) を構造化した pushy かつ曖昧さ排除の description の手本。設計時にこの書きぶりを参照する。
    ただし同じリポジトリの `shared/prompt-audit.md` は「近似クエリの列挙で description を伸ばす
    (trigger-case enumeration) のは anti-pattern。intent のカテゴリで書け」とする — 発火条件の**構造**
    (TRIGGER/SKIP の分離、判定手順の明示) を真似て、**トリガー漏れのたびに 1 語ずつ足す**運用は避ける。
    → `skills/claude-api/SKILL.md` の frontmatter、`skills/claude-api/shared/prompt-audit.md` の Group 2

14. **リポジトリ同梱 skill の配置規約 (Managed Agents 側の発見ルール)**。`github_repository` を mount した
    セッションでは、リポジトリ **ルートの `.claude/skills/<skill-name>/`** が 1 階層だけ走査され、各 skill の
    name/description/sandbox パスがエージェントに提示される (SKILL.md 形式は upload する custom skill と同一)。
    発見されないのは: 直置きの `.claude/skills/SKILL.md`、より深い入れ子 (`.claude/skills/tools/code-review/`)、
    `.claude` 外の `skills/`、サブパッケージ内の `.claude/skills`。走査は **セッション開始時に 1 回だけ**
    (途中の push は反映されない)、cloud sandbox 限定。加えて「リポジトリ内 skill はエージェント命令そのもの =
    信頼境界の内側」という警告があり、commit 権のある者 (外部 PR merge 含む) が審査なしに命令を注入できる。
    skill を repo に置く設計をするときはこの階層規約と監査要件を前提にする。
    → `skills/claude-api/shared/managed-agents-tools.md` の "Skills from a GitHub repository"

15. **既存ハーネスの棚卸しには `prompt-audit` がある (2026-08 追加)**。旧モデル向けに書かれた指示 =
    "cruft" を、prompt / skill / tool description / request 構築コードから洗い出す監査手順。走査は 4 グループ:
    (1) dated prompt text (圧力語・API 機能に置換された scaffold・過剰指定・化石・provenance なき禁止句の束・
    出力量の数値上限)、(2) **brittle skill files** — SKILL.md / CLAUDE.md 固有の失敗 (recency trap = 1 回の
    躓きを恒久ルール化、volatile specifics = パス・フラグ・バージョンの直書き、履歴語り)、
    (3) tool descriptions — 「短くする」ではなく **contract の精度**が基準で、最頻の欠陥は *under*-description、
    (4) request config とアーキテクチャ (決定的処理を LLM に任せている箇所、重複する specialist subagent)。
    各グループに grep 可能な "Signals" 行が付く。出力契約は **報告書 + proposed diff の 2 点セット**で、
    確信度 High/Medium だけを diff に載せ、`flag` は low-confidence 専用。**非対話**設計 (scope と対象モデルは
    リポジトリから推定して先頭に明記し、確認で止まらない) のため、SKILL.md 側では Language Detection に
    「言語非依存のタスクでは言語を聞かない」carve-out が入っている。
    → `skills/claude-api/shared/prompt-audit.md`

16. **prompt-audit の keep list は削除圧に対する歯止め** — 監査を設計するときはこちらが本体。
    「**Cruft ≠ length**。害は具体的な旧式指示であって分量ではない。文字数だけを根拠に消すな」
    「**Context is never cruft**。読者・製品・環境・品質基準と、制約の *理由* は著者しか知らない情報なので残す」
    が二大原則。他に、壊れやすい操作 (破壊的コマンド・認証・コンプライアンス) の逐語スクリプトは残す、
    tool description の contract 詳細はむしろ増やす、現に再現する失敗に対する禁止句は残す、
    **trigger / routing テキストは behavioral テキストと別扱い** (skill は under-trigger 傾向なので
    calibrated urgency を許容 — grep では区別できないので機能で分類する)、機能している重複は cruft ではない、
    「何も見つからない監査は何も変えない」。 → `skills/claude-api/shared/prompt-audit.md` の "What not to flag"

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 仕様の所在 | `spec/agent-skills-spec.md` | 本文は外部化 (agentskills.io/specification を指す 1 行のみ) |
| SKILL.md 雛形 | `template/SKILL.md` | frontmatter 2 行 + 見出しのみの最小雛形 |
| 概要・必須 frontmatter・導入 | `README.md` | name+description のみ必須、カテゴリ分類、plugin 導入手順、基本 skill の作り方 |
| plugin/カテゴリ構成 | `.claude-plugin/marketplace.json` | document-skills / example-skills / claude-api の 3 plugin と収録 skill 一覧 |
| skill 作成の一次権威 | `skills/skill-creator/SKILL.md` | 意図把握→draft→eval→改善ループ、progressive disclosure、記述スタイル、triggering 論、description 最適化 |
| eval/採点/benchmark の JSON schema | `skills/skill-creator/references/schemas.md` | evals.json / grading.json / benchmark.json / metrics / timing / comparison / analysis の正確なフィールド定義 |
| eval 用 subagent 定義 | `skills/skill-creator/agents/{grader,comparator,analyzer}.md` | 採点・blind 比較・勝因分析のサブエージェント指示 |
| eval 自動化スクリプト | `skills/skill-creator/scripts/*.py` | run_loop(description最適化)/run_eval/aggregate_benchmark/package_skill/quick_validate 等 |
| eval レビュー UI 生成 | `skills/skill-creator/eval-viewer/generate_review.py`, `assets/eval_review.html` | 人がレビューする HTML viewer 生成 (自作 HTML は書かない) |
| **既存 prompt / skill / tool description の cruft 監査** | `skills/claude-api/shared/prompt-audit.md` | 4 グループの dated-pattern 表 (各グループに grep 可能な Signals) + keep list + 報告書と proposed diff の出力契約 + 削除は仮説なので behavioral probe で検証 |
| 監査を呼ぶ側の契約 | `skills/claude-api/SKILL.md` の Subcommands / Language Detection / Quick Task Reference | `prompt-audit` サブコマンド行、`migrate` からの相互参照 (per-target 適用後に必ず監査)、言語非依存タスクの carve-out |
| document skill (tool 型模範) | `skills/pdf/` | SKILL.md + scripts/*.py 8 本 + reference.md + forms.md。本文から reference を明示誘導 |
| Office 生成 skill | `skills/{docx,pptx,xlsx}/` | 各 skill = SKILL.md + 共有 `scripts/office/` (soffice.py・validate.py・validators/{base,docx,pptx,redlining}・helpers/pptx_{chart,slide,theme})。固有 script は docx=comment/merge_runs/accept_changes+templates/、pptx=add_slide/clean/thumbnail、xlsx=recalc。旧 pptx/editing.md・pptxgenjs.md は廃止し SKILL.md 本文へ統合 |
| MCP サーバ作成 skill | `skills/mcp-builder/` | reference/ + scripts/ 構成。FastMCP/TS SDK での MCP 実装ガイド |
| Web アプリテスト skill | `skills/webapp-testing/` | Playwright、examples/ + scripts/ 同梱 |
| guidance 型 (SKILL.md 1 枚) の模範 | `skills/{frontend-design,brand-guidelines}/` | scripts なし・本文のみで方針を伝える設計 |
| Creative & Design 実例 | `skills/{algorithmic-art,canvas-design,theme-factory,web-artifacts-builder}/` | 生成アート・ポスター・テーマ適用・複雑 artifact のパターン |
| Enterprise & Communication 実例 | `skills/{internal-comms,doc-coauthoring,slack-gif-creator}/` | 社内文書・共同執筆・Slack GIF。examples/ 同梱例あり |
| repo 同梱 skill の配置・発見規約 | `skills/claude-api/shared/managed-agents-tools.md` | ルート `.claude/skills/<name>/` を 1 階層走査 (セッション開始時 1 回・cloud sandbox 限定)、発見されない配置の列挙、信頼境界の警告 |
| pushy な description の手本 / 大規模 variant 分割の模範 | `skills/claude-api/` | SKILL.md frontmatter が TRIGGER/SKIP 構造で発火条件と除外条件を明記。本体は `{lang}/` 8 言語 + `shared/` 26 ファイルに分割し、SKILL.md 本文は選択ロジックと "→ Read `<path>`" 誘導に徹する |

## 蒸留の範囲外

- **Agent Skills の完全な仕様定義 (全 frontmatter フィールドの型・意味)** — このリポジトリでは外部化済み。
  <https://agentskills.io/specification> を直接引く。ここでは README と skill-creator が触れる範囲
  (name/description 必須、license/compatibility 任意) だけを確認した。
- **各模範 skill の本文の中身 (ノウハウそのもの)** — pdf の pypdf レシピ、docx の OOXML 操作、mcp-builder の
  MCP 設計指針など。skill 設計の "型" を知るのが本蒸留の目的なので、各ドメインの実装知は該当
  `skills/<name>/SKILL.md` と同梱 reference を直接読む。特に `claude-api` のモデル ID・価格・
  Managed Agents API 仕様は上流で頻繁に更新されるため、本蒸留を経由せず必ず原典を読む
  (本蒸留が claude-api から取るのは description の書きぶり・分割構造・repo 同梱 skill の配置規約、
  および `shared/prompt-audit.md` の監査フレームだけ)。
  session budget / inference_geo / advisor / multiagent roster といった API 表面は skill 設計と無関係なので扱わない。
- **prompt-audit の pattern 表の行そのもの (Before/After 対や greppable な正規表現)** — 監査を実行するときは
  `skills/claude-api/shared/prompt-audit.md` を直接読んで表と Signals をそのまま使う。ここでは
  「どの軸で分類し、何を残す契約なのか」だけを索引した。モデル固有の破壊的変更 (どのパラメータが
  どのモデルで 400 になるか) は `shared/model-migration.md` の per-target 節が正で、prompt-audit 自身も
  そちらを参照するよう指示している。
- **eval スクリプトの実装詳細** — `scripts/*.py` の CLI 引数や内部ロジックは写していない。実行時は
  skill-creator SKILL.md の該当節のコマンド例と `references/schemas.md` を引く。
- **skill-creator の環境別分岐** (Claude.ai / Cowork の subagent 有無・browser 有無による手順差) —
  必要時に `skills/skill-creator/SKILL.md` 末尾の各 "-specific instructions" 節を読む。
- **THIRD_PARTY_NOTICES.md / 各 LICENSE.txt** — ライセンス条文。document skills は source-available
  (Proprietary)、他の多くは Apache 2.0 という区別だけ押さえる。
