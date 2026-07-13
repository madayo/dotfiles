現在の feature ブランチを push して PR を作成し、URL を報告する。
feature ブランチが未作成・コミットが未完了の場合も自動で対応する。

## 手順

### 1. ブランチ確認

`git branch --show-current` で現在のブランチを確認する。

- **main / master の場合（feature ブランチ未作成）**：
  1. 変更内容を `git status`、`git diff --cached`、`git diff` で確認する。
  2. 変更内容をもとに適切なブランチ名（例: `feature/xxx` または `fix/xxx`）を提案し、ユーザーに確認する。
  3. 許可を得たら `git checkout -b <ブランチ名>` でブランチを作成する。

- **feature / fix ブランチの場合**：そのまま次のステップへ進む。

### 2. コミット確認

`git status` で未コミットの変更があるか確認する。

- **未コミットの変更がある場合**：
  1. `git diff --cached` と `git diff` で staged / unstaged の変更内容を確認する。
  2. 変更内容をもとに日本語で適切なコミットメッセージを提案し、ユーザーに確認する。
  3. 許可を得たら関連ファイルのみを対象にして以下を実行する：
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
push は外部状態を変更するため、実行前にユーザーの明示的な許可を得る。

### 4. PR 作成

`git log main..HEAD --oneline`（main が存在しない場合は `master..HEAD`）でコミット一覧を確認し、日本語の PR タイトル、Summary、Test plan を作成する。

PR タイトルと本文をユーザーに確認し、許可を得てから以下のフォーマットで PR を作成する：

```
gh pr create --title "<日本語のタイトル>" --body "$(cat <<'EOF'
## Summary

- <変更点を日本語で箇条書き>

## Test plan

- [ ] <確認項目を日本語で記載>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 5. 報告

作成した PR の URL をユーザーに報告する。

## 注意事項

- main / master へ直接 commit・push しない。
- force push は行わない。
- ユーザーの変更を勝手に revert しない。
- コミットメッセージ、PR タイトル、PR 本文は日本語で作成する。
- PR 作成前にレビュー提案が必要なリポジトリでは、PR 作成前にレビュー実施またはレビュー提案を行う。
