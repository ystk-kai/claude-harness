# claude-harness

Claude Code の個人グローバルハーネス (skills / CLAUDE.md 管理ブロック) をバージョン管理し、どの環境でも `install.sh` で同じ状態に展開するリポジトリ。

## 収録スキル

| スキル | 用途 |
|---|---|
| `harness-design` | LLM ハーネス・プロンプト設計の参照資料集。蒸留版 (スキル内) + 原典 clone (`~/.claude/references/`) の 2 層で読む |
| `avoid-ai-slop-ja` | 日本語文章から AI 臭 (slop) を除くレビュー・リライトの手法 |

## 構成

- `skills/<name>/` — スキル本体 (SKILL.md + references/ + scripts/)。`~/.claude/skills/<name>` に symlink される
- `claude-md/<name>.md` — グローバル CLAUDE.md に挿入する managed block (常時ルール化したいスキルのみ)
- `install.sh` — 冪等な適用スクリプト

## 適用 (新しい環境)

### Claude Code に導入させる (推奨)

新しい環境の Claude Code に次のプロンプトを貼るだけで、導入から検証まで行われる:

```text
https://github.com/ystk-kai/claude-harness を ~/repos/claude-harness に clone し、
~/repos/claude-harness/install.sh --with-references を実行してください。
完了後に次の 3 点を検証して結果を報告してください:
1. ~/.claude/skills/ に skills/ 配下の各スキルへの symlink があること
2. ~/.claude/CLAUDE.md に managed:harness-design ブロックが挿入されていること
3. ~/repos/claude-harness/skills/harness-design/scripts/check-freshness.sh が全リポジトリ OK を返すこと
```

### 手動で導入する

```bash
git clone https://github.com/ystk-kai/claude-harness.git ~/repos/claude-harness
~/repos/claude-harness/install.sh
```

参照リポジトリ (harness-design の原典) も先にまとめて clone する場合:

```bash
~/repos/claude-harness/install.sh --with-references
```

`install.sh` がやること:

1. `skills/*/` を `~/.claude/skills/<name>` へ symlink (symlink でない実体がある場合はスキップして警告)
2. `claude-md/*.md` を `~/.claude/CLAUDE.md` に `managed:<name>` ブロックとして挿入 (既存ブロックは置換)
3. `--with-references` 指定時のみ、各スキルの `references/*.md` frontmatter の `source` URL を `~/.claude/references/` に `--filter=blob:none` で clone (既存はスキップ。履歴付き・blob は必要時取得なので鮮度チェックの差分表示がそのまま動く)

`~/.claude` 以外を使う環境では `CLAUDE_CONFIG_DIR` を設定して実行する。

## スキルの追加

1. `skills/<name>/SKILL.md` を作る (Agent Skills 標準の構成: SKILL.md + 必要に応じて references/・scripts/)。スキルは外部状態 (memory 等) に依存させず `references/` で自己完結させる。やむを得ない外部依存は frontmatter の `compatibility` で宣言する
2. 常時ルール化したい場合のみ `claude-md/<name>.md` を作る
3. `install.sh` を再実行する

## 更新

- スキル本文の変更: `git pull` だけで全環境に反映される (symlink のため)
- CLAUDE.md ブロックの変更: `claude-md/` を編集したら `install.sh` を再実行

## harness-design: 参照資料の 2 層構成と鮮度管理

参照リポジトリの実体 (数百 MB) はこのリポジトリに含めない。各蒸留版 frontmatter の `source` URL から clone して復元する。

- 蒸留版: `skills/harness-design/references/*.md`。frontmatter の `source` が repo リストの唯一の正、`distilled_commit` が蒸留時点
- 蒸留の規約と更新手順: `skills/harness-design/DISTILLING.md` (構成規約・STALE 更新手順・再蒸留プロンプト雛形)
- 鮮度チェック: `skills/harness-design/scripts/check-freshness.sh` (fetch して BEHIND / STALE を検出)。`frontmatter.sh` は install.sh と共用のパーサ
- 参照リポジトリの追加: `references/` に蒸留版を 1 ファイル作り、SKILL.md の表に行を足す

### 設計メモ: references をスキルディレクトリ内に置かない理由

[Agent Skills 標準](https://agentskills.io/specification) では `references/` はスキルディレクトリ内の任意サブディレクトリで、そのスキルのために書かれた focused な文書を置く場所と定義されている。一方 harness-design が扱うのは外部リポジトリの丸ごと clone (数百 MB・第三者ライセンス・`git pull` で独立に更新) であり、標準が想定する「スキル付属の参照文書」とは性質が異なる。そのため:

- 外部 clone (生データ) は共有コーパスとして `~/.claude/references/` に外出しする。スキル配布時に第三者リポジトリを同梱せずに済み、CLAUDE.md ルールや他スキルからも共有できる
- スキル外パスへの依存は SKILL.md の `compatibility` フィールド (標準仕様の宣言用フィールド) で明示する
- 自作の蒸留資料は標準どおり `skills/harness-design/references/` に置き、SKILL.md から 1 階層でリンクする (原典 = 外部の生データ、蒸留版 = このリポジトリで管理、の 2 層構成)。通常の参照は蒸留版で完結させ、原典の全文走査による入力トークンの肥大化を避ける
