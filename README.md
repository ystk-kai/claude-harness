# harness-design

LLM ハーネス・プロンプト設計のローカル参照資料集 (`~/.claude/references/`) を、どの環境でも同じ規約で使えるようにする Claude Code 用の個人ハーネス定義。

## 含まれるもの

- `skills/harness-design/SKILL.md` — 参照リポジトリの所在・振り分け・bootstrap・鮮度管理・読み方を定義するグローバルスキル
- `claude-md/harness-design.md` — グローバル CLAUDE.md に挿入する管理ブロック (スキル利用を常時ルール化する)
- `install.sh` — 冪等な適用スクリプト

参照リポジトリの実体 (数百 MB) はこのリポジトリに含めない。SKILL.md 記載の出所 URL から各環境で shallow clone して復元する。

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
3. `--with-references` 指定時のみ、SKILL.md 記載の出所 URL を `~/.claude/references/` に `--depth 1` で clone (既存はスキップ)

`~/.claude` 以外を使う環境では `CLAUDE_CONFIG_DIR` を設定して実行する。

## 更新

- スキル本文の変更: `git pull` だけで全環境に反映される (symlink のため)
- CLAUDE.md ブロックの変更: `claude-md/` を編集したら `install.sh` を再実行
- 参照リポジトリの追加: SKILL.md の表と出所 URL リストに追記する (install.sh は URL を SKILL.md から拾うため、変更はそこだけでよい)
