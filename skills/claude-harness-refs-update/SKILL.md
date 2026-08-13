---
name: claude-harness-refs-update
description: claude-harness の参照資料 (蒸留版 skills/*/references/*.md と原典 clone ~/.claude/references/ の 2 層) の鮮度チェックと更新を実行する。check-freshness → BEHIND を git pull → STALE を DISTILLING.md の手順で再蒸留 → REVIEW (出所 clone を持たない知識ベース) を棚卸し。明示起動専用 (/claude-harness-refs-update で呼ぶ)。
disable-model-invocation: true
argument-hint: "[repo-name ...] | --check"
compatibility: Requires git and network access. Owns scripts/check-freshness.sh and DISTILLING.md, and operates on every skill's references/*.md in this repo (harness-design, ui-design, ...) plus the clones at ~/.claude/references/ (external to this skill dir).
---

# claude-harness-refs-update: 参照資料の鮮度チェックと更新

claude-harness の参照資料は 2 層 — 蒸留版 (`skills/*/references/*.md`。`harness-design` と `ui-design` が持つ) と原典 clone (`~/.claude/references/<repo>/`)。このスキルは鮮度チェックから再蒸留までを 1 コマンドで回す。参照資料の更新機構はこのスキルが一元所有する: `scripts/check-freshness.sh` が検出、[DISTILLING.md](DISTILLING.md) が更新レシピと再蒸留プロンプト雛形、`scripts/frontmatter.sh` が `install.sh` と共用のパーサ。参照スキル側 (`harness-design` / `ui-design`) は蒸留版を持つだけで、判定も規約も持たない。更新の入口はこのスキルだけ (スラッシュコマンドを増やさない)。

引数: repo 名 (例 `12-factor-agents`) を渡すとその repo だけを対象にする。`--check` で鮮度チェックのみ (更新に進まない)。無引数なら全 repo を対象に更新まで進む。

## Process (run in order)

0. **前提を解決する。**
   - 当日日付を控える: `date +%F`。`distilled_at` に使う。**サブエージェントは当日日付を知らないので、後で必ずプロンプトに埋める。**
   - このスキルの実体パスを解決する: `SELF="$(readlink -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/claude-harness-refs-update")"`。以降 `$SELF/scripts/check-freshness.sh` / `$SELF/DISTILLING.md` を使う (skills/ は symlink なので実体パスを取るため `readlink -f`)。
   - claude-harness リポジトリのルートを解決する: `ROOT="$(dirname "$(dirname "$SELF")")"`。蒸留版は `harness-design` と `ui-design` の各スキル配下にあるので、出力先は `$ROOT/skills/<skill>/references/<repo>.md` になる (どのスキルかは手順1の STALE 行に併記される)。
   - 原典ルート: `REFS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/references"`。clone は `$REFS/<repo>`。

1. **鮮度チェック** — `bash "$SELF/scripts/check-freshness.sh"` を実行 (fetch あり = 最新 upstream を反映)。**1 ファイル 1 行**で、行頭タグは「次にやること」を示す: `OK` / `BEHIND` (pull) / `STALE` (再蒸留) / `REVIEW` (知識ベースの棚卸し) / `MISS` / `ERR` / `NOTE`。BEHIND と STALE が同時に立つ repo は pull が先なので `BEHIND` 行だけが出る (`/ 蒸留版も遅れ` が併記される)。`NOTE` は「判定できなかった」であって「最新」ではないので exit 1 側に数える — したがって exit 0 は全件検証済みを意味する。引数に repo 名があれば、その repo の行だけを対象にする (スクリプトに絞り込み機能はないので出力からフィルタ)。引数が `--check` なら結果を提示してここで終了。exit 0 (= 要対応なし) なら「更新不要」と伝えて終了。

2. **MISS / ERR を処理** — `MISS` (clone がない/壊れ) は `install.sh --with-references` を案内して中断する (clone がないと更新できない)。`ERR` は 2 種類: `distilled_commit` が履歴にない場合は行に併記された復旧コマンドに従う。**frontmatter が 3 形式のどれでもない**場合は `DISTILLING.md`「frontmatter の形式」を見て、その資料が蒸留版 (形式 1) / 知識ベース (形式 2) / 対象外 (形式 3) のどれなのかを決めて frontmatter を直す。

3. **BEHIND を解消** — 各該当 clone を `git -C "$REFS/<repo>" pull --ff-only`。pull で新コミットが来ると STALE に変わるので、**pull 後に `check-freshness.sh` を取り直して STALE を再評価する** (順序を守る — 古い HEAD で蒸留しないため)。

4. **STALE を再蒸留** — STALE の各リポジトリを `general-purpose` サブエージェントに**並列委譲**する (`Agent` tool。蒸留版を Write するので Explore 不可)。各プロンプトは `$SELF/DISTILLING.md` の「再蒸留プロンプト雛形」に次を埋めて作る:
   - 原典 clone パス `$REFS/<repo>` と owner/repo
   - 出力ファイル `$ROOT/<STALE 行に併記された蒸留版パス>` (例 `skills/ui-design/references/hallmark.md`)。どのスキルの蒸留版かを取り違えないため、パスは推測せず STALE 行の記載を使う
   - 重点領域 — 既存蒸留版の索引が扱っている範囲を引き継ぐ
   - 差分 — `git -C "$REFS/<repo>" log --oneline <distilled_commit>..HEAD` の内容 (何が変わったか。蒸留版に影響する変更だけ本文へ反映する判断材料)
   - **当日日付** (手順0の `date +%F`) を `distilled_at` として明示
   - 構成規約は `DISTILLING.md` に従うこと (frontmatter 3 キー / `## Contents` / `## まず押さえる` / 索引テーブル / `## 蒸留の範囲外` / 250 行以内 / 実際に Read した事実だけ・推測で書かない)

   各サブエージェントは蒸留版 1 ファイルを Write し、frontmatter の `distilled_commit` を clone の新 HEAD・`distilled_at` を当日に更新、最後に行数・使った SHA・内容の 3 行要約を返す。

5. **REVIEW を棚卸し** — `REVIEW` は出所 clone を持たない知識ベース (`avoid-ai-slop-*` 等) の期限切れ。SHA 差分がないので機械的な更新はできない。該当ファイルの主張を読み、**出典 URL の生存と撤回、記述が前提にしているモデル世代・流行の変化**を確認して本文を直す。委譲するなら `general-purpose` サブエージェント (WebFetch/WebSearch が要る)。直したら `reviewed_at` を当日に更新する。中身を見ずに日付だけ進めるのは禁止 (SHA の無言 bump と同じ)。見直した結果「変更不要」なら、その判断理由を commit message に書いて日付を進める。

6. **集約と確認** — 更新したファイル一覧と各 3 行要約を提示する。`bash "$SELF/scripts/check-freshness.sh" --offline` を再実行し、exit 0 に戻ったことを確認する。ここまでの変更は作業ツリーに残す。

7. **commit (ユーザーが望むときのみ)** — 変更内容と、各リポジトリの差分 3 行要約を含む commit message 案を提示して承認を得てから commit する。**SHA だけの無言 bump をしない** (内容への影響なしと判断して SHA だけ進める場合も、その理由を message に書く)。承認がなければ diff を残して終了。個人リポジトリなので main への直接 commit でよい。

## Gotchas

- サブエージェントは当日日付を知らない → 手順0の `date +%F` を必ずプロンプトに埋める (`distilled_at` の正確性)。
- BEHIND を pull してから STALE を再評価する。順序を逆にすると古い HEAD で蒸留してしまう。
- 出力先は symlink 越しでなく `readlink -f` で解決した実体パスを使う。蒸留版が属するスキルは repo ごとに違う (`harness-design` / `ui-design`) ので、STALE 行のパスをそのまま使い、`harness-design` 決め打ちにしない。
- `check-freshness.sh` に repo 絞り込みはない → 特定 repo 指定時は全走査の出力からフィルタする。
- 再蒸留は必ず `DISTILLING.md` の構成規約をプロンプトに渡す (250 行以内 / 索引駆動 / 推測で書かない)。規約をサブエージェントの記憶任せにしない。
- `REVIEW` は SHA 差分が無いので「何が変わったか」を機械的に出せない。出典の生存と、記述が前提にしているモデル世代・流行の変化を人手 (または Web 検索できるサブエージェント) で確認する。
- 新規リポジトリの追加は別作業 (`DISTILLING.md`「新規リポジトリの追加」)。このスキルは既存蒸留版の更新に使う。

## Quick checklist

- [ ] `date +%F` を控え、サブエージェントに `distilled_at` として渡した
- [ ] `MISS`/`ERR` を先に解消した (clone 未取得なら `install.sh --with-references`)
- [ ] BEHIND を `git pull --ff-only` してから STALE を再評価した
- [ ] 各再蒸留が `DISTILLING.md` の規約 (frontmatter 3 キー / 250 行以内 / 推測で書かない) に従った
- [ ] `distilled_commit` を clone の新 HEAD に、`distilled_at` を当日に更新した
- [ ] `REVIEW` は出典と前提の生存を確認したうえで `reviewed_at` を進めた (日付だけの bump をしていない)
- [ ] `check-freshness.sh` が exit 0 に戻った
- [ ] commit する場合、message に差分 3 行要約を含めた (SHA だけの無言 bump をしない)
