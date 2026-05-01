現在の feature ブランチを push して PR を作成し、URL を報告する。
feature ブランチが未作成・コミットが未完了の場合も自動で対応する。

## 手順

### 1. ブランチ確認

`git branch --show-current` で現在のブランチを確認する。

- **main / master の場合（feature ブランチ未作成）**：
  1. 変更内容を `git diff` と `git status` で確認する。
  2. 変更内容をもとに適切なブランチ名（例: `feature/xxx` または `fix/xxx`）を提案し、ユーザーに確認する。
  3. 許可を得たら `git checkout -b <ブランチ名>` でブランチを作成する。

- **feature / fix ブランチの場合**：そのまま次のステップへ進む。

### 2. コミット確認

`git status` で未コミットの変更があるか確認する。

- **未コミットの変更がある場合**：
  1. `git diff` で変更内容を確認する。
  2. 変更内容をもとに適切なコミットメッセージを提案し、ユーザーに確認する。
  3. 許可を得たら以下を実行する：
     ```
     git add <関連ファイル>
     git commit -m "$(cat <<'EOF'
     <コミットメッセージ>

     Co-Authored-By: Claude <noreply@anthropic.com>
     EOF
     )"
     ```

- **未コミットの変更がない場合**：そのまま次のステップへ進む。

### 3. push

`git push -u origin HEAD` で現在のブランチを push する。

### 4. PR 作成

`git log main..HEAD --oneline`（main が存在しない場合は `master..HEAD`）でコミット一覧を確認し、Summary と Test plan を作成する。

以下のフォーマットで PR を作成する：

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

### 5. 報告

作成した PR の URL をユーザーに報告する。
