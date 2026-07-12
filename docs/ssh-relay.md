# WSL の SSH Agent Relay

Windows の OpenSSH agent を WSL から使えるようにするための仕組み:

- `bootstrap.ps1` が npiperelay.exe を `C:\bin\` にインストール
- `install-wsl.sh` が socat をインストールし SSH 設定をリンク
- `.config/shell/env` が起動時に socat でパイプを中継するプロセスを起動

リポジトリのクローン自体は HTTPS で行うため、SSH はセットアップの前提ではない。
