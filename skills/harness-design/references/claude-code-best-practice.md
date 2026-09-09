---
source: https://github.com/shanraisshan/claude-code-best-practice
distilled_commit: 674d11de1a9b4f8408fdf351629f9ff367c9032b
distilled_at: 2026-09-09
---

# claude-code-best-practice 蒸留版

Claude Code の実践知を集めたリポジトリ (shanraisshan) の蒸留。原典 clone のルートは SKILL.md 参照。以下のパスはすべてリポジトリルートからの相対パス。

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
   可視性は `skillOverrides` で `on` / `name-only` / `user-invocable-only` / `off` を skill 単位に指定できるが、
   **managed の `skillOverrides` エントリを持つ skill・plugin skill・`disable-model-invocation: true` の skill は
   `/skills` 画面から切り替えられない**。バジェットの実測には `/skill-doctor` を使う — ロード済み skill の
   うち使われていないものと各 skill の context コストを出して剪定を助ける (**v2.1.252 以降 + feature-flag
   fetching が必要**。ただし 09-07 に bundled skill 表へ row 18 として追加された際の説明は
   「Introduced v2.1.261」で command 表の「Requires v2.1.252 or later」と**原典内で食い違う**。公式 docs で確認する。
   `/skills` 画面の `t` キーでも token 数順に並べ替えられる。なお `reports/claude-skills-for-larger-mono-repos.md` の
   「既定 15,000 文字」「`SLASH_COMMAND_TOOL_CHAR_BUDGET` で拡大」は settings レポート (同 env var は slash
   command tool 出力用) と食い違う。数値とキー名は settings レポートを正とする。
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
   `permissions.defaultMode` の `"auto"` (v2.1.142+、`~/.claude/settings.json` に書く)、`processWrapper`
   (managed/user/`--settings` のみ、v2.1.210)、`footerLinksRegexes`、`pluginConfigs` (v2.1.207 以降
   project/local を読まない)、`sshConfigs` (managed/user)、`strictPluginOnlyCustomization`・
   `disableCommandPluginSources` (managed のみ)、sandbox の緩和系 (`sandbox.filesystem.disabled`・
   `sandbox.network.strictAllowlist`/`tlsTerminate`・`sandbox.credentials` の `mask`)。
   **非対称**なのが要点で、逆に制限を強める値は下位スコープからも効く — `disableClaudeAiConnectors: true` は
   managed の `false` に対しても任意スコープから、`remoteControlAtStartup: false` は project/local からでも
   managed の `true` を上書きできる。`crossSessionInbound` (`accept` < `hold` < `refuse`) も同じ型で、
   より厳しい値なら project/local が managed に勝つ。配列のマージ例外は 2026-09-01 の更新で 4 キーに増えた
   — `fallbackModel` / `availableModels` / `modelPicker` / `modelSettings` はマージされず、定義した最上位の
   ファイルが値全体を供給する (`fallbackModel` は重複除去後 4 件目以降を無視、`availableModels` は managed が
   定義したら下位から拡張できない)。
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
   `Cd(path)` は allow を 1 本でも書いた時点で `/cd` が allowlist モードになり、ワイルドカードも Read/Edit と違う
   (`*` は 1 セグメントのみ、`**` は跨ぐ、gitignore 形式ではない)。`Skill(weather *)` と `MCP(server:tool)` 短縮形は
   2026-08-02 に「公式 docs に無い = 未検証」と注記された。確実なのは `mcp__server__tool` 形式のみで、`Task(agent-name)` は `Agent` の legacy alias。
   → `best-practice/claude-settings.md` の Permissions 節

9. **ハーネス側のハード上限を前提に設計する**。並列 subagent は `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`
   (既定 `20`) で制限され超過分は queue へ。ネストは `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (v2.1.219 時点の
   既定 `3`) まで。Stop hook のブロックは `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (既定 `8`) 回で打ち切られ以降は
   exit code に関係なくセッションが終了する — 無限にブロックする Stop hook は設計できない。
   `effortLevel` に `"max"` / `"ultracode"` は書けない (session 限定で `/effort` からのみ)。永続化できるのは
   `low` / `medium` / `high` / `xhigh` だが、**v2.1.243 以降 `/effort` はモデル別に `modelSettings` へ保存する**
   ようになり、トップレベルの `effortLevel` はエントリが無いモデルの fallback になった。モデルごとに既定を
   変えたいなら `modelSettings: {"opus": {"effortLevel": "xhigh"}, ...}` を書く。
   → `best-practice/claude-settings.md`

10. **subagent はコンテキスト管理の道具**。判断基準は「このツール出力を後で使うか、結論だけでよいか」—
    結論だけなら subagent に出す (探索の 20 file reads も dead end も子側に残る)。別コンテキストの
    同一モデルが自分の書いたバグを見つける (test time compute)。~40% 消費で劣化 ("dumb zone") が始まるので
    /clear・/compact・/rewind で刻む。自動 compact の発火点は `autoCompactWindow` (100,000〜1,000,000 tokens、
    未設定ならモデル別) で `/autocompact` / `--autocompact` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` から設定
    (v2.1.221+)。走っている subagent / 別セッションへの働きかけは cross-session messaging (`SendMessage`・
    `ListAgents`・`/list-agents` (alias `/peers`)、v2.1.224 で GA。v2.1.239 で agent-team のチームメイトと
    自セッション名の行も出るよう反転)。subagent のモデル指定は **v2.1.238 が breaking change** で、
    `CLAUDE_CODE_SUBAGENT_MODEL` は override から**既定値**に変わった — agent 定義の `model:` と呼び出し時の
    明示指定が env var に優先する。`teammateDefaultModel` は v2.1.251 で削除され、teammate はリードのモデルを継承する。
    **タスク管理を todo ツールに寄せる設計は避ける** — v2.1.233 で新しいモデルでは task/todo ツールが
    deprecated になり、既定は `TaskCreate`/`TaskUpdate`/`TaskGet`、旧 `TodoWrite`/`TodoRead`/`TodoDone` は
    `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` での opt-in になった。
    → README「Context」「Agents」tips、`tips/claude-thariq-tips-16-apr-26.md`

11. **Agent memory は CLAUDE.md と補完関係**。`memory:` frontmatter (user/project/local) で agent 専用の
    永続知識を持てる。MEMORY.md の先頭 200 行が system prompt に注入され、超過分は topic 別ファイルへ。
    CLAUDE.md (人が書く・全員が読む) / auto-memory (Claude が書く・本人のみ) / agent memory (agent が
    書く・その agent のみ) の 3 系統。 → `reports/claude-agent-memory.md`

12. **frontmatter の正確なリファレンスは best-practice/ にあるが、そのまま信じない**。skills 20・
    commands 20・subagents 16 フィールドの型・意味の表と、公式ビルトイン一覧 (bundled skills 18、
    slash commands 93、agent types 5) がある。設計時は記憶で書かずここを引く。ただし**日次 drift check が動かす
    のはバッジ行と `changelog/` 追記が中心で、表本体は ON HOLD で据え置かれる項目が多い**。09-08 時点:
    - bundled skills は 09-01 に `design` (v2.1.234。artboard をキャンバスに並べた UI モック等を artifact
      として公開。Anthropic API のみ) が row 11 に入って 16 → 17、09-07 に `skill-doctor` が row 18 に入って
      17 → 18。後者は **09-05 に「built-in command であって bundled skill ではない」と INVALID 判定された項目の
      反転**で、commands reference 側に `[Skill]` マーカーがあることを根拠に採用された — **1 run の INVALID を
      確定と見なさない**実例。row 15 `review` (v2.1.223 で `/code-review` の alias になったのに説明が旧挙動のまま)
      と row 16 `security-review` は削除候補のまま 07-30 から ON HOLD。**公式が数える bundled skill は 15 で
      この 2 つを含まない** (09-08 の run では公式ページの truncation で 3 件が検証不能となり「取得できなかった
      ことは削除の証拠ではない」と明記された)。**`review` という名前の自作 skill は `/review` から起動できない**
      (公式 docs の "typing the bundled alias `/review` never runs your skill")。
    - subagents 表 — 5 個 (`general-purpose`, `Explore`, `Plan`, `statusline-setup`, `claude-code-guide`)
      のまま。`claude` (model 継承・全ツール、dispatch された background セッションの既定) は 08-07 から
      ON HOLD。`fork` は 08-20 以降 INVALID / 再オープン / ON HOLD を往復した末 08-31 に drift 表から消え、
      09 月の run にも復活していない。**1 run の判定を確定と見なさない**。frontmatter 側は `experimental`
      (object、任意。`cacheTtl` に `5m` / `1h` を置き prompt cache の寿命を指定。subagent ファイルからのみ
      読まれる。v2.1.248 導入) が 08-29 から ON HOLD で未反映 — **未確定扱いで使う**。公式とずれる watch item:
      `permissionMode` に公式の `manual` (`default` の alias、v2.1.200+) が無く、`Explore` の model は `haiku`
      (公式は「親から継承」、Claude API では Opus 上限)、`model` 例は `claude-opus-4-6` のままで `claude-opus-5`
      にも `fable` にも追いつかず、`prompt` は公式の `--agents` CLI JSON 側にしか無い。
    - subagents 表のバッジは 09-08 に v2.1.261 → v2.1.263 へ進んだが、上記 2 件の ON HOLD と 4 件の
      watch item は 1 つも解消していない — **バッジの更新は表本体が直ったことを意味しない**。
    - `claude-settings.md` は 09-01 に v2.1.252 へ追いついた。一方 `claude-memory.md` (2026-03)・
      `claude-mcp.md` (2026-03)・`claude-cli-startup-flags.md` (2026-06) は数か月動いていない。
    → `best-practice/claude-skills.md`, `claude-commands.md`, `claude-subagents.md`, `claude-settings.md`

13. **MCP は少数精鋭**。「15 個入れて日常使いは 4 個」が典型。secrets は `${VAR}` 展開で環境変数に。権限は
    `mcp__<server>__<tool>` 構文。スコープは Subagent (`mcpServers:`) > Project (`.mcp.json`) > User。 → `best-practice/claude-mcp.md`

14. **主要ワークフローは Research → Plan → Execute → Review → Ship に収斂**。README の比較表に
    agents/commands/skills の構成数と各ステップ (黄タグ = 親ステップ内で反復するサブループ) がある。★ 数も
    ステップ列も日次更新されるので都度引く。 → README「DEVELOPMENT WORKFLOWS」、`development-workflows/rpi/rpi-workflow.md`

15. **fork 実行と background セッションの境界**。skill/command は `context: fork` で隔離コンテキストに逃がし、
    `agent:` で subagent type を指定 (既定 `general-purpose`)、`background` (boolean、既定 `true`、v2.1.218+) を
    `false` にすると呼び出したターン内で結果を待つ。この 3 つは skill と command のみで subagent 側には無い。
    ユーザー側の入口は `/subtask` (親の会話を継承する forked subagent を background で回す。**v2.1.212+ が必要で
    agent view を切っていると使えない**)。制約として、**走っている background セッションは `/resume` のピッカーから再開できない** (`claude agents` で attach するか先に停止する)、`/insights` はローカルセッションのみ HTML 化し cloud 不可、`/tasks` (alias `/bashes`) が見せるのは**現セッションの** background work (終了済み subagent を含む)。`/add-dir` は v2.1.234 からターン中に即確認を求め (以前はターン終了までキュー)、成功時に `DirectoryAdded` hook が走る — 追加ディレクトリの `.claude/` 設定はほぼ読まれないので、必要な副作用はこの hook 側で組む。
    → `best-practice/claude-skills.md`, `claude-commands.md` の Frontmatter Fields 表と各コマンド行

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 全体目次・機能→docs 対応表 | `README.md` | CONCEPTS 表 (機能ごとの docs/実装リンク)、Hot features、tips 集、ワークフロー比較、購読先 |
| agents/commands/skills の使い分け | `reports/claude-agent-command-skill.md` | 3 機構の比較表・使い分け基準・最軽量優先の解決順・frontmatter 比較 |
| skill frontmatter + 公式 skill | `best-practice/claude-skills.md` | skill の 20 フィールド (`background` と Agent Skills spec の `metadata`/`license`/`compatibility` 含む) とバンドルスキル 18 個 (`doctor` は `disableBundledSkills` の唯一の例外。row 11 `design` は v2.1.234 追加で 09-01 に反映。row 17 `workflow-authoring` は v2.1.248 追加・dynamic workflows 有効時のみ。row 18 `skill-doctor` は 09-07 追加で 09-05 の INVALID 判定を反転させたもの。row 15 `review` と row 16 `security-review` は削除候補で ON HOLD、公式の数え方では 15 個。両者は command 表にも重複) |
| subagent frontmatter + 公式 agent | `best-practice/claude-subagents.md` | subagent の 16 フィールドと built-in agent type 5 個 (`experimental` フィールド・`claude` agent は ON HOLD で表に未反映、`fork` は 08-31 以降 drift 表から消えたまま。`Explore` の model 欄・`model` 例の model 名・`permissionMode` の `manual` も未反映の watch item) |
| command frontmatter + 公式コマンド | `best-practice/claude-commands.md` | command の 20 フィールド (skill と同じ 3 フィールドが追加) と built-in slash command 93 個 (09-05 に `/skill-doctor` が Extensions タグの #50 として追加され 92 → 93、以降の行が繰り下がった)。09 月の drift で説明が変わった行: `/review` は引数が `/code-review` と同じ完全形 (`[low\|…\|ultra] [--fix] [--comment] [pr#\|branch\|path]`) になり、レベル省略時は**前回入力したレベルを再利用**する。`/ultrareview` は PR 参照で対象 PR、ブランチ名で比較基準を変える。`/desktop` は macOS または x64 Windows + Claude サブスクリプションが要る。`/usage-credits` から `DISABLE_EXTRA_USAGE_COMMAND=1` の記述が消えた (公式 docs 側から削除)。`/radio` の Bedrock/Vertex/Foundry 制限は v2.1.251 で解除。`/scroll-speed` は fullscreen rendering 限定で JetBrains ターミナル不可。`/diff` は 09-05 に公式 docs 準拠の "Review the changes in your working tree, including the edits Claude has made so far" に更新され ON HOLD が解消。一方 `/advisor` のテキスト形式・`/cost` の cache miss 表示・`/reload-plugins` の headless 対応・`/effort` の既定保存と `s` キーは公式 docs 表に無く changelog のみで ON HOLD 継続 |
| settings.json 網羅リファレンス | `best-practice/claude-settings.md` | 階層・permissions 構文・hooks・sandbox・model/effort・env vars・完全例 (「140+ settings / 315+ env vars」、2026-09-01 に v2.1.224 → v2.1.252 へ追いついた)。この run で入った主なキー: `crossSessionInbound`・`dialogExpiry`・`autoContinueAtUsageLimit`・`feedbackDrafts` (`SendFeedback` ツールの gate)・`desktopSessionCleanupPeriodDays`・`modelSettings`・`modelPicker`・`modelPricing` (managed)・`promptCacheTtl`/`subagentPromptCacheTtl`・`keybindingFlavor`・`spellcheck`・`disableCommandPluginSources`・marketplace source type `command` (+`mode: "link"`)・sandbox credentials の JWT/AWS マスキング (`decode: "jwt"`・`maskClaims`・`awsPairs`・`sigv4`)。公式側の**キー索引は `docs/en/settings-reference` に移動**し (`docs/en/settings` は task 指向のガイドに再編)、原典もこちらを Sources に追加した |
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

- **settings.json の全キーと permissions 構文の詳細** — 1400 行超の網羅表は写していない。キー名や構文を
  確定させるときは `best-practice/claude-settings.md` を直接引く。キー名の誤りは silent no-op になるため
  (`maxSkillDescriptionChars` の例) 記憶で書かない。原典が
  `*(not in official ... — unverified)*` と注記した値 (`thinkingBudgetTokens`・`Skill(...)`・`MCP(server:tool)`) は前提にしない。
- **公式 slash command・CLI フラグ・env vars の全リスト** — `best-practice/claude-commands.md` と
  `best-practice/claude-cli-startup-flags.md` を引く。
- **tips 全文** — カテゴリ別一覧は `README.md` の TIPS AND TRICKS 節。各 tip に一次ソースリンク付き。
- **★ 数とバッジ日付そのもの** — 日次 scheduled refresh でバッジと ★ 数が書き換わる。蒸留版は数値を持たない。
  バッジは「その表がまだ追われているか」の指標としてのみ使う (項目 12)。追跡対象は 2026-09-08 時点で skills / commands / subagents / README CONCEPTS が
  いずれも v2.1.263 (バッジ日付は 09-08)、settings が v2.1.252 (09-01)。
- **コミュニティワークフローの詳細比較・skill/agent コレクション集** — `README.md` の
  DEVELOPMENT WORKFLOWS / SKILL COLLECTIONS / AGENT COLLECTIONS 表。★ 数だけでなく**ステップ列も行の並び順も
  日次で書き換わる** (09-02 の Spec Kit は手順列が差し替わった) ため蒸留版は数値もステップ列も持たない。
  09-05 の run は 8 リポジトリ分のステップ列変更を検出しつつ**全件 ON HOLD** で据え置き、agent/command/skill の
  個数も run ごとに揺れる (ECC commands は 94/97/129/131/137/150、ECC agents は 68/92/98/106、gstack skills は
  53/58/48/65 と振れる)。採用の閾値は **2 run 連続で同じ値が出ること**で、09-07〜09-08 に BMAD skills
  50 → 29、oh-my-claudecode skills 35 → 37、OpenSpec workflow の 5 → 4 ステップ (`/opsx:verify` を落とす)
  が 2nd confirmation で確定した。逆に 1 run だけの値 (ECC agents 92 等) は毎回 DENY されている。
  **表の数値はスナップショットであって定説ではない**ので、他所へ引用しない。
- **Claude API 寄りの詳細** (Programmatic Tool Calling、SDK 設定、rate limits の数値) —
  `reports/claude-advanced-tool-use.md`, `claude-agent-sdk-vs-cli-system-prompts.md`, `claude-usage-and-rate-limits.md`。
- **hooks の実装詳細** — 別リポジトリ (shanraisshan/claude-code-hooks) が正。v2.1.252 で
  `PreModelSwitch` / `PostModelSwitch` が加わり全 28 イベント。実働サンプルは `.claude/hooks/`。
- **プレゼン資料・チュートリアル本文と CLI バイナリ抽出物** — `presentation/`, `tutorial/`, `reports/claude-spinner-verbs-and-tips.md`。
- 注意: 特定バージョン (v2.1.x) や beta 機能に固定された記述が多い。beta バッジは GA 化で外れる
  (Auto Mode は 2026-07-28、Voice Dictation と Artifacts は 2026-08-29 に削除) ため、バージョン依存・
  beta 前提の断定は避けバッジと `changelog/` の drift ログで確認する。**ON HOLD も INVALID も「保留」であって
  「否定」ではない** — 後日反転しうる (settings の JWT masking は 09-01 に、`skill-doctor` は 09-05 の INVALID を
  09-07 に反転して確定した)。ただし反転していない INVALID を取り込み候補に昇格させない。
- 注意: 原典が張る公式 docs の URL も動く。CONCEPTS 表の Commands 行は `docs/en/commands` を指すのに TIPS 表の
  commands / slash commands 3 リンクは `docs/en/skills` のまま (09-08 も ON HOLD)。URL は原典のリンクを写さず
  公式 docs で確認する。**機能名も同様** — README の "No Flicker Mode" は公式の "Fullscreen rendering" と
  一致せず 08-11 から ON HOLD。
