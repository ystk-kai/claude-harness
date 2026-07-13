---
name: harness-design
description: LLM ハーネス・プロンプト設計の参照資料を 2 層 (このスキル内の蒸留版 references/*.md と、~/.claude/references/ の原典 clone) で使うためのスキル。プロジェクトのハーネス (CLAUDE.md / AGENTS.md / skills / slash commands / subagents / hooks / MCP 設定) を設計・作成・レビュー・監査するとき、プロンプトエンジニアリング (プロンプトの設計・改善・テクニック選定) を行うとき、エージェントの信頼性設計を検討するとき、UI 生成用の DESIGN.md を選定するときに、まず蒸留版を読み、索引が指す原典ファイルだけを深掘りする。Triggers: harness, ハーネス, CLAUDE.md, AGENTS.md, skill 作成, subagent, プロンプト改善, prompt engineering, agent design, best practice, DESIGN.md
compatibility: Requires git and network access to clone/update the reference repos at ~/.claude/references/ (external to the skill directory; run install.sh --with-references)
---

# harness-design: ローカル参照資料集の使い方

ハーネス設計・プロンプト設計の判断は、Web 検索より先にこの資料集を参照する。構成は 2 層:
**蒸留版** (`references/*.md`、このスキル内。確度の高い要点と索引) と **原典** (原典ルート配下の clone。全文)。
蒸留版と原典が食い違う場合は原典が正 (蒸留版が古い可能性がある。「鮮度と更新」で検出・修正する)。

## 読む順序

1. まず該当リポジトリの蒸留版 (`references/<repo>.md`) を読む
2. 深掘りは蒸留版の索引が指す原典ファイルだけを Read する
3. 蒸留版に載っていない話題のみ原典を直接探す: README/目次で当たりを付け、`rg`/Grep で絞り込む (有用な発見は蒸留版への追記を検討する)

いずれの場合も、リポジトリ全体や README 全文をコンテキストに載せず、必要なファイルの必要な範囲だけ Read する。

## 参照リポジトリ

原典ルート: `~/.claude/references/` (`CLAUDE_CONFIG_DIR` 設定時は `$CLAUDE_CONFIG_DIR/references/`)。
原典 clone がないときは、このリポジトリの `install.sh --with-references` で一括取得する (入手方法は README)。
各リポジトリの出所 URL は、蒸留版 frontmatter の `source` を唯一の正とする。

資料は性格が異なる。同列の一覧に見えても正典性 (どこまで断定の根拠にできるか) と読み方は違うので、下のカテゴリと Read 条件で選ぶ。

- **コア原則** — エージェント設計の一般原則。アーキテクチャ判断の典拠にできる。
- **コア技法** — プロンプト技法。プロンプト設計・改善の典拠にできる。
- **Claude Code 固有** — CC のハーネス/skill の一次資料〜実践知。CC 固有の判断はここを最優先し、一般原則より優先する。
- **探索索引** — 大半が外部リンク集。「知識源」でなく「どこを見るかの地図」。ここ自体を断定の典拠にせず、指す一次資料に当たる。
- **隣接領域** — ハーネス設計とは別用途 (UI 生成)。ハーネス判断の典拠にしない。

| カテゴリ | 原典 | 蒸留版 | 使いどころ |
|---|---|---|---|
| コア原則 | `12-factor-agents/` | [references/12-factor-agents.md](references/12-factor-agents.md) | エージェントのアーキテクチャ判断 (状態管理、制御フロー、human-in-the-loop 等) の原則確認 |
| コア技法 | `Prompt-Engineering-Guide/` | [references/Prompt-Engineering-Guide.md](references/Prompt-Engineering-Guide.md) | プロンプト自体の設計・改善・テクニック選定 (few-shot, CoT 等) |
| Claude Code 固有 | `claude-code-best-practice/` | [references/claude-code-best-practice.md](references/claude-code-best-practice.md) | Claude Code のハーネス (CLAUDE.md, skills, subagents, hooks) を設計・監査するとき。「最も軽い機構を選ぶ」原則 |
| Claude Code 固有 | `skills/` (anthropics/skills) | [references/skills.md](references/skills.md) | skill 定義 (SKILL.md) を設計・作成・レビューするとき。公式の仕様・雛形・skill-creator・模範実装の一次資料 |
| 探索索引 | `awesome-harness-engineering/` | [references/awesome-harness-engineering.md](references/awesome-harness-engineering.md) | ハーネス設計の選択肢を広く調べるとき、他ツール事例を探すとき。指す一次資料に当たる |
| 隣接領域 | `awesome-design-md/` | [references/awesome-design-md.md](references/awesome-design-md.md) | UI 生成時にデザイン言語の雛形 DESIGN.md を選ぶとき (ハーネス設計とは別用途) |

## 鮮度と更新

- 蒸留版 frontmatter の `distilled_commit` が、どのコミット時点の原典に基づくかを示す
- `scripts/check-freshness.sh` が origin を fetch し、BEHIND (clone が upstream より古い) / STALE (蒸留版が clone より古い) と差分コミットを表示する。`--offline` で fetch を省略
- STALE のときは [DISTILLING.md](DISTILLING.md) の手順で蒸留版を更新する (SHA だけの無言 bump をしない)
- 一連の更新 (チェック → 原典 clone の `git pull` → STALE の再蒸留) は `/claude-harness-refs-update` で起動できる (`--check` でチェックのみ)
- 監査・レビューの基準として使うときは、使った版の commit SHA を成果物に記録する。ブランチ名は版の識別子にしない

## 判断の優先順位

- 複数リポジトリで見解が割れたら、Claude Code 固有の話は `claude-code-best-practice` を優先し、一般原則は `12-factor-agents` を優先する
- ただし skill 定義 (SKILL.md の仕様・雛形・設計パターン) は公式一次資料の `skills/` (anthropics/skills) を優先し、`claude-code-best-practice` の skill tips は二次情報として補完に使う
- バージョン依存の記述 (特定モデル・特定 CLI 版に固定された記述) は参考値として扱い、断定しない
