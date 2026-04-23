現在の feature ブランチを push して PR を作成し、URL を報告する。

## 手順

1. `git status` で未コミットの変更がないか確認する。あれば報告して止まる。
2. `git push -u origin HEAD` で現在のブランチを push する。
3. `git log main..HEAD --oneline` でコミット一覧を確認し、Summary と Test plan を作成する。
4. 以下のフォーマットで PR を作成する。

```
gh pr create --title "<タイトル>" --body "$(cat <<'EOF'
## Summary

- <変更点を箇条書き>

## Test plan

- [ ] <確認項目>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

5. 作成した PR の URL をユーザーに報告する。
