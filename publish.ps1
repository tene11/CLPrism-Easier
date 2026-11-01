<#
.SYNOPSIS
    このフォルダ (パッチとスクリプト) を GitHub の非公開リポジトリとして公開・更新します。
    publish.bat をダブルクリックすると、これが実行されます。

.DESCRIPTION
    1. GitHub CLI (gh) が無ければ入れる
    2. GitHub にログインしていなければ、ブラウザでログインしてもらう
    3. このフォルダを Git リポジトリにしてコミットする
    4. 初回は GitHub に非公開リポジトリを作って push、2 回目以降は変更を push する
    PrismLauncher フォルダ (ビルド用のソース) や vcpkg、ログは .gitignore で除外されます。
#>
param(
    [string]$RepoName = "prism-cleanroom",
    [ValidateSet("private", "public")]
    [string]$Visibility = "private"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = $PSScriptRoot

function Step($text) { Write-Host ""; Write-Host "==== $text ====" -ForegroundColor Cyan }
function Ok($text) { Write-Host "  OK: $text" -ForegroundColor Green }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function ExitCodeOf {
    # 出力を捨てて終了コードだけ返す。Windows PowerShell 5.1 では、エラー出力を捨てる指定が
    # "Stop" の設定と組み合わさると例外になるので、一時的に Continue にする
    $exe, $rest = $args
    $saved = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { & $exe @rest *> $null } finally { $ErrorActionPreference = $saved }
    return $LASTEXITCODE
}
function Run {
    $exe, $rest = $args
    & $exe @rest
    if ($LASTEXITCODE -ne 0) { throw "$exe $($rest -join ' ') が失敗しました (exit code $LASTEXITCODE)" }
}

try {
    Step "1/4 GitHub CLI"
    if (-not (Has "git")) { throw "git が見つかりません。先に build.bat を実行してください。" }
    if (-not (Has "gh")) {
        Write-Host "  GitHub CLI (gh) を入れます..." -ForegroundColor Yellow
        Run winget install --source winget --exact --id GitHub.cli --accept-package-agreements --accept-source-agreements
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not (Has "gh")) { throw "GitHub CLI を入れましたが見つかりません。publish.bat をもう一度実行してください。" }
    }
    Ok ((& gh --version) | Select-Object -First 1)

    Step "2/4 GitHub へのログイン"
    if ((ExitCodeOf gh auth status --hostname github.com) -ne 0) {
        Write-Host "  GitHub にログインします。表示されたコードをブラウザに入力してください。" -ForegroundColor Yellow
        & gh auth login --hostname github.com --git-protocol https --web --scopes workflow
        if ($LASTEXITCODE -ne 0) { throw "GitHub へのログインに失敗しました。" }
    }
    # .github/workflows を push するには "workflow" の権限が要る
    $saved = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $authStatus = (& gh auth status --hostname github.com 2>&1 | Out-String)
    $ErrorActionPreference = $saved
    if ($authStatus -notmatch "workflow") {
        Write-Host "  自動追従の設定ファイルを上げるため、GitHub の権限を追加します。ブラウザで許可してください。" -ForegroundColor Yellow
        & gh auth refresh --hostname github.com --scopes workflow
        if ($LASTEXITCODE -ne 0) { throw "GitHub の権限の追加に失敗しました。" }
    }
    Run gh auth setup-git
    $login = (& gh api user --jq .login).Trim()
    $userId = (& gh api user --jq .id).Trim()
    Ok "$login としてログイン済み"

    Step "3/4 コミット"
    Push-Location $root
    try {
        if (-not (Test-Path (Join-Path $root ".git"))) {
            Run git init --initial-branch=main
        }
        # 公開リポジトリに個人のメールアドレスが載らないよう、GitHub の noreply アドレスでコミットする
        Run git config --local user.name $login
        Run git config --local user.email "$userId+$login@users.noreply.github.com"
        Run git config --local core.autocrlf false

        # .gitignore に載っているのに、以前のコミットに入ってしまったファイル (ログなど) を外す
        foreach ($ignored in @(& git ls-files --cached --ignored --exclude-standard)) {
            if ($ignored) { Run git rm --cached --quiet -- $ignored }
        }
        Run git add --all
        if ((ExitCodeOf git diff --cached --quiet) -ne 0) {
            $message = if ((ExitCodeOf git rev-parse --verify --quiet HEAD) -eq 0) { "Update patches and scripts" } else { "Add Cleanroom support patches for Prism Launcher" }
            Run git commit --quiet -m $message
            Ok "コミットしました: $message"
        } else {
            Ok "変更はありません"
        }

        Step "4/4 GitHub へ公開"
        if ((ExitCodeOf git remote get-url origin) -ne 0) {
            Write-Host "  $Visibility リポジトリ $login/$RepoName を作成します..." -ForegroundColor Yellow
            Run gh repo create $RepoName "--$Visibility" --source . --remote origin --push --description "Prism Launcher patches: install Cleanroom from the loader dialog"
        } else {
            Run git push --set-upstream origin main
        }
        # Prism の新バージョンを見つけた自動チェックが、プルリクエストを作れるようにする
        Run gh api --method PUT "repos/$login/$RepoName/actions/permissions/workflow" -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true

        $url = (& gh repo view --json url --jq .url).Trim()
        Write-Host ""
        Write-Host "完了しました: $url" -ForegroundColor Green
        Write-Host "パッチが変わっていれば、GitHub が Windows 版のビルドを始めます (40〜90 分ほど)。" -ForegroundColor Green
        Write-Host "終わると Releases に zip ができます。進み具合は開いたページ (Actions) で見られます。" -ForegroundColor Green
        Start-Process "$url/actions"
    } finally {
        Pop-Location
    }
} catch {
    Write-Host ""
    Write-Host "エラー: $_" -ForegroundColor Red
    exit 1
}
