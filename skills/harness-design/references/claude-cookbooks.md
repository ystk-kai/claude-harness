---
source: https://github.com/anthropics/claude-cookbooks
distilled_commit: 85016cacf5b7923aa62aa2b514399325e9d159e9
distilled_at: 2026-07-28
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
15. **repo 自身のハーネスが良い設計例**。`cookbook-audit` スキルは (a) ルーブリック本体を `style_guide.md` に分離して「先に読め」と指示、(b) `validate_notebook.py` で ipynb を markdown 化してから読ませる ("saves context vs raw .ipynb")、(c) 4 次元 x 5 点のスコア形式を固定。決定的スクリプトによる前処理でコンテキストを節約する型。(`.claude/skills/cookbook-audit/SKILL.md`)

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
| 異種モデルの orchestrator-worker | `multimodal/using_sub_agents.ipynb` | 上位モデルが各サブエージェント用のプロンプトを実行時に書き、廉価モデルが抽出を担う構成 |

## ハーネス実装例の索引

| 対象 | 原典パス | 一行説明 |
|---|---|---|
| Agent SDK チュートリアル 8 本 | `claude_agent_sdk/README.md` | `query()` / `ClaudeSDKClient` / `ClaudeAgentOptions` から、MCP 連携・サブエージェント・hooks・ホスティングまで段階的に上げる構成 |
| フル装備の `.claude/` 実例 | `claude_agent_sdk/chief_of_staff_agent/.claude/` | `agents/*.md` (frontmatter に `name` / `description` / `tools`)、`commands/`、`hooks/*.py`、`output-styles/`、`settings.local.json` が一式揃った参照配置 |
| 書き込み系の安全 hook | `claude_agent_sdk/03_The_site_reliability_agent.ipynb` | PreToolUse hook で書き込み操作 (プールサイズ範囲・設定の妥当性) を検証してから通す。read-only → read-write への拡張手順 |
| MCP でのツール供給 | `claude_agent_sdk/02_The_observability_agent.ipynb` | git / GitHub MCP サーバでツールを外部化する。SRE 版は JSON-RPC サブプロセスの自作 MCP サーバ |
| Managed Agents (ホスト実行) | `managed_agents/README.md` | ステートフルなホスト型ランタイム。`CMA_iterate_fix_failing_tests.ipynb` が API 形状の入口 |
| ↳ 人間ゲート | `managed_agents/CMA_gate_human_in_the_loop.ipynb`, `managed_agents/CMA_operate_in_production.ipynb` | custom tool の `decide()` / `escalate()`、`requires_action` idle バウンス、長時間接続を張らずに HITL を回す `session.status_idled` webhook |
| ↳ 異種スペシャリストチーム | `managed_agents/CMA_coordinate_specialist_team.ipynb`, `managed_agents/CMA_watch_subagents_live.ipynb` | `multiagent` coordinator 設定、ロール別の tool スコープを絞る理由、per-thread の event delta とモデル `effort` をコストレバーにする |
| ↳ プロンプトのバージョン管理 | `managed_agents/CMA_prompt_versioning_and_rollback.ipynb` | v1 を labelled テストセットで評価 → v2 出荷 → 回帰検知 → セッションを version 1 に pin して rollback。「プロンプトがコードでないとき、レビューゲートはどこへ行くか」 |
| ↳ メモリストア | `managed_agents/CMA_remember_user_preferences.ipynb` | per-attachment `instructions` 付きの `memory_stores`、顧客別 read-write ストアとブランド共通 read-only ストアの併用 |
| ↳ 出力の自動採点 | `managed_agents/CMA_verify_with_outcome_grader.ipynb` | ステートレス grader が全 URL を実際に fetch して引用を検証し、rubric に基づくフィードバックで改稿を回す |
| ↳ コーディネータの経済性 | `managed_agents/CMA_plan_big_execute_small.ipynb` | 高価なコーディネータがトークン重い読解を安価な並列ワーカーへ流し、rigor を揃えた単独実行と per-thread コストで比較 |
| Skill 実装例 | `skills/custom_skills/` | `SKILL.md` (frontmatter は `name` / `description`) + `scripts/*.py` + `REFERENCE.md` の構成。progressive disclosure で必要時のみロード |
| repo 自身のハーネス | `.claude/skills/cookbook-audit/`, `.claude/agents/code-reviewer.md`, `.claude/commands/` | ルーブリックを別ファイルに分離したスキル、レビュー用サブエージェント、7 本のスラッシュコマンド (`/notebook-review` 等は CI からも呼ばれる) |
| ドキュメント品質のルーブリック | `.claude/skills/cookbook-audit/SKILL.md` | 問題起点の導入・学習目標・コード前後の説明・アンチパターン集。技術文書のレビュー基準としてそのまま流用できる |
| repo 規約 | `CLAUDE.md` | 日付なしモデルエイリアスを使う (`claude-sonnet-5` 等)、1 notebook 1 概念、出力は意図的に残す、`make check` を commit 前に回す |

## 12-factor-agents との食い違い

原則と実装が一致しない箇所は、そこが判断ポイント。

- **リトライ上限 (factor 9)**: `evaluator_optimizer.loop()` は `while True` で反復上限もエスカレーションも無い。原則側は「連続エラー ~3 回で人間へ / 決定的介入へ」。参照実装をコピーするならループ上限を足す。なお `patterns/agents/async_multi_agent_orchestration.ipynb` の `run_agent()` は `max_turns=20` を持っており、こちらは原則寄り。
- **プリフェッチ (factor 13) vs PTC**: 原則は「呼ぶと分かっているツールは決定的に事前実行して結果を context に入れる」。cookbook のコンテキスト対策の主軸は逆向きで、PTC で **結果を context に入れない**。大きな tool 結果が前提のときは PTC 側が優先される。
- **制御フローの所有 (factor 6/8) vs マネージド化**: 原則は launch/pause/resume を自前 API で持つこと。`managed_agents/` は同じ要求をホスト側の `requires_action` ゲートと `session.status_idled` webhook に寄せる。自前実装とマネージドのどちらを取るかの分岐点として読む。
- **フレームワーク依存への警戒 (README of 12-factor) vs SDK 推し**: `claude_agent_sdk/README.md` は Claude Code を "the closest thing to a 'bare metal' harness" と位置づけて SDK 採用を勧める。原則側の「フレームワークは 70-80% で頭打ち」という警告と緊張関係にある。ただし cookbook の `patterns/agents/` 自体は SDK を一切使わない素の実装なので、repo 内に両方の選択肢が並んでいる。
- **tool = 構造化出力 (factor 4) の徹底**: `patterns/agents/` は tool use API すら使わず XML + 正規表現で通す。原則の「tool call は JSON 出力 + 決定的コード、それ以上ではない」を最も素朴な形で示した実例。

## 蒸留の範囲外

- **API 一般の話題は別スキル (`claude-api`) の担当**。この蒸留版では扱わない。当たる場所: prompt caching・JSON mode・moderation・batch 等は `misc/`、RAG と contextual embeddings は `capabilities/retrieval_augmented_generation/` と `capabilities/contextual-embeddings/`、分類・要約・text-to-sql は `capabilities/` 配下、vision / multimodal は `multimodal/`、fine-tuning は `finetuning/`、extended thinking は `extended_thinking/`、外部ベンダ連携は `third_party/` (Pinecone / VoyageAI / MongoDB / LlamaIndex / Wolfram / Deepgram / ElevenLabs / Wikipedia)。
- **Skills 機能の API 面** (beta header `skills-2025-10-02`、`container` パラメータ、Files API での成果物ダウンロード、組み込み `xlsx` / `pptx` / `pdf` / `docx`): `skills/README.md` と `skills/CLAUDE.md` に詳しい。ここではハーネス設計に効く「SKILL.md + scripts + REFERENCE.md の構成」だけを索引した。
- **各 notebook のコードセル全文**: 本蒸留は README・markdown セル・`patterns/agents/` の実装コード・`prompts/`・`.claude/` を読んだ範囲で書いた。`managed_agents/` と `claude_agent_sdk/` の個々の notebook は README の記述と目次までで、セル単位の実装は未確認。API 形状を正確に知りたいときは該当 notebook を直接読む。
- **ホスティング・インフラ**: `claude_agent_sdk/hosting/` (docker / kubernetes / modal)、`managed_agents/self_hosted_sandboxes/`、`managed_agents/cma-mcp/`。
- **統合デモ**: `managed_agents/slack/`, `managed_agents/linear/`, `managed_agents/sentry/`, `managed_agents/roadtrip_planner/`、`claude_agent_sdk/session_browser_demo/`、`claude_agent_sdk/vulnerability_detection_agent/`。
- **フロントエンド美観のプロンプティング**: `coding/prompting_for_frontend_aesthetics.ipynb` (DESIGN.md 系の判断には別リファレンスを使う)。
- **課金**: `fable_5_fallback_billing/guide.ipynb`。
- **未読だがプロンプト / eval 設計に隣接するもの** (内容未確認、必要なら直接読む): `misc/metaprompt.ipynb` (プロンプト自動生成)、`misc/building_evals.ipynb` と `misc/generate_test_cases.ipynb` (eval とテストケース生成)、`misc/session_memory_compaction.ipynb`。
- **リポジトリ運営系**: `registry.yaml` / `authors.yaml` / `tests/` / `scripts/` / `CONTRIBUTING.md`。
