---
tracking: review
reviewed_at: 2026-07-12
review_interval_days: 180
---
# Banlist — three tiers

Scan for these. Tier decides how hard to act.

## Tier 1 — always ban (any document type)

- 装飾絵文字 🚀🎯✨💡🔥📈
- 全角ダッシュ ── / —: 技術・業務・説明文では挿入用法も含めて置き換える（読点・括弧・2 文に分ける。外して 1 文につなぐと理由や条件のかかる範囲が変わるなら 2 文に）。末尾を「──」で閉じる列挙は、何の列挙かを述語で言い切る。小説・随筆で文体として使うダッシュ、罫線・木構造・出典表記は対象外
- Markdown 残骸: `**` の取りこぼし、`: ` の不適切な半角スペース
- 根拠なし強評価: 非常に有効／画期的／革新的なアプローチ／大きなメリット／驚くべき効果／ゲームチェンジャー
- 咳払いの前置き: 実はですね／率直に言いますが／本当のところ
- 情報を運ばない進行宣言: それぞれ順に見ていきましょう／ここからが本題です
- 表層の定型句: いかがでしたでしょうか／ぜひ参考にしてください／○○の重要性を再認識／近年〜が注目されています／○○に他なりません

## Tier 2 — avoid by default (rewrite unless there's a real reason)

Judge by frequency, not presence: any of these once or twice reads naturally; scattered through a piece, they smell. Don't delete them all. Cut one only when cutting it leaves the claim unchanged.

- 働きがあれば残す前置き: ここで重要なのは（評価を担うなら述語へ移す:「〜が重要です」）／結論から言うと・結論として（比較から方針への切り替えを担うなら残す）／結局のところ・まとめると（新しい情報か結論の絞り込みがあれば残す）／○○することが大切です（決まりの文書で理由を述べるなら残す）
- メタ構造宣言: 以下の3つの観点から説明します／改めて整理します／STEP1（扱いは syntax-patterns.md §5: 数が合えば中身の文と 1 文にまとめ、長い説明の案内になっているなら残す）

- 偏愛語（質感を装う）: 泥臭い／手触り／肌感／体温／温度感／熱量／血の通った
- 偏愛語（認知を装う）: 解像度／腹落ち／メンタルモデル
- 偏愛語（評価を装う）: 本質／本質的／地に足のついた／等身大
- 抽象比喩・思想語: 営み／装置／インフラ／接続／思想／哲学／原則（思想の意味のとき）
- 必殺技造語: 真理／真実／結末／宿命／境地／極致／究極／美学／深淵／凝縮／結晶／結実
- 比喩テンプレ: 地図／羅針盤／コンパス／土台／柱／骨格／栄養／エンジン／潤滑油／スパイス／DNA／車の両輪／触媒／起爆剤
- 翻訳調動詞: 示している／指している／示唆している／物語っている／浮かび上がる／見えてくる／収斂する／位置づける
- アカデミック自称: 本稿／本記事／本論考／筆者
- 横文字メタファー: 思考のOS／人生をハック／習慣をインストール／マインドをリファクタリング／ラボ／アセット
- 便利語: 課題／活用／推進／最適化／価値／体験／可能性／重要性／多岐にわたる
- 冗長語尾: 〜することができます（→〜できます）
- ビジネスジャーゴン: コミットする／レバレッジを効かせる／解像度を上げる／ディープダイブ／アラインする／ROIを最大化

## Tier 3 — context-OK (allowed when earned)

- Necessary hedges where uncertainty is real (1 まで、儀式化しない)
- Domain terms / acronyms (define on first use)
- A single, earned metaphor used once
- 数値・固有名（むしろ歓迎）

Note: a word's tier is about *function*. 「原則 72 時間以内」 = "as a rule" (fine); 「設計の原則」 as a 思想語 (Tier 2). Judge by use, not surface.
