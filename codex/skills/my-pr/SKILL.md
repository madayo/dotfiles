---
name: my-pr
description: Prepare the current branch and create a GitHub pull request. Use when the user invokes my-pr or asks Codex to create a PR, including checking the current branch, creating a feature/fix branch when needed, committing pending changes with the required AI co-author trailer, pushing, creating the PR body, and reporting the PR URL.
---

# my-pr

現在の feature / fix ブランチを push して PR を作成し、URL を報告する。
feature / fix ブランチが未作成、またはコミットが未完了の場合も、ユーザー確認を挟んで対応する。

## 手順

### 1. ブランチ確認

`git branch --show-current` で現在のブランチを確認する。

- main / master の場合:
  1. 変更内容を `git status`、`git diff --cached`、`git diff` で確認する。
  2. 変更内容をもとに適切なブランチ名を提案する。
     - 機能追加: `feature/<name>`
     - バグ修正: `fix/<name>`
  3. ユーザーの許可を得てから `git checkout -b <ブランチ名>` でブランチを作成する。

- feature / fix ブランチの場合:
  - そのまま次のステップへ進む。

### 2. コミット確認

`git status` で未コミットの変更があるか確認する。

- 未コミットの変更がある場合:
  1. `git diff --cached` と `git diff` で staged / unstaged の変更内容を確認する。
  2. 変更内容をもとに、日本語で適切なコミットメッセージを提案する。
  3. ユーザーの許可を得てから関連ファイルのみ `git add` する。
  4. AI を利用したコミットとして、AGENTS.md のルールに従い `Co-Authored-By` trailer を付ける。Codex の場合は以下を使う。

```text
Co-Authored-By: Codex <codex@openai.com>
```

ユーザーが trailer を指定した場合はそれに従う。

- 未コミットの変更がない場合:
  - そのまま次のステップへ進む。

### 3. push

`git push -u origin HEAD` で現在のブランチを push する。
push は外部状態を変更するため、実行前にユーザーの明示的な許可を得る。

### 4. PR 作成

`git log main..HEAD --oneline` を確認する。main が存在しない場合は `master..HEAD` を使う。

コミット一覧と diff から日本語の PR タイトル、Summary、Test plan を作成し、ユーザーに PR 作成内容を確認する。
許可を得てから以下の形式で PR を作成する。

```text
gh pr create --title "<日本語のタイトル>" --body "$(cat <<'EOF'
## Summary

- <変更点を日本語で箇条書き>

## Test plan

- [ ] <確認項目を日本語で記載>

Generated with Codex
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
