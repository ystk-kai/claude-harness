---
source: https://github.com/anthropics/claude-cookbooks
distilled_commit: 93ea00c906248f67074a32d69cc3b560af020bf0
distilled_at: 2026-08-14
---

# claude-cookbooks 蒸留版

Anthropic 公式のクックブック集。`12-factor-agents` が原則なら、この repo は **その原則が動くコードになったもの (公式一次資料)**。
とくに `patterns/agents/` は "Building Effective Agents" (Erik Schluntz / Barry Zhang) の参照実装で、エージェント設計の骨格を最小コードで示す。
原典は `claude-cookbooks` の clone (原典ルートは SKILL.md 参照)。以下のパスはリポジトリルートからの相対パス。

## Contents

- まず押さえる
- 5 つのワークフローパターン
- マルチエージェント実装の要点 (async orchestration / research prompts)
- コンテキスト設計とエージェント eval
- コスト最適化レバーの優先順位
- ハーネス実装例の索引
- 12-factor-agents との食い違い
- 蒸留の範囲外

## まず押さえる

1. **制御フローは全部ふつうの Python 側にある**。`patterns/agents/util.py` は 45 行で、中身は `llm_call()` (単発 `messages.create`, `temperature=0.1`, `max_tokens=4096`) と `extract_xml()` (正規表現で `<tag>` を抜く) の 2 つだけ。フレームワークも tool-use API も使わず、for 文・dict・ThreadPoolExecutor で構造を作る。(`patterns/agents/util.py`)
2. **構造化出力は tool use ではなく XML タグで受けている**。5 パターン全てが `<analysis>` `<tasks>` `<evaluation>` `<feedback>` `<response>` を吐かせて `extract_xml` でパースする。tool 定義を持たない場所でも「構造化出力 + それを解釈する決定的コード」は成立する、という実演。(`patterns/agents/basic_workflows.ipynb`, `patterns/agents/orchestrator_workers.ipynb`)
3. **パターン選択は「サブタスクを事前に列挙できるか」で決まる**。列挙できる → `parallel()` (固定並列)。入力ごとに変わる → orchestrator-workers。原典の表現では "subtasks aren't pre-defined, but determined by the orchestrator based on the specific input"。(`patterns/agents/orchestrator_workers.ipynb`)
4. **orchestrator-workers を使わない条件が明記されている**: 単一出力の単純タスク (不要な複雑さ)、レイテンシがクリティカル、サブタスクが予測可能で事前定義できる (単純な並列化で足りる)。(`patterns/agents/orchestrator_workers.ipynb`)
5. **evaluator-optimizer の適合判定は 2 つのサイン**: フィードバックを与えると LLM の出力が実際に改善する / LLM 自身が意味のあるフィードバックを出せる。評価側プロンプトには "You should be evaluating only and not attemping to solve the task." を入れて役割を固定する。(`patterns/agents/evaluator_optimizer.ipynb`)
6. **サブエージェント数の実運用ガイドが数値で書かれている**: 単純 1、標準 2-3、中 3-5、高複雑度 5-10 (上限 20)、既定は 3。"Prefer fewer, more capable subagents over many overly narrow ones. More subagents = more overhead"。20 を超えそうなら分割設計そのものを見直す。(`patterns/agents/prompts/research_lead_agent.md`)
7. **サブエージェント側には「リサーチ予算」をツール呼び出し回数で渡す**: 単純タスクは 5 回未満、中で約 5 回、難で約 10 回、非常に難で最大 15 回。ハード上限 20 回 / 約 100 ソースで即 `complete_task`。上限をプロンプトに明記して暴走を止める。(`patterns/agents/prompts/research_subagent.md`)
8. **マルチエージェントのメッセージはポーリングさせない**。`Hub.drain()` の結果を **直近の tool result に追記する**設計で、メッセージが inline で届く。`wait_for_message` の description には「他にやることが無いときだけ使え」と書く。(`patterns/agents/async_multi_agent_orchestration.ipynb`)
9. **コンテキスト管理は 3 プリミティブを問題の種類で使い分ける**: compaction = トランスクリプト全体を要約 (lossy)、tool-result clearing = `tool_result` ブロックだけ差し替え (`tool_use` の記録は残す)、memory = ウィンドウ外へ退避してセッション間で持続。"start with the one that matches the bottleneck you're actually observing"。(`tool_use/context_engineering/context_engineering_tools.ipynb`)
10. **compaction のデフォルト要約プロンプトは task-agnostic なので、残すべきものを自分で指示する**。ベンチマークでは元の質問と回答フォーマット指示が消え、圧縮後のエージェントがユーザーに質問を言い直させて 0 点になる。カスタム `instructions` は「最も安い保険」。(`evals/agentic_search/reproduce_agentic_search_benchmarks.ipynb`)
11. **公開ベンチマークスコアの差は多くがハーネス設定の差**。"a handful of API parameters that don't matter for short conversations become load-bearing once an agent is running 30+ tool calls"。効く順に PTC (programmatic tool calling)、`effort` / `task_budget.total` / `thinking: adaptive`、compaction instructions、`pause_turn` の往復処理、`max_retries`。(`evals/agentic_search/reproduce_agentic_search_benchmarks.ipynb`)
12. **eval の grader は固定する**。採点対象は `<result>` タグの中身だけ (全文を渡すと false positive/negative が増える)、grader モデルは被験モデルに関係なく固定 (混ぜるとモデル間比較が壊れる)。(`evals/agentic_search/reproduce_agentic_search_benchmarks.ipynb`)
13. **サーバ側 tool の rate limit は例外を上げずに静かに劣化する**。API は 200 を返し、`too_many_requests` は response 内の tool result エラーとして現れる。原因不明の低スコアはトランスクリプト内の `rate_limit_error` を grep する。クライアント retry では直らないので並列度を下げる。(`evals/agentic_search/reproduce_agentic_search_benchmarks.ipynb`)
14. **~100 個を超える tool は前もって全部渡さない**。`tool_search` で必要な分だけ都度返す (コンテキスト 90% 超削減)、あるいは tool 名一覧を system prompt に置いて `describe_tool` でロードする。ロード前の tool はリクエストの `tools` に入れなくてよい。(`tool_use/tool_search_with_embeddings.ipynb`, `tool_use/tool_search_alternate_approaches.ipynb`)
15. **オーケストレーションの選択は「誰が計画を持つか」の 3 択**。single agent = Claude が turn ごとに決め中間結果は自分の context、subagents = リードが turn ごとに委譲し中間結果はリードの context、dynamic workflow = スクリプトが決め中間結果はスクリプト変数。workflow を取る条件は 3 つだけ ("bigger than one context window" / "verification enforced by structure" / "the orchestration itself is worth keeping")、それ以外は single agent で "Most tasks live here"。subagents は「4 件の委譲なら成立するが 400 件では成立しない」("fine for four delegations but not for four hundred") のと、中断すると計画ごと消えてやり直しになるのが限界。ランタイム側の上限は同時 16 agent (CPU コアが少ないと減る) / 1 run 1,000 agent で、超過分はスロットが空くまでキューに入る。(`claude_agent_sdk/08_Dynamic_workflows.ipynb`)
16. **予算は「プロンプトに書く」と「プラットフォームが強制する」の 2 層がある**。項目 7 のツール呼び出し予算は指示にすぎないが、`sessions.create` の `budget` (`{"type": "limit", "max_list_cost": {"currency": "USD", "amount": "10"}}`) はセッション内の全スレッド (サブエージェント含む) の list price 合計に対する強制上限。`amount` は minor unit の整数文字列で float 丸めが入らない。上限到達は失敗ではなく **pause** (`stop_reason` = `budget_reached`) で、ファイル・tool state・会話はそのまま残り、`sessions.update` で cap を上げると中断したターンから自力で再開する。強制はモデルリクエストの合間なので実測コストは cap を 1 リクエスト分だけ超えうる。cap は作成時にしか付けられず、`budget=None` で外すと二度と付け直せない一方通行 (省略は「維持」、`None` は「削除」)。消費済み額以下への引き下げは 400。ストリームを張らない運用では `session.budget_reached` webhook で拾う。(`managed_agents/CMA_cap_session_spend.ipynb`, `managed_agents/CMA_operate_in_production.ipynb`)
17. **スキルはリポジトリから自動発見できる**。GitHub repo を mount したセッションは開始時に repo ルートの `.claude/skills/` を 1 回スキャンし、各スキルの name / description / サンドボックス内パスをエージェントの system prompt に注入する。エージェント側に `skills` フィールドは要らない。モデルは description が要求に一致した時点で `read` tool で `SKILL.md` を開き、そこから指示された参照ファイルやスクリプトへ進む (read-then-follow)。境界: レイアウトは厳格で repo ルート直下の `.claude/skills/<name>/SKILL.md` だけ (1 段深い / `.claude` 無しは無視)、frontmatter が無くてもディレクトリ名 + 空 description で載る、description は 1 行に潰され 2,000 文字で truncate、announce は先頭 64 ディレクトリまで、スキャンは 1 回きり (mid-session の push は次セッションから)。ネストした `packages/foo/.claude/skills/` は、その配下を `read` tool で読んだ時点で遅延発見される (`bash` の `cat` では発火しない)。(`managed_agents/CMA_use_skills_from_a_repo.ipynb`)
18. **検証を構造で強制する型 = fan-out + adversarial verification**。extract (1 agent が claim を構造化出力で抽出) → verify (claim 1 件に 1 agent、並列、clean context、`schema` 付きで verdict と根拠の引用行を返す) → skeptic (`confirmed` の判定だけを再検証させ、引用が実際には支持していなければ `contradicted` へ落とす) → report。"Double-check your findings" は指示にすぎず context 圧のもとで飛ぶが、スクリプトの制御フローなら飛ばない。`confirmed` だけを skeptic に回す分岐は素の JavaScript なのでトークン 0。プロンプトの大半がタスクではなく work の *shape* の記述になる ("With workflows, the prompt describes the harness you want")。なお発見物はファイルではなく agent の**返り値**で回収する設計で、`SUMMARY.md` のようなレポート風ファイルを書こうとした agent は内容を return しろと差し戻された (実成果物のファイル書き込みは通常どおり)。(`claude_agent_sdk/08_Dynamic_workflows.ipynb`)
19. **コスト最適化のレバーは「知能の天井を下げない順」に引く**。順序は (1) prompt caching → (2) 入力トークン管理 → (3) エージェントループ効率 → (4) 出力トークン管理 → (5) Batch API → (6) モデル選択と `effort`。モデル切り替えを最後に置くのは "the easiest lever to pull but directly constrains the intelligence of your product" だから。ゲートは常に eval で、読む指標は per-token 価格ではなく **pass rate と cost per task** の 2 つ ("a model with a higher sticker price can be the cheaper option if it finishes the job in fewer turns")。品質バーを先に決め、コストをその制約下の最小化対象として扱う。(`cost_optimization/cost_optimization.ipynb`)
20. **repo 自身のハーネスが良い設計例**。`cookbook-audit` スキルは (a) ルーブリック本体を `style_guide.md` に分離して「先に読め」と指示、(b) `validate_notebook.py` で ipynb を markdown 化してから読ませる ("saves context vs raw .ipynb")、(c) 4 次元 x 5 点のスコア形式を固定。決定的スクリプトによる前処理でコンテキストを節約する型。(`.claude/skills/cookbook-audit/SKILL.md`)

## 5 つのワークフローパターン

`patterns/agents/README.md` が列挙する 5 パターン。制御フローの所在 (コード側 / モデル側) が設計上の分かれ目。

| パターン | 制御フローの所在 | 実装の骨格 | 使う / 使わない | 原典パス |
|---|---|---|---|---|
| Prompt Chaining | コード側 (完全に固定) | `chain(input, prompts)` = プロンプト list を for で回し、前段の出力を次段の入力にする | 変換手順が事前に確定しているとき。順序が入力依存なら不適 | `patterns/agents/basic_workflows.ipynb` |
| Parallelization | コード側 (固定並列) | `parallel(prompt, inputs)` = `ThreadPoolExecutor` で同一プロンプトを複数入力に並列適用 | サブタスクを事前列挙できるとき。列挙できないなら orchestrator へ | `patterns/agents/basic_workflows.ipynb` |
| Routing | 分類だけモデル側、分岐先はコード側 | LLM に `<reasoning>` + `<selection>` を吐かせ、`routes` dict のキーで専用プロンプトへディスパッチ | 入力の種類ごとに専用プロンプトを当てたいとき | `patterns/agents/basic_workflows.ipynb` |
| Orchestrator-Workers | 計画がモデル側、実行順はコード側 | `FlexibleOrchestrator`: (1) orchestrator が `<analysis>` と `<tasks><task><type><description>` を生成、(2) worker ごとに元タスク + 自分の型 + 指示を渡し `<response>` を回収 | サブタスクが入力依存で予測できないとき。単純/低レイテンシ要求/事前定義可能なら不適 | `patterns/agents/orchestrator_workers.ipynb` |
| Evaluator-Optimizer | ループ判定がモデル側 | `loop()`: generate → evaluate (`<evaluation>PASS｜NEEDS_IMPROVEMENT｜FAIL` + `<feedback>`) → PASS まで再生成。過去の試行を `memory` に積んで context に戻す | 評価基準が明確 + 反復改善に価値があるとき | `patterns/agents/evaluator_optimizer.ipynb` |

実装を読むときの注意 (実際のコードで確認した点):

- 3 つの基本パターンは "sample implementations meant to demonstrate core concepts - not production code" と明記されている。位置づけは「トレードオフ (コストとレイテンシを払って性能を買う) の最小デモ」。
- `FlexibleOrchestrator.process()` の docstring は "run them in parallel" と書いてあるが、実際の worker 実行は for ループの**逐次**。並列化は読者の宿題。
- `FlexibleOrchestrator` はプロンプトを `str.format(**kwargs)` のテンプレートとして持ち、変数不足を `ValueError` にする。worker の空応答は検出してエラープレースホルダに置換する。
- `evaluator_optimizer.loop()` は `while True` で **反復上限が無い**。PASS が出ないと止まらない (下の「食い違い」参照)。
- `parse_tasks()` は行頭タグの文字列スライスで XML を読む簡易実装。堅牢なパーサではない。

## マルチエージェント実装の要点

`patterns/agents/async_multi_agent_orchestration.ipynb` は Claude Opus 4.8 システムカードのマルチエージェント結果の裏にある 2 形態 —
**固定 N エージェントチーム** と **async サブエージェント (動的 spawn)** — の「形」だけを、ドメインタスク抜きで示す。公開 SDK + `asyncio` のみ。

- `Hub`: エージェントごとに inbox (list) と `asyncio.Event`。`post` / `drain` / `render`。`render` は `<agent-message from="...">` という独自 XML でメッセージを整形する (= コンテキスト形式を自分で所有する具体例)。
- 全エージェント共通の 2 tool: `send_message` (description に "This is the ONLY way to reach other agents — plain text in your turn goes nowhere.") と `wait_for_message` (ブロッキング。他の tool の結果にもメッセージは付いてくるので、本当に手空きのときだけ使う)。
- リード専用の 3 tool: `create_subagents` (即座に返る)、`get_status` (active / idling / done / crashed)、`kill_subagents` (不要になったら明示的に解散)。
- `run_agent()` が全エージェントを回す単一の tool-use ループ。`max_turns=20` 既定、`stop_reason` が想定外なら例外。`TRACE` dict に tool 呼び出し列を残して後から追える。

`patterns/agents/prompts/` の 3 本は本番系リサーチエージェントのプロンプト実物で、委譲設計のテンプレートとして読める。

| プロンプト | 中身の要点 | 原典パス |
|---|---|---|
| research lead | クエリを depth-first / breadth-first / straightforward に分類 → 型ごとに計画の立て方を規定 → `run_blocking_subagent` で委譲。サブエージェント数ガイド、境界の重複禁止、依存のあるブロッキングタスクを先に投げる、待ち時間は自分の分析に使う、時間切れなら追加投入せず即レポート作成 | `patterns/agents/prompts/research_lead_agent.md` |
| research subagent | ツール呼び出し予算、OODA ループ (最低 5 回・複雑でも 10 回程度)、内部ツール優先、`web_search` → `web_fetch` の基本ループ、ソース品質への懐疑 (推測の未来形・アグリゲータ・匿名の受動態などを報告時に明示)、上限で即 `complete_task` | `patterns/agents/prompts/research_subagent.md` |
| citations agent | 引用付与専用の別エージェント。本文を 1 文字も変えない制約 (不一致なら結果を破棄)、引用しすぎない・意味単位で引用する等のガイド | `patterns/agents/prompts/citations_agent.md` |

## コンテキスト設計とエージェント eval

| トピック | 原典パス | 一行説明 |
|---|---|---|
| compaction / clearing / memory の使い分け | `tool_use/context_engineering/context_engineering_tools.ipynb` | 3 プリミティブの識別子・beta header・トリガー・調整ノブの一覧表と、long-running research agent での実測トラジェクトリ。context rot の説明つき |
| memory tool + context editing の実装 | `tool_use/memory_cookbook.ipynb`, `tool_use/memory_demo/` | セッション跨ぎで学習を保持するコードレビューアシスタントのデモ |
| SDK 側の自動 compaction | `tool_use/automatic-context-compaction.ipynb` | `compaction_control` で閾値超過時に要約を注入し履歴を捨てる。カスタマーサービスのチケット処理で実演 |
| programmatic tool calling (PTC) | `tool_use/programmatic_tool_calling_ptc.ipynb` | tool を code execution 内から呼び、大きな結果をコンテキストに入れずに処理する。変更できない外部 API に対して効く |
| 大量 tool のスケーリング | `tool_use/tool_search_with_embeddings.ipynb`, `tool_use/tool_search_alternate_approaches.ipynb` | 埋め込み検索で tool を都度発見する / tool 名一覧 + `describe_tool` で遅延ロードする |
| 並列 tool 呼び出しの誘導 | `tool_use/parallel_tools.ipynb` | 並列呼び出しを渋るモデルに対し、複数 tool をまとめる meta-tool ("batch tool") を置くと並列化する。research lead プロンプトでも同じ batch tool 前提の記述がある |
| `tool_choice` の 3 モード | `tool_use/tool_choice.ipynb` | `auto` / 特定 `tool` 強制 / `any` (何か 1 つ必須) の挙動と使い分け |
| agentic search のハーネス再現 | `evals/agentic_search/reproduce_agentic_search_benchmarks.ipynb` | 公開スコアを公開 API で再現するための設定 (PTC・effort・task_budget・compaction instructions・`pause_turn` 往復・retry) と F1 grader |
| tool 定義そのものの eval | `tool_evaluation/tool_evaluation.ipynb`, `tool_evaluation/evaluation.xml` | 同一 eval タスクを複数エージェントが独立に実行して tool 定義の質を測る |
| 使用量・コストの可観測性 | `observability/usage_cost_api.ipynb` | Usage & Cost Admin API でトークン/コストをモデル・ワークスペース・API キー別に取得。キャッシュ効率やチャージバック用 |
| コスト最適化の eval 駆動手順 | `cost_optimization/cost_optimization.ipynb` | pass rate と cost per task の 2 軸で品質バーを固定し、レバーを 1 つずつ当てて Pareto フロンティアを描く。レバー個別の効き所は下の「コスト最適化レバーの優先順位」 |
| ↳ eval 運用の実務値 | `cost_optimization/cost_optimization.ipynb` | 本番判断には約 50 ケース x 設定ごと 5 トライアル以上。隣接設定が run 間で順位を入れ替えなくなるまで誤差幅を詰める。1 トライアルの結果で判断しない |
| 異種モデルの orchestrator-worker | `multimodal/using_sub_agents.ipynb` | 上位モデルが各サブエージェント用のプロンプトを実行時に書き、廉価モデルが抽出を担う構成 |

## コスト最適化レバーの優先順位

`cost_optimization/cost_optimization.ipynb` は Applied AI チームがビルダーに回すチェックリストを、保険金査定エージェント
(Opus `effort=high` / 12 tools / 10 件の eval セット) で 1 レバーずつ実測した 1 本。ベースライン 10/10 正解・$0.29/task に対し、
最終的な Pareto 最適は **`sonnet · medium` + system ブロックへの明示 breakpoint** で 13 倍安。
読みどころは順序そのものより **試したレバーの大半が効かなかった**事実で、効くかどうかはエージェントの形
(ターン数・スキーマの重さ・数値処理の有無・入力が前段結果に依存するか) で決まる。

| レバー | 実装の要点 | 効かない / 避ける条件 |
|---|---|---|
| prompt caching | auto は `cache_control={"type": "ephemeral"}` をリクエストに置くと最後の cacheable ブロック直後に breakpoint が 1 つ置かれ会話とともに前進。明示は最大 4 個で層ごとに TTL を変えられる。write は 5 分 TTL で 1.25x / 1 時間で 2x、read は 0.1x | キャッシュ破壊の 3 大要因: breakpoint より上の動的コンテンツ (timestamp / request ID)、会話途中のモデル切り替え (キャッシュはモデル単位)、毎ターンの compaction。lookup は breakpoint から約 20 ブロックしか遡らないので、append の多い loop は明示 breakpoint が要る |
| 入力トークン管理 | progressive disclosure。参照文書を `read_manual` 等の tool の裏へ、system prompt の tool 再掲を削る、`defer_loading: True` + `tool_search_tool_regex_20251119`、画像を 1280x720 まで事前縮小 (1 画像 ~1,200 tokens に収まる)、大きな表は Files API + code execution へ、`count_tokens` を ingestion gate に | 毎回文書の大半を読むならキャッシュ済み system prompt のままが安い。スキーマが 10K token 未満なら tool search は純オーバーヘッド。計算する数値が無ければ code execution はトークンを足すだけ |
| エージェントループ効率 | server 側は `clear_tool_uses_20250919` (`trigger` = `input_tokens` 150K, `keep.tool_uses`) / `clear_thinking` / `compact_20260112`。client 側は **jagged compaction** = 嵩む結果を溜めて自然な境界で一括 prune し、prune 間は message 配列を byte 同一に保つ。自己完結なサブタスクは subagent へ切り出して結果 1 行だけ返す | edit は必ずその地点以降の cache を無効化するので trigger は高めに置いて発火を稀にする。6 ターン程度の loop では trigger に届かず無意味 |
| 出力トークン管理 | `max_tokens` は backstop であって tuning knob ではない (モデルは値を見ず、超えたら `stop_reason="max_tokens"` で途中で切れる)。短くしたいなら出力の形を例つきでプロンプトに書く。早期離脱は sentinel (`<CANNOT_REVIEW>`) を `stop_sequences` に登録して説明文の生成を止める | — |
| Batch API | 全トークン 50% off / 24 時間以内の非同期処理。caching も併用できる | 単発リクエストなので tool loop は畳めない。適用するには loop の入力を全部先読みして 1 リクエストに inline する**アーキテクチャ変更**が要る。batch 内の cache hit は並行実行のため best effort。24 時間は expiry であって SLA ではない |
| モデルと `effort` | `effort` を low まで下げて eval が通るならモデル階層を 1 つ落とし `effort` を high に戻して再掃引。Haiku 4.5 は `effort` を取らない。advisor tool (`advisor_20260301`, beta `advisor-tool-2026-03-01`) で安いドライバに上位モデルの相談役を付ける | advisor は「いつ相談するか」を安い signal (payout 閾値 / fraud score 帯) で gate できないと成立しない — 難しいケースの識別自体がドライバに欠けている判断力だから |
| タスク分解 (subagent routing) | Haiku 5 体が事実収集 → Sonnet 1 回が rule card に照らして判断。実測で最安 (Opus ベースライン比 約 90% 減) | 1 件落として不採用。原因は例外条項の欠落で、"Flattening a manual into a rule list is where decomposition gives up accuracy." 判断側が中間コンテキストを必要とするなら分解しない |

## ハーネス実装例の索引

| 対象 | 原典パス | 一行説明 |
|---|---|---|
| Agent SDK チュートリアル 9 本 (00〜08) | `claude_agent_sdk/README.md` | `query()` / `ClaudeSDKClient` / `ClaudeAgentOptions` から、MCP 連携・サブエージェント・hooks・OpenAI Agents SDK からの移行・セッションブラウザ・脆弱性検出・ホスティング・dynamic workflow まで段階的に上げる構成 |
| dynamic workflow の起動と読み方 | `claude_agent_sdk/08_Dynamic_workflows.ipynb` | SDK からの起動は 2 点だけ: `allowed_tools` に `Workflow` を入れる + プロンプトで平文で "use a workflow to…" と頼む。スクリプトは `export const meta = {name, description, phases}` と `agent(prompt, options)` (clean context。`label` / `phase` / `schema` / `model` を指定可) / `parallel([...])` (全完了を待つバリア) / `pipeline(items, stage1, ...)` (item ごとに独立してステージを流す) / `phase("...")` で組む。ランタイムはスクリプトを `~/.claude/projects/` のセッションディレクトリにファイルとして残し、`.claude/workflows/` に置けば名前で再実行できる。spawn された subagent は `acceptEdits` で走り allowlist を継承。スクリプト自身は fs / shell に触れず、触れるのは spawn された agent だけ。ステージごとにモデルを振り分けられ (機械的な抽出は安いモデル、判断は最強モデル)、`CLAUDE_CODE_SUBAGENT_MODEL` で一括上書きも可能。進行は `TaskProgressMessage` / `TaskNotificationMessage` で流れ、background 実行のため `ResultMessage` は起動ターンと完了ターンで 2 回来る |
| フル装備の `.claude/` 実例 | `claude_agent_sdk/chief_of_staff_agent/.claude/` | `agents/*.md` (frontmatter に `name` / `description` / `tools`)、`commands/`、`hooks/*.py`、`output-styles/`、`settings.local.json` が一式揃った参照配置 |
| 書き込み系の安全 hook | `claude_agent_sdk/03_The_site_reliability_agent.ipynb` | PreToolUse hook で書き込み操作 (プールサイズ範囲・設定の妥当性) を検証してから通す。read-only → read-write への拡張手順 |
| MCP でのツール供給 | `claude_agent_sdk/02_The_observability_agent.ipynb` | git / GitHub MCP サーバでツールを外部化する。SRE 版は JSON-RPC サブプロセスの自作 MCP サーバ |
| Managed Agents (ホスト実行) | `managed_agents/README.md` | ステートフルなホスト型ランタイム。`CMA_iterate_fix_failing_tests.ipynb` が API 形状の入口 |
| ↳ 人間ゲート | `managed_agents/CMA_gate_human_in_the_loop.ipynb`, `managed_agents/CMA_operate_in_production.ipynb` | custom tool の `decide()` / `escalate()`、`requires_action` idle バウンス、長時間接続を張らずに HITL を回す `session.status_idled` webhook |
| ↳ 異種スペシャリストチーム | `managed_agents/CMA_coordinate_specialist_team.ipynb`, `managed_agents/CMA_watch_subagents_live.ipynb` | `multiagent` coordinator 設定、ロール別の tool スコープを絞る理由、per-thread の event delta とモデル `effort` をコストレバーにする。roster には agent 以外に advisor 1 件を混在させられる |
| ↳ 上位モデルへの相談 (advisor) | `managed_agents/CMA_consult_an_advisor.ipynb` | roster に `{"type": "advisor", "model": ...}` を 1 件だけ置くと、中位モデルが turn の途中で上位モデルへ相談できる。tool は入力を取らず会話全体がそのまま渡るので、「いつ相談するか」を決めるのは system prompt だけ。相談は `agent.tool_use` ではなく `anthropic.advisor` という短命スレッドの lifecycle として primary stream に現れ、コストはそのスレッドの `usage.list_cost` で個別に読める。子スレッドの同時実行上限の対象外。モデルのポリシー次第で応答が `redacted` ブロックで返る (働くモデルは全文を読むので結果は変わらない) ため、text / redacted の両方を正常系として書く |
| ↳ セッション予算 | `managed_agents/CMA_cap_session_spend.ipynb` | `budget` の付与、ターン終了時に流れる `session.usage` スナップショットと `usage.list_cost`、`budget_reached` での pause、cap の上げ下げと削除 (まず押さえる 16) |
| ↳ リポジトリ由来のスキル | `managed_agents/CMA_use_skills_from_a_repo.ipynb` | mount した repo の `.claude/skills/` を自動発見 (まず押さえる 17)。Skills API との使い分けも明記: repo skill = コードと一緒に変わるもの (ビルド / テスト規約・レビュー手順・runbook)、Skills API = リポジトリ横断の組織資産。同名衝突は両方 announce され、パスで区別される。Anthropic ホスト環境限定 |
| ↳ 推論リージョンの固定 | `managed_agents/CMA_pin_inference_geo.ipynb` | `model.inference_geo` (`"global"` / `"us"`) をエージェント定義に置く。ワークスペースの `allowed_inference_geos` / `default_inference_geo` に照らして保存時・セッション作成時・毎ターンの 3 回検証され、後からポリシーを狭めると実行中セッションも次ターンで拒否される (grandfather しない)。`agents.update` の `model` は merge ではなく置換なので `inference_geo` を書き忘れると pin が消える。1 セッションだけ別リージョンにするなら `sessions.create` の `agent_with_overrides`。処理場所の話であって保存場所 (`workspace_geo`) は別 |
| ↳ プロンプトのバージョン管理 | `managed_agents/CMA_prompt_versioning_and_rollback.ipynb` | v1 を labelled テストセットで評価 → v2 出荷 → 回帰検知 → セッションを version 1 に pin して rollback。「プロンプトがコードでないとき、レビューゲートはどこへ行くか」 |
| ↳ メモリストア | `managed_agents/CMA_remember_user_preferences.ipynb` | per-attachment `instructions` 付きの `memory_stores`、顧客別 read-write ストアとブランド共通 read-only ストアの併用 |
| ↳ 出力の自動採点 | `managed_agents/CMA_verify_with_outcome_grader.ipynb` | ステートレス grader が全 URL を実際に fetch して引用を検証し、rubric に基づくフィードバックで改稿を回す |
| ↳ コーディネータの経済性 | `managed_agents/CMA_plan_big_execute_small.ipynb` | 高価なコーディネータがトークン重い読解を安価な並列ワーカーへ流し、rigor を揃えた単独実行と per-thread の `usage.list_cost` (サーバ側計算) で比較。fan-out 数はデータ依存で決まるためセッションに `budget` を張ってガードレールにする。自前のレート表が要るのは「全部フロンティアモデルで走らせたら」という反実仮想だけ |
| Skill 実装例 | `skills/custom_skills/` | `SKILL.md` (frontmatter は `name` / `description`) + `scripts/*.py` + `REFERENCE.md` の構成。progressive disclosure で必要時のみロード |
| repo 自身のハーネス | `.claude/skills/cookbook-audit/`, `.claude/agents/code-reviewer.md`, `.claude/commands/` | ルーブリックを別ファイルに分離したスキル、レビュー用サブエージェント、7 本のスラッシュコマンド (`/notebook-review` 等は CI からも呼ばれる) |
| ドキュメント品質のルーブリック | `.claude/skills/cookbook-audit/SKILL.md` | 問題起点の導入・学習目標・コード前後の説明・アンチパターン集。技術文書のレビュー基準としてそのまま流用できる |
| repo 規約 | `CLAUDE.md` | 日付なしモデルエイリアスを使う (`claude-sonnet-5` 等)、1 notebook 1 概念、出力は意図的に残す、`make check` を commit 前に回す |

## 12-factor-agents との食い違い

原則と実装が一致しない箇所は、そこが判断ポイント。

- **リトライ上限 (factor 9)**: `evaluator_optimizer.loop()` は `while True` で反復上限もエスカレーションも無い。原則側は「連続エラー ~3 回で人間へ / 決定的介入へ」。参照実装をコピーするならループ上限を足す。なお `patterns/agents/async_multi_agent_orchestration.ipynb` の `run_agent()` は `max_turns=20` を持っており、こちらは原則寄り。
- **プリフェッチ (factor 13) vs PTC**: 原則は「呼ぶと分かっているツールは決定的に事前実行して結果を context に入れる」。cookbook のコンテキスト対策の主軸は逆向きで、PTC で **結果を context に入れない**。大きな tool 結果が前提のときは PTC 側が優先される。ただし `cost_optimization/cost_optimization.ipynb` の Batch 節はプリフェッチそのもの — loop が取りうる全レコードを先読みして 1 リクエストに inline し、tool の順序制御を system prompt の読解順に置き換える。対話フロンティアの約半額になるが、次の取得が前段結果に依存するタスクは畳めず、実測では pass rate も 1 件落ちた。分岐点は「入力が前段結果に依存するか」。
- **制御フローの所有 (factor 6/8) vs マネージド化**: 原則は launch/pause/resume を自前 API で持つこと。`managed_agents/` は同じ要求をホスト側の `requires_action` ゲートと `session.status_idled` / `session.budget_reached` webhook に寄せる。停止条件 (予算・人間の承認) をプロンプトやアプリコードではなくプラットフォーム側の強制機構に置く設計で、自前実装とマネージドのどちらを取るかの分岐点として読む。
- **計画のコード化 (factor 8) vs スクリプトを書くのはモデル**: dynamic workflow は計画をモデルの context から JavaScript のコードへ出すので factor 8 (own your control flow) に最も近い形だが、そのコードを実行時に書くのはモデル自身。決定的なのは生成後の実行だけで、生成そのものは非決定的。スクリプトを保存して `.claude/workflows/` から名前で再実行する運用とセットにして初めて決定性が戻る。リトライ面では stage 失敗時 (例: agent が構造化出力のリトライを使い切る) に `[Failed]` 通知が出て Claude が workflow を再起動し、完了済み agent はキャッシュ結果を返すので失敗ステージだけ再実行される (コストは上乗せ)。上限がランタイム側に入っている点は `evaluator_optimizer.loop()` の無制限ループより原則寄りだが、人間へのエスカレーション経路は用意されていない。(`claude_agent_sdk/08_Dynamic_workflows.ipynb`)
- **フレームワーク依存への警戒 (README of 12-factor) vs SDK 推し**: `claude_agent_sdk/README.md` は Claude Code を "the closest thing to a 'bare metal' harness" と位置づけて SDK 採用を勧める。原則側の「フレームワークは 70-80% で頭打ち」という警告と緊張関係にある。ただし cookbook の `patterns/agents/` 自体は SDK を一切使わない素の実装なので、repo 内に両方の選択肢が並んでいる。
- **tool = 構造化出力 (factor 4) の徹底**: `patterns/agents/` は tool use API すら使わず XML + 正規表現で通す。原則の「tool call は JSON 出力 + 決定的コード、それ以上ではない」を最も素朴な形で示した実例。

## 蒸留の範囲外

- **API 一般の話題は別スキル (`claude-api`) の担当**。この蒸留版では扱わない。上の「コスト最適化レバー」もアーキテクチャ判断の粒度までで、価格表・パラメータの詳細仕様は追わない (notebook 内の `PRICING` は執筆時点のリスト価格のハードコードで、原典自身が陳腐化を明記している)。当たる場所: prompt caching・JSON mode・moderation・batch 等は `misc/`、RAG と contextual embeddings は `capabilities/retrieval_augmented_generation/` と `capabilities/contextual-embeddings/`、分類・要約・text-to-sql は `capabilities/` 配下、vision / multimodal は `multimodal/`、fine-tuning は `finetuning/`、extended thinking は `extended_thinking/`、外部ベンダ連携は `third_party/` (Pinecone / VoyageAI / MongoDB / LlamaIndex / Wolfram / Deepgram / ElevenLabs / Wikipedia)。
- **Skills 機能の API 面** (beta header `skills-2025-10-02`、`container` パラメータ、Files API での成果物ダウンロード、組み込み `xlsx` / `pptx` / `pdf` / `docx`): `skills/README.md` と `skills/CLAUDE.md` に詳しい。ここではハーネス設計に効く「SKILL.md + scripts + REFERENCE.md の構成」だけを索引した。
- **各 notebook のコードセル全文**: 本蒸留は README・markdown セル・`patterns/agents/` の実装コード・`prompts/`・`.claude/` を読んだ範囲で書いた。`managed_agents/` と `claude_agent_sdk/` の個々の notebook は原則として README の記述と目次までで、セル単位の実装は未確認。例外 (markdown セル全部と主要コードセルを読んだもの) は `claude_agent_sdk/08_Dynamic_workflows.ipynb`, `managed_agents/CMA_cap_session_spend.ipynb`, `managed_agents/CMA_consult_an_advisor.ipynb`, `managed_agents/CMA_use_skills_from_a_repo.ipynb`, `managed_agents/CMA_pin_inference_geo.ipynb`, `cost_optimization/cost_optimization.ipynb`。API 形状を正確に知りたいときは該当 notebook を直接読む。
- **コスト最適化 notebook の合成データと実行結果**: `cost_optimization/assets/` (`policy_manual.md` の約 12K トークン引受マニュアル、`claims_ledger.csv` の 5,000 行台帳、`eval_set.csv` の 10 件ラベル、見積書・写真) はデモ用の合成データなので索引しない。notebook 通しの実行に約 $40 かかる旨と、掲載スコアがハードコードで実行ごとに変動する旨は原典が明記している。Pareto フロンティアの作図・トライアル集計コードも未索引。
- **レイテンシ最適化・商用価格**: 原典が明示的に対象外としている領域 (レイテンシは follow-up cookbook 予定、committed-use discount 等はアカウントチームの話)。
- **ホスティング・インフラ**: `claude_agent_sdk/hosting/` (docker / kubernetes / modal)、`managed_agents/self_hosted_sandboxes/`、`managed_agents/cma-mcp/`。
- **統合デモ**: `managed_agents/slack/`, `managed_agents/linear/`, `managed_agents/sentry/`, `managed_agents/roadtrip_planner/`、`claude_agent_sdk/session_browser_demo/`、`claude_agent_sdk/vulnerability_detection_agent/`。
- **フロントエンド美観のプロンプティング**: `coding/prompting_for_frontend_aesthetics.ipynb` (DESIGN.md 系の判断には別リファレンスを使う)。
- **課金**: `fable_5_fallback_billing/guide.ipynb`。
- **未読だがプロンプト / eval 設計に隣接するもの** (内容未確認、必要なら直接読む): `misc/metaprompt.ipynb` (プロンプト自動生成)、`misc/building_evals.ipynb` と `misc/generate_test_cases.ipynb` (eval とテストケース生成)、`misc/session_memory_compaction.ipynb`。
- **リポジトリ運営系**: `registry.yaml` / `authors.yaml` / `tests/` / `scripts/` / `CONTRIBUTING.md`。
