現在のブランチに対応する PR の Copilot レビューコメントを取得し、採用判定・修正・報告を行う。

## 手順

1. `gh pr view --json number,url` で現在のブランチの PR 番号を取得する。
2. `gh api repos/<owner>/<repo>/pulls/<番号>/comments` で Copilot のコメントを取得する。
   - owner/repo は `gh repo view --json nameWithOwner` で取得する。
3. 各 suggestion を採用 / 不採用で判断する。
   - 採用：コードを修正し、コミット・push する。
   - 不採用：理由を記録する。
4. 以下のフォーマットで `gh pr comment` を投稿する。

```
gh pr comment <番号> --body "$(cat <<'EOF'
Copilot レビューへの対応:

**#N (件名)** — 採用 / 不採用
<理由と対応内容>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
