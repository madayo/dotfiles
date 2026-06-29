# プロジェクト規約

## .env

- `.env` は Git 管理しない
- `.env.example` を管理する

## Docker

- `COMPOSE_PROJECT_NAME` を設定する
- ポート番号は `.env` 経由で管理する

## ディレクトリ構成

新規プロジェクトは以下を推奨する。

- `src/`
- `docker/`
- `tools/`
- `design/`
