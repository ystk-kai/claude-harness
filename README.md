# harness-design

LLM ハーネス・プロンプト設計のローカル参照資料集 (`~/.claude/references/`) を、どの環境でも同じ規約で使えるようにする Claude Code 用の個人ハーネス定義。

## 含まれるもの

- `skills/harness-design/SKILL.md` — 2 層構成 (蒸留版/原典) の読む順序・鮮度管理・判断の優先順位を定義するグローバルスキル
- `skills/harness-design/references/*.md` — 各参照リポジトリの蒸留版。frontmatter の `source` が repo リストの唯一の正、`distilled_commit` が蒸留時点
- `skills/harness-design/DISTILLING.md` — 蒸留版の構成規約・更新手順・再蒸留プロンプト雛形
- `skills/harness-design/scripts/check-freshness.sh` — 蒸留版の鮮度チェック (fetch して BEHIND / STALE を検出)
- `skills/harness-design/scripts/frontmatter.sh` — install.sh と check-freshness.sh が共用する frontmatter パーサ
- `claude-md/harness-design.md` — グローバル CLAUDE.md に挿入する管理ブロック (スキル利用を常時ルール化する)
- `install.sh` — 冪等な適用スクリプト

参照リポジトリの実体 (数百 MB) はこのリポジトリに含めない。SKILL.md 記載の出所 URL から各環境で shallow clone して復元する。

## 設計メモ: references をスキルディレクトリ内に置かない理由

[Agent Skills 標準](https://agentskills.io/specification) では `references/` はスキルディレクトリ内の任意サブディレクトリで、そのスキルのために書かれた focused な文書を置く場所と定義されている。一方このハーネスが扱うのは外部リポジトリの丸ごと clone (数百 MB・第三者ライセンス・`git pull` で独立に更新) であり、標準が想定する「スキル付属の参照文書」とは性質が異なる。そのため:

- 外部 clone (生データ) は共有コーパスとして `~/.claude/references/` に外出しする。スキル配布時に第三者リポジトリを同梱せずに済み、CLAUDE.md ルールや他スキルからも共有できる
- スキル外パスへの依存は SKILL.md の `compatibility` フィールド (標準仕様の宣言用フィールド) で明示する
- 自作の蒸留資料は標準どおり `skills/harness-design/references/` に置き、SKILL.md から 1 階層でリンクする (原典 = 外部の生データ、蒸留版 = このリポジトリで管理、の 2 層構成)。通常の参照は蒸留版で完結させ、原典の全文走査による入力トークンの肥大化を避ける

## 適用 (新しい環境)

```bash
git clone <this-repo-url> ~/repos/harness-design
~/repos/harness-design/install.sh
```

参照リポジトリも先にまとめて clone しておく場合:

```bash
~/repos/harness-design/install.sh --with-references
```

`install.sh` がやること:

1. `~/.claude/skills/harness-design` → このリポジトリへの symlink を作成
2. `~/.claude/CLAUDE.md` に `managed:harness-design` ブロックを挿入 (既存ブロックは置換)
3. `--with-references` 指定時のみ、`references/*.md` frontmatter の `source` URL を `~/.claude/references/` に `--filter=blob:none` で clone (既存はスキップ。履歴付き・blob は必要時取得なので鮮度チェックの差分表示がそのまま動く)

`~/.claude` 以外を使う環境では `CLAUDE_CONFIG_DIR` を設定して実行する。

## 更新

- スキル本文の変更: `git pull` だけで全環境に反映される (symlink のため)
- CLAUDE.md ブロックの変更: `claude-md/` を編集したら `install.sh` を再実行
- 参照リポジトリの追加: `references/` に蒸留版を 1 ファイル作り (frontmatter の `source` が唯一の正)、SKILL.md の表に行を足す。手順は `skills/harness-design/DISTILLING.md`
- 蒸留版の更新: `scripts/check-freshness.sh` で BEHIND / STALE を検出し、`DISTILLING.md` の更新手順に従う
