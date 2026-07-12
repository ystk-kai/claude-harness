---
name: claude-harness-refs-update
description: harness-design の参照資料 (蒸留版 references/*.md と原典 clone ~/.claude/references/ の 2 層) の鮮度チェックと更新を実行する。check-freshness → BEHIND を git pull → STALE を DISTILLING.md の手順で再蒸留。明示起動専用 (/claude-harness-refs-update で呼ぶ)。
disable-model-invocation: true
argument-hint: "[repo-name ...] | --check"
compatibility: Requires git and network access. Operates on harness-design's references/*.md and the clones at ~/.claude/references/ (external to this skill dir); reuses harness-design's scripts/check-freshness.sh and DISTILLING.md.
---

# claude-harness-refs-update: 参照資料の鮮度チェックと更新

`harness-design` の参照資料は 2 層 — 蒸留版 (`skills/harness-design/references/*.md`) と原典 clone (`~/.claude/references/<repo>/`)。このスキルは鮮度チェックから再蒸留までを 1 コマンドで回す。**ロジックは harness-design 側に既にある** (`scripts/check-freshness.sh` が検出、`DISTILLING.md` が更新レシピと再蒸留プロンプト雛形を持つ)。このスキルはそれらを呼ぶ薄いオーケストレーション層であり、判定や蒸留の規約を再実装しない。

引数: repo 名 (例 `12-factor-agents`) を渡すとその repo だけを対象にする。`--check` で鮮度チェックのみ (更新に進まない)。無引数なら全 repo を対象に更新まで進む。

## Process (run in order)

0. **前提を解決する。**
   - 当日日付を控える: `date +%F`。`distilled_at` に使う。**サブエージェントは当日日付を知らないので、後で必ずプロンプトに埋める。**
   - harness-design の実体パスを解決する: `HD="$(readlink -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/harness-design")"`。以降 `$HD/scripts/check-freshness.sh` / `$HD/DISTILLING.md` / `$HD/references/<repo>.md` を使う (symlink 越しでなく実体パスに書くため `readlink -f`)。
   - 原典ルート: `REFS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/references"`。clone は `$REFS/<repo>`。

1. **鮮度チェック** — `bash "$HD/scripts/check-freshness.sh"` を実行 (fetch あり = 最新 upstream を反映)。行頭タグ `OK` / `BEHIND` / `STALE` / `MISS` / `ERR` / `SKIP` / `NOTE` を読む。引数に repo 名があれば、その repo の行だけを対象にする (スクリプトに絞り込み機能はないので出力からフィルタ)。引数が `--check` なら結果を提示してここで終了。全 `OK` なら「更新不要」と伝えて終了。

2. **MISS / ERR を処理** — `MISS` (clone がない/壊れ) は `install.sh --with-references` を案内して中断する (clone がないと更新できない)。`ERR` (`distilled_commit` が履歴にない等) は各行に併記された復旧コマンドに従う。

3. **BEHIND を解消** — 各該当 clone を `git -C "$REFS/<repo>" pull --ff-only`。pull で新コミットが来ると STALE に変わるので、**pull 後に `check-freshness.sh` を取り直して STALE を再評価する** (順序を守る — 古い HEAD で蒸留しないため)。

4. **STALE を再蒸留** — STALE の各リポジトリを `general-purpose` サブエージェントに**並列委譲**する (`Agent` tool。蒸留版を Write するので Explore 不可)。各プロンプトは `$HD/DISTILLING.md` の「再蒸留プロンプト雛形」に次を埋めて作る:
   - 原典 clone パス `$REFS/<repo>` と owner/repo
   - 出力ファイル `$HD/references/<repo>.md` (手順0で解決した実体パス)
   - 重点領域 — 既存蒸留版の索引が扱っている範囲を引き継ぐ
   - 差分 — `git -C "$REFS/<repo>" log --oneline <distilled_commit>..HEAD` の内容 (何が変わったか。蒸留版に影響する変更だけ本文へ反映する判断材料)
   - **当日日付** (手順0の `date +%F`) を `distilled_at` として明示
   - 構成規約は `DISTILLING.md` に従うこと (frontmatter 3 キー / `## Contents` / `## まず押さえる` / 索引テーブル / `## 蒸留の範囲外` / 250 行以内 / 実際に Read した事実だけ・推測で書かない)

   各サブエージェントは蒸留版 1 ファイルを Write し、frontmatter の `distilled_commit` を clone の新 HEAD・`distilled_at` を当日に更新、最後に行数・使った SHA・内容の 3 行要約を返す。

5. **集約と確認** — 更新したファイル一覧と各 3 行要約を提示する。`bash "$HD/scripts/check-freshness.sh" --offline` を再実行し、対象が `OK` に戻ったことを確認する。ここまでの変更は作業ツリーに残す。

6. **commit (ユーザーが望むときのみ)** — 変更内容と、各リポジトリの差分 3 行要約を含む commit message 案を提示して承認を得てから commit する。**SHA だけの無言 bump をしない** (内容への影響なしと判断して SHA だけ進める場合も、その理由を message に書く)。承認がなければ diff を残して終了。個人リポジトリなので main への直接 commit でよい。

## Gotchas

- サブエージェントは当日日付を知らない → 手順0の `date +%F` を必ずプロンプトに埋める (`distilled_at` の正確性)。
- BEHIND を pull してから STALE を再評価する。順序を逆にすると古い HEAD で蒸留してしまう。
- 出力先は symlink 越しでなく `readlink -f` で解決した実体パスを使う。
- `check-freshness.sh` に repo 絞り込みはない → 特定 repo 指定時は全走査の出力からフィルタする。
- 再蒸留は必ず `DISTILLING.md` の構成規約をプロンプトに渡す (250 行以内 / 索引駆動 / 推測で書かない)。規約をサブエージェントの記憶任せにしない。
- 新規リポジトリの追加は別作業 (`DISTILLING.md`「新規リポジトリの追加」)。このスキルは既存蒸留版の更新に使う。

## Quick checklist

- [ ] `date +%F` を控え、サブエージェントに `distilled_at` として渡した
- [ ] `MISS`/`ERR` を先に解消した (clone 未取得なら `install.sh --with-references`)
- [ ] BEHIND を `git pull --ff-only` してから STALE を再評価した
- [ ] 各再蒸留が `DISTILLING.md` の規約 (frontmatter 3 キー / 250 行以内 / 推測で書かない) に従った
- [ ] `distilled_commit` を clone の新 HEAD に、`distilled_at` を当日に更新した
- [ ] `check-freshness.sh` が対象を `OK` に戻した
- [ ] commit する場合、message に差分 3 行要約を含めた (SHA だけの無言 bump をしない)
