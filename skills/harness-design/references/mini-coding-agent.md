---
source: https://github.com/rasbt/mini-coding-agent
distilled_commit: 717cae4ff10d01773bd12951f62a575825053414
distilled_at: 2026-07-28
---

# mini-coding-agent 蒸留版

Sebastian Raschka による教育目的の単一ファイル製コーディングエージェント (Ollama バックエンド、標準ライブラリのみ、実装 1019 行)。
**コーディングエージェントのハーネスが実装としてどう成立しているかの断面図**として使う。README が挙げる 6 コンポーネントが、そのまま実装の関数群に対応している (`mini_coding_agent.py:38-46` に対応表コメントがある)。
原典は `mini-coding-agent` の clone (原典ルートは SKILL.md 参照)。以下のパスはリポジトリルートからの相対パス。

## Contents

- まず押さえる
- 6 コンポーネントの実装対応
- ハードコードされた定数・既定値
- 索引 (設計判断からの逆引き / その他の文書)
- 蒸留の範囲外

## まず押さえる

1. **6 コンポーネントは概念ではなくコードの区画**。`mini_coding_agent.py:38-46` に「1) Live Repo Context -> WorkspaceContext」「4) Context Reduction -> clip, history_text」といった対応表がコメントで置かれ、本文中の各区画にも同じ番号の見出しコメントが振られている。ハーネスの断面を読むときの最短経路。
2. **プロンプトは「静的 prefix + 揺れる部分」の 2 層で、順序が固定されている**。`prompt()` (`mini_coding_agent.py:422-428`) は `prefix` → `memory_text()` → `Transcript:` → `Current user request:` の順に連結するだけ。`prefix` は `__init__` で 1 回だけ組んで保持する (`mini_coding_agent.py:257`, `build_prefix`)。**キャッシュ API は使っていない** — Ollama `/api/generate` に生の文字列を送るだけで (`OllamaModelClient.complete`)、cache reuse は「静的部分を先頭に置き続ける」という配置規律だけで成立させている。
3. **repo context は起動時に 1 回集めて固定する**。`WorkspaceContext.build` (`mini_coding_agent.py:85-123`) が git を 5 回叩き (`rev-parse --show-toplevel` / `branch --show-current` / `symbolic-ref refs/remotes/origin/HEAD` / `status --short` / `log --oneline -5`)、`AGENTS.md, README.md, pyproject.toml, package.json` を repo_root と cwd から集める。ターン毎の再収集はしない (= prefix を壊さないための設計)。git 呼び出しは全て `timeout=5` + 例外時 fallback 文字列で、git が無い環境でも落ちない。
4. **tool schema は「文字列で書かれたドキュメント」で、検証は別関数**。`build_tools` (`mini_coding_agent.py:282-328`) の schema は `{"path": "str", "start": "int=1"}` のような**文字列**であり、プロンプトへの表示用。実際の入力検査は `validate_tool` (`mini_coding_agent.py:536-600`) が手書きの if 分岐で行う。JSON Schema も型システムも使わない最小構成。
5. **`run_tool` のゲート順序が権限設計の核**: 未知ツール判定 → `validate_tool` → 重複呼び出し判定 → risky なら `approve` → 実行 + `clip` (`mini_coding_agent.py:496-515`)。**承認プロンプトより先に検証する**ので、引数が壊れたリスキーなツール呼び出しでユーザーを起こさない (テストで固定: `tests/test_mini_coding_agent.py:168-176`)。
6. **失敗は例外にせずコンテキストへ戻す**。`run_tool` は全ての失敗を `error: ...` 文字列として返し、transcript に tool 結果として記録される。引数不正時は `tool_example` (`mini_coding_agent.py:524-534`) の正しい呼び出し例を error 文に添付してモデルに自己修復させる。
7. **パス検証は resolve + samefile で symlink 脱出まで塞ぐ**。`path()` (`mini_coding_agent.py:734-740`) が相対パスを repo_root 基準に解決し、`path_is_within_root` (`mini_coding_agent.py:722-732`) が「存在する最も近い祖先まで遡ってから `samefile(root)` で比較」する。文字列 prefix 比較ではないので、`../` と symlink と大文字小文字非区別 FS の 3 ケースを同じ機構で扱える (テスト: `tests/test_mini_coding_agent.py:192-224`)。
8. **同一 tool 呼び出しの 3 回目を機械的に禁止**。`repeated_tool_call` (`mini_coding_agent.py:517-522`) は直近 2 件の tool イベントが同じ name + args なら次を拒否し、「別のツールを使うか final を返せ」と error で返す。プロンプトのルール文 (`mini_coding_agent.py:365`) と実装の二重掛け。
9. **transcript の圧縮は「直近 6 件だけ厚く残す」**。`history_text` (`mini_coding_agent.py:390-417`) は `recent_start = len(history) - 6` を境界に、tool 出力を直近 900 文字 / 過去 180 文字、それ以外を直近 900 / 過去 220 文字に切る。全体を最後に `MAX_HISTORY=12000` 文字で再度クリップ。**全ての上限は文字数でありトークン数ではない** — tokenizer を持たない設計。
10. **read の重複除去に「書き込みで無効化」を入れている**。過去分の `read_file` は同一パスを 2 回目以降スキップするが、`write_file` / `patch_file` のイベントを通過した時点でそのパスを `seen_reads` から捨てる (`mini_coding_agent.py:400-407`)。これがないと書き込み後の再読み込みが落とされ、モデルが古い内容を見る。この振る舞いは 2 本のテストで意図として固定されている (`tests/test_mini_coding_agent.py:302-358`)。
11. **永続 transcript と作業メモリを分けて持つ**。`record` (`mini_coding_agent.py:433-435`) は 1 イベント毎に session JSON 全体をディスクへ書き直す (完全な履歴)。並行して `note_tool` (`mini_coding_agent.py:437-443`) が「触ったファイル最大 8 件」「ツール結果の 220 文字要約 最大 5 件」だけを `memory` に蒸留する。`remember` (`mini_coding_agent.py:270-277`) は remove→append→`del bucket[:-limit]` の MRU で、重複排除と上限を同時に満たす。
12. **再開はセッション JSON の復元 + context の再構築**。`from_session` (`mini_coding_agent.py:260-268`) は history と memory をファイルから戻すが、`workspace` と `prefix` は新規に組み直される — 再開時は**現在の** git 状態が prefix に入る。`reset` (`mini_coding_agent.py:717-720`) は history と memory を空にするが session id とファイルは維持する。
13. **リトライ予算と tool step 予算を分離**。`ask` (`mini_coding_agent.py:445-491`) のループ条件は `tool_steps < max_steps` かつ `attempts < max_attempts` で、`max_attempts = max(max_steps * 3, max_steps + 4)`。出力形式が壊れた応答は `retry` として assistant メッセージ (`retry_notice`) を履歴に積むだけで tool step を消費しない (テスト: `tests/test_mini_coding_agent.py:100-113`)。打ち切り理由も 2 種類に書き分ける。
14. **委譲は「読み取り専用・深さ 1・要約 300 文字だけ継承」**。`tool_delegate` (`mini_coding_agent.py:847-866`) は子 `MiniAgent` を `approval_policy="never"`, `read_only=True`, `max_steps` 既定 3, `depth+1` で作る。`approve` は `read_only` を最優先で False にするため (`mini_coding_agent.py:603-604`)、子はリスキーなツールを一切実行できない。**継承する context は `clip(self.history_text(), 300)` を notes に 1 件入れるだけ**で、親の transcript 全体は渡さない。`max_depth=1` かつ `build_tools` が `depth < max_depth` の時のみ `delegate` を登録するので (`mini_coding_agent.py:321-327`)、孫エージェントは道具として存在しない。
15. **slash コマンドはモデルに届く前に REPL が食う**。`main` (`mini_coding_agent.py:986-1009`) が `/help /memory /session /reset /exit /quit` を分岐で処理し、モデル呼び出しを行わない。
16. **出力プロトコルは 2 系統を許容する**。`<tool>{"name":...,"args":{...}}</tool>` の JSON 形式と、複数行本文向けの `<tool name="write_file" path="f.py"><content>...</content></tool>` の XML 属性形式 (`parse`: `mini_coding_agent.py:615-647`, `parse_xml_tool`: `662-682`)。小型ローカルモデルが JSON 内で改行をエスケープし損ねる問題への実装上の逃げ道で、プロンプト側でも XML 形式を推奨させている (`mini_coding_agent.py:355-358`)。

## 6 コンポーネントの実装対応

| # | コンポーネント | 担当する関数・クラス (`mini_coding_agent.py`) | 何を捨て何を残すか |
|---|---------------|------------------------------------------|------------------|
| 1 | Live repo context | `WorkspaceContext` (75-140), `build` (85-123), `text` (125-140) | 残す: cwd / repo_root / branch / default_branch / `status --short` (1500 文字まで) / 直近 5 コミットの oneline / 既知ドキュメント 4 種 (各 1200 文字まで)。捨てる: 全ファイルツリー、diff 本体、履歴の詳細。起動時 1 回のみ収集 |
| 2 | Prompt shape / cache reuse | `build_prefix` (333-374), `memory_text` (376-385), `prompt` (422-428) | prefix = 役割 + ルール 15 行 + tool 一覧 + 出力例 + workspace。以降 request 毎に変わるのは memory / transcript / user request のみ。prefix の再生成は resume/新規構築時だけ |
| 3 | Structured tools / validation / permissions | `build_tools` (282-328), `run_tool` (496-515), `validate_tool` (536-600), `repeated_tool_call` (517-522), `approve` (602-613), `path` / `path_is_within_root` (722-740), `parse` (615-647), `tool_*` (742-842) | ツールは 6 + 条件付き `delegate` の 7 種。risky = `run_shell` / `write_file` / `patch_file`。`patch_file` は old_text が**ちょうど 1 回**出現しない限り拒否。`run_shell` の timeout は 1 以上 120 以下に強制 |
| 4 | Context reduction | `clip` (54-58), `history_text` (390-417) | tool 出力は生成時に 4000 文字で切り、履歴描画時にさらに 900 (直近) / 180 (過去) に切る。過去の重複 read は落とし、書き込みでその抑制を解除。最終的に 12000 文字で全体を切る |
| 5 | Transcript / memory / resumption | `SessionStore` (146-164), `record` (433-435), `note_tool` (437-443), `remember` (270-277), `ask` (445-491), `reset` (717-720), `from_session` (260-268) | 永続側は全イベント (role / name / args / content / created_at) を毎回同期書き込み。蒸留側は task 1 件 (300 文字) + files 8 件 + notes 5 件 (各 220 文字) のみ |
| 6 | Bounded delegation | `tool_delegate` (847-866), `build_tools` の depth ガード (321-327), `validate_tool` の delegate 分岐 (594-600) | 子は read_only + approval never + max_steps 3 (既定) + depth 1 上限。継承 context は親履歴の 300 文字要約 1 件。子は同じ `SessionStore` に**自分のセッション JSON を別 id で作る** |

## ハードコードされた定数・既定値

| 値 | 意味 | 場所 |
|----|------|------|
| `MAX_TOOL_OUTPUT = 4000` | 全 tool 結果の生成時クリップ長 (文字) | `mini_coding_agent.py:34` |
| `MAX_HISTORY = 12000` | transcript 描画全体の上限 (文字) | `mini_coding_agent.py:35` |
| 直近ウィンドウ 6 件 / 900 vs 180・220 文字 | 履歴の厚さの切り替え | `mini_coding_agent.py:397-415` |
| project_docs 1200 文字 / status 1500 文字 | workspace snapshot の各断片の上限 | `mini_coding_agent.py:113`, `120` |
| memory: files 8 件 / notes 5 件 / 各 220 文字 / task 300 文字 | 作業メモリの容量 | `mini_coding_agent.py:441-448` |
| `--max-steps 6` / `max_attempts = max(6*3, 6+4)` | 1 リクエストの tool step 上限とリトライ上限 | `mini_coding_agent.py:962`, `453` |
| `--max-new-tokens 512`, `--temperature 0.2`, `--top-p 0.9` | 生成パラメータ既定 | `mini_coding_agent.py:963-965` |
| `--approval ask` / `auto` / `never` | 承認ポリシー既定と選択肢 | `mini_coding_agent.py:956-961` |
| `--ollama-timeout 300` / `run_shell` timeout 20 (上限 120) / git timeout 5 | 各種タイムアウト (秒) | `mini_coding_agent.py:954`, `800-802`, `97` |
| `max_depth=1`, 子 `max_steps=3` | 委譲の境界 | `mini_coding_agent.py:236`, `858` |
| `IGNORED_PATH_NAMES` (`.git`, `.mini-coding-agent`, `__pycache__`, `.pytest_cache`, `.ruff_cache`, `.venv`, `venv`) | 一覧・検索から隠すパス。エージェント自身の状態ディレクトリを含む | `mini_coding_agent.py:36` |
| `.mini-coding-agent/sessions/<id>.json` | セッション保存先 (repo_root 直下) | `mini_coding_agent.py:914` |

## 索引

### 設計判断からの逆引き

| 判断したいこと | 見る実装 |
|---------------|---------|
| プロンプトの層構造をどう切るか | `build_prefix` / `prompt` (`mini_coding_agent.py:333-374`, `422-428`) |
| tool 定義と入力検査を分離する形 | `build_tools` / `validate_tool` (`mini_coding_agent.py:282-328`, `536-600`) |
| 承認ゲートをどこに挟むか | `run_tool` のゲート順序 / `approve` (`mini_coding_agent.py:496-515`, `602-613`) |
| workspace 外アクセスの塞ぎ方 | `path_is_within_root` (`mini_coding_agent.py:722-740`) + 該当テスト |
| 長い履歴の圧縮方針 | `history_text` (`mini_coding_agent.py:390-417`) |
| ループの停止条件・暴走防止 | `ask` の二重予算 / `repeated_tool_call` (`mini_coding_agent.py:445-491`, `517-522`) |
| 形式違反への自己修復 | `parse` / `retry_notice` / `tool_example` (`mini_coding_agent.py:615-659`, `524-534`) |
| セッション永続化と再開 | `SessionStore` / `record` / `from_session` (`mini_coding_agent.py:146-164`, `433-435`, `260-268`) |
| subagent の権限とスコープの絞り方 | `tool_delegate` (`mini_coding_agent.py:847-866`) |
| ハーネス挙動をテストで固定する書き方 | `tests/test_mini_coding_agent.py` (`FakeModelClient` に応答列を仕込む方式) |

### その他の文書

| 文書 | 内容 | 原典パス |
|------|------|----------|
| README | 6 コンポーネントの言語化、承認モード 3 種の説明、CLI フラグ一覧、resume 手順、slash コマンド一覧 | `README.md` |
| EXAMPLE | 空リポジトリに binary_search を実装させる 8 ステップのハンズオン (実装→編集→テスト追加→実行→修正) | `EXAMPLE.md` |
| tests | 挙動仕様として読める。特に read 重複除去 (302-358)、パス脱出 (192-224)、リトライ予算 (100-113)、承認前検証 (168-176) | `tests/test_mini_coding_agent.py` |
| CI | ubuntu/macos/windows × Python 3.10 × pip/uv の 6 通りで ruff + pytest | `.github/workflows/ci.yml` |
| 依存 | 実行時依存は標準ライブラリのみ (`pytest` のみ宣言)。`python mini_coding_agent.py` で直接動く | `pyproject.toml`, `README.md` |

## 蒸留の範囲外

- **原典が意図的に省いている領域** (README の明言に基づく):
  - `README.md:252` — "The agent is intentionally small and optimized for readability, not robustness."。堅牢性より可読性を優先すると宣言されている。
  - `README.md:249-251` — 出力形式 (`<tool>` / `<final>`) の遵守はモデル任せで、追従性の低いモデルでは壊れる。より強い instruction-following モデルを使えという指示のみ。
  - `--approval auto` は「モデルに任意コマンド実行とファイル書き込みを許す」ため trusted prompt / trusted repo 限定と明記 (`README.md:146-148`, `mini_coding_agent.py:960`)。
- **実装を読んで確認できる非対応事項** (README には明記なし): ストリーミング非対応 (`stream: False`)、並行実行なし (委譲は同期の直接呼び出し)、トークン数計測なし (全上限が文字数)、モデル出力の再試行にバックオフやレート制御なし、`run_shell` は `shell=True` でコマンド内容そのものの検査は行わない (承認ゲートのみが防壁)。
- **モデルバックエンドの抽象化**: `OllamaModelClient` / `FakeModelClient` が `complete(prompt, max_new_tokens)` を実装するだけの暗黙インターフェース。他プロバイダ対応や message 配列形式は扱わない (`/api/generate` の単一文字列プロンプトのみ)。
- **CLI の描画コード**: `build_welcome` / `middle` (`mini_coding_agent.py:61-69`, `869-909`) は端末幅に合わせた箱の整形のみで、ハーネス設計上の含意はない。
- **チュートリアル本文**: 6 コンポーネントの解説記事 (`magazine.sebastianraschka.com/p/components-of-a-coding-agent`) は clone に含まれない。設計意図の背景が必要なときは記事側を読む。
