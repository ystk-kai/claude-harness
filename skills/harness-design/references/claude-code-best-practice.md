---
source: https://github.com/shanraisshan/claude-code-best-practice
distilled_commit: 154e72475b5f85dd4b457ea36f38aaabac211718
distilled_at: 2026-07-22
---

# claude-code-best-practice 蒸留版

Claude Code の実践知を集めたリポジトリ (shanraisshan) の蒸留。原典は `claude-code-best-practice` の
clone を読む (原典ルートは SKILL.md 参照)。以下のパスはすべてリポジトリルートからの相対パス。

## Contents

- [まず押さえる](#まず押さえる)
- [索引](#索引)
- [蒸留の範囲外](#蒸留の範囲外)

## まず押さえる

1. **最も軽い機構を選ぶ**。同じ意図に複数機構がマッチしたとき、Claude は最軽量のものを優先する:
   skill (inline、コンテキストオーバーヘッドなし) > agent (別コンテキスト、自律タスク向け) >
   command (自動発火せず、ユーザーが `/` で明示起動したときのみ)。同じタスクを 3 機構で実装した
   worked example ("What is the current time?") で挙動差が確認できる。
   → `reports/claude-agent-command-skill.md`

2. **使い分け基準**。Agent: 自律的・複数ステップ、コンテキスト分離が必要、永続メモリ (`memory:`)、
   skill の preload (`skills:`)、ツール制限・permission mode 変更が必要なとき。Command: ユーザー起点の
   エントリポイント、他の agent/skill をオーケストレーションするとき (内容は起動まで context に載らない)。
   Skill: 意図ベースで自動発火させたい再利用手順、複数箇所 (command/agent/Claude 本体) から呼ぶ手順。
   → `reports/claude-agent-command-skill.md` の "When to Use Each"

3. **Command → Agent → Skill の層状オーケストレーション**。command が入口、agent が別コンテキストで
   自律実行 (preloaded skill 持ち)、skill が inline で出力生成。weather システムとして完動する実装例あり。
   → `orchestration-workflow/orchestration-workflow.md`, 実体は `.claude/commands|agents|skills/`

4. **ハーネスはプロンプトの言い換えではない**。「全部最終的にプロンプトになるから強いプロンプトで代替可能」
   という還元論は、context isolation・harness 強制のツール制限・hooks の決定的実行・model routing・並列・
   セッション横断永続化など 10 の能力の前で崩れる。決定論が要る挙動 (attribution、権限、フォーマット) は
   prompt でなく hooks/settings で強制する。
   → `reports/why-harness-is-important.md`

5. **CLAUDE.md は 1 ファイル 200 行以下を目標** (humanlayer は 60 行)。「どの開発者が起動して
   "run the tests" と言っても一発で動く」が品質基準。settings.json で決定的に強制できるもの
   (`attribution.commit` 等) を CLAUDE.md に書かない。長くなったら `.claude/rules/*.md` に分割し、
   `paths:` frontmatter で対象ファイルに触れたときだけ lazy-load させる。
   → README.md「CLAUDE.md + .claude/rules」tips、`best-practice/claude-memory.md`

6. **CLAUDE.md のロード規則 (モノレポ)**。ancestor (上方向) は起動時に全ロード、descendant (下方向) は
   そのディレクトリのファイルに触れたとき lazy-load、sibling は決してロードされない。よって root に
   リポジトリ共通規約、コンポーネント配下に固有規約を置く。個人用は CLAUDE.local.md (.gitignore)。
   → `best-practice/claude-memory.md`

7. **Skills のロードは CLAUDE.md と別物**。ancestor loading はなく、description だけが常駐
   (デフォルト 15,000 文字バジェット、超過は `/context` で警告)。full content は呼び出し時のみロード。
   ネストされた `packages/*/.claude/skills/` はそのディレクトリで作業したときに自動発見される。
   例外: subagent の `skills:` preload は full content を起動時注入。
   → `reports/claude-skills-for-larger-mono-repos.md`

8. **Skill の書き方 (Anthropic 内部の教訓)**。description は要約でなくトリガーとして書く
   ("when should I fire?")。明白なことは書かず、デフォルト挙動から押し出す差分だけ書く。手順を
   railroad せず goal と制約を与える。Gotchas セクションが最高シグナル (Claude の失敗点を追記していく)。
   scripts/references/examples を同梱してフォルダとして設計する。危険な skill は
   `disable-model-invocation: true` で明示起動のみに。
   → `tips/claude-thariq-tips-17-mar-26.md`、README「Skills」tips

9. **Skills は 9 類型にクラスタする** (Library & API Reference / Product Verification / Data Fetching &
   Analysis / Business Process Automation / Code Scaffolding ほか)。良い skill は 1 類型に収まる。
   特に Product Verification skill (signup-flow-driver 等) はエンジニアが 1 週間かけて磨く価値がある。
   → `tips/claude-thariq-tips-17-mar-26.md`

10. **スコープ設計原則**。個人状態・プロジェクト横断調整 (tasks, teams, auto-memory, credentials,
    keybindings) は global (`~/.claude/`) のみ。チーム共有可能な設定 (settings, rules, agents, commands,
    skills, hooks) は dual-scope で project が優先。settings の優先順位: CLI flags >
    `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.local.json` >
    `~/.claude/settings.json`。`deny` ルールは最優先で上書き不可。
    → `reports/claude-global-vs-project-settings.md`

11. **subagent はコンテキスト管理の道具**。判断基準は「このツール出力を後で使うか、結論だけでよいか」—
    結論だけなら subagent に出す (探索の 20 file reads も dead end も子側に残る)。別コンテキストの
    同一モデルが自分の書いたバグを見つける (test time compute)。~40% 消費でモデルの劣化 ("dumb zone")
    が始まるので /clear・/compact・/rewind でセッションを刻む。
    → README「Context」「Agents」tips、`tips/claude-thariq-tips-16-apr-26.md`

12. **Agent memory は CLAUDE.md と補完関係**。`memory:` frontmatter (user/project/local) で agent 専用の
    永続知識を持てる。MEMORY.md の先頭 200 行が system prompt に注入され、超過分は topic 別ファイルへ。
    CLAUDE.md (人が書く・全員が読む) / auto-memory (Claude が書く・本人のみ) / agent memory
    (agent が書く・その agent のみ) の 3 系統。
    → `reports/claude-agent-memory.md`

13. **frontmatter の正確なリファレンスは best-practice/ にある**。skills・commands・subagents 各 16
    フィールドの型・意味の表 (バージョン付き)。設計時に記憶で書かずここを引く。公式ビルトイン一覧
    (bundled skills 13、slash commands 88、agent types 5) も同ファイル群にある。コマンド一覧・settings
    キーは新バージョンで追加され続ける (例: `/subtask` の追加と `/fork` からの分割、`/doctor` への
    `/checkup` エイリアス、`fastMode`・`vimInsertModeRemaps`・`CLAUDE_CODE_PROCESS_WRAPPER` の新キー)
    ため、個数や有無は記憶で断定せず各表のバージョンバッジで確認する。
    → `best-practice/claude-skills.md`, `claude-commands.md`, `claude-subagents.md`

14. **MCP は少数精鋭**。「15 個入れて日常使いは 4 個」が典型。secrets は `${VAR}` 展開で環境変数に。
    権限は `mcp__<server>__<tool>` 構文。スコープは Subagent (`mcpServers:` frontmatter) > Project
    (`.mcp.json`) > User (`~/.claude.json`)。
    → `best-practice/claude-mcp.md`

15. **主要ワークフローは Research → Plan → Execute → Review → Ship に収斂**。Superpowers / Spec Kit /
    BMAD など 10+ のコミュニティワークフローの比較表が README にあり、agents/commands/skills の
    構成数まで整理されている。
    → README「DEVELOPMENT WORKFLOWS」、`development-workflows/rpi/rpi-workflow.md`

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 全体目次・機能→docs 対応表 | `README.md` | CONCEPTS 表 (機能ごとの docs/実装リンク)、Hot features、83 tips、ワークフロー比較、購読先 |
| agents/commands/skills の使い分け | `reports/claude-agent-command-skill.md` | 3 機構の比較表・使い分け基準・最軽量優先の解決順・frontmatter 比較 |
| skill frontmatter + 公式 skill | `best-practice/claude-skills.md` | skill の 16 フィールドとバンドルスキル 13 個の一覧 |
| subagent frontmatter + 公式 agent | `best-practice/claude-subagents.md` | subagent の 16 フィールドと built-in agent type 5 個 |
| command frontmatter + 公式コマンド | `best-practice/claude-commands.md` | command の 16 フィールドと built-in slash command 88 個 (`/subtask`・`/checkup` エイリアス含む) |
| settings.json 網羅リファレンス | `best-practice/claude-settings.md` | 階層・permissions 構文・hooks・sandbox・model・env vars・完全例 (約 1300 行) |
| CLAUDE.md の書き方・ロード規則 | `best-practice/claude-memory.md` | ancestor/descendant/sibling のロード挙動、モノレポでの配置指針 |
| MCP 設定と選定 | `best-practice/claude-mcp.md` | 日常用 MCP 5 選、.mcp.json 例、承認 settings、権限構文、3 スコープ |
| CLI フラグ・環境変数 | `best-practice/claude-cli-startup-flags.md` | `claude` の起動フラグ・サブコマンド・env vars の分類表 |
| /powerup | `best-practice/claude-power-ups.md` | インタラクティブな機能学習レッスン 10 個の紹介 |
| global vs project スコープ | `reports/claude-global-vs-project-settings.md` | global-only と dual-scope の切り分け・settings 優先順位・Tasks・Agent Teams |
| モノレポでの skill 発見 | `reports/claude-skills-for-larger-mono-repos.md` | ネスト discovery・description のみ常駐・文字バジェット・CLAUDE.md との差分表 |
| agent の永続メモリ | `reports/claude-agent-memory.md` | `memory:` frontmatter、3 スコープ、200 行注入、他メモリ系との比較 |
| ハーネス擁護論 | `reports/why-harness-is-important.md` | 「全部プロンプト」還元論への反証 10 項目と正しいメンタルモデル |
| Agent SDK vs CLI | `reports/claude-agent-sdk-vs-cli-system-prompts.md` | system prompt の差 (CLI は 110+ fragments)、出力の決定性は保証されない |
| 高度なツール使用 (API 寄り) | `reports/claude-advanced-tool-use.md` | Programmatic Tool Calling・Tool Search Tool・tool use examples |
| 使用量・レート制限 | `reports/claude-usage-and-rate-limits.md` | /usage・extra usage・fast mode の課金挙動 |
| 「モデルが劣化した」問題 | `reports/llm-day-to-day-degradation.md` | インフラ起因の実例 (2025-09 postmortem) と心理要因の切り分け |
| ブラウザ自動化 MCP 比較 | `reports/claude-in-chrome-v-chrome-devtools-mcp.md` | Chrome DevTools MCP / Claude in Chrome / Playwright MCP の使い分け |
| CLI バイナリ抽出 tips | `reports/claude-spinner-verbs-and-tips.md` | spinner 単語と CLI 内蔵 tips の抽出リスト |
| Anthropic 内部の skill 運用 | `tips/claude-thariq-tips-17-mar-26.md` | skill 9 類型・description の書き方・Gotchas・railroad しない等の原則 |
| セッション/コンテキスト管理 | `tips/claude-thariq-tips-16-apr-26.md` | 毎ターンが分岐点 (Continue/rewind/clear/compact/subagent)、context rot |
| Boris (Claude Code 作者) の tips | `tips/claude-boris-*.md` | 日付別 tips 集。README「TIPS AND TRICKS」節にカテゴリ別で集約済み |
| command→agent→skill 実装例 | `orchestration-workflow/orchestration-workflow.md` | weather システムの設計・実行フロー・パターン解説 (動く実体は `.claude/`) |
| RPI ワークフロー | `development-workflows/rpi/rpi-workflow.md` | Research→Plan→Implement の commands + 8 agents 構成の実装 |
| クロスモデル併用 | `development-workflows/cross-model-workflow/cross-model-workflow.md` | Claude で Plan、Codex で QA-Review する 2 ターミナル手順 |
| 機能別の動く実装例 | `implementation/*.md` | subagents/skills/commands/agent-teams/goal/scheduled-tasks の手順書 |
| Agent Teams 実例 | `agent-teams/` | team 構成の prompt・agents・skills・出力一式 |
| 入門チュートリアル | `tutorial/day0/`, `tutorial/day1/` | セットアップと Prompting→Agents→Skills の段階的入門 |
| 動画・ポッドキャスト要約 | `videos/*.md` | Boris/Thariq/Cat/Dex/Karpathy らの講演・対談の書き起こしノート |
| このリポジトリ自身のハーネス | `.claude/` | agents/commands/skills/hooks/settings.json の実働サンプル (音声 hooks 含む) |

## 蒸留の範囲外

- **settings.json の全キーと permissions 構文の詳細** — 本文 1300 行の網羅表は写していない。設計・監査で
  キー名や構文を確定させるときは `best-practice/claude-settings.md` を直接引く。
- **公式 slash command 88 個・CLI フラグ・env vars の全リスト** — `best-practice/claude-commands.md` と
  `best-practice/claude-cli-startup-flags.md` を引く。
- **83 個の tips 全文** — カテゴリ (Prompting/Planning/Context/Session/CLAUDE.md/Agents/Commands/Skills/
  Hooks/Workflows/Git/Debugging) ごとの一覧は `README.md` の TIPS AND TRICKS 節。各 tip に一次ソース
  (tweet/動画) リンク付き。
- **コミュニティワークフロー 10+ の詳細比較・skill/agent コレクション集** — `README.md` の
  DEVELOPMENT WORKFLOWS / SKILL COLLECTIONS / AGENT COLLECTIONS 表。
- **Claude API 寄りの詳細** (Programmatic Tool Calling、SDK 設定、rate limits の数値) —
  `reports/claude-advanced-tool-use.md`, `claude-agent-sdk-vs-cli-system-prompts.md`,
  `claude-usage-and-rate-limits.md`。
- **hooks の実装詳細** — このリポジトリでは別リポジトリ (shanraisshan/claude-code-hooks) が正。
  ローカルの実働サンプルは `.claude/hooks/` にある。
- **プレゼン資料・動画書き起こし・チュートリアル本文** — `presentation/`, `videos/`, `tutorial/`。
- 注意: 特定バージョン (v2.1.x) や beta 機能に固定された記述が多い。バージョン依存の断定は避け、
  frontmatter 表のバッジ (対応バージョン) と CHANGELOG で確認する。
