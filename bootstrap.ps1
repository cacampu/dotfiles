# bootstrap.ps1 — 新しい Windows PC の一括セットアップ
#
# 管理者 PowerShell で実行:
#   irm https://raw.githubusercontent.com/cacampu/dotfiles/main/bootstrap.ps1 | iex
#
# WSL が未インストールの場合は wsl --install 後に再起動を促して終了するので、
# 再起動後にもう一度同じコマンドを実行する。
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoUser = "cacampu"
$RepoUrl  = "https://github.com/$RepoUser/dotfiles.git"

function Log($msg)  { Write-Host "[dotfiles] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[warning]  $msg" -ForegroundColor Yellow }

# WSL ディストリビューションが起動可能かを確認し、なければインストールして終了
function Ensure-Wsl {
    # PS 5.1 は ErrorActionPreference=Stop だと native コマンドの stderr リダイレクトで
    # 例外を投げるため、この確認中だけ緩める
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    wsl -e true *> $null
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0) {
        Log "WSL distro not found. Installing..."
        wsl --install
        Warn "Reboot, launch Ubuntu once to create your user, then re-run this script."
        exit 0
    }
    Log "WSL is ready."
}

# npiperelay のインストール (C:\bin\npiperelay.exe) — WSL の SSH agent relay に必要
function Install-Npiperelay {
    $binDir = "C:\bin"
    $exePath = "$binDir\npiperelay.exe"

    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    if (-not (Test-Path $exePath)) {
        Log "Installing npiperelay to $exePath..."
        $url = "https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip"
        $zipPath = "$env:TEMP\npiperelay.zip"

        Invoke-WebRequest -Uri $url -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath "$env:TEMP\npiperelay_extracted" -Force
        Copy-Item "$env:TEMP\npiperelay_extracted\npiperelay.exe" -Destination $exePath

        Remove-Item $zipPath, "$env:TEMP\npiperelay_extracted" -Recurse
        Log "  npiperelay installed successfully."
    } else {
        Log "npiperelay already installed, skipping"
    }
}

# SSH ディレクトリと空ファイルの準備 (WSL 側から symlink されるため先に作る)
function Setup-WindowsSshDir {
    $winSshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $winSshDir)) {
        New-Item -ItemType Directory -Path $winSshDir -Force | Out-Null
        Log "Created $winSshDir"
    }

    $configPath = Join-Path $winSshDir "config"
    $knownHostsPath = Join-Path $winSshDir "known_hosts"

    if (-not (Test-Path $configPath)) { New-Item -ItemType File -Path $configPath | Out-Null }
    if (-not (Test-Path $knownHostsPath)) { New-Item -ItemType File -Path $knownHostsPath | Out-Null }
}

# chezmoi (Windows ネイティブ) でエディタ設定を AppData へ配備
function Setup-Chezmoi {
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        Log "Installing chezmoi..."
        winget install --id twpayne.chezmoi --accept-source-agreements --accept-package-agreements
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [Environment]::GetEnvironmentVariable("Path", "User")
    }
    Log "Applying Windows configs via chezmoi..."
    chezmoi init --apply $RepoUser
}

function Install-VscodeExtensions {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Warn "VSCode not installed, skipping extensions"
        return
    }
    $listFile = Join-Path (chezmoi source-path) "windows\extensions.txt"
    if (-not (Test-Path $listFile)) { Warn "extensions.txt not found, skipping"; return }
    Log "Installing VSCode extensions..."
    Get-Content $listFile | ForEach-Object {
        $id = $_.Trim()
        if ($id -match '^\S+\.\S+$') {
            code --install-extension $id
        }
    }
}

# WSL 側のセットアップ (クローン → install-wsl.sh)
function Setup-WslSide {
    Log "Setting up WSL side..."
    wsl -- bash -c 'command -v git >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y git; }'

    $clone = '[ -d "$HOME/.dotfiles" ] || git clone ' + $RepoUrl + ' "$HOME/.dotfiles"'
    wsl -- bash -c $clone

    wsl -- bash -c '"$HOME/.dotfiles/install-wsl.sh"'
    if ($LASTEXITCODE -eq 3) {
        # install-wsl.sh が /etc/wsl.conf を書き換えた場合は WSL の再起動が必要
        Log "Restarting WSL to enable metadata mount option..."
        wsl --shutdown
        Start-Sleep -Seconds 3
        wsl -- bash -c '"$HOME/.dotfiles/install-wsl.sh"'
    }
    if ($LASTEXITCODE -ne 0) { throw "WSL setup failed (exit code $LASTEXITCODE)" }
}

# 実行セクション
Ensure-Wsl
Install-Npiperelay
Setup-WindowsSshDir
Setup-Chezmoi
Install-VscodeExtensions
Setup-WslSide

Log "Bootstrap complete!"
