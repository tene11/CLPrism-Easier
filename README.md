# CLPrism Easier

[Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) の「Mod ローダーのインストール」画面で、
[Cleanroom](https://github.com/CleanroomMC/Cleanroom)（Minecraft 1.12.2 向けの Forge 後継ローダー）を
選んでインストールできるようにした非公式版です。

> [!IMPORTANT]
> これは **Prism Launcher 公式とも CleanroomMC とも無関係の非公式版** です。
> 不具合は本家ではなく、このリポジトリの [Issues](../../issues) に報告してください。

## できること

- ローダー画面に「Cleanroom」タブが増え、Cleanroom の GitHub Releases にあるバージョンから選んでインストールできる
- 普通の Forge が入っているインスタンスでは、置き換える前に確認する
- Cleanroom と衝突する別の LWJGL 3 が残っていたら外す（混ざると起動時にクラッシュするため）
- インストール後、Cleanroom が必要とする Java（25）が使われるよう、自動の Java 選択をやり直す
- Version 画面の「バージョン変更」で Cleanroom のバージョンを選び直せる（同じバージョンの入れ直しで修復も可能）
- Version 画面の Revert で通常の Forge に戻り、Remove で Cleanroom 関連をまとめて削除できる

Fabric や LiteLoader など、ほかのローダーとの衝突チェックには対応していません。

## 対応環境

| OS | 対応 |
|---|---|
| Windows（x64） | 対応（ポータブル版 zip） |
| Linux / Steam Deck | 対応予定 |
| macOS | **非対応**（動作確認できる環境がないため） |

| 項目 | バージョン |
|---|---|
| ベースの Prism Launcher | `PRISM_VERSION` に記載（現在 11.1.1） |
| Cleanroom | GitHub Releases にある MMC インスタンス zip（`cleanroom-<version>.zip`）付きのリリース |

## インストール（Windows）

1. [Releases](../../releases) から、いちばん新しい `PrismLauncher-<バージョン>-Cleanroom-Windows-x64-….zip` をダウンロードする
2. 空のフォルダに展開して `prismlauncher.exe` を起動する

今使っているポータブル版 Prism のフォルダに上書きで展開すると、インスタンスやアカウントをそのまま引き継げます。
念のため、上書きする前にフォルダごとバックアップを取っておくことをおすすめします。

### 注意

- Cleanroom 本体は同梱していません。インストール時に Cleanroom の GitHub Releases から直接ダウンロードします
- Prism 内の更新機能で本家の新しいバージョンに更新すると、Cleanroom の機能がなくなる場合があります。更新はこのリポジトリの Releases から行ってください
- 本家 Prism Launcher の新しいバージョンが出ても、パッチの修正が必要な場合は対応が遅れることがあります

## 自分でビルドする

このリポジトリには Prism Launcher 本体のソースは含まれず、`patches/` に差分だけを置いています。

Windows では `build.bat` をダブルクリックすると、必要なツール（Visual Studio Build Tools、Java、Qt、vcpkg）の準備から
ビルドまでを行い、結果が `PrismLauncher\install` にできます。

手動で行う場合:

```powershell
# 1. 本家を取得してパッチを当てる（PrismLauncher フォルダができます）
.\apply.ps1

# 2. 「x64 Native Tools Command Prompt for VS 2022」でビルドする
cd PrismLauncher
cmake --preset windows_msvc -D CMAKE_PREFIX_PATH="C:\Qt\6.10.2\msvc2022_64"
cmake --build --preset windows_msvc --config Release
cmake --install build --config Release
cmake --install build --config Release --component portable
```

パッチの中身は [docs/コードの解説.md](docs/コードの解説.md) で解説しています。
開発中の変更は `dev` ブランチにあります。

## ファイル構成

| パス | 内容 |
|---|---|
| `patches/` | Prism Launcher への変更（`git format-patch` 形式） |
| `PRISM_VERSION` | パッチの対象になる Prism Launcher のタグ |
| `build.bat` / `build.ps1` | 必要なツールの準備から手元でのビルドまでを一括で行う |
| `apply.ps1` | 本家の取得とパッチ適用 |
| `.github/workflows/` | Windows 版のビルドと Release 作成、本家の新バージョンへの追従 |
| `docs/` | コードの解説 |

## ライセンス

Prism Launcher と同じ GPL-3.0 です（[LICENSE](LICENSE)）。

Cleanroom は CleanroomMC のソフトウェアで、Cleanroom 本体はこのリポジトリや Releases には含まれていません。

Prism の README にあるとおり、`CMakeLists.txt` に含まれる API キーを外さずにビルドした場合は、
それぞれの利用規約に同意したことになります。自分でビルドしたものを配布する場合は注意してください。
