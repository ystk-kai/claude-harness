# 蒸留版の作成・更新レシピ

`references/*.md` (蒸留版) を作る・更新するときの規約と手順。蒸留版の品質と構造の一貫性は、この文書を唯一のレシピとして維持する。

## frontmatter の形式 (`references/*.md` 共通)

`skills/*/references/*.md` は 3 形式のいずれかを取る。`check-freshness.sh` はこの分類で処理を分け、
**どれにも当てはまらないものは `ERR`** にする。frontmatter が無いだけで無言に対象外にはならない
(「意図的な非追従」と「壊れた蒸留版」を区別できなくなるため)。

| 形式 | キー | 用途 | 判定 |
|---|---|---|---|
| 1. 蒸留版 | `source` + `distilled_commit` + `distilled_at` | 原典 clone を SHA で追従する | clone の HEAD と `distilled_commit` を比較 |
| 2. 知識ベース | `tracking: review` + `reviewed_at` + `review_interval_days` | 出所 clone を持たない自作の調査資料 (例: `avoid-ai-slop-*`) | `reviewed_at` からの経過日数が interval を超えたら `REVIEW` |
| 3. 対象外 | `tracking: none` | 鮮度管理しないと明示するもの | 何も報告しない |

形式 2 の `review_interval_days` は腐る速さで決める。モデル世代や流行に依存する記述 (生成画像の tell、
配色トレンド) は 90 日、機構に根ざした記述 (テンプレート由来のパターン、文章構文) は 180 日を目安にする。
棚卸しで内容を見直したら `reviewed_at` を当日に更新する — 中身を見ずに日付だけ進めるのは
形式 1 の「SHA だけの無言 bump」と同じ禁止事項。

## 構成規約 (形式 1 の蒸留版)

- frontmatter は 3 キー: `source` (出所 URL。repo リストの唯一の正)・`distilled_commit` (蒸留時点の完全 SHA)・`distilled_at` (YYYY-MM-DD)
- 本文構成: `## Contents` (100 行超のファイルでは必須) → `## まず押さえる` (確度の高い要点 5〜15 項目、各項目に原典相対パス併記) → 索引テーブル (トピック → 原典パス → 一行説明) → `## 蒸留の範囲外` (含めなかった領域と原典での当たり方)
- 250 行以内。原典の丸写し・長い引用をしない。実際に Read して確認した事実だけを書く (推測で書かない)
- 地の文は日本語。識別子・ファイルパス・英語原文の引用はそのまま
- 原典パスはリポジトリルートからの相対パスで書く。原典ルートの絶対パスを本文に直書きしない (ルートは SKILL.md が一元管理)

## 更新手順 (STALE のとき)

1. `scripts/check-freshness.sh` で BEHIND / STALE を確認する
2. BEHIND なら先に clone を `git pull --ff-only` で更新する
3. STALE の差分コミットを確認する: `git -C <clone> log --oneline <distilled_commit>..HEAD`、必要に応じて `git show <sha>`
4. 蒸留版に影響する変更だけ本文へ反映し、**同じコミットで** `distilled_commit` を新しい HEAD に、`distilled_at` を当日に更新する
5. 内容への影響なしと判断して SHA のみ進める場合も、その判断理由を commit message に書く。SHA だけの無言 bump は禁止 (機械的に検知する仕組みはなく、この規律で provenance を守る)

## 新規リポジトリの追加

1. どのスキルの資料かを決める (ハーネス設計なら `harness-design`、UI デザインなら `ui-design`)
2. その構成規約で `skills/<skill>/references/<cloneディレクトリ名>.md` を書く (ファイル名は `basename <source URL> .git` と一致させる。`check-freshness.sh` と `install.sh` はどちらもスキル横断で `skills/*/references/*.md` を走査するので、置き場所さえ合っていれば自動で対象になる)
3. `install.sh --with-references` を実行する (frontmatter の `source` から URL を拾って clone し、`.claude/skills` を worktree から外す)
4. そのスキルの SKILL.md の参照リポジトリ表に行を追加する

## 再蒸留プロンプト雛形

サブエージェントに蒸留を委譲するときの指示テンプレート:

```
<原典ルート>/<repo> にある git clone (<owner>/<repo>) を読み、蒸留版リファレンスを 1 ファイル書いてください。
出力ファイル: skills/<skill>/references/<repo>.md

手順:
1. git -C <clone> rev-parse HEAD で SHA を取得する
2. README と目次で構造を把握し、重点ファイルを実際に Read して要点を確認する (推測で書かない)
3. skills/claude-harness-refs-update/DISTILLING.md の構成規約に従って書く
   (frontmatter 3 キー / Contents / まず押さえる / 索引 / 蒸留の範囲外 / 250 行以内)

重点領域: <このリポジトリで何を索引したいか>

最後に、書いたファイルの行数・使った commit SHA・内容の 3 行要約だけを返してください。
```
