---
name: my-review
description: Review the current code changes from a tech lead perspective. Use when the user invokes my-review, asks Codex to review the current branch, review a diff range, or assess changes for requirements fit, side effects, simplicity, edge cases, security, naming, and maintainability.
---

# my-review

現在の修正内容をテックリード視点でレビューする。

## 引数

- 引数なし: staged / unstaged の作業ツリー差分を優先し、なければ現ブランチ全体を対象にする。
- 引数あり: `git diff $ARGUMENTS` で任意の比較を対象にする。
  - 例: `HEAD~1`, `main..feature/xxx`

## 手順

1. 引数に応じて diff を取得する。
   - 引数なし:
     1. `git status --short --branch` で現在のブランチと作業ツリー状態を確認する。
     2. `git diff --cached` で staged 変更を確認する。
     3. `git diff` で unstaged 変更を確認する。
     4. staged / unstaged がどちらも空の場合、`main...HEAD` または `master...HEAD` で現ブランチ全体を確認する。
   - 引数あり: `git diff $ARGUMENTS`
2. diff が空の場合は、終了前に以下を確認する。
   - `git branch --show-current` で作業ブランチを間違っていないか確認する。
   - `git status --short --branch` で未追跡ファイル、staged / unstaged 変更、upstream との差分を確認する。
   - `git branch --list main master` で比較先ブランチが存在するか確認する。
   - `git log --oneline --decorate -5` で直近コミットが想定どおりか確認する。
3. 上記を確認しても diff が空の場合のみ「変更なし」と報告して終了する。
4. diff の内容を確認する。
5. diff だけでは判断できない場合は、関連する Controller / Service / Request / Policy / Model / Migration / Test などを調査する。
6. 推測で判断せず、不明点は「要確認」として扱う。
7. 問題が見つかった場合は修正案を提示する。実際の修正はユーザーの許可を得てから行う。

## レビュー観点

1. 要件適合
   - 変更が意図した目的を正確に達成しているか。
2. 副作用
   - 既存機能への影響や破壊的変更がないか。
3. シンプルさ
   - 不要な抽象化や冗長なコードがないか。
   - 既存実装との整合性が取れているか。
4. エッジケース
   - 境界値、null、空配列、異常系、想定外入力。
5. セキュリティ
   - 認可漏れ。
   - 他ユーザーのデータ参照・更新・削除の可能性、IDOR。
   - Request バリデーション不足。
   - Mass Assignment。
   - SQL Injection。
   - XSS。
   - CSRF。
   - 機密情報の露出、ログ・レスポンス・Git 管理対象。
   - 権限昇格リスク。
6. 命名・可読性
   - 変数名・関数名が意図を正確に表しているか。
   - 将来の保守性を損なわないか。

## 注意事項

- diff のみで「問題なし」と判断しない。
- 認証・認可・バリデーションは実装箇所まで追跡して確認する。
- 指摘は重要度順に並べる。
- 問題の指摘には、重要度順に `#1` から始まる一意の連番を付ける。
- 修正の相談・確認など後続のやり取りでも同じ番号を維持し、再採番しない。
- Codex の標準的なコードレビュー形式を優先し、問題がある場合は findings を先に出す。

## 出力フォーマット

```text
## レビュー結果

**対象**: <diff の比較範囲>
**変更ファイル数**: N ファイル

### 問題あり

- #N [重要度: 高/中/低] `ファイル名:行番号`
  - 問題
  - 影響
  - 修正案

### セキュリティチェック結果

- 認証: OK / 要確認 / 問題あり
- 認可: OK / 要確認 / 問題あり
- データ漏洩: OK / 要確認 / 問題あり
- 入力値検証: OK / 要確認 / 問題あり

### 問題なし

- 観点名: OK

### 総評

<全体的な評価と次のアクション>
```
