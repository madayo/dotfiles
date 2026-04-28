---
name: my-pr-body
description: 現在の変更から PR タイトルと本文を作成し、そのまま PR 作成まで進めたい場面で使う
agent: ask
argument-hint: diff、目的、確認項目があれば書いてください
---

現在の feature ブランチで、PR タイトルと本文を作成し、PR 作成まで実行してください。

次の手順で進めてください。

1. `git status --porcelain` を実行し、未コミットの変更がある場合はその事実を報告して停止する。
2. `git rev-parse --abbrev-ref HEAD` で現在のブランチ名を確認し、`main` または `master` なら停止して報告する。
3. `git push -u origin HEAD` で現在のブランチを push する。
4. `git log main..HEAD --oneline` と差分情報から、PR 用のタイトルと本文（Summary / Test plan）を日本語で作成する。
5. 次の形式で `gh pr create` を実行する。

```bash
gh pr create --title "<タイトル>" --body "$(cat <<'EOF'
## Summary

- <変更点>

## Test plan

- [ ] <確認項目>
EOF
)"
```

6. 作成された PR の URL を報告する。

本文作成時の制約は次の通りです。

- 変更内容の事実だけを書く。
- 未確認の内容を断定しない。
- テスト未実施なら、その旨を明記する。
- 余計な前置きや感想は書かない。

文体と粒度は [../../.github/copilot-instructions.md](../../.github/copilot-instructions.md) に合わせてください。