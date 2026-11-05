---
name: my-implement-wt
description: Implement an approved change in a worktree, perform static checks, commit locally, and leave a pending verification memo. Use when my-implement-wt is invoked or worktree is specified as the execution method; defer runtime verification to my-verify in the main working tree.
---

# my-implement-wt

承認済みの変更を worktree 上で実装し、検証待ちメモを残す。docker 環境はメインツリーとセットのため、worktree では実行系の検証をしない。設計と実装までを並列で進め、保留した検証は `my-verify` でメインツリーに戻って行う。

## 前提と実行モードを確認する

- [my-implement](../my-implement/SKILL.md) の「実装の前提を確認する」を読み、要件・受け入れ条件、方針、承認範囲を確認する。承認済みなら確認を繰り返さない。
- 提案には、ブランチ名（`feature/<name>` または `fix/<name>`）、worktree のパス（メインツリーの `.codex/worktrees/<name>`）、起点、保留する検証、ローカル commit を行うこと（push はしない）を含める。
- 承認済みの方針にこの実行モードが含まれない場合は、実行モードだけを短く提示して承認を待つ。実装の依頼だけを commit の許可と扱わない。Plan モードなど実行が制限される状態では、その制限に従い、実装前に実行可能なモードへ移る。

## worktree を準備する

git コマンドは一つずつ実行し、パスは単独のコマンドで取得した絶対パスを以降の操作に使う。コマンドに渡す値はクォートする。

1. `git rev-parse --is-inside-work-tree` で git 管理下か確認する。失敗したら質問して止まる。`git rev-parse --path-format=absolute --git-dir` と `git rev-parse --path-format=absolute --git-common-dir` を別々に実行し、一致すればメインツリーと判定する。一致しない場合は、このセッションで今回の作業のために作った worktree なら実装を再開し、それ以外は止まって確認する。
2. メインツリーのルートを `git rev-parse --show-toplevel` で取得し、以降の作成操作はそのディレクトリで行う。ブランチは `git check-ref-format --branch <ブランチ>` で検証する。`<name>` は `[A-Za-z0-9._-]+` とし、先頭が `-` のものと `..` を含むものを除く。違反したら質問して止まる。
3. `git fetch origin` で最新を取る。失敗したら古い起点で進めずに止まる。起点は `git symbolic-ref -q --short refs/remotes/origin/HEAD` の結果、`origin/main`、`origin/master` の順に試し、`git show-ref -q --verify refs/remotes/<起点>` で存在を確認できた最初のものを使う。すべて失敗したら質問する。承認された起点と異なる場合は、変更を提示して承認を待つ。
4. `git show-ref -q --verify refs/heads/<ブランチ>` と `git show-ref -q --verify refs/remotes/origin/<ブランチ>`、`git worktree list`、`test -e <パス>` で衝突を確認する。既存のブランチ・worktree・ディレクトリと衝突したら止まって質問する。
5. `git check-ignore -q .codex/worktrees/<name>` で無視されることを確認する。無視されなければ、取得済みの `<git-common-dir>/info/exclude` に `/.codex/worktrees/` を追記する。必要なら親ディレクトリを作る。
6. `git worktree add --no-track -b <ブランチ> .codex/worktrees/<name> <起点>` で作成する。`--no-track` は起点のデフォルトブランチが upstream に設定されるのを防ぐ。
7. 作成した worktree の絶対パスを以降の作業ディレクトリにする。Codex ではコマンド実行の `workdir`（同等の指定がなければ各コマンドの明示的な `cd`）と、編集対象の絶対パスで切り替える。単発の `cd` が次のツール呼び出しにも引き継がれるとは扱わない。`git rev-parse --show-toplevel` と現在のブランチを確認し、以降はその worktree 配下だけを編集する。書き込み権限がなければ、必要な承認を得るまで編集しない。

## 実装・静的確認・commit

1. 承認された範囲で実装する。通常の実装詳細は既存パターンに沿って判断し、重要な方針変更が必要なら理由と改訂案を示して承認を待つ。要件外の改善は混ぜない。
2. ホストで副作用なく実行できる静的確認だけを行う（`git diff --check`、参照・呼び出しの整合確認など）。docker・コンテナの起動、依存のインストール、`.env` が必要な実行はしない。未実行の確認を成功扱いにしない。
3. [my-implement](../my-implement/SKILL.md) の「実装・検証する」にある観点でセルフレビューする。実施済みは静的確認だけで、実行検証は保留中と明記する。組み込み・独立レビューを実施した扱いにはしない。
4. 関連ファイルだけを `git add` し、日本語のメッセージと `AI_RULES.md` に従った Co-Authored-By を付けてローカル commit する。push はしない。複数行の本文は一時ファイルに書き、`git commit -F <ファイル>` で渡す。hook が失敗したら `--no-verify` は使わずに止まり、メインツリーでの検証へ進めない旨を報告する。解消後は commit から再開する。
5. `git rev-parse HEAD` で commit を取得し、検証待ちメモを書く。サンドボックスで Git 共通ディレクトリへの書き込みが許可されない場合は、権限を迂回せず必要な承認を求める。メモが書けなければ未完了と報告する。

## 検証待ちメモ

場所は `<git-common-dir>/codex-verify/<ブランチ名>.md`。`<git-common-dir>` は `git rev-parse --path-format=absolute --git-common-dir` で取得した絶対パスを使う。commit に混ざらずメインツリーからも読める。ブランチ名の `/` はディレクトリになるため、親ディレクトリも作る。同名のメモがあれば内容を確認し、別の作業のメモを上書きしない。

- 先頭行は `ブランチ: <名前>`。メインツリーと worktree の絶対パス、起点、commit も記録する。
- 要件と承認された範囲、主な変更ファイル。
- 受け入れ条件ごとの確認コマンド・実行先・期待結果、実施した静的確認と保留した検証。
- 依存の変更の有無と、docker 側での再インストールの要否。
- セルフレビューの指摘と採否、残る制約。

サブエージェントを利用する許可・指示がある場合は、worktree の絶対パスを渡し、その配下だけを対象にさせ、メインツリーを触らせない。

## 結果を返す

変更した動作と理由、ブランチ・worktree・commit、実施した確認と保留した検証、セルフレビューの指摘と採否、メモのパス、残る制約を簡潔に示す。コードからの判断と実行で確認した内容を区別する。
メインツリーが空いたら、同じセッションで「メインが空いたから戻って検証を再開して」と指示すればよいことを案内する。worktree は残し、以降もそのパスを作業ディレクトリとして扱う。
