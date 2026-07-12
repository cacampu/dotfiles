# リポジトリ構造とインストール設計

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
│   ├── mise/               # 開発ツールのバージョン管理(config.toml・shell-hooks.zsh)
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
├── docs/                   # ドキュメント(このディレクトリ)
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
5. シンボリックリンクの作成(`.config/` 直下を `$HOME/.config/` へ。原則ディレクトリごと symlink、
   zsh 等アプリが state を書く dir はファイル単位でリンク)
6. `mise install` — config.toml に定義した全ツールのインストール
7. Claude Code(`npm install -g`)
8. デフォルトシェルを zsh に変更

すべて冪等で、何度実行してもよい。
