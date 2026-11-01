<#
.SYNOPSIS
    ビルドに必要なものを確認・準備して、パッチ済みの Prism Launcher をビルドします。
    build.bat をダブルクリックすると、これが実行されます。
    実行内容はすべて build-log.txt に記録されます。
#>
param(
    [string]$QtVersion = "6.10.2",
    [string]$QtRoot = "C:\Qt",
    # Debug ビルドは本家 Prism の内部チェック (ASSERT) に引っかかるとランチャーごと落ちるので、普段は Release を使う
    [string]$Config = "Release"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = $PSScriptRoot
$log = Join-Path $root "build-log.txt"
Start-Transcript -Path $log -Force | Out-Null

function Step($text) { Write-Host ""; Write-Host "==== $text ====" -ForegroundColor Cyan }
function Ok($text) { Write-Host "  OK: $text" -ForegroundColor Green }
function Fail($text) { throw $text }
function Run {
    # 外部コマンドを実行し、出力 (エラー出力も) をログに残す。失敗したら止める。
    # Windows PowerShell 5.1 ではエラー出力を 2>&1 で受けると例外になるので、一時的に Continue にする
    $exe, $rest = $args
    $saved = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $exe @rest 2>&1 | ForEach-Object { "$_" } | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $saved
    }
    if ($code -ne 0) { Fail "$exe $($rest -join ' ') が失敗しました (exit code $code)" }
}
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

try {
    # GitHub で Prism の新バージョンへの追従 (プルリクエスト) をマージしていたら、それを取り込む
    if ((Test-Path (Join-Path $root ".git")) -and (Has "git")) {
        $saved = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & git -C $root remote get-url origin *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "GitHub から最新のパッチを取り込みます..." -ForegroundColor Cyan
            & git -C $root pull --ff-only 2>&1 | ForEach-Object { "$_" } | Out-Host
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  取り込めませんでした (手元に未公開の変更があるかもしれません)。手元のパッチのままビルドします。" -ForegroundColor Yellow
            }
        }
        $ErrorActionPreference = $saved
    }

    # ------------------------------------------------------------------
    Step "1/7 Visual Studio 2022 (C++ ビルドツール)"
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = $null
    if (Test-Path $vswhere) {
        $vs = & $vswhere -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    }
    if (-not $vs) {
        Write-Host "  Visual Studio 2022 Build Tools (C++) を入れます。" -ForegroundColor Yellow
        Write-Host "  数 GB のダウンロードがあり、20 分以上かかることがあります。許可を求められたら「はい」を押してください..." -ForegroundColor Yellow
        $override = "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.VC.CMake.Project"
        $saved = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & winget install --source winget --exact --id Microsoft.VisualStudio.2022.BuildTools --override $override --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object { "$_" } | Out-Host
        $ErrorActionPreference = $saved
        # winget は「再起動が必要」でも 0 以外を返すことがあるので、終了コードではなく実際に入ったかで判断する
        if (Test-Path $vswhere) {
            $vs = & $vswhere -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        }
        if (-not $vs) {
            Fail "Visual Studio 2022 Build Tools のインストールを確認できませんでした。PC を再起動してから、もう一度 build.bat を実行してください。"
        }
    }
    Ok $vs

    # CMake と Ninja は VS の「C++ CMake tools」コンポーネントに入っている
    $hasCMake = & $vswhere -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.CMake.Project -property installationPath
    if (-not $hasCMake) {
        Write-Host "  C++ CMake tools が無いので追加します。インストーラーの画面が出たら許可してください..." -ForegroundColor Yellow
        $setup = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\setup.exe"
        $p = Start-Process $setup -Verb RunAs -Wait -PassThru -ArgumentList @(
            "modify", "--installPath", "`"$vs`"",
            "--add", "Microsoft.VisualStudio.Component.VC.CMake.Project",
            "--passive", "--norestart")
        if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { Fail "C++ CMake tools の追加に失敗しました (exit code $($p.ExitCode))" }
        Ok "C++ CMake tools を追加しました"
    }

    # 開発者用ターミナルと同じ環境 (cl.exe, cmake, ninja) をこのウィンドウに読み込む
    Import-Module (Join-Path $vs "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64" | Out-Null
    foreach ($c in "cl", "cmake", "ninja") {
        if (-not (Has $c)) { Fail "$c が見つかりません。Visual Studio Installer で「C++ CMake tools for Windows」が入っているか確認してください。" }
    }
    Ok ("cmake " + ((& cmake --version) | Select-Object -First 1))

    # ------------------------------------------------------------------
    Step "2/7 Git"
    if (-not (Has "git")) { Fail "git が見つかりません: winget install --source winget --exact --id Git.Git" }
    Ok ((& git --version) -join "")

    # ------------------------------------------------------------------
    Step "3/7 Java (JDK 17)"
    if (-not (Has "javac")) {
        $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-17*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $jdk) {
            Write-Host "  JDK 17 を入れます..." -ForegroundColor Yellow
            Run winget install --source winget --exact --id EclipseAdoptium.Temurin.17.JDK --accept-package-agreements --accept-source-agreements
            $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-17*" | Select-Object -First 1
        }
        if (-not $jdk) { Fail "JDK 17 が見つかりません" }
        $env:JAVA_HOME = $jdk.FullName
        $env:Path = (Join-Path $jdk.FullName "bin") + ";" + $env:Path
    }
    Ok ((& cmd /c "javac -version 2>&1") -join "")

    # ------------------------------------------------------------------
    Step "4/7 Qt $QtVersion"
    $qt = Join-Path $QtRoot "$QtVersion\msvc2022_64"
    if (-not (Test-Path (Join-Path $qt "lib\cmake\Qt6"))) {
        if (-not (Has "aqt")) {
            Run winget install --source winget --exact --id miurahr.aqtinstall --accept-package-agreements --accept-source-agreements
            $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
        }
        Write-Host "  Qt $QtVersion を $QtRoot に入れます (数分かかります)..." -ForegroundColor Yellow
        Run aqt install-qt windows desktop $QtVersion win64_msvc2022_64 -m qtimageformats qtnetworkauth -O $QtRoot
    }
    Ok $qt

    # ------------------------------------------------------------------
    Step "5/7 vcpkg (依存ライブラリの管理)"
    if (-not ($env:VCPKG_ROOT -and (Test-Path (Join-Path $env:VCPKG_ROOT "scripts\buildsystems\vcpkg.cmake")))) {
        $env:VCPKG_ROOT = Join-Path $root "vcpkg"
        if (-not (Test-Path (Join-Path $env:VCPKG_ROOT ".git"))) {
            Write-Host "  vcpkg を取得します..." -ForegroundColor Yellow
            Run git clone https://github.com/microsoft/vcpkg.git $env:VCPKG_ROOT
        }
        if (-not (Test-Path (Join-Path $env:VCPKG_ROOT "vcpkg.exe"))) {
            Run (Join-Path $env:VCPKG_ROOT "bootstrap-vcpkg.bat") -disableMetrics
        }
    }
    Ok $env:VCPKG_ROOT

    # ------------------------------------------------------------------
    Step "6/7 パッチ済みのソース"
    $src = Join-Path $root "PrismLauncher"
    # patches フォルダの中身が前回当てたものと違えば、当て直す (新しいパッチが届いたとき用)
    $patchFiles = @(Get-ChildItem (Join-Path $root "patches") -Filter *.patch | Sort-Object Name)
    $patchHash = ((@(Join-Path $root "PRISM_VERSION") + $patchFiles.FullName | ForEach-Object { (Get-FileHash $_ -Algorithm SHA256).Hash }) -join ",")
    $stamp = Join-Path $src ".git\cleanroom-patches.sha256"
    if (-not (Test-Path (Join-Path $src ".git"))) {
        & (Join-Path $root "apply.ps1") -Destination $src
        Set-Content -Path $stamp -Value $patchHash
    } elseif (-not (Test-Path $stamp) -or (Get-Content $stamp -Raw).Trim() -ne $patchHash) {
        Write-Host "  パッチが更新されているので当て直します..." -ForegroundColor Yellow
        & (Join-Path $root "apply.ps1") -Destination $src -Force
        Set-Content -Path $stamp -Value $patchHash
    }
    Ok "$src (パッチ $($patchFiles.Count) 個)"

    # ------------------------------------------------------------------
    Step "7/7 ビルド ($Config)  初回は依存ライブラリのビルドで 30 分以上かかることがあります"
    Push-Location $src
    try {
        Run cmake --preset windows_msvc -D "CMAKE_PREFIX_PATH=$qt"
        Run cmake --build --preset windows_msvc --config $Config
        # 本体・Qt の DLL・jar などを install フォルダにまとめ、portable.txt でポータブル版にする
        Run cmake --install build --config $Config
        Run cmake --install build --config $Config --component portable
    } finally {
        Pop-Location
    }

    $exe = Join-Path $src "install\prismlauncher.exe"
    Write-Host ""
    Write-Host "完了しました: $exe" -ForegroundColor Green
    if (Test-Path $exe) { Start-Process explorer.exe "/select,`"$exe`"" }
} catch {
    Write-Host ""
    Write-Host "エラー: $_" -ForegroundColor Red
    Write-Host "build-log.txt に記録があります。Claude に「ログ見て」と伝えてください。" -ForegroundColor Red
    $failed = $true
} finally {
    Stop-Transcript | Out-Null
}
if ($failed) { exit 1 }
