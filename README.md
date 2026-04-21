# 想定環境  
WSL * Windows Terminal 向けの設定

## Copilot 設定

- workspace 共通 instruction: `.github/copilot-instructions.md`
- user 共通 instruction: `.copilot/instructions/*.instructions.md`
- user 共通 prompt files: `.copilot/prompts/*.prompt.md`
- user 共通 hooks: `.copilot/hooks/*.json`
- Claude 互換 instruction: `.claude/CLAUDE.md`

`bin/initialize/_link.sh` で VS Code user prompts 配下をリンクします。

役割分担は次のとおりです。

- `.copilot/instructions`: Copilot 向けの個人既定ルール
- `.copilot/prompts`: 全プロジェクトで再利用する個人 prompt
- `.copilot/hooks`: Copilot Agent 完了時の自動処理
- `.github/copilot-instructions.md`: このリポジトリ専用ルール
- `.claude/CLAUDE.md`: Claude Code と共有したい共通ルール

VS Code では `.github/copilot-instructions.md` が workspace instruction として読み込まれます。user-level prompt は WSL 環境の `~/.vscode-server/data/User/prompts` にリンクして読み込ませます。user-level instructions と hooks を dotfiles 配下から読む場合は、既存の VS Code user settings に `chat.instructionsFilesLocations` と `chat.hookFilesLocations` を手動で追記してください。`CLAUDE.md` 互換 instruction を使う場合も `chat.useClaudeMdFile` を user settings 側で有効にします。

## Copilot 通知音

- `.copilot/hooks/copilot-notify.json` で Copilot Agent の `Stop` と `SubagentStop` にフックします。
- 実際の通知処理は `.copilot/bin/copilot-notify.sh` が担当します。
- 音声ファイルは Windows のユーザディレクトリ配下 `Music/beep2.wav` を直接参照します。

通知音を変える場合は Windows 側の `Music/beep2.wav` を差し替えてください。PowerShell の `SoundPlayer` を使うため、音声ファイルは `.wav` を前提にしています。

`.copilot/hooks` や `.copilot/instructions` は `~/.copilot` にリンクしません。必要なら既存の VS Code user settings から `~/dotfiles/.copilot/hooks` と `~/dotfiles/.copilot/instructions` を直接読み込ませてください。

例:

```json
{
	"chat.useClaudeMdFile": true,
	"chat.instructionsFilesLocations": {
		"~/dotfiles/.copilot/instructions": true
	},
	"chat.hookFilesLocations": {
		"~/dotfiles/.copilot/hooks": true
	}
}
```
