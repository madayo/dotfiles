承認済みの変更を worktree 上で実装し、docker が必要な検証は保留して、検証待ちメモを残す。

依頼内容: `$ARGUMENTS`（空なら会話の文脈から判断し、判断できなければ質問する）

docker 環境はメインツリーとセットのため、worktree では実行系の検証をしない。設計と実装までを並列で進め、検証は `/my-verify` でメインツリーに戻ってから行う。

worktree に入っている間（手順 4 以降）は、複数の git 呼び出しや、`$(git ...)` で別の git の出力を埋め込む形のコマンドが拒否される。git コマンドは 1 つずつ単純な形式で実行し、パスは先に単独のコマンドで取得して、その値を以降のコマンドに直接書く。`git commit -m "$(cat <<'EOF' ... EOF)"` のように、HEREDOC で本文を渡す形は実行できる。

## 手順

1. 要件・受け入れ条件、採用する方針、承認の範囲を、会話から確認する。承認の扱いは、`~/.claude/commands/my-implement.md` の手順 1 を Read して、その手順に従う（承認済みなら繰り返し確認しない。未承認なら実装せず、提案して承認を待つ）。提案には、次の実行モードを含める。
   * ブランチ名（`feature/<name>` または `fix/<name>`）、worktree のパス（`.claude/worktrees/<name>`）、起点
   * 保留する検証と、ローカル commit を行うこと（push はしない）
   * ただし、承認済みの方針に実行モードが含まれていない場合（例: worktree モードでない `/my-design` で承認された方針を、あとから worktree で実装する場合）は、承認済みでも、実行モードだけを短く提示して承認を得る（commit は、実装の依頼だけでは行わないため）。Plan モード中は、実行モードを plan ファイルに書き、ExitPlanMode で承認を求める（この場合に限り、新しい承認として扱う）。
2. 現在地を判定する。
   * `git rev-parse --is-inside-work-tree` が失敗する（git 管理外）: worktree を作れないので、質問して止まる。
   * `git rev-parse --path-format=absolute --git-dir` と `--git-common-dir`（それぞれ単独のコマンドで実行する）が一致する: メインツリー。手順 3 へ進む。
   * 一致しない（worktree 内）: このセッションで今回の作業のために入った worktree なら、手順 4 から再開する。それ以外は想定外なので、止まって質問する（メインツリーへ戻るなら `/my-verify`、別の作業は別セッションで進める）。
3. worktree を作成して入る。コマンドはメインツリーのルート（`git rev-parse --show-toplevel`）で実行する。
   * ブランチ名は `git check-ref-format --branch <ブランチ>` で検証し、`<name>` は `[A-Za-z0-9._-]+`（先頭が `-` のものと `..` を含むものを除く）に限る。違反する場合は質問して止まる。以降のコマンドに渡す値は、すべてクォートする。
   * `git fetch origin` で最新を取る。失敗したら、古い起点で進めず、質問して止まる。
   * 起点は、`git symbolic-ref -q --short refs/remotes/origin/HEAD`、`origin/main`、`origin/master` の順に試し、`git show-ref -q --verify refs/remotes/<起点>` で存在を確認できた最初のものを使う。すべて失敗したら質問する。
   * ブランチ名・パスが既存のブランチ、worktree、ディレクトリと衝突する場合は、質問して止まる。確認は、`git show-ref -q --verify refs/heads/<ブランチ>` と `refs/remotes/origin/<ブランチ>`、`git worktree list`、`test -e <パス>` で行う。
   * `git check-ignore -q .claude/worktrees/<name>` が失敗する（無視されていない）場合は、`$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude` に `/.claude/worktrees/` を追記する（`info` ディレクトリがなければ `mkdir -p` で作る）。
   * `git worktree add --no-track -b <ブランチ> .claude/worktrees/<name> <起点>` で作成する。`--no-track` は、起点（`origin/<デフォルトブランチ>`）が upstream に設定されるのを防ぐ。
   * `EnterWorktree` を、`path` に作成した worktree の絶対パスを指定して呼ぶ。`ExitWorktree` の `remove` は worktree とブランチを消すので使わない。
4. 承認された範囲で実装する。範囲内の実装の細部は、既存のパターンに沿って判断する。重要な方針変更が必要になったら、理由と改訂案を示して承認を待つ。要件外の改善は混ぜない。
5. 確認はホストで副作用なく実行できるものだけ行う（`git diff --check`、参照・呼び出しの整合確認など）。docker・コンテナの起動、依存のインストール、`.env` が必要な実行はしない。未実行の確認を成功扱いにしない。
6. 基本確認とセルフレビューは、`~/.claude/commands/my-implement.md` の「基本確認とセルフレビュー」節を Read して、その手順に従う。セルフレビューを行う場合は、「実行した検証」は静的確認だけで、実行検証は保留していることを明記して渡す。報告後にセルフレビューを行って修正した場合は、手順 5 の確認をやり直し、手順 7（commit）と手順 8（メモの更新）に戻る。
7. ローカル commit する。関連ファイルだけを `git add` し、日本語のメッセージに、`~/dotfiles/AI_RULES.md` の Git 運用に従った Co-Authored-By を付ける。push はしない。hook で失敗したら、`--no-verify` は使わず、commit せずに止まり、メインツリーへ持ち込めない旨を報告する。原因が解消したら、手順 7 から再開する。
8. 検証待ちメモを書く。

## 検証待ちメモ

* 場所: `<git-common-dir>/claude-verify/<ブランチ名>.md`。`<git-common-dir>` は、`git rev-parse --path-format=absolute --git-common-dir` を単独のコマンドで実行して得た絶対パス。commit に混ざらず、メインツリーからも読める。ブランチ名の `/` はディレクトリになるので、親ディレクトリも `mkdir -p` で作る。
* 書き込み: worktree に入っているセッションでは、メイン側のパスへの `Write` ツールが拒否される。`mkdir -p` と、Bash の heredoc（`cat > <メモのパス> <<'EOF'`）での書き込みを、別々のコマンドで実行する。
* 内容:
  * ブランチ（先頭行に `ブランチ: <名前>` の形式で書く）、worktree のパス、起点、commit
  * 要件と承認された範囲の要約
  * 主な変更ファイル
  * 受け入れ条件ごとの確認コマンドと期待結果
  * 依存の変更の有無（docker 側での再インストールの要否）
  * 基本確認の結果、セルフレビューの指摘と採否（行った場合）、「詳細レビュー未実施」（`/my-review` 前のため）
  * 残る制約

## サブエージェント

使い方は `/my-implement` に従う。指示には worktree の絶対パスを含め、そのパス配下だけを対象にさせ、メインツリーを触らせない。git コマンドは 1 つずつ単純な形式で実行するよう伝える。

## 報告

変更した動作と理由、ブランチ・worktree・commit、実施した確認と保留した検証、基本確認の結果、セルフレビューの指摘と採否（行った場合）、「詳細レビュー未実施」、メモのパス、残る制約を簡潔に示す。コードからの判断と、実行で確認した内容を区別する。
再開の方法として、メインツリーが空いたら、同じセッションで「メインが空いたから戻って検証を再開して」と指示すればよいことを案内する。`/my-review` は `/my-verify` の後に提案する。worktree からは出ない。
