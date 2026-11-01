<#
.SYNOPSIS
    作業用ブランチのコミットから patches フォルダを作り直します。

.DESCRIPTION
    PRISM_VERSION のタグから現在の HEAD までのコミットを、1 コミット = 1 ファイルのパッチとして
    patches フォルダに書き出します。既存の patches\*.patch は先に削除されます。

.EXAMPLE
    .\update-patches.ps1
    .\update-patches.ps1 -Source D:\work\PrismLauncher
#>
param(
    [string]$Source = (Join-Path $PSScriptRoot "PrismLauncher")
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($args -join ' ') が失敗しました (exit code $LASTEXITCODE)"
    }
}

$tag = (Get-Content (Join-Path $PSScriptRoot "PRISM_VERSION") -Raw).Trim()
$out = Join-Path $PSScriptRoot "patches"

Push-Location $Source
try {
    $dirty = & git status --porcelain --untracked-files=no
    if ($dirty) {
        Write-Host "注意: コミットされていない変更はパッチに含まれません" -ForegroundColor Yellow
    }

    New-Item -ItemType Directory -Force $out | Out-Null
    Remove-Item (Join-Path $out "*.patch") -ErrorAction SilentlyContinue

    # --zero-commit: コミットハッシュを 0 にして、作り直すたびに差分が出ないようにする
    Invoke-Git -c core.autocrlf=false format-patch "$tag..HEAD" --zero-commit --no-signature -o $out
    Write-Host "patches フォルダを更新しました" -ForegroundColor Green
} finally {
    Pop-Location
}
