<#
.SYNOPSIS
    本家 Prism Launcher を取得して、patches フォルダのパッチを当てます。

.DESCRIPTION
    1. PRISM_VERSION に書かれたタグで PrismLauncher を clone します（既にあれば再利用）
    2. そのタグから作業用ブランチ（既定: cleanroom）を作ります
    3. patches\*.patch を番号順に git am で当てます

.EXAMPLE
    .\apply.ps1
    .\apply.ps1 -Destination D:\work\PrismLauncher
    .\apply.ps1 -Force    # 作業用ブランチを作り直す（そのブランチの変更は消えます）
#>
param(
    [string]$Destination = (Join-Path $PSScriptRoot "PrismLauncher"),
    [string]$Branch = "cleanroom",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($args -join ' ') が失敗しました (exit code $LASTEXITCODE)"
    }
}

$tag = (Get-Content (Join-Path $PSScriptRoot "PRISM_VERSION") -Raw).Trim()
$patches = @(Get-ChildItem (Join-Path $PSScriptRoot "patches") -Filter *.patch | Sort-Object Name)
if ($patches.Count -eq 0) {
    throw "patches フォルダにパッチがありません"
}

if (-not (Test-Path (Join-Path $Destination ".git"))) {
    Write-Host "Prism Launcher $tag を取得しています: $Destination" -ForegroundColor Cyan
    # パッチは LF 改行なので、Windows の CRLF 変換をしない状態で取得する
    Invoke-Git clone -c core.autocrlf=false --recursive --branch $tag https://github.com/PrismLauncher/PrismLauncher.git $Destination
}

Push-Location $Destination
try {
    # 前回 git am が途中で失敗していたら、その作業を取り消す
    if (Test-Path ".git\rebase-apply") {
        Write-Host "途中で止まっていたパッチ適用を取り消します" -ForegroundColor Yellow
        & git am --abort 2>$null
        if (Test-Path ".git\rebase-apply") { Invoke-Git am --quit }
    }

    # Git for Windows は既定で改行を CRLF に変換するが、そのままだと LF のパッチが当たらない。
    # このフォルダだけ変換を止め、ファイルを LF で取り出し直す。
    $normalize = $false
    if ((& git config --local core.autocrlf) -ne "false") {
        Invoke-Git config --local core.autocrlf false
        $normalize = $true
    }

    # 未コミットの変更があると git am が途中で止まるので、先に確認する
    $dirty = & git status --porcelain --untracked-files=no
    if ($dirty) {
        throw "$Destination に未コミットの変更があります。commit か stash してから再実行してください。"
    }

    & git rev-parse --verify --quiet "refs/heads/$Branch" | Out-Null
    $branchExists = ($LASTEXITCODE -eq 0)
    if ($branchExists -and -not $Force) {
        throw "ブランチ '$Branch' は既にあります。作り直す場合は -Force を付けてください（そのブランチの変更は消えます）。"
    }

    # Prism の新しいバージョンに追従したとき、手元の clone にはまだそのタグが無い
    & git rev-parse --verify --quiet "refs/tags/$tag" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Prism Launcher $tag を取得しています" -ForegroundColor Cyan
        Invoke-Git fetch --no-tags origin "refs/tags/${tag}:refs/tags/${tag}"
    }

    Write-Host "タグ $tag からブランチ '$Branch' を作成します" -ForegroundColor Cyan
    Invoke-Git switch --force-create $Branch $tag
    if ($normalize) {
        Write-Host "改行コードを LF に揃えます (次のビルドは全体のビルドし直しになります)" -ForegroundColor Yellow
        Remove-Item ".git\index" -Force
        Invoke-Git reset --hard --quiet
    }
    Invoke-Git submodule update --init --recursive

    # Windows の改行変換でパッチが壊れないようにする。
    # git の名前/メールが未設定でも git am が通るよう、未設定なら仮の値を使う。
    $gitOptions = @("-c", "core.autocrlf=false")
    if (-not (& git config user.name)) {
        $gitOptions += @("-c", "user.name=prism-cleanroom", "-c", "user.email=prism-cleanroom@localhost")
    }

    Write-Host "パッチを $($patches.Count) 個当てます" -ForegroundColor Cyan
    try {
        Invoke-Git @gitOptions am --3way @($patches.FullName)
    } catch {
        Write-Host "パッチの適用に失敗しました。元に戻すには $Destination で 'git am --abort' を実行してください。" -ForegroundColor Red
        throw
    }

    Write-Host "完了しました: $Destination (ブランチ $Branch)" -ForegroundColor Green
} finally {
    Pop-Location
}
