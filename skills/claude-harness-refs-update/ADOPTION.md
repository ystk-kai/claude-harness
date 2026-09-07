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
- **環境固有・機密の値を書かない。** この repo は公開されている。アカウント ID・ホスト名・IP・バケット名・
  ユーザー名・社内組織名や、permission / soft_deny ルールの具体的な中身は台帳に載せない。書くのは
  「どの設計上の判断が要るか」までで、値は環境側 (`~/.claude/`) に置く。影響対象を示すのに具体値が
  必要になったら、それは台帳ではなく環境側に書くべき項目

---

## 2026-09-07

### awesome-harness-engineering 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | RECOMMENDED | 運用 / skill | 記憶・参照資料の失効を**主張単位**で検出する型 (OpenWiki self-correcting memory) — 各 claim をバージョン付きの根拠と紐づけ、根拠が動いた claim だけを stale として旗立て、再検証まで「不確か」を持続させる。grep 済: `check-freshness.sh` の判定は形式 1 が clone HEAD と `distilled_commit` の SHA 比較、形式 2 が `reviewed_at` の経過日数だけで、いずれも**ファイル単位**。蒸留版の個々の主張と原典パスの対応が切れても検出されない (原典側でファイルが移動・削除されても STALE は「差分がある」としか言わない)。索引テーブルの原典パス生存チェックを足すのが最小の一歩 | ahe: `README.md` `Memory & State` 節 (`0a10903`)、<https://www.langchain.com/blog/self-correcting-memory-openwiki> |
| 未対応 | FYI | CLAUDE.md / skill / subagent / hook / settings | `lintsinghua/claude-code-book` — Claude Code ハーネス内部の teardown (15 章 139 図)。tool system・**4 段階の permission pipeline**・context compaction・memory・hooks・subagent スケジューリング・MCP・skills・streaming・plan mode を設計判断の *why* 付きで扱う。permission や hook の設計根拠を調べるときの当たり先候補。第三者の teardown なので挙動の確定には公式 docs を優先する。grep 済: この repo に permission pipeline の記述は無い | ahe: `README.md` `Tutorials & Educational` 節 (`adfc01b`) |

### claude-code-best-practice 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | RECOMMENDED | 運用 | `/skill-doctor` で「ロード済みだが未使用の skill」と「skill ごとの context コスト」を出せる。grep 済: 環境側 12 skill + この repo 5 skill が常時ロードされており剪定判断の材料になるが、台帳にも repo にも `/skill-doctor` の記述は無い。`/skills` 画面の `t` キーで token 数ソートも可。要件は **v2.1.252 以降 + feature-flag fetching** (原典が 09-06 に v2.1.261 から訂正したので古い数字を持たない) | ccbp: `best-practice/claude-commands.md` #50、`changelog/best-practice/claude-commands/changelog.md` 2026-09-05 / 09-06 (`70481a1`, `80b755c`) |
| 未対応 | FYI | 運用 | 原典 README の DEVELOPMENT WORKFLOWS 表の agent / command / skill 個数とステップ列は run ごとに揺れ、09-05 の run は 8 リポジトリ分の変更提案を**全件 ON HOLD** で据え置いた。他リポジトリのワークフロー構成をこの表から引用してハーネス設計の根拠にしない (二次資料の 1 run 判定を確定と見なさない規律の追加実例) | ccbp: `changelog/development-workflows/changelog.md` 2026-09-05 (#10〜#21) |

---
## 2026-09-05

### skills (anthropics/skills) 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | RECOMMENDED | skill | 公式 frontend-design の AI っぽさ tell クラスタが 3 → 5 に増え、既存の tell リストに**無い**項目が出た: **template chrome** (中黒つなぎの meta 文字列、`WORD — fragment`、`#0B0B0B`/`#111` の擬似黒、リンク末尾の `→`)、`#D97757` を「Anthropic 自身の accent なので tell」と名指し、typography 既定禁止 3 項目 (見出し中 1 語だけのアクセント / ラベルの全大文字 / 不要な typographic ラベル)、行長 80 字未満。grep 済: eyebrow・ALL-CAPS・カード kit の同一 radius/shadow (`opacity 0.1`) は `avoid-ai-slop-design/references/web-ui.md` に既出だが、上記は未収載。`ui-design` / `avoid-ai-slop-design` の次の棚卸しで差分を足す | skills: `skills/frontend-design/SKILL.md` (`41bbe19`) |
| 未対応 | RECOMMENDED | 運用 | モデル移行後に prompt を据え置くと**精度でなくコストで効く** (Opus 4.8 向け prompt を Opus 5 で回すと ticket あたり +36%、精度は不変。監査後は未監査比 -14% かつ正答 92%→97%)。モデルを上げたら `prompt-audit` を走らせる運用にする | skills: `skills/claude-api/shared/cost-optimization.md` § 2.2 |
| 未対応 | FYI | CLAUDE.md | 「hold all findings for the final response」「don't narrate」型の update suppressor と、「never use bullets」「no headers」「no bold」型の anti-formatting rule は over-narrate / over-format する旧モデル向けで、現行モデル (特に Fable 5.1) では逆に *under*-narrate / *under*-format を招く。`~/.claude/CLAUDE.md`・`claude-md/`・各 `SKILL.md` を grep したが該当表現は無く実害なし。今後この型の指示を書かない指針として持つ | skills: `skills/claude-api/shared/prompt-audit.md` Group 1d (`5304866`) |
| 未対応 | FYI | hook | 数ターンごとに「reminder: ...」を履歴へ差し込み次リクエストで取り除く実装は二重に有害 — 現行モデルは 1 回で保持し、かつ preserved thinking では**取り除くこと自体が history edit** で cache が miss し以降の thinking block が無効化される。残すなら `role: "system"` + `clear_at: "next_user_message"` を毎ターン append し過去分を消さない。この repo と環境側に hook 定義は無い (grep 済) | skills: `shared/prompt-audit.md` Group 1d、`shared/prompt-caching.md` |
| 未対応 | FYI | skill / MCP | progressive disclosure の閾値が数値化された — tool schema は**合計 ~10K token を超えてはじめて `defer_loading` が黒字**で、それ未満は検索ステップが純オーバーヘッド。「取りに行くターン」が増えて逆に高くつく場合があるので eval で検証する条件付き | skills: `shared/cost-optimization.md` § 2.2 と "Workload shape -> lever" 表 |
| 未対応 | FYI | subagent | subagent は「自己完結する重い中間結果を吸収して 1 行返す」ステップに使う。判断側がその中間文脈を要るなら使わない。**subagent は親と cache を共有しない新規 prefix** になる。context editing は節約レバーではなく context-window ツール (クリアのたびに cache を壊す)、`max_tokens` は backstop であってチューニングノブではない | skills: `shared/cost-optimization.md` § 2.3 / § 2.4 |
| 未対応 | FYI | 運用 | Managed Agents のリポジトリ skill 発見は **cloud sandbox 限定** (self-hosted sandbox は `github_repository` 非対応)、agent 1 つに attach できる skill は**最大 20** | skills: `shared/managed-agents-tools.md` |

### claude-code-best-practice 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | RECOMMENDED | settings | `/effort` は v2.1.243 から**モデル別に `modelSettings` へ保存**するようになり、トップレベル `effortLevel` は「`modelSettings` にエントリの無いモデルの fallback」へ降格した。環境側 `settings.json` に `effortLevel` が実在する (grep 済) ので**この repo で唯一実ハーネスに当たる項目**。no-op ではないが、モデルごとに既定 effort を固定したいなら `modelSettings` 側に書く。あわせて `modelSettings` / `modelPicker` は**マージ例外**で、最上位スコープのファイルが値全体を供給する (下位からの追記が消える) | ccbp: `best-practice/claude-settings.md` Model Overrides 表・Scope precedence 節、同 changelog 2026-09-01 項目 4・5・7 |
| 未対応 | RECOMMENDED | 運用 | 公式の settings キー索引が **`docs/en/settings-reference` に移動**した (`docs/en/settings` は task 指向ガイドに再編されキー索引を持たない)。settings を調べるときの当たり先を変える | ccbp: `best-practice/claude-settings.md` Sources 節、同 changelog 2026-09-01 項目 2 |
| 未対応 | FYI | settings / subagent | `CLAUDE_CODE_SUBAGENT_MODEL` は v2.1.238 で **override から「既定値」に変わった** (agent 定義の `model:` や呼び出し時の明示指定に負ける)。`teammateDefaultModel` は **v2.1.251 で削除**され残すと no-op (teammate はリードのモデルを継承)。環境側 `settings.json` と repo をいずれも grep したが未使用で該当なし | ccbp: `best-practice/claude-settings.md`、同 changelog 2026-09-01 項目 6・12 |
| 未対応 | FYI | skill | `skillOverrides` の運用注意 — **plugin skill / `disable-model-invocation: true` の skill / managed `skillOverrides` エントリを持つ skill は `/skills` 画面から可視性を切り替えられない**。この repo では `claude-harness-refs-update` が該当する (明示起動専用の設計なので意図どおり)。ユーザーの手動 toggle を前提にした skill 設計をしない、の根拠として持つ | ccbp: `best-practice/claude-commands.md` `/skills` 行、同 changelog 2026-09-02 項目 2 |
| 未対応 | FYI | hook | hook イベントが **26 → 28** になり v2.1.252 で `PreModelSwitch` / `PostModelSwitch` が追加された (2026-08-31 台帳の「公式 changelog の孫引き」項目が原典表に反映された形)。この repo と環境側に hook 定義は無い (grep 済) | ccbp: `best-practice/claude-settings.md` hooks リダイレクト節、同 changelog 2026-09-01 項目 13 |
| 未対応 | FYI | settings | 凍結していた `claude-settings.md` が v2.1.224 → v2.1.252 に追いつき、新設キーが本文に載った: `crossSessionInbound` (`accept`/`hold`/`refuse`。**より厳しい値なら project/local が managed に勝つ**非対称ルールの新実例)、`dialogExpiry`、`autoContinueAtUsageLimit`、`feedbackDrafts` (`SendFeedback` の gate)、`desktopSessionCleanupPeriodDays`、`promptCacheTtl` / `subagentPromptCacheTtl`、`keybindingFlavor`、`spellcheck`、`disableCommandPluginSources` (managed のみ)、marketplace source type `command` (+`mode: "link"`)、sandbox credentials の JWT/AWS マスキング。2026-08-27 台帳の「未反映の新キー」項目はこれで解消 | ccbp: `best-practice/claude-settings.md`、同 changelog 2026-09-01 項目 3・4・8・9・10 |
| 未対応 | FYI | 運用 | slash command の前提条件が明文化: `/subtask` は **v2.1.212+ かつ agent view 有効時限定**、`/desktop` は macOS または **x64** Windows + サブスクリプション必須、`/review` は引数が `/code-review` と同じ完全形になりレベル省略時は**前回のレベルを再利用**。`/usage-credits` の `DISABLE_EXTRA_USAGE_COMMAND=1` は公式 docs から消えたため、2026-08 蒸留に載せていた記述を撤回 | ccbp: `best-practice/claude-commands.md` #61/#66/#91、同 changelog 2026-09-02 項目 1・3 / 2026-09-04 項目 1・2 |
| 未対応 | FYI | 運用 | 前回台帳の watch item の現況: `experimental.cacheTtl` (subagent frontmatter) と `claude` built-in agent は 09-04 時点でも **ON HOLD のまま**で公式表に未反映 → 確定情報として使わない。`fork` agent type は 08-31 に drift 表から消えて以降 09 月の run にも復活せず**判断保留のまま**。2026-09-01 台帳の `fork` 項目 (5 回目の変転) をこれで更新する | ccbp: `changelog/best-practice/claude-subagents/changelog.md`、`changelog/best-practice/claude-commands/changelog.md` |

### claude-cookbooks 再蒸留から

原典側では BREAKING / RECOMMENDED として上がったが、**このハーネスには permission ルールも hook も Agent SDK コードも無い** (`~/.claude/settings.json` に `permissions` / `hooks` キーが両方とも存在しないことを確認済) ため、全件 `FYI` に落とす。

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | FYI | settings | permission のパスルールを絶対パスで書くとき、**スラッシュ 1 個で始めると設定ソース基準で解決されて何にもマッチしない** (`dontAsk` 下では全 read が拒否される)。正しい形はスラッシュ 2 個。環境側 `settings.json` に permission ルール自体が無いので現時点の該当なし。将来 allowlist を書くときの必須知識 | cookbooks: `claude_agent_sdk/scheduled_repository_reviewer/scheduled_repository_reviewer.ipynb` code cell 12 |
| 未対応 | FYI | hook | `allowed_tools` の `Read(...)` ルールは `Grep` / `Glob` へ **best-effort にしか適用されない**。read を repo 内に閉じ込めたいなら `PreToolUse` hook で symlink 解決後のパス検査と、`/`・`~` 始まり / `..` を含む / `{` を含む glob の deny を重ねる | cookbooks: 同 notebook (MD 11)、`scheduled_review.py` |
| 未対応 | FYI | settings | 他人の repo を処理するエージェントには `setting_sources=[]` を設定する。マシン側設定を切るだけでなく**対象 repo 自身の `.claude/settings.json` と `CLAUDE.md` をセッションから外す** ("a repository you don't control should not configure its own reviewer")。あわせて `strict_mcp_config=True` で MCP tool 定義が全リクエストに載るのを防ぐ | cookbooks: 同 notebook (MD 11) |
| 未対応 | FYI | 運用 | `max_budget_usd` は「超過してから止まる」ので実費は cap を超えうる。bound 超過は `ResultError` (claude-agent-sdk **0.2.140 以降**の型) として raise される | cookbooks: 同 notebook (MD 11, Prerequisites) |
| 未対応 | FYI | 運用 | resume ベースの「前回を覚えている」エージェントは、継続が効いたかを**スキーマの required フィールド**で証明させる (前回 id と所見 id を echo させ、呼び出し側で突き合わせて行頭マーカーを出す)。resume したエージェントは前回読んだファイルの記憶で答えるので、プロンプト冒頭で「ファイル一覧を取り直せ」と明示する | cookbooks: 同 notebook (MD 9, MD 21) |
| 未対応 | FYI | 運用 | 旧モデル ID の一括置換表が原典にある。現行の正は `claude-sonnet-5` / `claude-haiku-4-5` / `claude-opus-4-8` で、`claude-opus-4-1` / `claude-opus-4-5` / `claude-sonnet-4-5` / `claude-sonnet-4-6` は retire 済み。Bedrock は新しめが suffix 無し、古いものだけ `-YYYYMMDD-v1:0` 付きの混在。repo と `~/.claude/` を grep したが retired ID の記載は無し | cookbooks: `26b5cdc`、`CLAUDE.md` 3 節、`scripts/validate_all_notebooks.py` の `deprecated_models` |

### awesome-harness-engineering 再蒸留から

差分 4 件はすべて curated list への新規リンク追加で、収載規約 (`CONTRIBUTING.md`)・repo 運用規約 (`AGENTS.md`)・`templates/*.md` に変更なし。既存の書き方を無効化する内容は含まれない。

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | FYI | 運用 | セキュリティ系エージェントハーネスの設計型 (4 フェーズ 11 ステージ) が公開された。読みどころは解析前の threat modeling で攻撃面を絞る / multi-agent の決定論的投票で false positive を抑える / adversarial validation を修正候補の採用ゲートにする / ハーネス水準の有効性指標に **Mean Time to Adapt** を置く | ahe: `4b2305d`、`README.md` の `Security, Sandbox & Permissions` |
| 未対応 | FYI | 運用 | 複数 agent runtime を跨ぐ運用の「harness fragmentation」に対し、統一 API 規約の裏で runtime を交換可能にする self-hosted router が登場。単一 CLI に縛られない運用を将来検討する場合の当たり先 | ahe: `1e5cbe1`、`README.md` の `Task Runners & Orchestration` |
| 未対応 | FYI | skill / hook | ワークフロー一式 (plan→test→implement→review→verify→remember→improve) を agent + skill + hook + memory の**インストール可能な配布物**として梱包する例と、同じ構成要素を zero-code で宣言的に生成するプラットフォームが追加された。自前 skill 群のパッケージ化・配布形態を考えるときの参照 | ahe: `cf8a1a3`, `43905de`、`README.md` の `Generators & Meta-Harnesses` |

---

## 2026-09-01

### claude-code-best-practice 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | FYI | skill | bundled alias が同名の自作 skill を完全に隠す — 公式 docs 引用 "typing the bundled alias `/review` never runs your skill"。skill 名を bundled skill / slash command と衝突させると起動経路を失う。この repo の 5 skill と環境側 12 skill を grep したが `review` 名は無く実害なし。新規 skill 命名時のチェック項目として持つ | ccbp: `changelog/best-practice/claude-skills/changelog.md` の 2026-08-31 entry (`e8f40e6`) |
| 未対応 | FYI | subagent | 原典 subagent 表の未反映 watch item が 3 件に増えた — `permissionMode` の `manual` (`default` の alias、v2.1.200+)、`model` 例の model 名 (公式は `claude-opus-5`、原典は `claude-opus-4-6` のままで `fable` 未記載)、`prompt` フィールド (公式では `--agents` CLI JSON にしか存在せず frontmatter 表には無い)。この repo は subagent 定義ファイルも追跡対象の `settings.json` も持たない (grep 済) ので影響なし。subagent を書く場面では原典の表を正としない | ccbp: `best-practice/claude-subagents.md` と同 changelog の 2026-08-31 entry |
| 未対応 | FYI | 運用 | `fork` agent type が 08-31 の subagents drift 表から**行ごと消えた** (08-20 INVALID → 08-24 再オープン → 08-27 再 INVALID → 08-30 ON HOLD に続く 5 回目の変転)。台帳の既存 `fork` 項目 (2026-08-31 / 08-26 分) の「ON HOLD」記述もこれで更新する。二次資料の 1 run 判定を確定と見なさない規律の実例として累積 | ccbp: `changelog/best-practice/claude-subagents/changelog.md` の 2026-08-31 entry |

---

## 2026-08-31

### claude-code-best-practice / claude-cookbooks 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | FYI | subagent | subagent frontmatter に `experimental` (object 任意。`cacheTtl` に `5m` / `1h` を置き prompt cache の寿命を指定。subagent ファイルからのみ読まれる、v2.1.248) が drift check で検出された。環境側に長寿命の subagent 定義が 8 件あるので当たりうるが (grep 上いずれも未使用)、**原典自身が ON HOLD で表に未反映**のため確定事実として使えない。採用前に公式 docs で裏を取る | ccbp: `changelog/best-practice/claude-subagents/changelog.md` の 2026-08-29 / 08-30 entry |
| 未対応 | FYI | hook | v2.1.251 で `PreModelSwitch` / `PostModelSwitch` hook が追加されたと CONCEPTS drift ログが記録。モデル切替時に決定的処理を挟む設計の候補だが、凍結した `claude-settings.md` (v2.1.224) には未収録で原典の記述も公式 changelog の孫引き。環境側 `settings.json` の hooks にも未使用 (grep 済) | ccbp: `changelog/best-practice/concepts/changelog.md` 2026-08-30 entry の verification 行 |
| 未対応 | FYI | skill | `workflow-authoring` が bundled skill (row 16) として確定。dynamic workflows 有効環境では workflow スクリプト作成用の参照 skill が既に載っているので、同等の自作 skill を足す前に重複を確認する。この repo と環境側の skills には同種のものは無い (grep 済) ので現時点の対応は不要 | ccbp: `best-practice/claude-skills.md` row 16, `changelog/best-practice/claude-skills/changelog.md` 2026-08-29 |
| 未対応 | FYI | 運用 | 原典の ON HOLD は「否定」ではない、の実例が増えた。Voice Dictation (06-25 起票) と Artifacts (07-03 起票) の beta バッジは 1〜2 か月 ON HOLD ののち 08-29 に confidence 0.95 で削除確定。逆に `workflow-authoring` は 08-28 INVALID → 08-29 COMPLETE、`fork` agent type は 4 回目の判定反転。「二次資料の 1 run 判定でハーネスを直さない」既存方針の追加裏付け | ccbp: 上記 3 changelog の 2026-08-28〜30 entry |
| 未対応 | FYI | 運用 | Anthropic 公式が「コーディネータ + 安価な並列ワーカー」の**コスト優位の断言と比率 (約 2.5 倍安・3 倍速) を撤回**した。残るのは「チームの入力トークンの 84-98% がワーカー単価で課金される」という構造だけで、比率は run ごとの 1 サンプル扱い。オーケストレーション構成をコスト理由で正当化するときは、比率ではなく rigor を揃えた実測を根拠にする。この repo にコスト優位を前提とした記述は無い (grep 済) | cookbooks: `bbfab1b`, `managed_agents/CMA_plan_big_execute_small.ipynb` |

---

## 2026-08-27

### awesome-harness-engineering / claude-code-best-practice 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 未対応 | RECOMMENDED | settings | `/permissions` に v2.1.246 で **Auto mode タブ**が付き、classifier ルールの閲覧・編集と auto mode 拒否履歴の確認が UI からできるようになった。`permissions.defaultMode: "auto"` を使う環境では、手書きした `autoMode.soft_deny` が実際に発火しているかを確認する手段がこれまで無かった。拒否履歴で実効性を測り、空振りしているルールを畳める。**個々のルールの内容は環境固有なのでこの台帳には書かない** (公開リポジトリ) | ccbp: `best-practice/claude-commands.md` row 13 `/permissions`, commit `9640e8a` |
| 未対応 | FYI | 運用 | Codex CLI (<https://github.com/openai/codex>) が `Demo Harnesses` に追加。OpenAI 公式の agent loop (sandbox 化された tool 実行・複数ファイル編集・streaming loop) の OSS 参照実装として位置づけられている。環境側に置いている codex 呼び出しの回避策は `codex-companion.mjs` の引数渡しという**プラグイン側の実装都合**に対するものなので、この upstream は直接の解決にはならない。恒久対処 (argv/stdin 経由への修正) を検討するときの一次ソース候補 | ahe: `README.md` の `### Demo Harnesses`, commit `9925eb4` |
| 未対応 | FYI | 運用 | 自己改良ハーネスの設計軸 — Exo (<https://github.com/exoharness/exo>) は prompt / memory / tool / policy を agent 自身に編集させるが、**immutable event log だけは書き換えられない**ことで recursive self-improvement を安全側に留める。ハーネス自身に `CLAUDE.md` や skill を書き換えさせる運用を組むなら「唯一の書き換え不能な土台」を先に決める。中身は未検証 (README の注記ベース) | ahe: `README.md` の `### Generators & Meta-Harnesses`, commit `6a14670` |
| 未対応 | FYI | settings | 凍結した `claude-settings.md` (v2.1.224 止まり、v2.1.247 に対し 23 版遅れ) に無い新キーの実例が増えた: `modelPicker`・`promptCacheTtl`・`keybindingFlavor`・`spellcheck`・`ANTHROPIC_DEFAULT_MODEL` (v2.1.246)、`spinnerTipsOverride` (v2.1.247、同版で `SendFeedback` ツールと `/claude-api cost-optimize` も追加)。`~/.claude/settings*.json` と `claude-harness` を grep したがいずれも未使用 — settings を触るときは同レポートを正としない、の裏付けとして持つだけ | ccbp: `changelog/best-practice/concepts/changelog.md` の 2026-08-26 / 08-27 entry #13 |
| 未対応 | FYI | 運用 | `fork` agent type の判定が **3 回反転**した (08-20 INVALID → 08-24 v2.1.241 docs で確認・再オープン → 08-27「docs は 6 agent、fork 不在」で再 INVALID)。2026-08-26 の台帳項目「再オープンされた」も撤回する。二次資料の 1 run 判定を確定と見なさない規律の追加実例。`claude-harness` 内の `fork` 参照は蒸留版と本台帳だけ (grep 済) で実害なし | ccbp: `changelog/best-practice/claude-subagents/changelog.md` の 2026-08-27 entry |

---

## 2026-08-26

### awesome-harness-engineering / claude-code-best-practice / skills 再蒸留から

| 状態 | 深刻度 | 対象 | 内容 | 根拠 |
|---|---|---|---|---|
| 一部対応 (2026-08-28。環境ローカルの `~/.claude/hooks/` に guard スクリプトを作成・テスト済だが、`settings.json` への登録は auto mode classifier にブロックされ未完了。対象は特定プラグインの引数渡しの不具合への回避策で、この repo の収録物ではないため `hooks/` にも `settings/global.json` にも載せない) | RECOMMENDED | hook | 自然言語の禁止事項は built-in control に写像しない限り guardrail にならない (公開 `CLAUDE.md` 481 件で裏打ちがあるのは約 4%)。この repo が所有する hook は現時点でゼロなので、対象になるのは環境ローカルの `~/.claude/CLAUDE.md` に散文で書かれた規約。**どの規約が該当するかは環境固有なのでこの台帳には書かない** (公開リポジトリ)。原則だけ残す — 散文の禁止事項は `PreToolUse` の block に写すか、写さないと決めた理由を書く | ahe: `82736a9`, README `Permissions & Authorization` の <https://arxiv.org/abs/2608.23550> |
| 未対応 | FYI | skill | 手順書型 skill では「機械的に自分で直す項目」と「user が決める項目」を行頭マーカーで分離し、末尾の Checklist / Report 節でも同じマーカーで再掲する型 (`[BREAKS]` / `[DECIDE]`)。値が確定できないものは推測で書かず report に列挙させる。この repo では `claude-harness-refs-update` が同じ分離を構造として持ち (再蒸留 = 機械的 / 取り込み候補 = user 判断、深刻度 3 値も本台帳にある) ので新規対応は不要。他の手順書 skill を足すときの型として使う | skills: `3b3fad9`, `skills/claude-api/python/claude-api/sdk-upgrade.md` |
| 未対応 | FYI | 運用 | 二次資料の 1 run 判定を確定と見なさない、の実例が増えた。`fork` agent type は 2026-08-20 に「公式 docs に無い = 誤検出」で INVALID にされた後、2026-08-24 に公式 docs (v2.1.241) で確認され再オープン。前回蒸留の「INVALID で決着」は撤回した。`/list-agents` も v2.1.239 で挙動が反転し、除外されていた agent-team のチームメイトが列挙対象に入った。どちらも `claude-harness` 内に参照はない (grep 済) ので実害なし | ccbp: `changelog/subagents/changelog.md` の 2026-08-24 entry, `05dd0ee` |

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
