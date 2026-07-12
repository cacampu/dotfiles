# dotfiles

zsh / neovim / zellij を中心とした設定ファイル群。Linux・WSL・Windows の 3 環境に対応している。

- **WSL / Linux 側**: `install.sh` が `.config/` 以下を `$HOME/.config/` へ symlink(編集した瞬間に反映)
- **Windows 側**: [chezmoi](https://www.chezmoi.io/) をネイティブに実行し、`AppData/` 以下をエディタ設定として配備

## クイックスタート

新しい Windows PC なら、管理者 PowerShell で下記ワンライナーだけで WSL 込みのセットアップが完了する:

```powershell
irm https://raw.githubusercontent.com/cacampu/dotfiles/main/bootstrap.ps1 | iex
```

Linux / 手動 WSL の手順は [docs/setup.md](docs/setup.md) を参照。

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/setup.md](docs/setup.md) | セットアップ手順(Windows / Linux / 手動 WSL) |
| [docs/workflow.md](docs/workflow.md) | 設定変更のワークフロー(chezmoi の apply / re-add / update) |
| [docs/architecture.md](docs/architecture.md) | ディレクトリ構造とインストールスクリプトの設計 |
| [docs/tools/](docs/tools/README.md) | 開発ツール管理(mise)と、ツール別の依存・使い方 |
| [docs/tools/adding-tools.md](docs/tools/adding-tools.md) | 新しいツールを追加するときの手順と設計判断 |
| [docs/ssh-relay.md](docs/ssh-relay.md) | WSL から Windows の SSH agent を使う仕組み |
