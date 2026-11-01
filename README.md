# prism-cleanroom

[Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) の「Mod ローダーのインストール」画面で
[Cleanroom](https://github.com/CleanroomMC/Cleanroom)（Minecraft 1.12.2 向けの Forge 後継ローダー）を
選べるようにするパッチ集です。

Prism Launcher 本体のソースは含まず、`patches/` にある差分だけを置いています。
Cleanroom のバージョン一覧は Prism の meta サーバーではなく、Cleanroom の GitHub Releases から取得します。

## 対応バージョン

| 項目 | バージョン |
|---|---|
| Prism Launcher | `PRISM_VERSION` に記載（現在 11.1.1） |
| Cleanroom | GitHub Releases にある MMC インスタンス zip（`cleanroom-<version>.zip`）付きのリリース |

## 進捗

- [x] 第1段階: ローダー画面に「Cleanroom」タブを追加し、GitHub Releases からバージョン一覧を表示する
- [x] 第2段階: 選んだバージョンの zip をダウンロードして、インスタンスに組み込む
- [x] 第3段階: Cleanroom の Revert（通常の Forge に戻す）と Remove（LWJGL 3 と空 jar もまとめて削除）

ほかのローダー（Fabric、LiteLoader など）との衝突チェックは対応していません。


## 使い方（Windows）

必要なもの: Git、Visual Studio 2022 Build Tools、Qt 6（ビルド手順は
[Prism 公式のビルド手順](https://prismlauncher.org/wiki/development/build-instructions/) を参照）

```powershell
# 1. 本家を取得してパッチを当てる（PrismLauncher フォルダができます）
.\apply.ps1

# 2. 「x64 Native Tools PowerShell for VS 2022」でビルドする
cd PrismLauncher
cmake --preset windows_msvc -D CMAKE_PREFIX_PATH="C:\Qt\6.10.2\msvc2022_64"
cmake --build --preset windows_msvc --config Release
cmake --install build --config Release
cmake --install build --config Release --component portable
```

`apply.ps1` は既に `PrismLauncher` フォルダがあれば clone をスキップします。
作業用ブランチ `cleanroom` を作り直したいときは `.\apply.ps1 -Force` を使います（そのブランチの変更は消えます）。

## パッチを更新するとき

`PrismLauncher` フォルダの `cleanroom` ブランチで変更をコミットしてから、次を実行します。

```powershell
.\update-patches.ps1
```

`PRISM_VERSION` のタグから HEAD までのコミットが、1 コミット = 1 ファイルで `patches/` に書き出されます。

## GitHub に公開・更新するとき

`publish.bat` をダブルクリックします。初回は GitHub へのログイン（ブラウザ）のあと、非公開リポジトリ `prism-cleanroom` を作って公開します。
2 回目以降は、変更をコミットして push するだけです。コミットには GitHub の noreply アドレスが使われます。

## ファイル構成

| パス | 内容 |
|---|---|
| `patches/` | Prism Launcher への変更（`git format-patch` 形式） |
| `PRISM_VERSION` | パッチの対象になる Prism Launcher のタグ |
| `apply.ps1` | 本家の取得とパッチ適用 |
| `update-patches.ps1` | 作業ブランチからパッチを書き出し直す |
| `build.bat` / `build.ps1` | 必要なツールの準備からビルドまでを一括で行う |
| `publish.bat` / `publish.ps1` | このフォルダを GitHub の非公開リポジトリに公開・更新する |
| `.gitattributes` | パッチの改行コードが Windows で変換されないようにする設定 |

## ライセンス

Prism Launcher と同じ GPL-3.0 です（[LICENSE](LICENSE)）。
これは Prism Launcher 公式とは無関係の非公式パッチです。
Prism の README にあるとおり、`CMakeLists.txt` に含まれる API キーを外さずにビルドした場合は、
それぞれの利用規約に同意したことになります。ビルド済みのファイルを配布する場合は注意してください。
