---
source: https://github.com/shanraisshan/claude-code-best-practice
distilled_commit: 6624aaf5ef45b8c347c26688deaeb44d96b85616
distilled_at: 2026-08-12
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
   command (自動発火せず、ユーザーが `/` で明示起動したときのみ)。使い分けは — Agent: 自律的・複数ステップ、
   コンテキスト分離、永続メモリ (`memory:`)、skill の preload (`skills:`)、ツール制限や permission mode の
   変更が必要なとき。Command: ユーザー起点の入口、他の agent/skill をオーケストレーションするとき
   (内容は起動まで context に載らない)。Skill: 意図ベースで自動発火させたい再利用手順、複数箇所から呼ぶ手順。
   同じタスク ("What is the current time?") を 3 機構で実装した worked example で挙動差が確認できる。
   → `reports/claude-agent-command-skill.md` (特に "When to Use Each")

2. **Command → Agent → Skill の層状オーケストレーション**。command が入口、agent が別コンテキストで
   自律実行 (preloaded skill 持ち)、skill が inline で出力生成。weather システムとして完動する実装例あり。
   → `orchestration-workflow/orchestration-workflow.md`、実体は `.claude/commands|agents|skills/`

3. **ハーネスはプロンプトの言い換えではない**。「全部最終的にプロンプトになるから強いプロンプトで代替可能」
   という還元論は、context isolation・harness 強制のツール制限・hooks の決定的実行・model routing・並列・
   セッション横断永続化など 10 の能力の前で崩れる。決定論が要る挙動 (attribution、権限、フォーマット) は
   prompt でなく hooks/settings で強制する。
   → `reports/why-harness-is-important.md`

4. **CLAUDE.md は 1 ファイル 200 行以下を目標** (humanlayer は 60 行)。「どの開発者が起動して
   "run the tests" と言っても一発で動く」が品質基準。settings.json で決定的に強制できるもの
   (`attribution.commit` 等) を CLAUDE.md に書かない。長くなったら `.claude/rules/*.md` に分割し、
   `paths:` frontmatter で対象ファイルに触れたときだけ lazy-load させる。ロード規則はモノレポ設計に直結する:
   ancestor (上方向) は起動時に全ロード、descendant (下方向) はそのディレクトリのファイルに触れたとき
   lazy-load、sibling は決してロードされない。よって root に共通規約、コンポーネント配下に固有規約を置く。
   個人用は CLAUDE.local.md (.gitignore)。
   → README.md「CLAUDE.md + .claude/rules」tips、`best-practice/claude-memory.md`

5. **Skills のロードは CLAUDE.md と別物**。ancestor loading はなく、description だけが常駐。full content は
   呼び出し時のみロード。ネストされた `packages/*/.claude/skills/` はそのディレクトリで作業したときに自動発見
   される。例外: subagent の `skills:` preload は full content を起動時注入。バジェットの正は settings 側の
   2 キー — `skillListingBudgetFraction` (既定 `0.01` = context window の 1%。超過すると使用頻度の低い skill の
   description が名前だけに collapse され、呼べるが理由が見えなくなる) と `skillListingMaxDescChars`
   (既定 `1536`、1 skill の `description` + `when_to_use` 合算上限、超過分は truncate)。後者は
   2026-07-31 まで原典が `maxSkillDescriptionChars` と誤記していた無効キー (silent no-op) なので注意。
   可視性は `skillOverrides` で `on` / `name-only` / `user-invocable-only` / `off` を skill 単位に指定できる。
   なお `reports/claude-skills-for-larger-mono-repos.md` は「既定 15,000 文字」「`SLASH_COMMAND_TOOL_CHAR_BUDGET`
   で拡大」と書くが、settings レポート側では同 env var は slash command tool 出力用と定義されている。
   数値とキー名は settings レポートを正とする。
   → `reports/claude-skills-for-larger-mono-repos.md`, `best-practice/claude-settings.md`

6. **Skill の書き方 (Anthropic 内部の教訓)**。description は要約でなくトリガーとして書く
   ("when should I fire?")。明白なことは書かず、デフォルト挙動から押し出す差分だけ書く。手順を
   railroad せず goal と制約を与える。Gotchas セクションが最高シグナル (Claude の失敗点を追記していく)。
   scripts/references/examples を同梱してフォルダとして設計する。危険な skill は
   `disable-model-invocation: true` で明示起動のみに。良い skill は 9 類型 (Library & API Reference /
   Product Verification / Data Fetching & Analysis / Business Process Automation / Code Scaffolding ほか)
   のどれか 1 つに収まる。特に Product Verification skill (signup-flow-driver 等) は 1 週間かけて磨く価値がある。
   → `tips/claude-thariq-tips-17-mar-26.md`、README「Skills」tips

7. **スコープ設計原則**。個人状態・プロジェクト横断調整 (tasks, teams, auto-memory, credentials,
   keybindings) は global (`~/.claude/`) のみ。チーム共有可能な設定 (settings, rules, agents, commands,
   skills, hooks) は dual-scope で project が優先。settings の優先順位: CLI flags >
   `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.local.json` >
   `~/.claude/settings.json`。`deny` ルールは最優先で上書き不可。**権限昇格につながる設定は
   project/local から無視される** — untrusted なリポジトリが自分に権限を与えられないようにするため:
   `permissions.defaultMode` の `"auto"` (v2.1.142 以降、project/local では無視。`~/.claude/settings.json`
   に書く)、`processWrapper` (managed / user / `--settings` のみ、v2.1.210)、`footerLinksRegexes`
   (user / `--settings` / managed のみ)、`pluginConfigs` (v2.1.207 以降 project/local を読まない)、
   `sshConfigs` (managed / user のみ)、`strictPluginOnlyCustomization` (managed のみ)、sandbox の緩和系
   3 キー `sandbox.filesystem.disabled`・`sandbox.network.strictAllowlist`・`sandbox.network.tlsTerminate`
   と `sandbox.credentials` の `mask` モード (いずれも user / managed / `--settings` のみ。原典が
   v2.1.224 追従で明記)。**非対称**なのが要点で、逆に制限を強める値は下位スコープからも効く —
   `disableClaudeAiConnectors: true` は managed の `false` に対しても任意スコープから、
   `remoteControlAtStartup: false` は project/local からでも managed の `true` を上書きできる
   (opt out はできるが opt in はできない)。`fallbackModel` だけは配列なのにマージされず、
   定義した最上位のファイルがチェーン全体を供給する (重複除去後 4 件目以降は無視)。
   → `reports/claude-global-vs-project-settings.md`, `best-practice/claude-settings.md`

8. **permissions 構文には落とし穴がある**。`Tool(param:value)` (`Agent(model:opus)`,
   `Agent(isolation:worktree)`, `Bash(run_in_background:true)`) は **deny / ask ルール専用**で allow では
   使えない — 1 パラメータ値の許可では全体の安全性を担保できないため、allow は各ツール固有の specifier
   構文を使う。ツールの主コンテンツ欄へのマッチ (`Bash(command:rm *)`) も禁止で起動時 warning が出る。
   `Write(path)` / `NotebookEdit(path)` / `Glob(path)` は allow に書くと parse は通るが**一切参照されない** —
   allow 評価は `Edit(path)` と `Read(path)` しか見ない (v2.1.210)。起動時 warning が出るだけの実質 no-op なので
   書き込み許可は `Edit` 側で表現する (deny / ask では期待通り機能する)。
   `:*` サフィックス (`Bash(npm:*)`) は非推奨ではないが末尾でしか解釈されない
   (`Bash(git:* push)` はコロンをリテラル扱い)。permission ダイアログはスペース形式で書く。
   allow のツール名 glob は **`mcp__<server>__` というリテラル前置がある場合しか受理されない** —
   `"*"` / `"B*"` / `"mcp__*"` は起動時 warning 付きで skip され何も自動承認しない
   (`mcp__github__*` は有効)。全体を allowlist 化したいなら `deny: ["*"]` + 個別 allow で組む。
   `Cd(path)` は allow を 1 本でも書いた時点で `/cd` が allowlist モードになり、
   ワイルドカードの意味も Read/Edit と違う (`*` は 1 セグメントのみ、`**` は跨ぐ、gitignore 形式ではない)。
   skill の `Skill(weather-fetcher)` / `Skill(weather *)` と `MCP(server:tool)` 短縮形は 2026-08-02 に
   「公式 permissions docs に無い = 未検証」と注記された。確実なのは `mcp__server__tool` 形式のみで、
   `Task(agent-name)` は `Agent` の legacy alias。
   → `best-practice/claude-settings.md` の Permissions 節

9. **ハーネス側のハード上限を前提に設計する**。並列 subagent は
   `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (既定 `20`) で制限され、超過分は queue に入る。ネストは
   `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (v2.1.219 時点の既定 `3`) までで、上限深度の subagent はさらに
   spawn できない。Stop hook のブロックは `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (既定 `8`) 回で打ち切られ、
   以降は hook の exit code に関係なくセッションが終了する — 無限にブロックする Stop hook は設計できない。
   `effortLevel` に `"max"` / `"ultracode"` は書けない (session 限定で `/effort` からのみ。settings.json に
   書くと拒否される)。永続化できるのは `low` / `medium` / `high` / `xhigh`。
   → `best-practice/claude-settings.md`

10. **subagent はコンテキスト管理の道具**。判断基準は「このツール出力を後で使うか、結論だけでよいか」—
    結論だけなら subagent に出す (探索の 20 file reads も dead end も子側に残る)。別コンテキストの
    同一モデルが自分の書いたバグを見つける (test time compute)。~40% 消費でモデルの劣化 ("dumb zone")
    が始まるので /clear・/compact・/rewind でセッションを刻む。自動 compact の発火点は
    `autoCompactWindow` (100,000〜1,000,000 tokens、未設定ならモデル別のチューニング値) で調整でき、
    `/autocompact` / `--autocompact` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` から設定する (v2.1.221+)。
    走っている subagent / 別セッションへの働きかけは cross-session messaging
    (`SendMessage`・`ListAgents`・`/list-agents` (alias `/peers`)、v2.1.224 で GA) で、
    agent-team のチームメイトは列挙対象に含まれない。
    → README「Context」「Agents」tips、`tips/claude-thariq-tips-16-apr-26.md`

11. **Agent memory は CLAUDE.md と補完関係**。`memory:` frontmatter (user/project/local) で agent 専用の
    永続知識を持てる。MEMORY.md の先頭 200 行が system prompt に注入され、超過分は topic 別ファイルへ。
    CLAUDE.md (人が書く・全員が読む) / auto-memory (Claude が書く・本人のみ) / agent memory
    (agent が書く・その agent のみ) の 3 系統。
    → `reports/claude-agent-memory.md`

12. **frontmatter の正確なリファレンスは best-practice/ にあるが、そのまま信じない**。skills 20・
    commands 20・subagents 16 フィールドの型・意味の表と、公式ビルトイン一覧 (bundled skills 15、
    slash commands 89、agent types 5) がある。設計時は記憶で書かずここを引く。ただし個数・有無は版で
    増減し (v2.1.224 で skill/command 双方に Agent Skills spec 由来の `metadata` / `license` /
    `compatibility` が追加 — 3 つとも Claude Code は受理するだけで挙動には使わない。`metadata` は map
    以外を drop し、`paths` のような既存フィールド名を key に流用しない。`compatibility` は 500 字上限。
    v2.1.218 で `background` 追加、v2.1.205 で `/doctor` が built-in command から bundled skill へ再分類)、
    原典の日次 drift check には遅れ・揺れ・**自己誤り**がある: (a) `/review` は v2.1.223 で
    `/code-review` の alias になったが、bundled skills 表 row 14 は「PR の高速 1 パスレビュー」という
    旧挙動の説明のまま。`review` / `security-review` を bundled skill として数えるかは 2026-07-30 以来
    ON HOLD → 2026-08-01 に「15 が正しい」といったん決着 → 翌日 raw marker count で覆り、
    2026-08-12 (v2.1.228) 時点も未決着で表は 15 個のまま。公式 docs 側の整理は「`security-review` は
    `/init` と同じ built-in command reachable via the Skill tool で bundled skill ではない」
    「commands reference の **[Skill]** マーカー付きは 13 行で `review` も `security-review` も含まれない」。
    (b) 2026-07-27 の run が `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` に誤って
    `_CODE_` を足して説明も反転させ、`effortLevel` に無効値 `max`/`ultracode` を追加し、4 日後の
    2026-07-31 に revert された。(c) subagents 表は `Explore` の model を `haiku` とするが公式は
    「親の会話から継承」と書き、`model` 欄の例も `claude-opus-4-6` のままで `fable` 未記載。v2.1.224 で
    公式に載った catch-all の `claude` agent (model 継承・全ツール、dispatch された background セッションの
    既定) も 2026-08-07 から 2026-08-12 (v2.1.228) まで毎日 ON HOLD の再掲で表は 5 個のまま — いずれも
    watch item として挙がるだけで未修正。日次 run で動くのは実質バッジ行 1 行と changelog 追記だけで、
    本文は据え置かれる。断定する前に各表のバージョンバッジと `changelog/` 配下の該当 changelog.md を見る。
    → `best-practice/claude-skills.md`, `claude-commands.md`, `claude-subagents.md`, `claude-settings.md`

13. **MCP は少数精鋭**。「15 個入れて日常使いは 4 個」が典型。secrets は `${VAR}` 展開で環境変数に。
    権限は `mcp__<server>__<tool>` 構文。スコープは Subagent (`mcpServers:` frontmatter) > Project
    (`.mcp.json`) > User (`~/.claude.json`)。
    → `best-practice/claude-mcp.md`

14. **主要ワークフローは Research → Plan → Execute → Review → Ship に収斂**。コミュニティワークフローの
    比較表が README にあり、agents/commands/skills の構成数と各ステップ (黄タグ = 親ステップ内で反復する
    サブループ) まで整理されている。★ 数もステップ列も日次更新されるので都度引く。
    → README「DEVELOPMENT WORKFLOWS」、`development-workflows/rpi/rpi-workflow.md`

15. **skill/command の fork 実行は 3 フィールドで制御する**。`context: fork` で隔離サブエージェント
    コンテキストに逃がし、`agent:` で subagent type を指定 (既定 `general-purpose`)、`background`
    (boolean、既定 `true`、v2.1.218+) を `false` にすると呼び出したターン内で結果を待つ。後続処理が
    結果に依存するなら `background: false`。この 3 つは skill と command のみで、subagent 側の
    frontmatter にはない。
    → `best-practice/claude-skills.md`, `claude-commands.md` の Frontmatter Fields 表

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 全体目次・機能→docs 対応表 | `README.md` | CONCEPTS 表 (機能ごとの docs/実装リンク)、Hot features、tips 集、ワークフロー比較、購読先 |
| agents/commands/skills の使い分け | `reports/claude-agent-command-skill.md` | 3 機構の比較表・使い分け基準・最軽量優先の解決順・frontmatter 比較 |
| skill frontmatter + 公式 skill | `best-practice/claude-skills.md` | skill の 20 フィールド (`background` と Agent Skills spec の `metadata`/`license`/`compatibility` 含む) とバンドルスキル 15 個 (`doctor` は `disableBundledSkills` の唯一の例外。`security-review` = 現在の diff の脆弱性レビュー (`--fix` / `--comment`)。`review` は `/code-review` の alias 化後も旧説明のまま残り、`review`/`security-review` を bundled と数えるかは未決着で command 表にも重複) |
| subagent frontmatter + 公式 agent | `best-practice/claude-subagents.md` | subagent の 16 フィールドと built-in agent type 5 個 (`Explore` の model 欄・`model` 例の model 名・公式に増えた `claude` agent はいずれも未反映の watch item) |
| command frontmatter + 公式コマンド | `best-practice/claude-commands.md` | command の 20 フィールド (skill と同じ 3 フィールドが追加) と built-in slash command 89 個 (`/import` (codex/gemini 設定の取り込み)・`/list-agents`・`/autocompact` が追加、`/ultraplan` は機能ごと削除。`/doctor` は bundled skill 側へ移動、`/review`・`/security-review` は両表に併記) |
| settings.json 網羅リファレンス | `best-practice/claude-settings.md` | 階層・permissions 構文・hooks・sandbox・model/effort・env vars・完全例 (1400 行、v2.1.224 追従で「127+ settings / 311 env vars」。2026-07-31・08-02・08-07 と大きな drift 修正が続き、キー名・permission 挙動・スコープ制限・env var が毎回増減する) |
| CLAUDE.md の書き方・ロード規則 | `best-practice/claude-memory.md` | ancestor/descendant/sibling のロード挙動、モノレポでの配置指針 |
| MCP 設定と選定 | `best-practice/claude-mcp.md` | 日常用 MCP 5 選、.mcp.json 例、承認 settings、権限構文、3 スコープ |
| CLI フラグ・環境変数 | `best-practice/claude-cli-startup-flags.md` | `claude` の起動フラグ・サブコマンド・env vars の分類表 |
| /powerup | `best-practice/claude-power-ups.md` | インタラクティブな機能学習レッスン 10 個の紹介 |
| global vs project スコープ | `reports/claude-global-vs-project-settings.md` | global-only と dual-scope の切り分け・settings 優先順位・Tasks・Agent Teams |
| モノレポでの skill 発見 | `reports/claude-skills-for-larger-mono-repos.md` | ネスト discovery・description のみ常駐・文字バジェット (数値は settings レポートを正とする)・CLAUDE.md との差分表 |
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
| 各レポートの drift 履歴 | `changelog/**/changelog.md` | 日次 drift check の指摘・ON HOLD・誤修正の revert 記録。表の値を疑うときここを見る |

## 蒸留の範囲外

- **settings.json の全キーと permissions 構文の詳細** — 1300 行超の網羅表は写していない。設計・監査で
  キー名や構文を確定させるときは `best-practice/claude-settings.md` を直接引く。キー名の誤りは
  silent no-op になるため (`maxSkillDescriptionChars` の例) 記憶で書かない。原典は公式 docs で裏が取れない
  キー・構文に `*(not in official ... — unverified)*` を inline 注記する運用なので (2026-08-02 監査時点では
  `thinkingBudgetTokens`・`Skill(...)`・`MCP(server:tool)`)、この注記付きの値は設計の前提にしない。
- **公式 slash command・CLI フラグ・env vars の全リスト** — `best-practice/claude-commands.md` と
  `best-practice/claude-cli-startup-flags.md` を引く。
- **tips 全文** — カテゴリ (Prompting/Planning/Context/Session/CLAUDE.md/Agents/Commands/Skills/
  Hooks/Workflows/Git/Debugging) ごとの一覧は `README.md` の TIPS AND TRICKS 節。各 tip に一次ソース
  (tweet/動画) リンク付き。
- **コミュニティワークフローの詳細比較・skill/agent コレクション集** — `README.md` の
  DEVELOPMENT WORKFLOWS / SKILL COLLECTIONS / AGENT COLLECTIONS 表。scheduled refresh で日次更新され、
  ★ 数・skill/agent 個数だけでなく**ステップ列そのものも書き換わる** (2026-07-30〜08-03 に Superpowers と
  Spec Kit、08-07〜08-10 に BMAD-METHOD・oh-my-claudecode・Compound Engineering・HumanLayer・Matt Pocock
  Skills のステップ列が入れ替わった) ため、蒸留版はこれらの数値もステップ列も持たない。個数は ★ の
  ドリフトとは別に事実訂正でも動く (2026-08-11 に Compound Engineering の agents が 39 → 0 へ訂正)。
  逆に、上流 README と食い違う個数を「directory-count baseline」として意図的に据え置く運用もあり
  (OpenSpec の skills は 12 個の確認が 14 run 続いても表は 0)、表の個数は上流の実態と一致しない。
- **Claude API 寄りの詳細** (Programmatic Tool Calling、SDK 設定、rate limits の数値) —
  `reports/claude-advanced-tool-use.md`, `claude-agent-sdk-vs-cli-system-prompts.md`,
  `claude-usage-and-rate-limits.md`。
- **hooks の実装詳細** — このリポジトリでは別リポジトリ (shanraisshan/claude-code-hooks) が正。
  ローカルの実働サンプルは `.claude/hooks/` にある。
- **プレゼン資料・動画書き起こし・チュートリアル本文** — `presentation/`, `videos/`, `tutorial/`。
- 注意: 特定バージョン (v2.1.x) や beta 機能に固定された記述が多い。beta バッジは GA 化で外れる
  (Auto Mode は 2026-07-28 に公式 docs 確認のうえ beta バッジ削除) ため、バージョン依存・beta 前提の断定は
  避け、frontmatter 表のバッジ (対応バージョン) と `changelog/` 配下の drift check ログで確認する。
  Voice Dictation・Artifacts の beta バッジは 1 か月以上 ON HOLD のまま残っている。
- 注意: 原典が張る公式 docs の URL も動く。2026-07-30 に README の CONCEPTS 表の Commands 行は
  `docs/en/slash-commands` から `docs/en/commands` へ修正されたが、同じ README の TIPS 表で commands /
  slash commands / command を指す 3 リンクは `docs/en/skills` を指したままで、1 ファイル内に 2 つの宛先が
  並存している。docs URL は原典のリンクを写さず、公式 docs 側で当たり先を確認する。**機能名も同様** —
  README の "No Flicker Mode" は公式 docs のページタイトル "Fullscreen rendering" と一致せず、
  2026-08-11 に検出されて 2026-08-12 も ON HOLD (コミュニティ呼称が優勢なため判断保留)。原典の呼称で
  公式 docs を検索しても当たらないことがあるので、機能名は公式 docs 側の表記で引き直す。
