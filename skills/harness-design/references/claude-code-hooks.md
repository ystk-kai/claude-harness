---
source: https://github.com/shanraisshan/claude-code-hooks
distilled_commit: 8beecc514a1cd4775ec2aff34b86488141a1c9dd
distilled_at: 2026-07-28
---

# claude-code-hooks 蒸留版

Claude Code の全 hook を音で鳴らすリポジトリ (shanraisshan) の蒸留。副産物として
**hook の実務リファレンスが 1 ファイル (`.claude/hooks/HOOKS-README.md`, 603 行) に集約**されており、
そこが本体。以下のパスはすべてリポジトリルートからの相対パス (原典ルートは SKILL.md 参照)。

**注意: 個人による二次情報。** 著者が公式 docs / changelog を追って手で書き写しているため、公式仕様との
食い違いや内部 drift が実在する (後述)。仕様を確定させるときは公式 docs を正とする。以下「原典の記載ベース」
と書いた箇所は、著者の記述をそのまま要約したもので、こちらで公式確認はしていない。

## Contents

- [まず押さえる](#まず押さえる)
- [hook カタログ (カテゴリ別)](#hook-カタログ-カテゴリ別)
- [索引](#索引)
- [蒸留の範囲外](#蒸留の範囲外)

## まず押さえる

1. **hook は 30 個** (Claude Code v2.1.162 / 2026-06-04 時点の原典 badge)。発火タイミング・受け取る
   入力フィールド・matcher 対応・導入バージョンが 1 つの表に揃っている。設計時はこの表を起点にする。
   → `.claude/hooks/HOOKS-README.md` の "Hook Events Overview" 表 (30 行)、追加履歴は `README.md` の Changelog 表

2. **handler type は 4 種**: `command` (stdin JSON → exit code / stdout で制御)、`prompt` (単発でモデルに
   yes/no 判定させる、`{"ok": bool, "reason": str}` を返す)、`agent` (Read/Grep/Glob 付きサブエージェントで
   多ターン検証)、`http` (v2.1.63+、URL に JSON を POST)。**判断が必要なゲートは prompt/agent、決定論が
   必要な強制は command** という使い分けになる。
   → `.claude/hooks/HOOKS-README.md` の "Hook Types"

3. **prompt/agent 型は 9 イベントでしか使えない** (PreToolUse, PostToolUse, PostToolUseFailure,
   PermissionRequest, UserPromptSubmit, Stop, SubagentStop, TaskCreated, TaskCompleted)。残り 21 は
   command-only。`http` の非対応リストはさらに別 (18 イベント) で、prompt/agent の除外リストと一致しない。
   → 同上 "Hook Types" 各節の除外リスト

4. **全 hook が stdin で JSON を受ける。共通フィールドは 7 つ**: `hook_event_name`, `session_id`,
   `transcript_path`, `cwd`, `permission_mode` (`default`/`plan`/`acceptEdits`/`dontAsk`/`bypassPermissions`)、
   および subagent 文脈でのみ入る `agent_id`・`agent_type` (v2.1.69+)。hook 固有フィールドは
   カタログ表の Options 列に列挙されている。
   → 同上 "Common Input Fields (stdin JSON)"

5. **全 hook が stdout JSON で返せる universal fields は 5 つ**: `continue` (false で Claude を停止)、
   `stopReason`、`suppressOutput`、`systemMessage` (ユーザーへの警告表示)、`additionalContext`
   (会話にコンテキスト注入)。つまり「追加コンテキスト注入」と「全停止」はどの hook からでも可能。
   → 同上 "Universal JSON Output Fields"

6. **ブロックの手段は hook ごとに違う**。この非対称性が hook 設計の最大の落とし穴で、原典の
   "Decision Control Patterns" 表 (16 行) が唯一の一覧。抜粋: PreToolUse は
   `hookSpecificOutput.permissionDecision` (`allow`/`deny`/`ask`/`defer` — defer は headless `-p` のみ、
   v2.1.89+)、PermissionRequest は `hookSpecificOutput.decision.behavior`、Stop / SubagentStop /
   ConfigChange は top-level `decision: "block"`、PreCompact と PostToolBatch は `decision` + exit code 2、
   TeammateIdle / TaskCreated / TaskCompleted は `{"continue": false, "stopReason": ...}` (v2.1.70+)、
   WorktreeCreate は非ゼロ exit で作成失敗 + stdout でパス指定。
   → 同上 "Decision Control Patterns"

7. **PreToolUse の `decision` / `reason` は deprecated**。`"decision": "approve"` →
   `hookSpecificOutput.permissionDecision: "allow"`、`"block"` → `"deny"` に置き換える。
   → 同上 "PreToolUse Decision Control Deprecation"

8. **強制できないことの境界** (原典の記載ベース): MessageDisplay は display-only で
   `hookSpecificOutput.displayContent` により画面表示だけ差し替えられるが transcript とモデルの見る内容は
   変わらない、かつブロック不可。matcher 非対応の hook は常時発火する (UserPromptSubmit, Stop, TeammateIdle,
   TaskCreated, TaskCompleted, WorktreeCreate, WorktreeRemove, CwdChanged, Setup, PostToolBatch,
   MessageDisplay)。managed policy 経由で設定された hook は user/project/local の `disableAllHooks` では
   無効化できない (v2.1.49 で修正)。
   → 同上 "Per-Hook Matcher Reference", "Configuring Hooks"

9. **承認の自動化系** (headless / CI 用途): PreToolUse の `hookSpecificOutput.autoAllow: true` で以降の
   同ツール使用を自動承認 (v2.0.76+)、PreToolUse が `AskUserQuestion` にマッチしたとき
   `hookSpecificOutput.updatedInput` で質問に自動回答 (v2.1.85+、公式 docs 未記載・changelog 由来)、
   PermissionDenied は `hookSpecificOutput.retry: true` でモデルに再試行を許可 (v2.1.89+)。ただし
   PermissionRequest の `updatedInput` は deny rule に再評価されるようになった (v2.1.102 / v2.1.110) ので、
   hook で deny を迂回することはできない。
   → 同上 "Known Issues & Workarounds", "Decision Control Patterns"

10. **hook option は 6 つ**: `timeout` (ms)、`async: true` (バックグラウンド実行、ログ・通知向け)、
    `once: true` (セッション 1 回だけ。**skill と settings のみで、agent frontmatter は非対応**)、
    `statusMessage` (スピナー表示文字列)、`if` (v2.1.85+、permission rule 構文 `Bash(git *)` で条件付き
    プロセス起動。tool 系 4 hook のみ、handler 単位)、`asyncRewake` (v2.1.72+、**公式 docs 未記載**。
    async かつ exit code 2 でモデルを起こす。著者が settings schema の `propertyNames` から発見)。
    → 同上 "Hook Option: ..." 各節

11. **settings.json の登録形** — `hooks.<HookName>` は配列で、各要素が `{ matcher?, hooks: [handler...] }`。
    matcher を省略すると全マッチ。30 hook 分の実例が 4 ファイルに同一構造で揃っており、そのまま雛形に使える。
    `once: true` は PreCompact / SessionStart / SessionEnd のみ、timeout は Setup だけ 30000 で他は 5000、
    `async: true` は全 hook、matcher 実例は FileChanged の `".envrc|.env|.env.local"` のみ。
    プラットフォーム差は Windows のみ (`python` + 相対パス、他は `python3` + `${CLAUDE_PROJECT_DIR}`)。
    → `.claude/settings.json` (399 行)、`install/settings-{mac,linux,windows}.json`、差分理由は `install/README-linux.md`

12. **agent frontmatter hooks は実測 6 個しか発火しない** (PreToolUse, PostToolUse, PermissionRequest,
    PostToolUseFailure, Stop, SubagentStop)。v2.1.0 changelog は 3 個としか書いていないが著者のテストで 6 個。
    一方 2026-02 時点の公式 docs は skill/agent frontmatter で "All hook events are supported" と記載し、
    **原典自身が「再テスト推奨」と保留している** (upstream issue #27153 を報告済み・未解決)。ここは公式で確認する。
    → `.claude/hooks/HOOKS-README.md` の "Agent Frontmatter Hooks"、`CLAUDE.md` の "Agent Hooks"

13. **agent の `Stop` hook は `hook_event_name` が `"SubagentStop"` で届く**。当初はバグ報告
    (issue #19220) だったが、現在は公式 docs が仕様として明記 ("For subagents, Stop hooks are automatically
    converted to SubagentStop")。agent 側で hook 名分岐するスクリプトは両方を受ける必要がある。
    → 同上 "Agent Stop Hook Bug (SubagentStop vs Stop)"

14. **環境変数 7 つ**: `$CLAUDE_PROJECT_DIR` (全 hook)、`$CLAUDE_ENV_FILE` (SessionStart / CwdChanged /
    FileChanged 限定。後続 Bash に env を渡す。追記 `>>` を使う。Windows では v2.1.111 まで silent no-op)、
    `${CLAUDE_PLUGIN_ROOT}`、`${CLAUDE_SKILL_DIR}` (v2.1.69+)、`${CLAUDE_PLUGIN_DATA}` (v2.1.78+、更新で
    消えない永続データ)、`$CLAUDE_CODE_REMOTE` (web 環境で `"true"`)、
    `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` (v2.1.74 まで SessionEnd は 1.5s で強制 kill されていた)。
    → 同上 "Environment Variables"

15. **運用系**: `/hooks` で対話的に管理 (`[User]`/`[Project]`/`[Local]`/`[Plugin]` の出所ラベル付き、
    `disableAllHooks` トグルもここ)、`claude hooks reload` で再起動なしに再読込 (v2.0.47+)。同一の handler が
    複数の settings に定義されても 1 回だけ実行される (dedup)。セッション中に外部プロセスが settings を
    書き換えると警告が出る。
    → 同上 "Hooks Management Commands", "Hook Deduplication & External Changes"

## hook カタログ (カテゴリ別)

30 hook の発火条件・入力フィールド・matcher 値・導入バージョンは
**`.claude/hooks/HOOKS-README.md` の "Hook Events Overview" 表と "Per-Hook Matcher Reference" 表**が正。
ここでは束ねた分類と、そのカテゴリ固有の注意だけ置く。

| カテゴリ | hook (原典の番号順) | カテゴリ固有の注意 |
|---|---|---|
| ツール実行前後・権限 | `PreToolUse` `PermissionRequest` `PostToolUse` `PostToolUseFailure` `PostToolBatch` `PermissionDenied` | matcher は `tool_name` (regex 可、MCP は `mcp__<server>__<tool>`)。`if` オプションが使えるのは PostToolBatch / PermissionDenied を除くこの系。PostToolBatch は並列ツール呼び出しのバッチ完了後・次のモデル呼び出し前に 1 回だけ発火し matcher 非対応 |
| プロンプト送信・表示 | `UserPromptSubmit` `UserPromptExpansion` `MessageDisplay` | UserPromptSubmit は stdout で prompt 自体を書き換えられる。UserPromptExpansion は slash command / MCP prompt の展開時 (matcher は `command_name`)、`decision: "block"` で展開自体を止められる。MessageDisplay は表示のみ |
| ターン終了 | `Stop` `StopFailure` | Stop は matcher 非対応・`decision: "block"` で続行を強制できる。StopFailure は API エラー由来の終了 (matcher は `rate_limit` 等 7 値) |
| セッション境界 | `SessionStart` `SessionEnd` `Setup` | SessionStart の matcher は `startup`/`resume`/`clear`/`compact`。SessionEnd は `logout` 等 6 値。Setup は `--init`/`--init-only`/`--maintenance` 起動時で、**公式 hooks reference には未掲載** (changelog v2.1.10 のみ) |
| compaction | `PreCompact` `PostCompact` | matcher は `manual`/`auto`。PreCompact は v2.1.105 以降 compaction をブロックできる |
| subagent 境界 | `SubagentStart` `SubagentStop` | matcher は `agent_type` (`Bash`/`Explore`/`Plan`/カスタム名) |
| agent teams (実験的) | `TeammateIdle` `TaskCreated` `TaskCompleted` | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が必要。3 つとも matcher 非対応。TaskCreated は exit code 2 でタスク作成をブロックでき stderr がモデルに戻る |
| 環境・設定・指示の変化 | `ConfigChange` `CwdChanged` `FileChanged` `InstructionsLoaded` | direnv 的な反応型 env 管理向け。**FileChanged は matcher (pipe 区切り basename) が必須**。InstructionsLoaded は CLAUDE.md / `.claude/rules/*.md` のロード時で matcher は `load_reason` 5 値。ConfigChange は `decision: "block"` 可 |
| worktree 分離 | `WorktreeCreate` `WorktreeRemove` | カスタム VCS 対応用。WorktreeCreate は非ゼロ exit で作成失敗、stdout で worktree パスを供給 |
| MCP elicitation | `Elicitation` `ElicitationResult` | matcher は `server_name`。`hookSpecificOutput.action` (`accept`/`decline`/`cancel`) + `content` でユーザー応答を自動化・上書きできる |
| 通知 | `Notification` | matcher は `notification_type` (`permission_prompt`/`idle_prompt`/`auth_success`/`elicitation_dialog`) |

## 索引

| トピック | 原典パス | 内容 (一行) |
|---|---|---|
| **hook 実務リファレンス本体** | `.claude/hooks/HOOKS-README.md` | 30 hook カタログ・handler 4 型・matcher 表・決定制御表・universal 出力・env var・option・既知バグ (603 行) |
| hook 追加履歴 (導入バージョン) | `README.md` | 追加日 / 累計個数 / hook 名 / Claude Code バージョンの表 (4 個 → 30 個の系譜)、デモ動画リンク |
| リポジトリ全体の構造・不変条件 | `CLAUDE.md` | hook count を一致させるべき 14 ファイルの列挙、命名規約 (hook は PascalCase / sound folder は lowercase) |
| settings.json 登録形 (30 hook 実例) | `.claude/settings.json` | `disableAllHooks` + 30 hook 分の handler。matcher / once / timeout / statusMessage の実例 |
| 配布用 settings (OS 別) | `install/settings-{mac,linux,windows}.json` | 同内容。Windows のみ `python` + 相対パス |
| 導入手順・前提 | `install/README-{mac,linux,windows}.md` | Python 3 / 音声プレイヤ (afplay / paplay / winsound)、settings のマージ手順 |
| 実働 hook スクリプト | `.claude/hooks/scripts/hooks.py` | 30 hook を 1 本で捌く single-dispatch 実装 (483 行)。`hook_event_name` で分岐、`--agent=<name>` で agent 用サウンド、`hooks-log.jsonl` に全入力を監査ログ出力 |
| hook 個別 toggle (独自実装) | `.claude/hooks/config/hooks-config.json` | `disable<Hook>Hook` の真偽値 31 キー。`hooks-config.local.json` が優先。**公式機能ではなくスクリプト側の実装** |
| agent frontmatter hooks の実例 | `.claude/agents/claude-code-hook-agent.md` | 6 hook を frontmatter に書いた動く agent (`matcher: ".*"` の書き方も含む) |
| 全 hook 発火テスト用 agent | `.claude/agents/claude-code-test-agent.md` | 30 hook 分の handler を frontmatter に持ち、発火を log に追記して実測する (303 行)。結果ログは `tests-agents-hook/agent-hook-fired.log` |
| ライフサイクル可視化デモ | `demo/` | `hooks-lifecycle.html` (SVG フローチャートが発火で光る) + `server.py` (port 3456、`/api/state`) + `demo-hooks.py`。どの prompt でどの hook を焚けるかの guided prompt カード付き。手順は `demo/README.md` |
| hook 追加の全手順 (自動化) | `.claude/commands/workflows/workflow-add-hook.md` | 新 hook を 14 ファイルに一括追加する手順書 (275 行)。公式 docs 3 URL の fetch → プロパティ決定 → 全ファイル更新 → stale count sweep → grep 検証 |
| 公式仕様との drift 検知 | `.claude/commands/workflows/workflow-changelog.md`, `.claude/agents/workflows/workflow-changelog-agent.md` | 2 agent を並列起動して公式 docs / changelog と repo を突き合わせる read-then-report ワークフロー。settings schema の `propertyNames` から未文書 hook を発掘する手口も含む |
| drift 検査ルール集 | `changelog/verification-checklist.md` | 5 段階の検査深度 (exists / presence-check / content-match / field-level / cross-file) と、実際に取り逃した drift から追加された累積ルール (104 行) |
| drift 検知の実績ログ | `changelog/changelog.md` | 日付 + バージョンごとの発見と対処 (✅/❌/✋)。false positive の記録もある (存在しない `OpenInEditor` hook 等) — 二次情報の誤りの実例として読める |
| hook 追加の設計メモ | `plans/add-new-hooks-teammate-idle-task-completed.md` | TeammateIdle / TaskCompleted 追加時の段取り (13 個 → 15 個のとき) |
| デモ動画・スライド | `presentation/index.html`、`README.md` の YouTube リンク | 全 hook を 1 スライドずつ解説 (2915 行、can-block バッジ付き)。動画 4 本は Notification / PermissionRequest / PostToolUseFailure / TaskCreated 追加時のデモ。**本文ではなくデモなので仕様確認には使わない** |
| Codex CLI 側の hook (参考) | `.codex/hooks.json`, `.codex/hooks/HOOKS-README.md` | 同著者による Codex CLI 版 hook 設定 (5 hook)。Claude Code とは別系統 |

## 蒸留の範囲外

- **hook 仕様の一次確認** — 公式 docs (https://code.claude.com/docs/en/hooks と `/hooks-guide`) が正。
  原典自身がこの 2 ページ + Claude Code CHANGELOG を fetch して書き写す構造なので、
  発火条件・入力フィールド・can-block・matcher 値を確定させるときは公式を直接読む。
- **各 hook の入力フィールド全リストと matcher 値全リスト** — 30 行 × Options 列の全量は写していない。
  `.claude/hooks/HOOKS-README.md` の 2 つの表を引く。
- **二次情報としての drift 実例 (注意喚起)** — 実測で確認したもの: `demo/README.md` の本文は
  "all 26 Claude Code hooks" のままだが `demo/.claude/settings.json` は 30 hook を登録済み。
  `.claude/hooks/HOOKS-README.md` の hooks-config.json サンプル JSON は toggle 30 キー
  (`disableTaskCreatedHook` が欠落) だが実ファイルは 31 キーで同キーを持つ。
  **個数や有無を原典の散文から断定しない** — 表と実ファイルを見る。
- **音声通知の実装詳細** (OS 別プレイヤ検出、TTS 生成、sound folder 命名) — hook 設計には無関係。
  `.claude/hooks/scripts/hooks.py` と HOOKS-README の TTS 節。
- **スライド・動画の内容** — `presentation/index.html` と YouTube。索引に対象 hook だけ載せた。
- **バージョン依存の記述** — 本文の option / フィールドには判明している導入バージョンを併記したが、
  未記載のものは検証していない。原典の badge (v2.1.162 / 2026-06-04) より新しい挙動は追えていない。
