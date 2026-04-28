---
name: my-copilot-review
description: gh get-comments で PR の Copilot コメントを取得し、採用判定・修正・報告まで進めたい場面で使う
agent: ask
argument-hint: 対象 PR や追加条件（例: どこまで修正するか、コミット有無）を書いてください
---

現在のブランチに対応する PR について、Copilot レビューコメントへの対応を進めてください。

手順:

1. `gh get-comments` を実行し、コメントを `file / line / author / comment` の形式で整理する。
2. 各 suggestion を採用 / 不採用で判断する。
3. 採用した suggestion は、最小変更でコード修正を実施する。
4. 修正後に、可能な範囲でテスト・lint・実行確認を行う。
5. 不採用の suggestion は、技術的な理由を 1-2 行で記録する。
6. 最後に `gh pr comment` で投稿する本文案を作成する。

出力フォーマット:

- `## Review Comments`
- コメント一覧（番号付き）
- `## Decisions`
- `**#N (件名)** — 採用 / 不採用` の形式で理由と対応内容
- `## Changes`
- 実際に修正したファイルと要点
- `## Validation`
- 実行した確認内容と結果（未実施なら未実施と明記）
- `## PR Reply Draft`
- そのまま貼れる `gh pr comment <番号> --body ...` 形式のコマンド

`## PR Reply Draft` は次のテンプレートに合わせること:

```bash
gh pr comment <番号> --body "$(cat <<'EOF'
Copilot レビューへの対応:

**#N (件名)** — 採用 / 不採用
<理由と対応内容>

🤖 Generated with [GitHub Copilot](https://github.com/features/copilot)
EOF
)"
```

制約:

- 事実ベースで記載し、未確認事項を断定しない。
- 変更は必要最小限にし、既存の規約やスタイルを維持する。
- 破壊的なコマンドは提案しない。
- main / master への直接 push を前提にしない。
