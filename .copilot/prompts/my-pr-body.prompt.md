---
name: my-pr-body
description: 現在の変更から PR タイトルと本文の叩き台を素早く作りたい場面で使う
agent: ask
argument-hint: diff、目的、確認項目があれば書いてください
---

現在の変更内容から、PR 用のタイトル案と本文案を日本語で作成してください。

出力形式は次の順にしてください。

1. タイトル案を 1 行
2. `## Summary`
3. 箇条書きで変更点
4. `## Test plan`
5. 箇条書きで確認項目

次の制約を守ってください。

- 変更内容の事実だけを書く。
- 未確認の内容を断定しない。
- テスト未実施なら、その旨を明記する。
- 余計な前置きや感想は書かない。

文体と粒度は [../../.github/copilot-instructions.md](../../.github/copilot-instructions.md) に合わせてください。