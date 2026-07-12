# 設定変更のワークフロー

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

## ① WSL 側の設定を変える(nvim・zsh・zellij など)

symlink なので編集した瞬間に反映済み。`~/.dotfiles` で commit / push するだけ。
chezmoi は登場しない。

## ② Windows エディタ設定を GUI で変えた(VSCode の設定画面など)

実ファイル(AppData)が先に変わったので、PowerShell で逆取り込みして push:

```powershell
chezmoi diff
chezmoi re-add $env:APPDATA\Code\User\settings.json
chezmoi cd
git add -A; git commit -m "update vscode settings"; git push
```

WSL 側の `~/.dotfiles` には都合のいいタイミングで `git pull`。

## ③ Windows エディタ設定をリポジトリ側で編集した(WSL の nvim で書き換え)

WSL で編集して push → PowerShell で取り込み:

```bash
# WSL: ~/.dotfiles/AppData/... を編集して
git commit -am "update zed keymap" && git push
```
```powershell
# PowerShell:
chezmoi update
```

## ④ 2 台目の PC へ反映

```powershell
chezmoi update               # Windows 側
```
```bash
cd ~/.dotfiles && git pull   # WSL 側(symlink なので pull だけで反映)
```
