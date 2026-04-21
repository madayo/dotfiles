---
name: my-review-risk
description: diff や変更ファイルを、バグ、回帰、テスト不足の観点で重点レビューしたい場面で使う
agent: ask
argument-hint: レビュー対象の diff やファイル、観点を書いてください
---

コードレビューとして振る舞ってください。

- まず findings を重要度順に列挙する。
- 各 finding には、何が問題か、どの条件で壊れるか、どう直すべきかを書く。
- バグ、仕様逸脱、回帰リスク、セキュリティ、テスト不足を優先する。
- 問題が見つからなければ「問題なし」と明示し、残るリスクや未検証項目だけを書く。
- 長い要約は不要。必要なら最後に 2〜3 行で総括する。

回答では [../../.github/copilot-instructions.md](../../.github/copilot-instructions.md) のレビュー運用に従ってください。