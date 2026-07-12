---
source: https://github.com/dair-ai/Prompt-Engineering-Guide
distilled_commit: 57673726396dd94acb23bdb1e67f27c78ee85a8e
distilled_at: 2026-07-12
---

# Prompt-Engineering-Guide 蒸留版

dair-ai によるプロンプトエンジニアリングのガイド・論文・技法集 (promptingguide.ai の Next.js ソース)。
本文はすべて `pages/` 配下の `.mdx`。各ページは `<name>.<lang>.mdx` の多言語構成で、
**日本語版は `.ja.mdx` ではなく `.jp.mdx`** (例: `pages/techniques/cot.jp.mdx`)。
新しめのページ (agents/, guides/, meta-prompting) は `.en.mdx` のみ。
パスはすべてリポジトリルートからの相対 (原典ルートは SKILL.md 参照)。

## Contents

- まず押さえる
- テクニック索引 (逆引き: 場面 → 技法)
- 索引 (テクニック以外のセクション)
- 日本語版ページの分布
- 蒸留の範囲外

## まず押さえる

1. **プロンプトの 4 要素**: Instruction / Context / Input Data / Output Indicator。この分解で
   プロンプトを設計・レビューする。— `pages/introduction/elements.en.mdx`
2. **設計の基本則**: Start Simple (反復前提で小さく始める)、指示は具体的に (Specificity)、
   曖昧さを避ける、「するな」より「しろ」で書く (To do or not to do)。
   — `pages/introduction/tips.en.mdx`
3. **LLM パラメータが前提**: temperature / top_p は低いほど決定的 (事実 QA 向き)、高いほど
   多様 (創作向き)。他に max length, stop sequences, frequency/presence penalty。
   — `pages/introduction/settings.en.mdx`
4. **まず zero-shot、足りなければ few-shot**: 指示チューニング済みモデルは例示なしで多くの
   タスクをこなす。失敗したら例示 (デモンストレーション) で in-context learning に切り替える。
   — `pages/techniques/zeroshot.en.mdx`, `pages/techniques/fewshot.en.mdx`
5. **推論タスクには CoT**: 中間推論ステップを例示する。zero-shot CoT は "Let's think step by
   step" を足すだけ。例示の手作りを避ける Auto-CoT もある。— `pages/techniques/cot.en.mdx`
6. **CoT の精度をさらに上げるなら self-consistency**: 多様な推論パスをサンプリングし
   最も一貫した答えを採る (greedy decoding の置き換え)。— `pages/techniques/consistency.en.mdx`
7. **知識不足による hallucination には RAG**: 外部知識源を検索して文脈に注入し、事実整合性と
   信頼性を上げる。knowledge-intensive なタスク向け。— `pages/techniques/rag.en.mdx`
8. **ツール利用と推論を組み合わせるなら ReAct**: reasoning trace と action を交互に生成し、
   外部ソースから情報を取得。CoT との併用が最良と報告。エージェント設計の原型。
   — `pages/techniques/react.en.mdx`
9. **複雑なタスクは分割**: サブタスクに分けて出力を次のプロンプトに渡す (Prompt Chaining)。
   透明性・制御性・デバッグ性が上がる。— `pages/techniques/prompt_chaining.en.mdx`
10. **探索・先読みが要る問題は ToT**: 思考の木を探索アルゴリズム (BFS/DFS) + 自己評価で探索。
    単発プロンプトでは解けない計画系に。— `pages/techniques/tot.en.mdx`
11. **正確な計算・日付処理は LLM にやらせない**: PAL は解法を Python 等のランタイムに
    オフロードする。— `pages/techniques/pal.en.mdx`
12. **プロンプト自体も自動最適化できる**: APE は指示文の生成と選択を black-box 最適化として
    行い、人手の "Let's think step by step" を上回る zero-shot CoT プロンプトを発見した。
    — `pages/techniques/ape.en.mdx`
13. **factuality 対策**: ground truth を文脈で与える、確率パラメータを下げる、知らないときは
    "I don't know" と言わせる、既知/未知の QA 例を混ぜる。— `pages/risks/factuality.en.mdx`
14. **prompt injection / jailbreak は設計時のリスク**: injection, leaking, jailbreaking の
    攻撃例と防御 (指示での防御、パラメータ化、引用符/追加フォーマット等) を押さえる。
    — `pages/risks/adversarial.en.mdx`
15. **エージェントでは context engineering が中心**: システムプロンプト・指示・制約・ツール・
    記憶を含む「文脈全体」の設計として捉える。— `pages/agents/context-engineering.en.mdx`,
    `pages/guides/context-engineering-guide.en.mdx`

## テクニック索引

`pages/techniques/` 配下、_meta.en.json の掲載順。パスは `.en.mdx` を示す (日本語版は
meta-prompting 以外 `.jp.mdx` あり)。

| テクニック | 本質 (一行) | 選ぶ場面 | 原典パス |
|---|---|---|---|
| Zero-shot | 例示なしで指示のみ | まず試すデフォルト。単純な分類・変換 | `pages/techniques/zeroshot.en.mdx` |
| Few-shot | 例示で in-context learning | zero-shot が失敗する時。出力形式を例で固定したい時 | `pages/techniques/fewshot.en.mdx` |
| Chain-of-Thought (CoT) | 中間推論ステップを促す | 算術・常識・記号推論。few-shot でも失敗する複雑タスク | `pages/techniques/cot.en.mdx` |
| Meta Prompting | 内容でなく構造・パターンで指示する | トークン節約、few-shot の例示バイアスを避けたい時 | `pages/techniques/meta-prompting.en.mdx` |
| Self-Consistency | 複数推論パスの多数決 | CoT の答えが不安定な時。精度をコストで買う | `pages/techniques/consistency.en.mdx` |
| Generated Knowledge | 先に知識を生成させてから回答 | 常識・知識を要するが検索基盤がない時 | `pages/techniques/knowledge.en.mdx` |
| Prompt Chaining | サブタスク分割し出力を次段へ渡す | 一発プロンプトが複雑すぎる時。透明性・デバッグ性が欲しい時 | `pages/techniques/prompt_chaining.en.mdx` |
| Tree of Thoughts (ToT) | 思考の木 + 探索 (BFS/DFS) + 自己評価 | 探索・先読み・バックトラックが要る問題 (計画、ゲーム) | `pages/techniques/tot.en.mdx` |
| RAG | 外部知識を検索して文脈に注入 | knowledge-intensive なタスク、hallucination 抑制、最新情報 | `pages/techniques/rag.en.mdx` |
| ART | タスクライブラリから推論+ツール使用のデモを自動選択 | ツール使用デモの手作りを避けたい時 | `pages/techniques/art.en.mdx` |
| APE | プロンプト自体を LLM で生成・探索・選択 | 指示文の自動最適化。人手プロンプトの改善 | `pages/techniques/ape.en.mdx` |
| Active-Prompt | 不確実性の高い問題を選んで人手 CoT 注釈 | CoT 例示セットをタスクに適応させたい時 | `pages/techniques/activeprompt.en.mdx` |
| Directional Stimulus | 小型 policy LM がヒント (stimulus) を生成 | frozen LLM を細かく誘導したい時 (要約の方向付け等) | `pages/techniques/dsp.en.mdx` |
| PAL | 解法をプログラム生成しランタイムで実行 | 正確な計算・日付・記号操作。自由文 CoT の計算ミス回避 | `pages/techniques/pal.en.mdx` |
| ReAct | 推論 trace と行動 (ツール呼び出し) を交互生成 | 外部情報の取得・環境操作が要るタスク。エージェントの基本形 | `pages/techniques/react.en.mdx` |
| Reflexion | 環境フィードバックを言語化した自己反省を次試行の文脈に | 試行錯誤で学習させたい時 (逐次的意思決定、コーディング) | `pages/techniques/reflexion.en.mdx` |
| Multimodal CoT | テキスト+画像の 2 段階 (根拠生成→回答) CoT | 視覚情報を含む推論タスク | `pages/techniques/multimodalcot.en.mdx` |
| GraphPrompt | グラフ向けプロンプトフレームワーク | グラフ構造データの下流タスク (ページは stub) | `pages/techniques/graph.en.mdx` |

### 逆引き (場面 → 技法)

- 出力形式を安定させたい → Few-shot / Meta Prompting
- 推論の正答率を上げたい → CoT → Self-Consistency → ToT (コスト順)
- 事実性・最新性が要る → RAG / Generated Knowledge (risks/factuality も参照)
- ツール・外部環境と連携 → ReAct / ART / PAL (function calling は `pages/agents/function-calling.en.mdx`)
- プロンプト自体を改善したい → APE / Active-Prompt + `pages/guides/optimizing-prompts.en.mdx`
- 複雑ワークフローの信頼性 → Prompt Chaining / Reflexion + `pages/agents/` 一式

## 索引

| セクション | 内容 | 主なパス |
|---|---|---|
| Introduction | 基礎: プロンプトの要素、LLM 設定、設計 tips、基本例 | `pages/introduction/{basics,elements,settings,tips,examples}.en.mdx` |
| AI Agents | エージェント入門、構成要素、function calling、workflow vs agent、context engineering、deep agents | `pages/agents/*.en.mdx` (en のみ) |
| Guides | 長文ガイド: prompt 最適化、reasoning LLM、context engineering、deep research、4o 画像生成 | `pages/guides/*.en.mdx` (en のみ) |
| Applications | 応用: コード生成、function calling、合成データ (RAG 用)、context caching、PAL によるデータ生成等 | `pages/applications/*.en.mdx` |
| Prompt Hub | タスク別プロンプト実例集 (classification, coding, evaluation, information-extraction, reasoning 等 12 分類) | `pages/prompts/<task>/*.mdx` |
| Models | モデル別ガイド: ChatGPT, GPT-4, Claude 3, Gemini, Llama 3, Mistral, Mixtral, Phi-2, Gemma, Grok-1 等 | `pages/models/*.en.mdx` |
| Risks & Misuses | adversarial prompting (injection/leaking/jailbreak), factuality, biases | `pages/risks/{adversarial,factuality,biases}.en.mdx` |
| LLM Research Findings | 研究トピック解説: LLM agents, RAG (faithfulness/hallucination), reasoning, 合成データ, tokenization 等 | `pages/research/*.en.mdx` |
| Papers / Tools / Readings | 論文・ツール・追加資料のリンク集 | `pages/{papers,tools,readings}.en.mdx` |
| Notebooks / Datasets | 実行例 notebook とデータセットのリンク | `notebooks/`, `pages/{notebooks,datasets}.en.mdx` |

## 日本語版ページの分布

`.jp.mdx` の有無 (en ページ数比)。日本語で読みたい場合は同名 `.jp.mdx` を先に確認:

- 完備: introduction (5/5), risks (3/3), techniques (17/18, meta-prompting のみ en)
- 部分的: models (14/21), prompts (12/36), applications (5/9), research (3/13)
- なし: agents (0/7), guides (0/5) — 新しいセクションは en のみ

注意: 訳は古い場合がある。正は `.en.mdx`。

## 蒸留の範囲外

- **各技法の具体的プロンプト例・コード例**: 本文の大半は実例。使う時は該当
  `pages/techniques/<name>.en.mdx` を直接読む (LangChain/OpenAI のコード例含む)。
- **Prompt Hub の個別プロンプト**: 12 タスク分類 × 個別ページ。実例が欲しい時に
  `pages/prompts/<task>/` を開く。
- **モデル別の詳細**: 各モデルの能力・ベンチ結果・使い方は `pages/models/*.en.mdx`。
  2024 年前半までの情報が中心で古い可能性が高い。
- **長文ガイドの本文**: reasoning LLM の使い分け、deep research、context engineering の
  詳細は `pages/guides/*.en.mdx` と `pages/agents/*.en.mdx` を直接読む。
- **論文リスト・リンク集**: `pages/papers.en.mdx`, `pages/readings.en.mdx`。
- **サイト実装 (Next.js/Nextra)**: `components/`, `theme.config.tsx` 等はハーネス設計には無関係。
