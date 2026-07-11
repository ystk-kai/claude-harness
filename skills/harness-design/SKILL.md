---
name: harness-design
description: LLM ハーネス・プロンプト設計のローカル参照資料集 (~/.claude/references/) を使うためのスキル。プロジェクトのハーネス (CLAUDE.md / AGENTS.md / skills / slash commands / subagents / hooks / MCP 設定) を設計・作成・レビュー・監査するとき、プロンプトエンジニアリング (プロンプトの設計・改善・テクニック選定) を行うとき、エージェントの信頼性設計を検討するとき、UI 生成用の DESIGN.md を選定するときに、このスキルを読んでから該当リポジトリを参照する。Triggers: harness, ハーネス, CLAUDE.md, AGENTS.md, skill 作成, subagent, プロンプト改善, prompt engineering, agent design, best practice, DESIGN.md
---

# harness-design: ローカル参照資料集の使い方

ハーネス設計・プロンプト設計の判断は、Web 検索より先に以下のローカル clone を正として参照する。
ローカルパスを読む (Grep/Glob/Read が使える・決定的・オフライン耐性)。URL は出所の証跡と復旧用。

## 参照リポジトリ

ルート: `~/.claude/references/`

| パス | 内容 | 使いどころ |
|---|---|---|
| `claude-code-best-practice/` | Claude Code の実践知 (agents/commands/skills/memory の使い分け、workflows、tips)。「最も軽い機構を選ぶ」原則は `reports/claude-agent-command-skill.md` | Claude Code のハーネス (CLAUDE.md, skills, subagents, hooks) を設計・監査するとき |
| `awesome-harness-engineering/` | AI エージェントハーネス構築のパターン・テンプレート・資料の curated list | ハーネス設計の選択肢を広く調べるとき、他ツール事例を探すとき |
| `12-factor-agents/` | 信頼性の高い LLM アプリケーションを作る 12 原則 | エージェントのアーキテクチャ判断 (状態管理、制御フロー、human-in-the-loop 等) の原則確認 |
| `Prompt-Engineering-Guide/` | プロンプトエンジニアリングの技法・論文・ガイド集 (dair-ai) | プロンプト自体の設計・改善・テクニック選定 (few-shot, CoT 等) |
| `awesome-design-md/` | 開発者向けサイトのデザイン言語を分析した DESIGN.md 集 (73+) | UI 生成時にデザイン言語の雛形 DESIGN.md を選ぶとき (ハーネス設計とは別用途) |

出所 (復旧用 URL):

- https://github.com/shanraisshan/claude-code-best-practice
- https://github.com/ai-boost/awesome-harness-engineering
- https://github.com/humanlayer/12-factor-agents
- https://github.com/dair-ai/Prompt-Engineering-Guide
- https://github.com/voltagent/awesome-design-md

## Bootstrap (パスが存在しないとき)

```bash
mkdir -p ~/.claude/references && cd ~/.claude/references
git clone --depth 1 <上記の出所 URL>
```

## 鮮度と再現性

- 通常はそのまま読む。最新情報が必要なときだけ `git pull --ff-only` してから読む。
- 監査・レビューの基準として使うときは、使った版の commit SHA (`git rev-parse HEAD`) を成果物に記録する。ブランチ名は版の識別子にしない。

## 読み方

- リポジトリ全体や README 全文をコンテキストに載せない。README/目次で当たりを付け、`rg`/Grep で絞り込み、必要なファイルの必要な範囲だけ Read する。
- 複数リポジトリで見解が割れたら、Claude Code 固有の話は `claude-code-best-practice` を優先し、一般原則は `12-factor-agents` を優先する。バージョン依存の記述 (特定モデル・特定 CLI 版に固定された記述) は参考値として扱い、断定しない。
