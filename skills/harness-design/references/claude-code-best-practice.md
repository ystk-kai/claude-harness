---
source: https://github.com/shanraisshan/claude-code-best-practice
distilled_commit: 035cd8bafc8eccac08a74cdda82924660c36266e
distilled_at: 2026-09-26
---

# claude-code-best-practice 蒸留版

Claude Code の実践知を集めたリポジトリ (shanraisshan) の蒸留。原典 clone のルートは SKILL.md 参照。以下のパスはすべてリポジトリルートからの相対パス。

## Contents

- [まず押さえる](#まず押さえる)
- [索引](#索引)
- [蒸留の範囲外](#蒸留の範囲外)

## まず押さえる

1. **最も軽い機構を選ぶ**。同じ意図に複数機構がマッチしたとき Claude は最軽量を優先する: skill (inline、
   コンテキストオーバーヘッドなし) > agent (別コンテキスト) > command (自動発火せず `/` 明示起動のみ)。
   Agent: 自律的・複数ステップ、コンテキスト分離、永続メモリ (`memory:`)、skill の preload (`skills:`)、
   ツール制限や permission mode の変更が要るとき。Command: ユーザー起点の入口、他の agent/skill を
   オーケストレーションするとき (内容は起動まで context に載らない)。Skill: 意図ベースで自動発火させたい
   再利用手順。同じタスクを 3 機構で実装した worked example あり。
   → `reports/claude-agent-command-skill.md` (特に "When to Use Each")

2. **Command → Agent → Skill の層状オーケストレーション**。command が入口、agent が別コンテキストで
   自律実行 (preloaded skill 持ち)、skill が inline で出力生成。weather システムとして完動する実装例あり。 →
   `orchestration-workflow/orchestration-workflow.md` (実体は `.claude/commands|agents|skills/`)

3. **ハーネスはプロンプトの言い換えではない**。「全部プロンプトになるから強いプロンプトで代替可能」という還元論は、
   context isolation・harness 強制のツール制限・hooks の決定的実行・model routing・並列・セッション横断永続化など
   10 の能力の前で崩れる。決定論が要る挙動 (attribution、権限、フォーマット) は hooks/settings で強制する。
   → `reports/why-harness-is-important.md`

4. **CLAUDE.md は 1 ファイル 200 行以下を目標** (humanlayer は 60 行)。「どの開発者が起動して
   "run the tests" と言っても一発で動く」が品質基準。settings.json で決定的に強制できるもの
   (`attribution.commit` 等) を CLAUDE.md に書かない。長くなったら `.claude/rules/*.md` に分割し、
   `paths:` frontmatter で対象ファイルに触れたときだけ lazy-load させる。ロード規則はモノレポ設計に直結する:
   ancestor は起動時に全ロード、descendant はそのディレクトリのファイルに触れたとき lazy-load、sibling は
   決してロードされない。root に共通規約、コンポーネント配下に固有規約。個人用は CLAUDE.local.md。
   subagent 単位で CLAUDE.md を切る手段が `omitClaudeMd: true` (boolean、任意、v2.1.271) — user/project/local の
   CLAUDE.md を読まずに起動し managed policy file だけは読む。`--agent` や `agent` 設定で**メインセッションとして
   走る場合は無視**。原典の subagents 表には 09-25 も未反映 (ON HOLD、項目 12)。`AGENTS.md` は v2.1.277 から
   公式サポート (公式 overview の引用: "Claude Code can read that on its own or alongside CLAUDE.md") だが、README の
   Memory 行 Location には未記載で 09-23 から ON HOLD。 → README.md「CLAUDE.md + .claude/rules」tips、
   `best-practice/claude-memory.md`、`changelog/best-practice/claude-subagents/changelog.md`、`concepts/changelog.md` (09-23)

5. **Skills のロードは CLAUDE.md と別物**。ancestor loading はなく、description だけが常駐。full content は
   呼び出し時のみロード。ネストされた `packages/*/.claude/skills/` はそのディレクトリで作業したときに自動発見
   される。例外: subagent の `skills:` preload は full content を起動時注入。バジェットの正は settings 側の
   2 キー — `skillListingBudgetFraction` (既定 `0.01` = context window の 1%。超過すると使用頻度の低い skill の
   description が名前だけに collapse され、呼べるが理由が見えなくなる) と `skillListingMaxDescChars`
   (既定 `1536`、1 skill の `description` + `when_to_use` 合算上限、超過分は truncate)。後者は
   2026-07-31 まで原典が `maxSkillDescriptionChars` と誤記していた無効キー (silent no-op) なので注意。
   可視性は `skillOverrides` で `on` / `name-only` / `user-invocable-only` / `off` を skill 単位に指定できるが、
   **managed の `skillOverrides` エントリを持つ skill・plugin skill・`disable-model-invocation: true` の skill は
   `/skills` 画面から切り替えられない**。バジェットの実測には `/skill-doctor` (未使用 skill と各 skill の
   context コストを出す。**v2.1.252 以降 + feature-flag fetching が必要**。skills 表 row 18 の
   「Introduced v2.1.261」と**原典内で食い違う**)。`/skills` 画面の `t` キーで token 数順にも並ぶ。なお
   `reports/claude-skills-for-larger-mono-repos.md` の「既定 15,000 文字」「`SLASH_COMMAND_TOOL_CHAR_BUDGET` で
   拡大」は settings レポート (同 env var は slash command tool 出力用) と食い違う。後者を正とする。
   → `reports/claude-skills-for-larger-mono-repos.md`, `best-practice/claude-settings.md`

6. **Skill の書き方 (Anthropic 内部の教訓)**。description は要約でなくトリガーとして書く ("when should I
   fire?")。明白なことは書かず、デフォルト挙動から押し出す差分だけ書く。手順を railroad せず goal と制約を
   与える。Gotchas セクションが最高シグナル (Claude の失敗点を追記していく)。scripts/references/examples を
   同梱しフォルダとして設計。危険な skill は `disable-model-invocation: true` で明示起動のみに。良い skill は
   9 類型 (Library & API Reference / Product Verification / Data Fetching & Analysis / Code Scaffolding ほか) の 1 つに収まる。
   → `tips/claude-thariq-tips-17-mar-26.md`

7. **スコープ設計原則**。個人状態・プロジェクト横断調整 (tasks, teams, auto-memory, credentials,
   keybindings) は global (`~/.claude/`) のみ。チーム共有可能な設定 (settings, rules, agents, commands,
   skills, hooks) は dual-scope で project が優先。settings の優先順位: CLI flags >
   `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.local.json` >
   `~/.claude/settings.json`。`deny` ルールは最優先で上書き不可。**権限昇格につながる設定は
   project/local から無視される** — untrusted なリポジトリが自分に権限を与えられないようにするため:
   `permissions.defaultMode` の `"auto"` (v2.1.142+、`~/.claude/settings.json` に書く)、`processWrapper`
   (managed/user/`--settings` のみ、v2.1.210)、`footerLinksRegexes`、`pluginConfigs` (v2.1.207+)、
   `sshConfigs` (managed/user)、`strictPluginOnlyCustomization`・`disableCommandPluginSources` (managed のみ)、
   sandbox の緩和系 (`sandbox.filesystem.disabled`・`sandbox.network.strictAllowlist`/`tlsTerminate`・
   `sandbox.credentials` の `mask`)。
   **非対称**なのが要点で、逆に制限を強める値は下位スコープからも効く — `disableClaudeAiConnectors: true` は
   managed の `false` に対しても任意スコープから、`remoteControlAtStartup: false` は project/local からでも
   managed の `true` を上書きできる。`crossSessionInbound` (`accept` < `hold` < `refuse`) も同じ型で、
   より厳しい値なら project/local が managed に勝つ。配列のマージ例外は 2026-09-01 の更新で 4 キーに増えた
   — `fallbackModel` / `availableModels` / `modelPicker` / `modelSettings` はマージされず、定義した最上位の
   ファイルが値全体を供給する (`fallbackModel` は重複除去後 4 件目以降を無視、`availableModels` は managed が
   定義したら下位から拡張できない)。
   → `reports/claude-global-vs-project-settings.md`, `best-practice/claude-settings.md`

8. **permissions 構文には落とし穴がある**。`Tool(param:value)` (`Agent(model:opus)`, `Agent(isolation:worktree)`,
   `Bash(run_in_background:true)`) は **deny / ask 専用**で allow では使えない (allow は各ツール固有の specifier 構文)。
   主コンテンツ欄へのマッチ (`Bash(command:rm *)`) も禁止で起動時 warning。`Write(path)` / `NotebookEdit(path)` /
   `Glob(path)` は allow に書くと parse は通るが**一切参照されない** — allow 評価は `Edit(path)` と `Read(path)` しか
   見ない (v2.1.210)。実質 no-op なので書き込み許可は `Edit` 側で表現する (deny / ask では機能する)。`:*` サフィックスは
   末尾でしか解釈されない (`Bash(git:* push)` はコロンをリテラル扱い)。allow のツール名 glob は **`mcp__<server>__` という
   リテラル前置がある場合しか受理されない** — `"*"` / `"B*"` / `"mcp__*"` は warning 付きで skip され何も自動承認しない。
   全体を allowlist 化するなら `deny: ["*"]` + 個別 allow。
   `Cd(path)` は allow を 1 本でも書くと `/cd` が allowlist モードになり、ワイルドカードも Read/Edit と違う
   (`*` は 1 セグメントのみ、`**` は跨ぐ、gitignore 形式ではない)。`Skill(weather *)` と `MCP(server:tool)` 短縮形は
   2026-08-02 に「公式 docs に無い = 未検証」と注記済み。確実なのは `mcp__server__tool` のみ、`Task(agent-name)` は
   `Agent` の legacy alias。 → `best-practice/claude-settings.md` の Permissions 節

9. **ハーネス側のハード上限を前提に設計する**。並列 subagent は `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`
   (既定 `20`) で制限され超過分は queue へ。ネストは `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (v2.1.219 時点の
   既定 `3`) まで。Stop hook のブロックは `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (既定 `8`) 回で打ち切られ以降は
   exit code に関係なくセッションが終了する — 無限にブロックする Stop hook は設計できない。
   `effortLevel` に `"max"` / `"ultracode"` は書けない (session 限定で `/effort` からのみ)。永続化できるのは
   `low` / `medium` / `high` / `xhigh` だが、**v2.1.243 以降 `/effort` はモデル別に `modelSettings` へ保存する**
   ようになり、トップレベルの `effortLevel` はエントリが無いモデルの fallback になった
   (`modelSettings: {"opus": {"effortLevel": "xhigh"}, ...}`)。 → `best-practice/claude-settings.md`

10. **subagent はコンテキスト管理の道具**。判断基準は「このツール出力を後で使うか、結論だけでよいか」— 結論だけなら
    subagent に出す (探索の 20 file reads も dead end も子側に残る)。別コンテキストの同一モデルが自分の書いたバグを
    見つける (test time compute)。~40% 消費で劣化 ("dumb zone") が始まるので /clear・/compact・/rewind で刻む。自動
    compact の発火点は `autoCompactWindow` (100,000〜1,000,000 tokens、未設定ならモデル別) で `/autocompact` /
    `--autocompact` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` から設定 (v2.1.221+)。走っている subagent / 別セッションへの働きかけは cross-session messaging (`SendMessage`・
    `ListAgents`・`/list-agents` (alias `/peers`)、v2.1.224 で GA。v2.1.239 で agent-team のチームメイトと
    自セッション名の行も出るよう反転)。subagent のモデル指定は **v2.1.238 が breaking change** で、
    `CLAUDE_CODE_SUBAGENT_MODEL` は override から**既定値**に変わった — agent 定義の `model:` と呼び出し時の
    明示指定が env var に優先する。`teammateDefaultModel` は v2.1.251 で削除され、teammate はリードのモデルを継承する。
    **タスク管理を todo ツールに寄せる設計は避ける** — v2.1.233 で新しいモデルでは task/todo ツールが
    deprecated になり、既定は `TaskCreate`/`TaskUpdate`/`TaskGet`、旧 `TodoWrite`/`TodoRead`/`TodoDone` は
    `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` での opt-in になった。
    → README「Context」「Agents」tips、`tips/claude-thariq-tips-16-apr-26.md`

11. **Agent memory は CLAUDE.md と補完関係**。`memory:` frontmatter (user/project/local) で agent 専用の永続知識を
    持てる。MEMORY.md の先頭 200 行が system prompt に注入され、超過分は topic 別ファイルへ。CLAUDE.md (人が書く・
    全員が読む) / auto-memory (Claude が書く・本人のみ) / agent memory (agent が書く・その agent のみ) の 3 系統。
    → `reports/claude-agent-memory.md`

12. **frontmatter の正確なリファレンスは best-practice/ にあるが、そのまま信じない**。skills 20・
    commands 20・subagents 16 フィールドの型・意味の表と、公式ビルトイン一覧 (bundled skills 19、
    slash commands 94、agent types 5) がある。設計時は記憶で書かずここを引く。ただし**日次 drift check が動かす
    のはバッジ行と `changelog/` 追記が中心で、表本体は ON HOLD で据え置かれる項目が多い**。09-25 時点:
    - bundled skills は 09-23 に row 19 `update-config` (settings.json を自然言語で編集。theme/model 等の単純な
      設定は `/config`) が入り 19。09-24 から `artifact-design` (v2.1.281 の CHANGELOG に "bundled" とあるが
      commands reference に無く model 起動のみらしい) が追加候補 ON HOLD。削除候補 3 件 — row 15 `review`
      (v2.1.223 で `/code-review` の alias、説明が旧挙動のまま)・row 16 `security-review` (公式は「Skill ツール経由で
      呼べる built-in command」)・row 18 `skill-doctor` (commands reference の `[Skill]` マークが run ごとに揺れる) —
      は判定が**反転を繰り返している**: 09-17 に後 2 者が INVALID → 09-18 に再 ON HOLD、09-20 に `review` が
      INVALID → 09-23 に再 ON HOLD。公式側の数え方も 15 / 16 / 17 と run ごとに違う。**1 run の INVALID を確定と
      見なさない**、bundled skill の個数は引用しない。**`review` という名前の自作 skill は `/review` から起動できない**
      (公式 docs の "typing the bundled alias `/review` never runs your skill")。
    - `allowed-tools` の型は commands 表が 09-16 に `string` → `string/list` へ訂正されたが、skills 表は `string` の
      ままで**原典内で食い違う** (`disallowed-tools` は両表とも `string/list`)。
    - subagents 表 — 5 個 (`general-purpose`, `Explore`, `Plan`, `statusline-setup`, `claude-code-guide`)
      のまま。`claude` (model 継承・全ツール、dispatch された background セッションの既定) は 08-07 から
      ON HOLD。`fork` は 08-20 以降 INVALID / 再オープン / ON HOLD を往復した末 08-31 に drift 表から消え、
      09 月の run にも復活していない。**1 run の判定を確定と見なさない**。frontmatter 側は `experimental`
      (object、任意。`cacheTtl` に `5m` / `1h` を置き prompt cache の寿命を指定。subagent ファイルからのみ
      読まれる。v2.1.248 導入) が 08-29 から ON HOLD で未反映 — **未確定扱いで使う**。09-15 に
      `omitClaudeMd` (boolean、任意、v2.1.271) が HIGH / NEW として追加提案されたがこれも ON HOLD で
      表は 16 フィールドのまま (項目 4 に内容)。公式とずれる watch item:
      `permissionMode` に公式の `manual` (`default` の alias、v2.1.200+) が無く、`Explore` の model は `haiku`
      (公式は「親から継承」、Claude API では Opus 上限)、`model` 例は `claude-opus-4-6` のまま、`prompt` は
      公式の `--agents` CLI JSON 側にしか無い。
    - バッジは 09-25 に v2.1.282 まで進んだが subagents 側の ON HOLD 3 件と watch item は 1 つも解消していない —
      **バッジの更新は表本体が直ったことを意味しない**。`model` 欄の watch item は 09-15 に拡張され、
      公式が `fable` エイリアスと `claude-opus-5` を例示しているのに原典は `claude-opus-4-6` のままと明記された。
    - **ON HOLD は解消されずに静かに消えることがある**。commands 側の `/cost` (cache miss 表示)・`/reload-plugins`
      (headless 対応)・`/effort` (既定保存と `s` キー) は 09-05 を最後に changelog から落ちたが公式 docs 表には
      入っておらず、以降の run は「fully in sync」と宣言。**「最新 run に出ていない = 解決した」ではない**。
    - `claude-settings.md` は 09-01 に v2.1.252 へ追いついたが、`claude-memory.md` (2026-03)・`claude-mcp.md` (2026-03)・
      `claude-cli-startup-flags.md` (2026-06) は数か月動いていない。
    → `best-practice/claude-skills.md`, `claude-commands.md`, `claude-subagents.md`, `claude-settings.md`

13. **MCP は少数精鋭**。「15 個入れて日常使いは 4 個」が典型。secrets は `${VAR}` 展開。権限は `mcp__<server>__<tool>` 構文。スコープは Subagent (`mcpServers:`) > Project (`.mcp.json`) > User。 → `best-practice/claude-mcp.md`

14. **主要ワークフローは Research → Plan → Execute → Review → Ship に収斂**。README の比較表に
    agents/commands/skills の構成数と各ステップ (黄タグ = 親ステップ内で反復するサブループ) がある。★ 数も
    ステップ列も日次更新されるので都度引く。 → README「DEVELOPMENT WORKFLOWS」、`development-workflows/rpi/`

15. **fork 実行と background セッションの境界**。skill/command は `context: fork` で隔離コンテキストに逃がし、
    `agent:` で subagent type を指定 (既定 `general-purpose`)、`background` (boolean、既定 `true`、v2.1.218+) を
    `false` にすると呼び出したターン内で結果を待つ。この 3 つは skill と command のみで subagent 側には無い。
    ユーザー側の入口は `/subtask` (親の会話を継承する forked subagent を background で回す。**v2.1.212+ が必要で
    agent view を切っていると使えない**)。制約: **走っている background セッションは `/resume` のピッカーから再開できない** (`claude agents` で attach するか先に停止)、`/insights` はローカルセッションのみ HTML 化、`/tasks` (alias `/bashes`) が見せるのは**現セッションの** background work。`/add-dir` は v2.1.234 からターン中に即確認を求め、成功時に `DirectoryAdded` hook が走る — 追加ディレクトリの `.claude/` 設定はほぼ読まれないので必要な副作用はこの hook で組む。
    → `best-practice/claude-skills.md`, `claude-commands.md` の Frontmatter Fields 表と各コマンド行

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| 全体目次・機能→docs 対応表 | `README.md` | CONCEPTS 表 (機能ごとの docs/実装リンク)、Hot features、tips 集、ワークフロー比較、購読先 |
| agents/commands/skills の使い分け | `reports/claude-agent-command-skill.md` | 3 機構の比較表・使い分け基準・最軽量優先の解決順・frontmatter 比較 |
| skill frontmatter + 公式 skill | `best-practice/claude-skills.md` | skill の 20 フィールド (`background` と Agent Skills spec の `metadata`/`license`/`compatibility` 含む。`allowed-tools` は `string` 表記のままで commands 表と食い違う) とバンドルスキル 19 個 (`doctor` は `disableBundledSkills` の唯一の例外。row 11 `design` は v2.1.234 追加。row 17 `workflow-authoring` は v2.1.248 追加・dynamic workflows 有効時のみ。row 19 `update-config` は 09-23 追加。row 15 `review`・row 16 `security-review`・row 18 `skill-doctor` は削除候補 ON HOLD で INVALID との間を往復中、`artifact-design` は追加候補 ON HOLD。`review` と `security-review` は command 表にも重複) |
| subagent frontmatter + 公式 agent | `best-practice/claude-subagents.md` | subagent の 16 フィールドと built-in agent type 5 個 (`experimental` と `omitClaudeMd` (v2.1.271) の 2 フィールド・`claude` agent は ON HOLD で表に未反映、`fork` は 08-31 以降 drift 表から消えたまま。`Explore` の model 欄・`model` 例の model 名 (公式は `claude-opus-5` / `fable`)・`permissionMode` の `manual` も未反映の watch item) |
| command frontmatter + 公式コマンド | `best-practice/claude-commands.md` | command の 20 フィールド (skill と同じ 3 フィールドが追加。`allowed-tools` は 09-16 に `string/list` へ訂正) と built-in slash command 94 個。#13 `/output-style [style]` (09-20 に引数表記を `[name]` から訂正、v2.1.269+) は **v2.1.74 で「deprecated、`/config` を使え」として削除された行の復活**で、削除済みコマンドも戻りうる実例。09-23 に v2.1.280 準拠で 10 行の説明が更新: `/clear` 前の会話は rewind メニューから復元可 (v2.1.191+)、`/model` と `/rename` は `-p` でも動く (v2.1.205+、`/model` は現セッションのみ)、`/rename` は制御文字除去と 200 文字上限 (v2.1.221+)、`/heapdump` はメニュー非表示で `.heapsnapshot` に会話と credentials が入るため共有は `-diagnostics.json` のみ、`/bug` はサードパーティ provider では `~/.claude/feedback-bundles/` にローカル保存、`/feedback` は引数なしで Claude が起草した feedback の下書きキュー、`/import` (`[codex\|gemini\|cursor]`) は Bedrock/Vertex/Foundry/gateway 等と feature-flag fetching 無効時に使えない。既存の記載: `/advisor` は `-p` と Remote Control で引数なしだと現在値をテキスト出力 (v2.1.260)。`/review` は `/code-review` の alias で引数も同形、レベル省略時は前回のレベルを再利用。`/skill-doctor` は v2.1.252 以降 + feature-flag fetching (skills 表 row 18 の「v2.1.261」と食い違う)。`/status` の "Auto mode server" 行 (v2.1.278) は公式 docs 未掲載で 09-19 から ON HOLD |
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
| 入門チュートリアル / 動画要約 | `tutorial/day0/`, `tutorial/day1/`, `videos/*.md` | 段階的入門と、Boris/Thariq/Cat/Dex/Karpathy らの講演・対談の書き起こしノート |
| このリポジトリ自身のハーネス | `.claude/` | agents/commands/skills/hooks/settings.json の実働サンプル (音声 hooks 含む) |
| 各レポートの drift 履歴 | `changelog/**/changelog.md` | 日次 drift check の指摘・ON HOLD・誤修正の revert 記録。表の値を疑うときここを見る |

## 蒸留の範囲外

- **settings.json の全キーと permissions 構文の詳細** — 1400 行超の網羅表は写していない。確定させるときは
  `best-practice/claude-settings.md` を直接引く。キー名の誤りは silent no-op (`maxSkillDescriptionChars` の例)。原典が
  `*(not in official ... — unverified)*` と注記した値 (`thinkingBudgetTokens`・`Skill(...)`・`MCP(server:tool)`) は前提にしない。
- **公式 slash command・CLI フラグ・env vars の全リスト** — `best-practice/claude-commands.md` と
  `best-practice/claude-cli-startup-flags.md` を引く。
- **tips 全文** — カテゴリ別一覧は `README.md` の TIPS AND TRICKS 節。各 tip に一次ソースリンク付き。
- **★ 数とバッジ日付** — 日次 refresh で書き換わる。蒸留版は数値を持たない。バッジは「その表がまだ追われているか」の
  指標としてのみ使う (項目 12)。2026-09-25 時点で skills / commands / subagents が v2.1.282、settings は v2.1.252
  (09-01) のまま 3 週間以上動いていない。
- **コミュニティワークフローの詳細比較・skill/agent コレクション集** — `README.md` の
  DEVELOPMENT WORKFLOWS / SKILL COLLECTIONS / AGENT COLLECTIONS 表。★ 数だけでなく**ステップ列も行の並び順も
  日次で書き換わる** (09-19 に Matt Pocock の workflow 先頭へ `setup-matt-pocock-skills` が追加) ため蒸留版は
  数値もステップ列も持たない。run ごとに各リポジトリで別系統のステップ列が提案され大半が「1 run 目」として ON HOLD、
  個数も揺れる (gstack skills は 53/48/65/53/32/53/58、BMAD agents は 0 と 5 を往復)。採用の閾値は **2 run 連続で
  同じ値**だが、**確定した値も翌週には変わる** — 表の数値はスナップショットであって定説ではないので他所へ引用しない。
- **Claude API 寄りの詳細** (Programmatic Tool Calling、SDK 設定、rate limits の数値) —
  `reports/claude-advanced-tool-use.md`, `claude-agent-sdk-vs-cli-system-prompts.md`, `claude-usage-and-rate-limits.md`。
- **hooks の実装詳細** — 別リポジトリ (shanraisshan/claude-code-hooks) が正。v2.1.252 で
  `PreModelSwitch` / `PostModelSwitch` が加わり全 28 イベント。実働サンプルは `.claude/hooks/`。
- **プレゼン資料・チュートリアル本文と CLI バイナリ抽出物** — `presentation/`, `tutorial/`, `reports/claude-spinner-verbs-and-tips.md`。
- 注意: 特定バージョン (v2.1.x) や beta 機能に固定された記述が多い。beta バッジは GA 化で外れる (Auto Mode 2026-07-28、
  Voice Dictation と Artifacts 2026-08-29) ため、バージョン依存・beta 前提の断定は避け `changelog/` の drift ログで確認する。
  **ON HOLD も INVALID も「保留」であって「否定」ではない** — 後日反転しうる (`skill-doctor` は 09-05 INVALID → 09-07 追加
  → 09-15 削除候補 → 09-17 INVALID → 09-18 再 ON HOLD、`/output-style` は v2.1.74 で削除された行が v2.1.269 で復活)。
  ただし反転していない INVALID を取り込み候補に昇格させない。逆に **1 run の提案も早まって取り込まない** — 09-10 の
  「`/review --comment` は GitLab MR にも投稿する」、09-19 の「`/plugin install --marketplace`」はどちらも後の run で INVALID。
- 注意: 原典が張る公式 docs の URL・anchor・機能名も動く。Rules の anchor は 09-18 に `#organize-rules-with-clauderules` →
  `#organize-rules-with-claude/rules/` へ変わり、Plugins 行の 3 URL は redirect 経由 (09-25 ON HOLD)、TIPS 表の commands
  3 リンクは `docs/en/skills` のまま。README の "No Flicker Mode" (公式は "Fullscreen rendering")・"Claude Code Web"
  (v2.1.281 で設定ラベルが "Cloud sessions") も未追従。URL は原典のリンクを写さず公式 docs で確認する。原典自身、09-15 の
  run で `claude-code-guide` agent が sitemap に無い URL を複数 fabricate したと記録している。
