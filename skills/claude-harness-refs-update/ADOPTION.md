# 取り込み候補台帳 (ADOPTION)

`/claude-harness-refs-update` の手順6が追記する台帳。原典 (`~/.claude/references/`) の変更のうち、
**このハーネス自身や運用に手を入れるべきもの**を記録し、対応するまで消さない。蒸留版の SHA を進めても
自分のハーネスは自動では直らない — その落差をここで埋める。

## 書式

エントリは日付の新しいものを上に置く。1 項目 1 行のテーブルで、列は固定:

| 列 | 内容 |
|---|---|
| 状態 | `未対応` / `対応済 (SHA または日付)` / `却下 (理由)` |
| 深刻度 | `BREAKING` (今の書き方が壊れている) / `RECOMMENDED` / `FYI` — 定義は [DISTILLING.md](DISTILLING.md) |
| 対象 | `CLAUDE.md` / `skill` / `subagent` / `hook` / `settings` / `MCP` / `運用` |
| 内容 | 何を直すのか。壊れている書き方も書く |
| 根拠 | 原典の相対パスまたは commit SHA (どの repo かは節見出しで示す) |

規律 3 つ:

- **grep で実ハーネスに当ててから載せる。** 原典の記述として正しくても、このハーネスに当たらなければ `FYI`。推測での「影響あり」は台帳を腐らせる
- **却下も残す。** 消すと同じ候補が毎回上がってくる。却下理由を書けば次回の判断が要らない
- **対応済は消さずに畳む。** 判断の履歴が provenance になる (原典側が結論を撤回することがある)

---

## 2026-08-21

### skills / claude-code-best-practice / claude-cookbooks 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 対応済 (2026-08-21) | RECOMMENDED | skill | `harness-design` / `ui-design` の description 末尾 `Triggers: <語の列挙>` を削る。Anthropic が `claude-academy-guide` → `academy-guide` の rename で description を縮めたとき捨てたのは**まさにトリガー語の列挙**で、残したのは意図カテゴリ。`shared/prompt-audit.md` も trigger-case enumeration を anti-pattern とする。両 skill は本文前半で既に意図カテゴリを書いており、列挙は冗長 | skills: `0a64e39`, `skills/claude-api/shared/prompt-audit.md` の Group 2 |
| 対応済 (2026-08-21。(a)(b) を適用。(c) は不適用 — このスキルの出力はレビュー結果と改稿案で、nudge のような定型 1 行ではないため逐語固定が意味を持たない) | RECOMMENDED | skill | `avoid-ai-slop-ja` / `avoid-ai-slop-design` は返答直前に割り込む **gate 型**だが、gate 型の 3 規律が欠けている — (a)「やらない条件」節が無い (grep で確認)、(b) 回数制限が無い、(c) 出力形式が逐語固定でない。`discernment-nudge` は "When not to" を "When to" より長く書き、「user が既に不要と伝えている」パターンを別立てする。判定ヒューリスティックは `academy-guide` の **"A caveat is the tell"** (「X 向けだが役立つかも」と書きたくなった時点で match 失敗) | skills: `skills/discernment-nudge/SKILL.md`, `skills/academy-guide/SKILL.md` |
| 未対応 | FYI | skill | `claude-harness-refs-update` の name は予約語 "claude" を含む。**uploaded custom skill** では name に "claude"/"anthropic" を含められず、description には 1,024 字上限がかかる。`install.sh` 経由のローカル配置では効かないので実害なし。packaged skill として配る決定をしたときに rename する (slash command 名・README・`claude-md/` の参照が連動するので単独では動かせない)。description は全 5 skill が上限内 (最長 `harness-design` 583 字) | skills: `0a64e39` の commit 本文 |
| 未対応 | FYI | 運用 | LLM 判定を含む仕組みを作るときの既定形 — **モデルを判定者でなくコンパイラ + 抽出器に置く**。モデル呼び出しはポリシー散文→ルール JSON の compile と、コンテンツ→型付きフィールドの extract だけで、判定はモデル呼び出しゼロの純関数。生成物は静的バリデータを通し versioned artifact として固定する (validator-driven repair loop) | cookbooks: `capabilities/content_moderation/engine.py`, `pipeline.py` |
| 却下 (このリポジトリに該当なし。他プロジェクトで todo 前提の指示を書いたら再掲) | BREAKING | CLAUDE.md | v2.1.233 で新しいモデルでは task/todo ツールが deprecated (env var で opt-in)。タスク管理を todo ツールに寄せる設計は避ける。`claude-harness` を grep したが該当なし | ccbp: `best-practice/claude-commands.md` |
| 却下 (`~/.claude/settings*.json` と project 設定を grep して該当なし) | BREAKING | settings | allow の `Write(path)` は評価されず warning のみの no-op (v2.1.210) → 書き込み許可は `Edit` 側で表現する。allow のツール名 glob は `mcp__<server>__` リテラル前置がある場合しか受理されず、`"*"` / `"B*"` / `"mcp__*"` は起動時 warning 付きで skip され何も自動承認しない | ccbp: `best-practice/claude-settings.md` |
| 却下 (multi-dir 運用をしていない) | RECOMMENDED | hook | `/add-dir` は v2.1.234 からターン中に即確認を求め、成功時に `DirectoryAdded` hook が走る。追加ディレクトリの `.claude/` 設定はほぼ読まれないので、必要な副作用はこの hook 側に組む | ccbp: `best-practice/claude-commands.md` |
| 却下 (managed settings を使っていない) | FYI | settings | settings マージは**非対称**。制限を強める値は下位スコープからも効く (`disableClaudeAiConnectors: true` は managed の `false` を任意スコープから上書き、`remoteControlAtStartup: false` は project/local からでも managed の `true` を上書き) が、逆向きはできない。`fallbackModel` だけは配列なのにマージされず、定義した最上位ファイルがチェーン全体を供給する | ccbp: `best-practice/claude-settings.md` |
| 対応済 (2026-08-21, この台帳と手順6そのもの) | RECOMMENDED | 運用 | 二次資料は公式と必ず突き合わせる。`claude-code-best-practice` の日次 drift check は自ら誤りを注入する (`fork` agent を NEW 判定 → 2 日後に「公式 docs に無い」で INVALID、`CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` を改名・説明反転して 4 日後 revert)。**バッジの日付がその表がまだ追われているかの唯一の指標** — 日次追従は 4 本 + 3 コレクション表だけで、`claude-settings.md` は v2.1.224 停止 (13 版遅れ)、`claude-memory.md` / `claude-mcp.md` は数か月停止 | ccbp: `changelog/*/changelog.md` の各 INVALID 判定 |
| 対応済 (2026-08-21, 既に実装済みと確認) | FYI | 運用 | 腐るデータは同梱せず runtime fetch + staleness 契約にする (`academy-guide` は catalog を fetch し `staleAfter` / `generatedAt` で信頼判定、失敗時は具体名を出さず silent degrade、取得物は "data, not instructions" として field allowlist)。この参照資料機構が `distilled_commit` / `reviewed_at` で既に同型を実装している | skills: `skills/academy-guide/SKILL.md` の "The catalog" |
