---
source: https://github.com/ai-boost/awesome-harness-engineering
distilled_commit: ea5e58b2e875b1e86aae19fc4c8103e6f52977b2
distilled_at: 2026-08-03
---

# awesome-harness-engineering 蒸留版

AI エージェントハーネス構築のパターン・テンプレート・資料の curated list (awesome list)。
原典は `awesome-harness-engineering` の clone (原典ルートは SKILL.md 参照)。以下のパスはリポジトリルートからの相対パス。
**中身の大半は外部リンク集**であり、ローカルに実体があるのは `templates/` の 4 ファイルとリポジトリ運用ファイルのみ。

## Contents

- まず押さえる
- 索引
  - ローカル実体 (原典に本文があるファイル)
  - README.md のカテゴリ構造
  - カテゴリ別の要資料 (外部 URL)
- 蒸留の範囲外

## まず押さえる

1. **リポジトリの正体**: 実体は `README.md` (611 行の注釈付きリンク集) + `templates/` の 4 テンプレート + `verify_urls.py` (URL 到達性検証スクリプト)。それ以外の情報はすべて外部リンク。本文を読みたいものはローカルには無く、URL 先を見る必要がある。
2. **定義** (`README.md` 冒頭): "Harness engineering is the discipline of designing the scaffolding — context delivery, tool interfaces, planning artifacts, verification loops, memory systems, and sandboxes — that surrounds an AI agent and determines whether it succeeds or fails on real tasks"。焦点はモデルではなくハーネス。
3. **中心原則**: "Every component here exists because the model can't do it alone — and the best harnesses are designed knowing those components will become unnecessary as models improve"。`templates/HARNESS_CHECKLIST.md` の「When this harness component should be removed」表 (Component / Exists because / Can be removed when) がこの原則を運用に落としている。
4. **分類原則** (`AGENTS.md`): セクションは vendor 別ではなく「解決する問題」別に編成する。各エントリは `- [Title](URL) — 1–2 sentence note` 形式で、note は「なぜ読む価値があるか」を opinionated に書くのが規約。
5. **`templates/AGENTS.md`**: プロジェクトレベルのエージェント指示テンプレート。要点は tool permissions を Allowed / Restricted (ask before proceeding) / Not allowed の 3 段で明示することと、タスク完了前の Verification gates (tests / linter / 変更範囲) をチェックリスト化すること。"agents perform better with clear boundaries than vague restrictions" とコメントで明言。
6. **`templates/PLAN.md` + `templates/IMPLEMENT.md`**: 長時間タスク用のペア artifact。PLAN.md は milestone ごとに `verify: <command>` を付け scope boundaries (in/out) を書く。IMPLEMENT.md は append-only の実装ログで、Deviations summary (Deviation / Reason / Plan updated?) と Open questions を追跡。OpenAI の "Run Long-Horizon Tasks with Codex" が示す Plan.md/Implement.md パターンのテンプレート化。
7. **Foundations の最初の 4 本**: OpenAI "Harness Engineering" (https://openai.com/index/harness-engineering/)、Anthropic "Building Effective Agents" (https://www.anthropic.com/research/building-effective-agents)、Anthropic "Harness Design for Long-Running Application Development" (https://www.anthropic.com/engineering/harness-design-long-running-apps)、Martin Fowler "Harness Engineering" (https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)。ハーネス設計を「分野」として定義する canonical essays としてリストの起点に置かれている。同セクション末尾には `lopopolo/harness-engineering` (https://github.com/lopopolo/harness-engineering) が加わり、再利用可能な `AGENTS.md`/`CLAUDE.md` 成果物・playbook・eval・ドメインモデリング文書を束ねた OSS の anthology + agent context bundle として位置づけられている (README の注記ベース、中身は未検証)。ハーネス成果物そのものを探すならここが最初の当たり先。
8. **ハーネスの構造分解**: LangChain "The Anatomy of an Agent Harness" (https://blog.langchain.com/the-anatomy-of-an-agent-harness/) は filesystem / code execution / sandbox / memory / context management の 5 primitives に分解。arXiv 論文 "What makes a harness a harness" (https://arxiv.org/abs/2606.10106) は agent loop / tool interface / context management / control mechanisms の 4 要素を必要十分条件として定義。
9. **「ハーネスだけで性能が動く」実証系**: LangChain "Improving Deep Agents with Harness Engineering" (https://blog.langchain.com/improving-deep-agents-with-harness-engineering/) はモデル交換なしのハーネス変更のみで Terminal Bench 2.0 のランクを 30 位から top 5 に改善した事例。LangChain "Tuning the harness, not the model" (Nemotron 3 Ultra playbook, https://blog.langchain.com/tuning-the-harness-not-the-model-a-nemotron-3-ultra-playbook, 2026 年 7 月) は harness-only tuning で Nemotron 3 Ultra を Deep Agents 上で Opus 4.8 の 1 point 差まで、約 1/10 のコスト ($4.48 vs $43.48) で到達させ、「evals はハーネス作業の訓練データ」「モデルの生の能力でなく fit が品質を決める」を実証。deepset "Harness Engineering" (https://www.deepset.ai/blog/harness-engineering) も failure 分類 (context / constraint / verification / planning) を各ハーネス部品に対応付ける同趣旨の synthesis。
10. **収載基準** (`CONTRIBUTING.md`): (1) specific harness problem に対応する、(2) 読む価値の理由 note が必須、(3) vendor-agnostic by principle (特定モデル依存でもパターンが一般化すれば可)。除外: 一般 AI/ML 論文・ハーネス無関係のモデルベンチマーク・マーケ記事・「モデルの使い方」チュートリアル。
11. **ハーネスと sandbox の内外関係**: "The Agent Harness Belongs Outside the Sandbox" (README `Security, Sandbox & Permissions`, https://www.mendral.com/blog/agent-harness-belongs-outside-sandbox) は agent loop を sandbox の外に置く設計論。credential を untrusted container に入れず、sandbox を suspendable な cattle として扱う。「harness inside」と「harness outside」は実装差でなく別のセキュリティ・信頼性モデルだという主張で、containment 設計 (Anthropic "how we contain Claude" 等) に一段の選択軸を足す。同セクションには OS 側に isolation primitive が無い環境への移植を扱う一次資料 (OpenAI "Building a safe, effective sandbox to enable Codex on Windows", https://openai.com/index/building-codex-windows-sandbox/) も並ぶ。
12. **鮮度と信頼性の注意**: エントリ数が多く (README 全体で `- [Title](URL)` 形式のエントリが 438)、2026 年の新しめの記事・arXiv・小規模リポジトリが大量に混在する。本蒸留は README の注記に基づき、外部 URL の生死や記載内容の真偽は未検証。重要判断では URL 先の一次資料を直接確認すること。リンク検証は原典の `verify_urls.py` で行う建て付け。

## 索引

### ローカル実体 (原典に本文があるファイル)

| トピック | 場所 (原典相対パス) | 内容 (一行) |
|---|---|---|
| リンク集本体 | `README.md` | 全カテゴリの注釈付き外部リンク集 (611 行)。この蒸留の元 |
| repo 運用規約 | `AGENTS.md` (`CLAUDE.md` は symlink) | この repo 自体への agent 指示: entry 形式、問題別分類の原則、収載/除外基準 |
| 収載基準 | `CONTRIBUTING.md` | 収載 3 条件 (specific problem / worth time / vendor-agnostic) と除外基準 |
| AGENTS.md テンプレ | `templates/AGENTS.md` | プロジェクト用 agent 指示: 構成・規約・permissions 3 段・verification gates |
| 計画テンプレ | `templates/PLAN.md` | milestone + `verify:` コマンド + scope boundaries + risks の計画 artifact |
| 実装ログテンプレ | `templates/IMPLEMENT.md` | append-only の決定ログ + deviations summary + open questions |
| レビューチェックリスト | `templates/HARNESS_CHECKLIST.md` | 出荷前レビュー 6 領域 (instructions / tools / context / planning / permissions / verification) + 部品除去条件表 |
| URL 検証 | `verify_urls.py` | README 内 URL の到達性を並列検証し JSON 出力する CI 用スクリプト |

### README.md のカテゴリ構造

| カテゴリ (README のセクション) | 内容 (一行) |
|---|---|
| Foundations | harness engineering を定義する canonical essays (OpenAI / Anthropic / Google / Fowler / arXiv 調査) |
| Design Primitives | 以下 12 サブカテゴリ。「問題別」分類の本体 |
| — Agent Loop | ReAct 以来のループ構造、hooks、middleware、compaction 段階、loop 制御の研究と実装 |
| — Planning & Task Decomposition | 計画 artifact (Plan.md 等)、planner/executor 分離、multi-agent topology 選択 |
| — Context Delivery & Compaction | context engineering、圧縮/compaction、prompt caching、filesystem paradigm、コード検索 MCP、agent 可読 wiki 生成、log 検索型の programmatic memory |
| — Tool Design | tool の命名・schema・エラー設計、structured output、tool annotation |
| — Skills & MCP | MCP 仕様・公式サーバ・skills フレームワーク・agent 間プロトコル (A2A 等) |
| — Permissions & Authorization | 構造化 permission、excessive agency、agent の認証認可標準 |
| — Memory & State | クロスセッション記憶 (Letta/mem0/Zep 系)、graph memory・記憶ガバナンスの研究、既存セッションログを記憶に転用する系 |
| — Task Runners & Orchestration | multi-agent フレームワーク (LangGraph/ADK/AutoGen/CrewAI 等)、並列実行基盤 (worktree 分離)、handoff 用の artifact 参照プリミティブ |
| — Verification & CI Integration | 検証をループに組み込む方法、eval の CI 統合、regression testing |
| — Observability & Tracing | trace 基盤 (Langfuse/Phoenix 等)、OTel GenAI 規約、token/コストの作業単位への帰属 |
| — Debugging & Developer Experience | session replay、agent 用デバッガ、fault taxonomy 研究 |
| — Human-in-the-Loop | interrupt/approval パターン、HITL プロトコル、自律度の計測 |
| Reference Implementations | 実リポジトリ研究用。4 サブカテゴリ: Tutorials & Educational / Generators & Meta-Harnesses (自己改善ハーネス) / Demo Harnesses (OpenHands, SWE-agent 等) / Adjacent Collections |
| Security, Sandbox & Permissions | sandbox 実装 (E2B/Daytona/microVM 系、使い捨て DB sandbox)、prompt injection 防御、封じ込め・ガバナンス |
| Evals & Verification | eval フレームワークとベンチマーク (SWE-bench, tau-bench, Inspect AI 等) |
| Templates | 上記 `templates/` 4 ファイルへの索引 (ローカル実体はここだけ) |
| Production Infrastructure & Operations | 本番運用: managed 基盤、コスト最適化、スケーリング、self-healing |
| Related Awesome Lists | 隣接領域の curated list (context engineering, Claude Code, MCP servers 等) |

### カテゴリ別の要資料 (外部 URL)

各カテゴリからベンダー公式・定番・要となる解説を数個ずつ。選定は蒸留者の判断。

| トピック | 場所 (URL) | 内容 (一行) |
|---|---|---|
| Foundations | https://openai.com/index/harness-engineering/ | OpenAI によるharness engineering の分野定義 (コンテキスト構造化の指針も兼ねる) |
| Foundations | https://www.anthropic.com/research/building-effective-agents | Anthropic の基礎ガイド: workflow vs agent の使い分けと primitives の合成 |
| Foundations | https://www.anthropic.com/engineering/harness-design-long-running-apps | 複数セッション開発向けハーネス設計。「部品の前提は失効する」の出典 |
| Foundations | https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html | Fowler の synthesis: context engineering / architectural constraints / entropy management の 3 系統 |
| Foundations | https://blog.langchain.com/the-anatomy-of-an-agent-harness/ | ハーネスの 5 primitives 分解と、モデルがハーネスに overfit する共進化の警告 |
| Foundations | https://github.com/RUCAIBox/awesome-agent-harness | 500+ 文献のハーネス工学サーベイ。学術側の補完 |
| Foundations | https://blog.langchain.com/tuning-the-harness-not-the-model-a-nemotron-3-ultra-playbook | harness-only tuning で Nemotron 3 Ultra を Opus 4.8 の 1 point 差・約 1/10 コストに。fit が品質を決める実証 |
| Foundations | https://github.com/lopopolo/harness-engineering | 再利用可能な `AGENTS.md`/`CLAUDE.md`・playbook・eval・ドメインモデリング文書を束ねた anthology + agent context bundle。ハーネスを「組織の非機能要件を運ぶ環境」と再定義 |
| Agent Loop | https://arxiv.org/abs/2210.03629 | ReAct 論文。Thought/Action/Observation ループの原典 |
| Agent Loop | https://openai.com/index/unrolling-the-codex-agent-loop/ | Codex のループ 1 周 (observe/plan/act/verify) の分解 |
| Agent Loop | https://blog.langchain.com/improving-deep-agents-with-harness-engineering/ | ハーネス変更のみで Terminal Bench rank 30→top5 の実証 |
| Agent Loop | https://github.com/cobusgreyling/loop-engineering | agent loop の 7 production pattern + readiness/state/cost/drift を扱う CLI 群。one-off prompting から durable/observable な loop への実践資料 |
| Planning | https://developers.openai.com/blog/run-long-horizon-tasks-with-codex/ | Plan.md / Implement.md を再利用可能なハーネス artifact にする実践 |
| Planning | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents | コンテキストウィンドウをまたぐ進捗維持: initializer→coder の引き継ぎ設計 |
| Planning | https://blog.langchain.com/choosing-the-right-multi-agent-architecture/ | subagents / skills / handoffs / router の 4 パターン選択の判断枠組み |
| Context | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents | コンテキスト全体 (system prompt / tools / 履歴) を有限資源として管理する体系 |
| Context | https://platform.claude.com/docs/en/build-with-claude/compaction | Claude API のサーバサイド compaction 公式リファレンス |
| Context | https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching | prompt caching の公式解説。ハーネスレベルの最重要コストレバー |
| Context | https://github.com/alexisfox7/PRO-LONG | 観測を構造化ログに append し、agent がコードで検索する programmatic memory。固定 summarization/compaction を retrieval 問題に置換 (4.2–5.8x token 削減、ARC-AGI-3) |
| Context | https://github.com/langchain-ai/openwiki | LangChain の CLI。コードベース/目的別メモリの agent 可読 wiki を生成・維持し、Google Open Knowledge Format で出力して CI で鮮度を保つ |
| Tool Design | https://www.anthropic.com/engineering/writing-effective-tools-for-agents | tool の命名・schema・エラーメッセージ・返り値規約の公式ガイド |
| Tool Design | https://platform.openai.com/docs/guides/function-calling | function calling の事実上の業界標準 JSON Schema 規約 |
| Skills & MCP | https://modelcontextprotocol.io/introduction | MCP 公式イントロダクション |
| Skills & MCP | https://github.com/modelcontextprotocol/servers | 公式リファレンス MCP サーバ実装集 |
| Skills & MCP | https://www.anthropic.com/engineering/code-execution-with-mcp | MCP をコード実行と組み合わせて効率化する Anthropic の実践記事 |
| Skills & MCP | https://github.com/DietrichGebert/ponytail | built-in を優先し新規依存を避け最小コードだけ書く「lazy senior dev」として振る舞わせる skill。実 Claude Code セッションで約 54% 行数削減・約 20% コスト削減 (safety guard は維持)。capability 追加ではなく over-engineering を抑える側のハーネス介入 |
| Permissions | https://www.anthropic.com/engineering/beyond-permission-prompts | 自然言語 permission ではなく構造化 authorization を組み込む設計 |
| Permissions | https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ | OWASP による excessive agency リスクの定義 |
| Permissions | https://platform.claude.com/docs/en/agent-sdk/permissions | Claude Agent SDK の permission アーキテクチャ公式リファレンス |
| Permissions | https://github.com/Infisical/agent-vault | credential broker が agent と API の間に立ち、outbound request に本物の credential を注入して secret を agent に持たせない。API key/PAT 流出を harness 層の境界で潰す |
| Memory | https://github.com/letta-ai/letta | Letta (MemGPT)。3 層メモリ (core/archival/recall) の reference architecture |
| Memory | https://github.com/mem0ai/mem0 | drop-in の universal memory layer 定番 |
| Memory | https://github.com/vshulcz/deja-vu | 既にディスクにあるコーディングエージェントのセッションを索引して MCP で返すだけの zero-dependency binary。LLM 呼び出し・embedding・API key 無しで memory の cold-start を埋める |
| Orchestration | https://github.com/langchain-ai/langgraph | graph ベース state machine。ループ制御・checkpoint の具体的実装 |
| Orchestration | https://github.com/openai/openai-agents-python | OpenAI Agents SDK: handoffs と guardrails 中心の軽量 multi-agent |
| Orchestration | https://github.com/google/adk-python | Google ADK: code-first の multi-agent orchestration |
| Orchestration | https://www.anthropic.com/engineering/building-c-compiler | 16 並列 Claude で C コンパイラを作る協調事例 |
| Orchestration | https://github.com/vercel/eve | Vercel の filesystem-first な durable agent framework。instructions/tools/skills/channels/cron を通常ディレクトリに置き harness を inspectable かつ version-controlled にする |
| Orchestration | https://github.com/modiqo/waggle | handoff で context を貼り付ける代わりに約 30 byte の解決可能な artifact 参照を渡す。各 consumer が byte 予算内で必要な projection だけ解決し、訂正が全保持者に伝播 |
| Orchestration | https://github.com/stablyai/orca | Codex / Claude Code / OpenCode / Pi を分離 git worktree で並走させる orchestrator。fleet 実行を desktop IDE 化 |
| Verification & CI | https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents | agent eval の枠組み。unit-test 型 eval が agent で機能しない理由 |
| Verification & CI | https://github.com/promptfoo/promptfoo | YAML 駆動 LLM テスト + LLM-as-judge + CI 統合の定番 |
| Verification & CI | https://github.com/vaquarkhan/mcp-test-harness | MCP サーバの pytest 型テスト framework。stdio/SSE/HTTP 横断で tool/schema の regression を通常のテスト失敗に落とす |
| Observability | https://github.com/langfuse/langfuse | 最も普及した self-hostable LLM observability |
| Observability | https://opentelemetry.io/docs/specs/semconv/gen-ai/ | OTel の GenAI span 標準属性規約 |
| Observability | https://github.com/mikehasa/agentacct | local-first の Agent Work Intelligence。Claude Code / Codex / OpenCode の既存セッションログを取り込み、token と推定コストを作業ステップへ confidence 付きで帰属させて private dashboard に出す (cloud sync / API key 不要) |
| Debugging | https://github.com/AgentOps-AI/agentops | session replay・コスト追跡・failure 検出の agent engineering platform |
| Debugging | https://github.com/cosmtrek/mindwalk | Claude Code / Codex の JSONL セッションログをコードベースの 3D マップ上で replay。探索の drift と context 圧を可視化し、agent の footprint がタスク範囲と合っていたかを見る |
| HITL | https://langchain-ai.github.io/langgraph/concepts/human_in_the_loop/ | interrupt / breakpoint による HITL の体系的解説 |
| HITL | https://platform.claude.com/docs/en/agent-sdk/user-input | Claude Agent SDK の承認・ユーザー入力処理の実装リファレンス |
| HITL | https://github.com/SmileLikeYe/agent-chief | local-first の attention orchestration 層。3 段の worthiness engine が「人を割り込ませる / agent に振る / memory に整理する」を判定し、agent 由来の通知の洪水を構造化された HITL 判断に変える |
| Reference impl | https://github.com/wquguru/harness-books | `Tutorials & Educational` の書籍 2 冊。Claude Code / Codex を観察対象に、prompt / tool / permission / recovery path / team rule を「モデルの付属品ではなく 1 つの control plane」として説く書籍長の解説 |
| Reference impl | https://github.com/huggingface/smolagents | 意図的に最小 (~1,000 行) の agent library。ループの学習用 |
| Reference impl | https://github.com/OpenHands/OpenHands | 最もアーキテクチャが完成した OSS コーディングエージェント |
| Reference impl | https://github.com/Tracer-Cloud/opensre | AI SRE エージェント構築の OSS framework。60+ の observability/remediation tool 連携と合成インシデントの評価環境を備え、インシデント対応を評価可能なハーネスとして扱う |
| Reference impl | https://github.com/SWE-agent/SWE-agent | Agent-Computer Interface (専用 viewer/search/editor) の原点 |
| Reference impl | https://github.com/yc-software/qm | Y Combinator の multiplayer ハーネス。個人ごとの隔離 workspace + 共有 Slack channel/project を併存させ、backend (Claude Code / Codex / OpenCode / Pi) と scope 所有の skills を差し替え可能にする。チーム規模導入の参照 |
| Reference impl | https://platform.claude.com/docs/en/agent-sdk/overview | Claude Code のハーネス全体をプログラマブルに使う公式 SDK |
| Security/Sandbox | https://www.anthropic.com/engineering/how-we-contain-claude | Anthropic のプロダクト横断の封じ込め (containment) 設計 |
| Security/Sandbox | https://openai.com/index/building-codex-windows-sandbox/ | Seatbelt/seccomp 相当の capability isolation が無い Windows で Codex を sandbox 化した OpenAI の一次資料。AppContainer / Windows Sandbox / MIC が不足した理由と、write-restricted token + network 抑止で作る elevated sandbox |
| Security/Sandbox | https://github.com/e2b-dev/E2B | agent 用 Firecracker microVM sandbox の定番 |
| Security/Sandbox | https://simonwillison.net/series/prompt-injection/ | prompt injection 問題の最も網羅的な公開解説シリーズ |
| Security/Sandbox | https://github.com/tldrsec/prompt-injection-defenses | 実用的な prompt injection 防御のカタログ |
| Security/Sandbox | https://github.com/LVTD-LLC/pgsandbox | local-first MCP サーバ。使い捨て PostgreSQL を scoped role + TTL 回収 + 制限付き SQL/schema tool で提供し、長命 admin 資格情報を渡さずに migration 検証や DB バグ再現をさせる |
| Evals | https://www.swebench.com | コーディングエージェントの canonical benchmark |
| Evals | https://github.com/UKGovernmentBEIS/inspect_ai | UK AISI の eval framework。外部 agent の評価をネイティブ対応 |
| Evals | https://github.com/sierra-research/tau-bench | user-tool-policy の三者相互作用を測るベンチマーク |
| Production | https://www.langchain.com/state-of-agent-engineering | LangChain の業界サーベイ (1,300+ 回答) |
| Related lists | https://github.com/hesreallyhim/awesome-claude-code | Claude Code 特化の curated list |
| Related lists | https://github.com/appcypher/awesome-mcp-servers | MCP サーバの網羅リスト |

## 蒸留の範囲外

- **各エントリの詳細な注記**: README の各エントリには 1–2 文の opinionated note が付いており、本蒸留はその大半 (438 のうち上記以外) を割愛した。特定の問題領域を深掘りするときは `README.md` の該当セクションを直接 Grep/Read する (セクション見出しは `## ` / `### `、エントリは `- [Title](URL) — note` 形式で機械的に抽出できる)。
- **Generators & Meta-Harnesses と研究系エントリの個別評価**: 自己改善ハーネス (meta-harness / harness-evolver 系) や 2026 年の arXiv 論文群は数が多く玉石混交のため、個別には挙げていない。関心があれば `README.md` の `### Generators & Meta-Harnesses` と各カテゴリ末尾の arXiv エントリを見る。
- **templates/ の全文**: 各テンプレートは短い (40–80 行) ので、使うときは原典の `templates/*.md` をそのままコピーして使う。コメントが本体なので、`AGENTS.md` (repo 運用規約) の指示どおりコメント構造を保つ。
- **URL の生死確認**: 本蒸留では実施していない。必要なら原典で `python verify_urls.py` を実行する (要 `aiohttp`)。
- **Claude Code 固有のベストプラクティス**: このリストは vendor 横断が主眼。Claude Code 固有の判断は `claude-code-best-practice/` (別蒸留) を優先する。
