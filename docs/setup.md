# セットアップ手順

- **WSL / Linux 側**: `install.sh` が `.config/` 以下を `$HOME/.config/` へ symlink(編集した瞬間に反映される)
- **Windows 側**: [chezmoi](https://www.chezmoi.io/) をネイティブに実行し、`AppData/` 以下をエディタ設定として配備

## 新しい Windows PC(推奨: ワンライナー)

管理者 PowerShell で:

```powershell
irm https://raw.githubusercontent.com/cacampu/dotfiles/main/bootstrap.ps1 | iex
```

これだけで以下がすべて実行される:

1. WSL の確認(未インストールなら `wsl --install` → **再起動 → Ubuntu を一度起動して
   ユーザーを作成 → もう一度同じコマンドを実行**)
2. npiperelay のインストールと `~/.ssh` の準備(SSH agent relay 用)
3. chezmoi のインストールと Windows エディタ設定(VSCode / Zed)の配備
4. VSCode 拡張機能のインストール
5. starship のインストールと PowerShell プロファイル(`$PROFILE`)への init hook 追加
6. WSL 内でのクローン(HTTPS・認証不要)と `install-wsl.sh` の実行
   (`/etc/wsl.conf` 更新にともなう WSL 再起動も自動で処理)

SSH 鍵や PAT の事前準備は不要。push できるようにするには、セットアップ完了後に
WSL 内で `gh auth login` を実行する(`gh` はセットアップで導入済み)。

VSCode・Zed 本体はインストールしない。必要なら先に入れておく
(`winget install Microsoft.VisualStudioCode ZedIndustries.Zed`)と、
VSCode 拡張機能のインストールまで bootstrap がやってくれる。

## Linux(デスクトップ)

```bash
git clone https://github.com/cacampu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-linux.sh
```

## 手動で WSL のみセットアップする場合

```bash
git clone https://github.com/cacampu/dotfiles.git ~/.dotfiles
~/.dotfiles/install-wsl.sh
```

npiperelay が必要なので、Windows 側で先に `bootstrap.ps1` を実行しておくこと。
SSH agent relay の仕組みは [ssh-relay.md](ssh-relay.md) を参照。
