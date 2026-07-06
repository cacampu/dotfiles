# dotfiles

zsh / neovim / zellij を中心とした設定ファイル群。Linux・WSL・Windows の 3 環境に対応している。

- **WSL / Linux 側**: `install.sh` が `.config/` 以下を `$HOME/.config/` へ symlink(編集した瞬間に反映される)
- **Windows 側**: [chezmoi](https://www.chezmoi.io/) をネイティブに実行し、`AppData/` 以下をエディタ設定として配備

## セットアップ手順

### 新しい Windows PC(推奨: ワンライナー)

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
5. WSL 内でのクローン(HTTPS・認証不要)と `install-wsl.sh` の実行
   (`/etc/wsl.conf` 更新にともなう WSL 再起動も自動で処理)

SSH 鍵や PAT の事前準備は不要。push できるようにするには、セットアップ完了後に
WSL 内で `gh auth login` を実行する(`gh` はセットアップで導入済み)。

VSCode・Zed 本体はインストールしない。必要なら先に入れておく
(`winget install Microsoft.VisualStudioCode ZedIndustries.Zed`)と、
VSCode 拡張機能のインストールまで bootstrap がやってくれる。

### Linux(デスクトップ)

```bash
git clone https://github.com/cacampu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-linux.sh
```

### 手動で WSL のみセットアップする場合

```bash
git clone https://github.com/cacampu/dotfiles.git ~/.dotfiles
~/.dotfiles/install-wsl.sh
```

npiperelay が必要なので、Windows 側で先に `bootstrap.ps1` を実行しておくこと。

## 設定変更のワークフロー

chezmoi のモデルは「**ソース(リポジトリ)→ 実ファイルへの一方向コピーを `apply` で行い、
逆方向は `re-add`、差分確認は `diff`**」。よく使うコマンド:

| コマンド | 意味 |
|---|---|
| `chezmoi diff` | ソースと実ファイルの差分表示(apply 前の確認) |
| `chezmoi apply` | ソース → 実ファイルへ反映 |
| `chezmoi re-add <file>` | 実ファイル → ソースへ逆取り込み(GUI で編集した後) |
| `chezmoi update` | git pull + apply(他マシン・WSL 側の変更を取り込む) |
| `chezmoi cd` | ソースディレクトリ(Windows 側クローン)へ移動 |

Windows 側 chezmoi はリポジトリの独立したクローンを `~\.local\share\chezmoi` に持つ。
WSL の `~/.dotfiles` とは別物で、**同期は git(GitHub)経由**で行う。

### ① WSL 側の設定を変える(nvim・zsh・zellij など)

symlink なので編集した瞬間に反映済み。`~/.dotfiles` で commit / push するだけ。
chezmoi は登場しない。

### ② Windows エディタ設定を GUI で変えた(VSCode の設定画面など)

実ファイル(AppData)が先に変わったので、PowerShell で逆取り込みして push:

```powershell
chezmoi diff
chezmoi re-add $env:APPDATA\Code\User\settings.json
chezmoi cd
git add -A; git commit -m "update vscode settings"; git push
```

WSL 側の `~/.dotfiles` には都合のいいタイミングで `git pull`。

### ③ Windows エディタ設定をリポジトリ側で編集した(WSL の nvim で書き換え)

WSL で編集して push → PowerShell で取り込み:

```bash
# WSL: ~/.dotfiles/AppData/... を編集して
git commit -am "update zed keymap" && git push
```
```powershell
# PowerShell:
chezmoi update
```

### ④ 2 台目の PC へ反映

```powershell
chezmoi update               # Windows 側
```
```bash
cd ~/.dotfiles && git pull   # WSL 側(symlink なので pull だけで反映)
```

## ディレクトリ構造

```
.dotfiles/
├── bootstrap.ps1           # 新しい Windows PC の一括セットアップ(irm | iex で実行)
├── install.sh              # 共通ベース(Linux/WSL 両方から呼ばれる)
├── install-linux.sh        # Linux デスクトップ用(install.sh + GUI エディタ)
├── install-wsl.sh          # WSL 用(install.sh + SSH relay)
│
├── .zshenv                 # zsh 起動時の最初に読まれる(XDG_CONFIG_HOME 等を設定)
│
├── .config/                # WSL/Linux 側の設定(install.sh が丸ごと symlink)
│   ├── zsh/                #   ディレクトリを追加するだけで新しい設定が反映される
│   ├── shell/              #   env(PATH・WSL SSH relay)・aliases・loaders
│   ├── git/
│   ├── mise/               # 開発ツールのバージョン管理(node・go・neovim 等)
│   ├── nvim/               # Neovim 設定(lazy.nvim ベース)
│   └── zellij/
│
├── AppData/                # Windows 側の設定(Windows ネイティブ chezmoi が配備)
│   └── Roaming/
│       ├── Code/User/      # VSCode settings.json / keybindings.json
│       └── Zed/            # Zed settings.json / keymap.json
│
├── windows/
│   └── extensions.txt      # VSCode 拡張機能リスト(bootstrap.ps1 が参照)
│
├── .chezmoiignore          # chezmoi の配備対象を AppData/ のみに制限(OS で分岐)
└── Dockerfile.test         # install.sh の動作確認用コンテナ
```

## インストールスクリプトの設計

```
bootstrap.ps1(Windows: WSL 確認・npiperelay・chezmoi・VSCode 拡張)
    └→ wsl: git clone → install-wsl.sh(WSL 固有: wsl.conf・SSH relay)
                            └→ install.sh(CLI ツール共通)

install-linux.sh(Linux GUI 固有: Zed・VSCode)
    └→ install.sh
```

`install.sh` が行う処理:

1. apt パッケージ(curl・git・zsh・build-essential 等)
2. [mise](https://mise.jdx.dev/) — 開発ツールのバージョンマネージャ
3. fzf・oh-my-zsh・starship・Rust
4. GitHub CLI
5. シンボリックリンクの作成(`.config/` 直下を丸ごと `$HOME/.config/` へ)
6. `mise install` — config.toml に定義した全ツールのインストール
7. Claude Code(`npm install -g`)
8. デフォルトシェルを zsh に変更

すべて冪等で、何度実行してもよい。

## ツール管理

開発ツールは [mise](https://mise.jdx.dev/) で一元管理する(`.config/mise/config.toml`):

| ツール | 用途 |
|--------|------|
| neovim | メインエディタ |
| node   | JavaScript ランタイム(Claude Code 依存) |
| go     | Go 開発 |
| zig    | Zig 開発 |
| ghc / cabal | Haskell 開発 |
| nim    | Nim 開発 |
| julia  | Julia 開発 |
| java   | Java 開発(Corretto) |
| zellij | ターミナルマルチプレクサ |
| ripgrep / fd / bat / eza | CLI ユーティリティ |

## WSL の SSH Agent Relay

Windows の OpenSSH agent を WSL から使えるようにするための仕組み:

- `bootstrap.ps1` が npiperelay.exe を `C:\bin\` にインストール
- `install-wsl.sh` が socat をインストールし SSH 設定をリンク
- `.config/shell/env` が起動時に socat でパイプを中継するプロセスを起動

リポジトリのクローン自体は HTTPS で行うため、SSH はセットアップの前提ではない。
