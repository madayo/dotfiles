現在のブランチに対応する PR の Copilot レビューコメントを取得し、採用判定・修正・報告を行う。

## 手順

1. `gh get-comments` でカレントブランチの PR コメントを取得する。
   - 出力形式: `file / line / author / comment`
2. 各 suggestion を採用 / 不採用で判断する。
   - 採用：コードを修正し、コミット・push する。
   - 不採用：理由を記録する。
3. 以下のフォーマットで `gh pr comment` を投稿する。

```
gh pr comment <番号> --body "$(cat <<'EOF'
Copilot レビューへの対応:

**#N (件名)** — 採用 / 不採用
<理由と対応内容>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
