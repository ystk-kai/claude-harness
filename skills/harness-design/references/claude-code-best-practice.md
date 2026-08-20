---
source: https://github.com/shanraisshan/claude-code-best-practice
distilled_commit: 902a28644fb0f5598982b530a6892c32d800529d
distilled_at: 2026-08-21
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
   (内容は起動まで context に載らない)。Skill: 意図ベースで自動発火させたい再利用手順。同じタスクを
   3 機構で実装した worked example で挙動差が確認できる。
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
   ancestor は起動時に全ロード、descendant はそのディレクトリのファイルに触れたとき lazy-load、sibling は
   決してロードされない。root に共通規約、コンポーネント配下に固有規約。個人用は CLAUDE.local.md。
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
   で拡大」と書くが、settings レポートは同 env var を slash command tool 出力用と定義する。数値とキー名は
   settings レポートを正とする (ただしそれ自体が v2.1.224 で更新停止。項目 12 参照)。
   → `reports/claude-skills-for-larger-mono-repos.md`, `best-practice/claude-settings.md`

6. **Skill の書き方 (Anthropic 内部の教訓)**。description は要約でなくトリガーとして書く
   ("when should I fire?")。明白なことは書かず、デフォルト挙動から押し出す差分だけ書く。手順を
   railroad せず goal と制約を与える。Gotchas セクションが最高シグナル (Claude の失敗点を追記していく)。
   scripts/references/examples を同梱してフォルダとして設計する。危険な skill は
   `disable-model-invocation: true` で明示起動のみに。良い skill は 9 類型 (Library & API Reference /
   Product Verification / Data Fetching & Analysis / Code Scaffolding ほか) のどれか 1 つに収まる。
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
   (`sandbox.filesystem.disabled`・`sandbox.network.strictAllowlist`・`sandbox.network.tlsTerminate`・
   `sandbox.credentials` の `mask`。user / managed / `--settings` のみ)。**非対称**なのが要点で、逆に制限を
   強める値は下位スコープからも効く — `disableClaudeAiConnectors: true` は managed の `false` に対しても
   任意スコープから、`remoteControlAtStartup: false` は project/local からでも managed の `true` を上書き
   できる (opt out はできるが opt in はできない)。`fallbackModel` だけは配列なのにマージされず、定義した
   最上位のファイルがチェーン全体を供給する (重複除去後 4 件目以降は無視)。
   → `reports/claude-global-vs-project-settings.md`, `best-practice/claude-settings.md`

8. **permissions 構文には落とし穴がある**。`Tool(param:value)` (`Agent(model:opus)`,
   `Agent(isolation:worktree)`, `Bash(run_in_background:true)`) は **deny / ask ルール専用**で allow では
   使えない — 1 パラメータ値の許可では全体の安全性を担保できないため、allow は各ツール固有の specifier
   構文を使う。ツールの主コンテンツ欄へのマッチ (`Bash(command:rm *)`) も禁止で起動時 warning が出る。
   `Write(path)` / `NotebookEdit(path)` / `Glob(path)` は allow に書くと parse は通るが**一切参照されない** —
   allow 評価は `Edit(path)` と `Read(path)` しか見ない (v2.1.210)。warning が出るだけの実質 no-op なので
   書き込み許可は `Edit` 側で表現する (deny / ask では期待通り機能する)。`:*` サフィックス (`Bash(npm:*)`) は
   非推奨ではないが末尾でしか解釈されない (`Bash(git:* push)` はコロンをリテラル扱い)。permission ダイアログ
   はスペース形式で書く。allow のツール名 glob は **`mcp__<server>__` というリテラル前置がある場合しか
   受理されない** — `"*"` / `"B*"` / `"mcp__*"` は起動時 warning 付きで skip され何も自動承認しない
   (`mcp__github__*` は有効)。全体を allowlist 化したいなら `deny: ["*"]` + 個別 allow で組む。
   `Cd(path)` は allow を 1 本でも書いた時点で `/cd` が allowlist モードになり、ワイルドカードの意味も
   Read/Edit と違う (`*` は 1 セグメントのみ、`**` は跨ぐ、gitignore 形式ではない)。`Skill(weather *)` と
   `MCP(server:tool)` 短縮形は 2026-08-02 に「公式 permissions docs に無い = 未検証」と注記された。確実なのは
   `mcp__server__tool` 形式のみで、`Task(agent-name)` は `Agent` の legacy alias。
   → `best-practice/claude-settings.md` の Permissions 節

9. **ハーネス側のハード上限を前提に設計する**。並列 subagent は
   `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (既定 `20`) で制限され、超過分は queue に入る。ネストは
   `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (v2.1.219 時点の既定 `3`) までで、上限深度の subagent はさらに
   spawn できない。Stop hook のブロックは `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (既定 `8`) 回で打ち切られ、以降は
   hook の exit code に関係なくセッションが終了する — 無限にブロックする Stop hook は設計できない。
   `effortLevel` に `"max"` / `"ultracode"` は書けない (session 限定で `/effort` からのみ)。永続化できるのは
   `low` / `medium` / `high` / `xhigh`。
   → `best-practice/claude-settings.md`

10. **subagent はコンテキスト管理の道具**。判断基準は「このツール出力を後で使うか、結論だけでよいか」—
    結論だけなら subagent に出す (探索の 20 file reads も dead end も子側に残る)。別コンテキストの
    同一モデルが自分の書いたバグを見つける (test time compute)。~40% 消費でモデルの劣化 ("dumb zone")
    が始まるので /clear・/compact・/rewind でセッションを刻む。自動 compact の発火点は `autoCompactWindow`
    (100,000〜1,000,000 tokens、未設定ならモデル別のチューニング値) で、`/autocompact` / `--autocompact` /
    `CLAUDE_CODE_AUTO_COMPACT_WINDOW` から設定する (v2.1.221+)。走っている subagent / 別セッションへの
    働きかけは cross-session messaging (`SendMessage`・`ListAgents`・`/list-agents` (alias `/peers`)、
    v2.1.224 で GA) で、agent-team のチームメイトは列挙対象に含まれない。
    **タスク管理を todo ツールに寄せる設計は避ける** —
    v2.1.233 で新しいモデルでは task/todo ツールが deprecated (env var で opt-in) になった。
    → README「Context」「Agents」tips、`tips/claude-thariq-tips-16-apr-26.md`

11. **Agent memory は CLAUDE.md と補完関係**。`memory:` frontmatter (user/project/local) で agent 専用の
    永続知識を持てる。MEMORY.md の先頭 200 行が system prompt に注入され、超過分は topic 別ファイルへ。
    CLAUDE.md (人が書く・全員が読む) / auto-memory (Claude が書く・本人のみ) / agent memory (agent が
    書く・その agent のみ) の 3 系統。
    → `reports/claude-agent-memory.md`

12. **frontmatter の正確なリファレンスは best-practice/ にあるが、そのまま信じない**。skills 20・
    commands 20・subagents 16 フィールドの型・意味の表と、公式ビルトイン一覧 (bundled skills 15、
    slash commands 89、agent types 5) がある。設計時は記憶で書かずここを引く。ただし**日次 drift check が
    動かすのはバッジ行と `changelog/` 追記だけで、表本体は据え置かれる**ため、個数は公式 docs と一致しない。
    2026-08-20 (v2.1.237) 時点の未決着 3 件と誤検出 1 件:
    - bundled skills 表 row 14 `review` — v2.1.223 で `/code-review` の alias になったが説明は旧挙動
      (fast single-pass PR review) のまま。削除すれば 15 → 14 だが 2026-07-30 から ON HOLD。
    - row 15 `security-review` — 2026-08-13 に 2 エージェントの独立確認で「bundled で正」と決着したが
      **翌 2026-08-14 に再オープンされ以後 ON HOLD**。2026-08-18 の run が公式 skills docs の
      "A few built-in commands are also available through the Skill tool, including `/init` and
      `/security-review`" を根拠に「bundled skill ではなく Skill tool から呼べる built-in command」と結論。
      公式が数える bundled skill は 13 で `review` / `security-review` を含まない。row 15 が挙げる
      `--fix` / `--comment` も公式側の記述から消えている。前回蒸留の「row 15 は正で決着」は撤回。
    - subagents 表 — 2026-08-20 の scan は公式が 6 agent (`Explore`, `Plan`, `general-purpose`, `claude`,
      `statusline-setup`, `claude-code-guide`) を挙げるとするが表は 5 個。`claude` (model 継承・全ツール、
      dispatch された background セッションの既定) の追加は 2026-08-07 から ON HOLD。`Explore` の model を
      `haiku` とする行も公式の「親から継承」と食い違い、`model` 欄の例は `claude-opus-4-6` のままで
      `fable` 未記載。
    - `fork` は 2026-08-17 に NEW として挙がり 2 日 ON HOLD の後、2026-08-20 に「公式 docs に無い = 誤検出」
      として INVALID にされた。drift check 自身が誤りを注入する例 (2026-07-27 に
      `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` を改名・説明反転させ 4 日後に revert した件と同種)。
    さらに**日次追従を受けているのは 4 本 (skills / commands / subagents / README CONCEPTS) と 3 つの
    コレクション表だけ**。`claude-settings.md` は 2026-08-07 / v2.1.224 で止まり (v2.1.237 に対し 13 版遅れ)、
    `claude-memory.md` (2026-03-14)・`claude-mcp.md` (2026-03-07)・`claude-cli-startup-flags.md`
    (2026-06-06) は数か月動いていない。バッジの日付が、その表がまだ追われているかの唯一の指標。
    → `best-practice/claude-skills.md`, `claude-commands.md`, `claude-subagents.md`, `claude-settings.md`

13. **MCP は少数精鋭**。「15 個入れて日常使いは 4 個」が典型。secrets は `${VAR}` 展開で環境変数に。権限は
    `mcp__<server>__<tool>` 構文。スコープは Subagent (`mcpServers:`) > Project (`.mcp.json`) > User。
    → `best-practice/claude-mcp.md`

14. **主要ワークフローは Research → Plan → Execute → Review → Ship に収斂**。README の比較表に
    agents/commands/skills の構成数と各ステップ (黄タグ = 親ステップ内で反復するサブループ) がある。
    ★ 数もステップ列も日次更新されるので都度引く。
    → README「DEVELOPMENT WORKFLOWS」、`development-workflows/rpi/rpi-workflow.md`

15. **fork 実行と background セッションの境界**。skill/command は `context: fork` で隔離サブエージェント
    コンテキストに逃がし、`agent:` で subagent type を指定 (既定 `general-purpose`)、`background` (boolean、
    既定 `true`、v2.1.218+) を `false` にすると呼び出したターン内で結果を待つ (後続処理が結果に依存する
    ならこれ)。この 3 つは skill と command のみで、subagent 側の frontmatter にはない。ユーザー側の
    入口は `/subtask` (親の会話を丸ごと継承する forked subagent を
    background で回し、終了時に結果を元の会話へ返す)。background セッションには制約があり、**走っている
    background セッションは `/resume` のピッカーから再開できない** (`claude agents` で attach するか先に
    停止する)、`/insights` はローカルマシンのセッションだけを HTML レポート化し cloud では使えない。
    `/add-dir` は v2.1.234 からターン中に即確認を求める (それ以前はターン終了までキューされた) うえ、
    成功時に `DirectoryAdded` hook が走る — 追加ディレクトリの `.claude/` 設定はほぼ読まれないので、
    必要な副作用はこの hook 側で組む。
    → `best-practice/claude-skills.md`, `claude-commands.md` の Frontmatter Fields 表と各コマンド行

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 全体目次・機能→docs 対応表 | `README.md` | CONCEPTS 表 (機能ごとの docs/実装リンク)、Hot features、tips 集、ワークフロー比較、購読先 |
| agents/commands/skills の使い分け | `reports/claude-agent-command-skill.md` | 3 機構の比較表・使い分け基準・最軽量優先の解決順・frontmatter 比較 |
| skill frontmatter + 公式 skill | `best-practice/claude-skills.md` | skill の 20 フィールド (`background` と Agent Skills spec の `metadata`/`license`/`compatibility` 含む) とバンドルスキル 15 個 (`doctor` は `disableBundledSkills` の唯一の例外。row 14 `review` と row 15 `security-review` はどちらも bundled と数えるかが未決着で公式は 13 個。両者は command 表にも重複) |
| subagent frontmatter + 公式 agent | `best-practice/claude-subagents.md` | subagent の 16 フィールドと built-in agent type 5 個 (公式は `claude` を含む 6 個。`Explore` の model 欄・`model` 例の model 名も未反映の watch item) |
| command frontmatter + 公式コマンド | `best-practice/claude-commands.md` | command の 20 フィールド (skill と同じ 3 フィールドが追加) と built-in slash command 89 個 (`/advisor` は v2.1.232 から `fable` を受ける (Fable 5 アクセス必須)、`/doctor` は bundled skill 側へ移動、`/review`・`/security-review` は両表に併記) |
| settings.json 網羅リファレンス | `best-practice/claude-settings.md` | 階層・permissions 構文・hooks・sandbox・model/effort・env vars・完全例 (1400 行、「127+ settings / 311 env vars」。2026-08-07 / v2.1.224 で更新停止 — 過去に 2026-07-31・08-02・08-07 と大きな drift 修正が続きキー名・permission 挙動・スコープ制限が毎回増減した経緯があるので、v2.1.225 以降の変更は反映されていない前提で読む) |
| CLAUDE.md の書き方・ロード規則 | `best-practice/claude-memory.md` | ancestor/descendant/sibling のロード挙動、モノレポでの配置指針 (2026-03 で更新停止) |
| MCP 設定と選定 | `best-practice/claude-mcp.md` | 日常用 MCP 5 選、.mcp.json 例、承認 settings、権限構文、3 スコープ (2026-03 で更新停止) |
| CLI フラグ・環境変数 | `best-practice/claude-cli-startup-flags.md` | `claude` の起動フラグ・サブコマンド・env vars の分類表 (2026-06 で更新停止) |
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
  キー名や構文を確定させるときは `best-practice/claude-settings.md` を直接引く。キー名の誤りは silent
  no-op になるため (`maxSkillDescriptionChars` の例) 記憶で書かない。原典は公式 docs で裏が取れないキー・
  構文に `*(not in official ... — unverified)*` を inline 注記するので、この注記付きの値
  (`thinkingBudgetTokens`・`Skill(...)`・`MCP(server:tool)` 等) は設計の前提にしない。
- **公式 slash command・CLI フラグ・env vars の全リスト** — `best-practice/claude-commands.md` と
  `best-practice/claude-cli-startup-flags.md` を引く。
- **tips 全文** — カテゴリ (Prompting/Planning/Context/Session/CLAUDE.md/Agents/Commands/Skills/Hooks/
  Workflows/Git/Debugging) 別の一覧は `README.md` の TIPS AND TRICKS 節。各 tip に一次ソースリンク付き。
- **★ 数とバッジ日付そのもの** — 原典は日次 scheduled refresh で全レポートの Last Updated バッジと
  README の ★ 数を書き換える。追いかけても腐るだけなので蒸留版は数値を持たない。バッジは「その表が
  まだ追われているか」の指標としてのみ使う (項目 12)。追跡対象バージョンは 2026-08-20 時点で v2.1.237。
- **コミュニティワークフローの詳細比較・skill/agent コレクション集** — `README.md` の
  DEVELOPMENT WORKFLOWS / SKILL COLLECTIONS / AGENT COLLECTIONS 表。★ 数だけでなく**ステップ列そのものも
  書き換わる**ため、蒸留版はこれらの数値もステップ列も持たない。逆に、上流 README と食い違う個数を
  「directory-count baseline」として意図的に据え置く運用もあり (OpenSpec の skills は 12〜13 個の確認が
  16 run 以上続いても表は 0、GSD の agents も 0)、表の個数は上流の実態と一致しない。数日で往復する項目
  (ECC の agents 67/68/96/100、BMAD の skills 25〜49) は 2 回連続確認まで採用されない。
- **Claude API 寄りの詳細** (Programmatic Tool Calling、SDK 設定、rate limits の数値) —
  `reports/claude-advanced-tool-use.md`, `claude-agent-sdk-vs-cli-system-prompts.md`,
  `claude-usage-and-rate-limits.md`。
- **hooks の実装詳細** — 別リポジトリ (shanraisshan/claude-code-hooks) が正。実働サンプルは `.claude/hooks/`。
- **プレゼン資料・チュートリアル本文と CLI バイナリ抽出物** — `presentation/`, `tutorial/`,
  `reports/claude-spinner-verbs-and-tips.md` (spinner 単語と CLI 内蔵 tips の抽出リスト)。
- 注意: 特定バージョン (v2.1.x) や beta 機能に固定された記述が多い。beta バッジは GA 化で外れる
  (Auto Mode は 2026-07-28 に公式 docs 確認のうえ削除) ため、バージョン依存・beta 前提の断定は避け、
  バッジと `changelog/` 配下の drift check ログで確認する。Voice Dictation・Artifacts の beta バッジは
  1 か月以上 ON HOLD のまま残っている (confidence が自動適用閾値 0.7 未満で据え置き)。
- 注意: 原典が張る公式 docs の URL も動く。2026-07-30 に README の CONCEPTS 表の Commands 行は
  `docs/en/slash-commands` から `docs/en/commands` へ修正されたが、同じ README の TIPS 表で commands /
  slash commands / command を指す 3 リンクは `docs/en/skills` を指したままで、1 ファイル内に 2 つの宛先が
  並存している。docs URL は原典のリンクを写さず、公式 docs 側で当たり先を確認する。**機能名も同様** —
  README の "No Flicker Mode" は公式 docs の "Fullscreen rendering" と一致せず 2026-08-11 の検出から
  2026-08-20 時点も ON HOLD (コミュニティ呼称が優勢で判断保留)。機能名は公式 docs 側の表記で引き直す。
