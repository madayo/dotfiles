---
name: my-verify
description: Resume runtime verification deferred by my-implement-wt in the main working tree, using its pending memo. Use when my-verify is invoked or the user says the main tree is available and asks to resume deferred verification; not for ordinary verification during implementation.
---

# my-verify

`my-implement-wt` が残した検証待ちメモを使い、メインツリーで対象ブランチに切り替えて、docker などで保留した検証を行う。承認済みの変更の検証なので、設計・承認をやり直さない。Plan モードなど実行が制限される状態では、その制限に従い、実行可能なモードへ移ってから検証する。

git コマンドは一つずつ実行し、取得した絶対パスを以降の操作に使う。メモ由来のパスやブランチ名も、コマンドに渡すときはクォートする。

## 対象と現在地を確認する

1. 会話の直前の `my-implement-wt` の報告から対象ブランチを特定する。文脈がなければ、`git rev-parse --path-format=absolute --git-common-dir` で取得したパスの `codex-verify/` 配下を再帰的に調べる（ブランチ名の `/` はディレクトリになる）。メモの先頭行 `ブランチ: <名前>` を使い、候補が複数なら質問する。文脈もメモもなければ質問して止まる。対象ブランチは `git check-ref-format --branch <ブランチ>` と `git show-ref -q --verify refs/heads/<ブランチ>` で確認し、検証対象の commit がメモや報告と異なる場合は、変更内容と承認範囲を確認してから進む。特定後、対象ブランチと、worktree の取り外し・ブランチ切り替えを行うことを短く伝える。
2. `git rev-parse --path-format=absolute --git-dir` と `git rev-parse --path-format=absolute --git-common-dir` を別々に実行する。一致すればメインツリー、一致しなければ worktree 内と判定する。worktree 内なら `git status --short` で未コミット・未追跡の変更がないことを確認する。変更があれば止まって報告する。
3. `git worktree list --porcelain` の先頭エントリからメインツリーの絶対パスを取得し、メモや報告のパスとも照合する。以降のコマンドの `workdir`（同等の指定がなければ各コマンドの明示的な `cd`）と編集対象をメインツリーへ切り替える。単発の `cd` だけで切り替わったと扱わない。そこで改めて Git ディレクトリと共通ディレクトリの一致、および元と同じ Git 共通ディレクトリであることを確認する。切り替えや書き込みができなければ、メインツリーで新しいセッションを開いて `my-verify` を実行するよう案内して止まる。

## メインツリーで検証を準備する

1. `git branch --show-current` で切り替え前のブランチを控える。detached HEAD なら `git rev-parse --short HEAD` で commit を控え、`git for-each-ref --contains HEAD refs/heads refs/remotes` が空なら、どのブランチにも含まれない commit があるため止まって確認する。切り替え前の commit も記録し、検証が中断しても依存差分を再確認できるようにする。
2. 現在のブランチが対象ブランチなら、再実行・中断からの再開として、取り外し・切り替えを省略する。ただし `git status --short` と差分を確認し、メモや前回の報告に記録された検証中の修正と一致する場合だけ進む。一致しない、または特定できない変更があれば止まって確認する。切り替え前のブランチ・commit は前回の記録を使い、不明ならその旨を報告する。それ以外のブランチなら、`git status --short` が空であることを確認し、変更があれば止まって報告する。
3. 切り替え前のブランチ・commit を、取り外し・切り替え前にメモへ記録する。メモがなければ、直前の報告の検証待ち情報も含めて同じ `codex-verify/<ブランチ名>.md` に作成する。`git worktree list --porcelain` の2件目以降で、対象ブランチを持つ worktree を探す。外してよいのは、メモ（なければ直前の報告）にある絶対パスと一致し、かつメインツリーの `.codex/worktrees/` 配下にあるものだけ。それ以外なら止まって質問する。
4. 外す前に `git -C <パス> status --short --ignored` を実行する。出力があれば一覧を示して確認を取る。ignore 済みのファイルは `--force` なしでも消えるため、無視しない。問題なければメインツリーを作業ディレクトリにして `git worktree remove <パス>` で外す。`--force` は使わず、失敗したら止まって報告する。現在のツール操作が外す worktree を参照している状態で削除しない。
5. 現在のブランチが対象ブランチでなければ、`git switch --no-overwrite-ignore <ブランチ>` で切り替える。メインツリーの ignore 済みファイルとの衝突などで失敗したら、強制せず止まって確認する。検証後も対象ブランチに留まり、元のブランチへ自動で戻さない。

## 検証・必要な修正・メモの後始末

1. メモ（なければ直前の報告）から、受け入れ条件、確認コマンドと期待結果、依存の変更を読む。再インストールの要否はメモだけで判断しない。切り替え前の commit と対象ブランチの lockfile の差分、および docker 側のインストール状態が対象ブランチの lockfile と一致するかを確認する。依存の変更がある、または一致を確認できなければ docker 側で再インストールする。実行先・副作用・既存の許可を確認し、必要な許可がない操作は承認を待つ。lockfile が変わった場合は報告する。
2. [my-implement](../my-implement/SKILL.md) の「実装・検証する」に従い、保留した検証を実行する。今回の変更に起因する問題は承認範囲内で修正し、最終差分の基本確認に留める。詳細レビューはここでは行わない。範囲外の修正が必要なら変更せず提案して止まる。検証中の修正は commit しない。
3. すべて確認できたらメモを削除する。未確認が残る場合は、実施結果、残る検証・制約、切り替え前のブランチ・commit、検証中の未 commit 修正のファイル一覧と変更内容をメモへ記録して残す。同じファイルが後から編集された場合も識別できるよう、差分や内容のハッシュなど照合可能な記録を残す。メモがなければ同じ `codex-verify/<ブランチ名>.md` に作成する。

## 結果を返す

[my-implement](../my-implement/SKILL.md) の「結果を返す」に従い、検証結果と残る制約を報告する。対象ブランチ、切り替え前のブランチ、外した worktree、検証中の未 commit 修正（なければ「なし」）、メモの削除・更新状況も添える。
詳細レビューが未実施なら「詳細レビュー未実施」と明記し、`my-review` はユーザーの指示を受けて実施する。
