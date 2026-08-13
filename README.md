# claude-harness

Claude Code の個人グローバル設定 — スキルと CLAUDE.md の常時ルール — をここで一元管理する。`install.sh` を叩けば、どのマシンの `~/.claude` にも同じ状態が組み上がる。

<img src="assets/architecture.svg" alt="claude-harness の全体像" width="100%">

## 収録スキル

| スキル | 用途 | 起動 |
|---|---|---|
| `harness-design` | LLM ハーネス・プロンプト設計の参照資料集 (原典 8 本)。蒸留版 → 原典 clone の 2 層で読む。追従しない資料から採った手法は `PATTERNS.md` | 自動 |
| `ui-design` | UI 生成のデザイン参照資料集 (原典 3 本: DESIGN.md 雛形 / アンチスロップ規律 / デザイントークン仕様)。同じ 2 層 | 自動 |
| `avoid-ai-slop-ja` | 日本語文章から AI 臭 (slop) を除くレビュー・リライトの手法 | 自動 |
| `avoid-ai-slop-design` | Web UI・スライド・図解・生成画像の AI 臭検出カタログと処方 (計測研究・学術ソースの出典付き) | 自動 |
| `claude-harness-refs-update` | 参照資料 (蒸留版と原典 clone) の鮮度チェックと再蒸留。更新機構の所有者 | `/claude-harness-refs-update` |

「自動」はスキルの `description` に合致した作業で Claude Code が自分で読み込む。更新スキルだけは明示起動専用 (`disable-model-invocation`)。

## 導入

前提は git・bash・Claude Code。

```bash
git clone https://github.com/ystk-kai/claude-harness.git ~/claude-harness
~/claude-harness/install.sh --with-references
```

`--with-references` を外すと原典 clone (合計数百 MB) を取らない。蒸留版だけでも参照スキルは動くが、索引から原典の該当ファイルを読む経路が使えなくなる。`~/.claude` 以外に展開する環境は `CLAUDE_CONFIG_DIR` を設定して実行する。

### Claude Code に任せる

新しい環境の Claude Code に次を貼ると、clone から検証まで実行してくれる。

```text
https://github.com/ystk-kai/claude-harness を ~/claude-harness に clone し、
~/claude-harness/install.sh --with-references を実行してください。
完了後に次の 3 点を検証して結果を報告してください:
1. ~/claude-harness/skills/ の各ディレクトリに対応する symlink が ~/.claude/skills/ にあること
2. ~/.claude/CLAUDE.md に claude-md/ の各ファイルに対応する managed ブロックがあること
3. bash ~/claude-harness/skills/claude-harness-refs-update/scripts/check-freshness.sh --offline
   が exit 0 を返すこと (exit 1 なら行頭タグごとに何が要対応か報告する)
```

## 仕組み

管理対象は 3 種類 + 任意の 1 種。

- `skills/<name>/` — スキル本体 (SKILL.md + 必要に応じて references/・scripts/、スキル固有の補助文書。実例: `harness-design/PATTERNS.md`、`claude-harness-refs-update/DISTILLING.md`)
- `claude-md/<name>.md` — グローバル CLAUDE.md に常時挿入するルール
- `settings/global.json` (任意) — `~/.claude/settings.json` にキー単位でマージする設定。**この repo は payload を同梱しない** (有効プラグインや marketplace の一覧は個人環境の情報なので公開しない)。必要な環境でローカルに置くと機構が働く
- `install.sh` — 冪等な展開スクリプト。何度実行しても同じ状態に収束する

`install.sh` は 4 つのことをする (3 は `settings/global.json` を置いた環境だけ)。

1. **skills を symlink する** — `skills/*/` を `~/.claude/skills/<name>` へ張る。symlink でない実体が既にある場合は上書きせず、警告してスキップする (手動で退避してから再実行)
2. **CLAUDE.md にルールを差し込む** — `claude-md/*.md` を `<!-- BEGIN managed:<name> -->` 〜 `<!-- END managed:<name> -->` で囲んで `~/.claude/CLAUDE.md` へ。既存の同名ブロックは位置を問わず取り除き、ファイル末尾に貼り直す。手書き部分は触らない
3. **settings.json にキーをマージする** — `settings/global.json` に書いたキーだけを `~/.claude/settings.json` へ入れる。`extraKnownMarketplaces` と `enabledPlugins` はキー単位のマージ (既存の他キーは残る)、`hooks` はこの repo の `hooks/` を指す handler だけを剥がしてから貼り直す (再実行しても重複しない。現在この repo は hook を収録していないので、過去に入れた分の掃除だけが働く)。`{{REPO_DIR}}` は絶対パスへ置換される。内容が変わるときだけ書き、直前の内容を `settings.json.pre-claude-harness.bak` に残す (ユーザー自身の `.bak` を潰さないため専用の接尾辞を使う)。`jq` が無い環境ではこの手順だけスキップする。壊れた JSON やトップレベルが object でない `settings.json` は、生の jq エラーになる前に中断する
4. **原典を clone する (`--with-references` 指定時のみ)** — 各スキルの `references/*.md` の frontmatter にある `source` URL を `~/.claude/references/<repo>/` へ `git clone --filter=blob:none` で取得する。blob は必要時取得だが履歴は完全なので、鮮度チェックの差分表示がそのまま動く

`--with-references` は第 1 引数のときだけ効く (`install.sh --foo --with-references` は無視される)。clone 済みのディレクトリは再取得しない — 原典の更新は `/claude-harness-refs-update` の仕事。

`--with-references` の実行ごとに、clone 済みのものも含めて `.claude/skills` を worktree から外す (sparse-checkout)。原典を置いただけで第三者のスキルがディレクトリスコープで自動登録されるのを防ぐため。中身が必要なら `git -C <clone> show HEAD:.claude/skills/...` で読める。`.claude/{agents,commands,hooks,settings.json,rules}` は入れ子では自動ロードされないので残してあり、実例として読める。

スキル本体は symlink なので、内容の変更は `git pull` だけで全環境に反映される。`install.sh` の再実行が要るのは、スキルを追加・改名したときと `claude-md/` を変えたときだけ。

### 管理しないもの

`~/.claude` を丸ごと再現するツールではない。意図的に対象外にしているもの:

- **`permissions` と sandbox 系の settings** — 環境ごとに違ってよく、repo が上書きすると権限昇格の事故につながる。`permissions.defaultMode` のような user スコープ限定キーはとくに手で管理する
- **`effortLevel` / `theme` / `tui` などの個人設定** — マシンごとに変えたいもの
- **`~/.claude/agents/` `~/.claude/memory/` `~/.claude/tasks/`** — 個人状態、またはプロジェクト横断の調整に使うもの
- **この repo が置いていないスキル** — `~/.claude/skills/` に実体で置いたスキルや、plugin marketplace 由来のスキルは触らない
- **有効プラグインと marketplace の一覧** — 個人環境の情報なので公開 repo に載せない。`settings/global.json` をローカルに置けば機構は使えるが、この repo は同梱しない

つまり新しいマシンで復元されるのは `skills/` と `claude-md/` だけ。それ以外は手で揃える。

## 参照資料の 2 層構成

原典リポジトリの実体はこのツリーに含めず、蒸留版 frontmatter の `source` URL から clone して復元する。

- **蒸留版** — `skills/{harness-design,ui-design}/references/*.md`。要点と索引を 250 行以内にまとめたもの。`source` が repo リストの唯一の正、`distilled_commit` が蒸留時点の原典 SHA
- **原典** — `~/.claude/references/<repo>/`。全文。蒸留版と食い違ったら原典が正
- **更新機構** — `skills/claude-harness-refs-update/` が一元所有する。`scripts/check-freshness.sh` が検出、`DISTILLING.md` が構成規約と再蒸留の手順、`scripts/frontmatter.sh` は `install.sh` と共用のパーサ

鮮度チェックは `bash skills/claude-harness-refs-update/scripts/check-freshness.sh`。1 ファイル 1 行で、行頭タグが次にやることを示す — `BEHIND` (clone を pull)、`STALE` (蒸留版を再蒸留)、`REVIEW` (出所 clone を持たない知識ベースの棚卸し期限切れ)、`OK`、`MISS` / `ERR` / `NOTE`。要対応があれば exit 1。`--offline` で fetch を省略できる。BEHIND と STALE が同時に立つ repo は pull が先なので `BEHIND` 行だけが出る。

`skills/*/references/*.md` の frontmatter は 3 形式のいずれかを取り、**どれでもないものは `ERR`** になる。frontmatter が無いだけで無言に対象外にはしない — 「意図的な非追従」と「壊れた蒸留版」が区別できなくなるため。

| 形式 | キー | 用途 |
|---|---|---|
| 蒸留版 | `source` + `distilled_commit` + `distilled_at` | 原典 clone を SHA で追従する |
| 知識ベース | `tracking: review` + `reviewed_at` + `review_interval_days` | 出所 clone を持たない自作の調査資料 (`avoid-ai-slop-*` の references) |
| 対象外 | `tracking: none` | 鮮度管理しないと明示するもの |

チェックから更新まで一括で回すなら `/claude-harness-refs-update` — 鮮度チェック → BEHIND の `git pull` → STALE の再蒸留 → REVIEW の棚卸しを順に実行する。`--check` でチェックのみ、repo 名を渡すとその repo だけを対象にする。更新の入口はこのコマンド 1 つに集約してある。

参照リポジトリを増やすときは、蒸留版を `skills/<skill>/references/<clone ディレクトリ名>.md` として 1 ファイル作り、そのスキルの SKILL.md の表に行を足す。`check-freshness.sh` と `install.sh` はどちらも `skills/*/references/*.md` をスキル横断で走査するので、置き場所が合っていれば自動で対象になる。詳しい規約は [DISTILLING.md](skills/claude-harness-refs-update/DISTILLING.md)。

### 追従しない資料から手法だけ採る

継続追従するほどではない資料 (探索索引の先・記事・製品リポジトリ) にも、単発で使える手法はある。この場合は蒸留版も原典 clone も作らず、[skills/harness-design/PATTERNS.md](skills/harness-design/PATTERNS.md) に 1 項目 = 1 手法 + 出所 1 行で足す。資料本体は追わない。

採録ゲート 5 条件 (既存蒸留版と非重複 / 実読確認 / 転用可能 / 出所明記 / 蒸留版を作るほどではない) と退出規約 (公式資料や蒸留版に同等以上の記述が現れたら削除して蒸留版へ寄せる) は同ファイルが自己所有する。`references/` の外に置いてあるため `check-freshness.sh` と `install.sh` の走査対象外で、鮮度管理の対象にもならない。

## スキルを増やす・外す

増やすとき:

1. `skills/<name>/SKILL.md` を書く (Agent Skills 標準の構成: SKILL.md + 必要に応じて references/・scripts/)。memory などの外部状態に依存させず `references/` で自己完結させる。外部依存が避けられない場合は frontmatter の `compatibility` に書く
2. 常時ルール化したいスキルだけ `claude-md/<name>.md` を足す
3. `install.sh` を再実行する

外すとき・改名するときは手動の掃除が要る。`install.sh` は消えたスキルの symlink も、消えた `claude-md/` の managed ブロックも刈らない。`rm ~/.claude/skills/<旧名>` と CLAUDE.md の該当ブロック削除を自分でやってから再実行する (改名後の残骸は dangling symlink になる)。

## 設計メモ: 原典 clone をスキルディレクトリ内に置かない理由

[Agent Skills 標準](https://agentskills.io/specification) の `references/` は、そのスキルのために書かれた focused な文書を置く場所と定義されている。一方ここで扱う原典は外部リポジトリの丸ごと clone (数百 MB・第三者ライセンス・`git pull` で独立に更新) で、性質が違う。そのため:

- 外部 clone (生データ) は共有コーパスとして `~/.claude/references/` に外出しする。スキル配布時に第三者リポジトリを同梱せずに済み、CLAUDE.md ルールや他スキルからも共有できる
- スキル外パスへの依存は SKILL.md の `compatibility` フィールド (標準仕様の宣言用フィールド) で明示する
- 自作の蒸留資料は標準どおり `skills/<skill>/references/` に置き、SKILL.md から 1 階層でリンクする。通常の参照は蒸留版で完結させ、原典の全文走査による入力トークンの肥大化を避ける
- 原典と 1:1 対応しない自作文書 (`PATTERNS.md` 等) は `references/` に入れずスキル直下に置く。`harness-design/references/` を蒸留版だけの場所に保ち、「frontmatter の `source` が repo リストの唯一の正」という規約を崩さないため。走査スクリプトは `source` 無しのファイルを無言で飛ばすので技術的には同居できるが、置くと人間側の読み分けが曖昧になる
