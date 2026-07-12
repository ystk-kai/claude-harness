# スライド・図解の tell — 検出と処方

スライド・図解の tell は生成ツールのテンプレート機構 (python-pptx 等によるコード生成にはテンプレート・画像ライブラリ・レイアウトアルゴリズムがない) に根差すため、画像系の tell より寿命が長い。

## スライドの tell

- **全 bullet 同一リズム** — 「全 bullet が同じ長さ、1 枚 3-4 個、全部動詞始まり」。2slides はこれを「最も信頼できる AI tell」とし、視聴者の 71% が 3 枚以内で AI 製と判別したと主張
- **全枚同一レイアウト** — headline + 3 bullets + supporting image + footer の反復。タイトルも「Title Case 約 6 語 + コロン: サブタイトル」で全枚同型
- **rigid layout・弱い視覚階層** — 36 人への質的研究で、AI 生成スライドの rigid layout・poor hierarchy・文脈に合わない generic template が報告されている
- **stock placeholder icons** — 'team' 'growth' 'strategy' に対する単色ラインアイコン、見出し脇の無意味アイコン
- **AI 定番配色** — muted blues + warm grays + 単一アクセント、または紫グラデ・gradient text (web-ui.md と共通)
- **装飾絵文字の均等撒布** (🚀🎯✨💡) と **❌/✅ 比較スライド** — 文章側の banlist と同一の tell のビジュアル版。地の文・関係性の図解に置き換える
- **generic title** — 「Overview」「Key Takeaways」など何も伝えないタイトル、"In today's fast-paced world…" 型のオープニング
- **brand 後付けの痕跡** — font substitution、近似色、揺れる logo 位置、別フォントのメトリクスを前提にした改行・overflow。「整っているが自社らしくない」状態
- **書体・色・チャートスタイルの deck 間均質化** — どの deck も同じに見える (Duke AI Co-Lab)
- footer の不整合 (位置・有無が枚ごとにバラつく)、過飽和 AI 画像の混在

## 図解の tell

- **関係性の曖昧さ** — 並列なのか、因果なのか、手順なのか、比較なのかが決まらないまま見た目だけ整う。読み手が「つまり何を判断すればいいのか」に到達できない
- **要素過多** — 見出し・補足・図・アイコン・注釈・背景の飾りが同居し視線が迷う。視線誘導・分類・強調のどれでもない「なんとなく寂しいから入れる装飾」
- **図の文法エラー** — 読めないラベル、誤接続、逆向き/矢頭なしの線、同一要素の重複、同じ形への異なるラベル (DiagrammerGPT が系統的に報告)
- **一枚 raster 生成** — 図解を 1 枚の画像として生成すると上記の文法エラーと文字崩れが避けられない

根本原因はデザインセンスではなく、目的・関係性・優先順位の曖昧さ。装飾を消すだけでは直らない (記号より構造)。

## 処方 (スライド・図解固有)

1. **統一と変化を別管理する** — title・body・icon family・photo style・line weight は deck 全体で固定し、レイアウトや背景の変更は章転換・比較・強調など意味がある場合だけ行う
2. **brand を先に登録する** — brand font・hex・logo rule・スライド種別ごとの参照を生成前に与える (後付け置換が痕跡を作る)
3. **bullet のリズムを崩す** — 長さ・形を揃えない。言い切りと説明文を混ぜ、1 項目で足りるなら 1 項目にする (文章側は avoid-ai-slop-ja の variance 規約と同じ)
4. **図解は raster ではなく plan から** — 先に entities / relationships / layout の plan を作り、別工程で全 arrow・label・縮尺を元資料と照合し、最終版は editable vector + 通常のテキストレンダリングで組む
5. **関係性を 1 つ選んでから描く** — 並列/因果/手順/比較のどれかを決め、それ以外の要素を消す。装飾は視線誘導・分類・強調のどれかを言えなければ入れない

## 出典

- https://2slides.com/blog/can-ai-make-slides-that-dont-look-ai-generated (8 大 tell と 71% 判別)
- https://www.pageon.ai/blog/chatgpt-presentation (python-pptx 由来の同一レイアウト)
- https://www.scholink.org/ojs/index.php/selt/article/download/56608/12502 (36 人の質的研究)
- https://ai.colab.duke.edu/colab-ai-blog/all-blogs/why-does-everything-look-the-same/ (Duke AI Co-Lab)
- https://www.decktopus.com/blog/how-ai-actually-builds-slide-layouts-and-why-branding-breaks (brand 後付けの痕跡)
- https://winningpresentations.com/ai-generated-slides-look-generic/ (statistical average = generic)
- https://arxiv.org/abs/2310.12128 (DiagrammerGPT: 図の文法エラー)
- https://journals.asm.org/doi/10.1128/jmbe.00321-25 (図解エラーの教材化)
- https://www.duarte.com/blog/design-slides-for-virtual-presentations/ (統一と変化の管理)
- 日本語: https://note.com/wanho/n/na88104486e80 (関係性・要素過多・目的なし装飾) / https://qiita.com/minorun365/items/68740e4ba1d81177199b
