---
name: my-copilot-review
description: Retrieve and handle GitHub Copilot review comments for the pull request associated with the current branch. Use when the user invokes my-copilot-review or asks Codex to check Copilot review comments, judge whether suggestions should be adopted, apply approved fixes, and prepare a PR comment response.
---

# my-copilot-review

現在のブランチに対応する PR の Copilot レビューコメントを取得し、採用判定・修正・報告を行う。

## 手順

1. 必ず `gh get-comments` でカレントブランチの PR コメントを取得する。
   - 出力形式: `file / line / author / comment`
2. 各 suggestion を採用 / 不採用で判断し、簡潔な理由を添えてユーザーに報告する。
3. 修正が必要な suggestion は、ユーザーの許可を得てから実装する。
4. 修正後は必要なテスト・ログ・差分確認を行う。
5. 最終的に、ユーザーの確認を得てから以下の形式で `gh pr comment` を投稿する。

```text
gh pr comment <番号> --body "$(cat <<'EOF'
Copilot レビューへの対応:

**#N (件名)** - 採用 / 不採用
<理由と対応内容>

Generated with Codex
EOF
)"
```

## 判断基準

- 採用:
  - 明確なバグ修正、セキュリティ改善、保守性改善である。
  - 既存設計と矛盾しない。
  - 変更範囲が suggestion の意図に対して過剰でない。
- 不採用:
  - 既存仕様や設計意図と矛盾する。
  - 挙動変更のリスクが suggestion の利益を上回る。
  - 根拠が弱く、現時点では要確認に留めるべき。

## 注意事項

- `gh get-comments` や `gh pr comment` は GitHub の状態を参照・変更する。投稿など外部状態を変更する操作はユーザー確認後に行う。
- Copilot の提案をそのまま鵜呑みにせず、周辺実装と要件を確認する。
- 不明点がある場合は「要確認」として扱う。
