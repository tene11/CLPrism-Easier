# CLPrism Easier

> [!IMPORTANT]
> これは [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) の**非公式**改造版です。
> Prism Launcher 公式とも CleanroomMC とも関係ありません。この版で起きた問題は本家ではなく、このリポジトリの Issues に報告してください。

Prism Launcher の「Mod ローダーのインストール」画面で、
[Cleanroom](https://github.com/CleanroomMC/Cleanroom)（Minecraft 1.12.2 向けの Forge 後継ローダー）を
選べるようにした Prism Launcher のフォークです。

## 概要

- ローダー画面に「Cleanroom」タブが増え、Cleanroom の GitHub Releases にあるバージョンから選んでインストールできます。
- インスタンスの新規作成画面（「カスタム」）でも、Mod ローダーに Cleanroom を選んで、最初から Cleanroom 入りのインスタンスを作れます。
- Version 画面から、Cleanroom のバージョン変更・入れ直し（修復）ができます。
- 本家からの変更は Cleanroom 関連の部分だけなので、本家 Prism Launcher のインスタンスや設定をそのまま使えます。
- 変更内容はパッチとして公開しています。今のところ、このリポジトリをフォークして GitHub Actions でビルドする方法をおすすめしています（[インストール方法](#インストール方法windows)）。

### 対応予定の機能

- 1.12.2 のライブラリ mod を、非公式の推奨版に置き換える機能
- MixinBooter への依存を要求しないようにする機能

Fabric や LiteLoader など、ほかのローダーとの衝突チェックには対応していません。

## 対応状況

| OS | 状況 |
|---|---|
| Windows (x64) | 対応。フォーク＋GitHub Actions で自分でビルドする方法を推奨（ビルド済み版は準備中） |
| Linux | 準備中 |
| macOS | **非対応**（macOS の環境がないため、対応する予定はありません） |

| 項目 | バージョン |
|---|---|
| Prism Launcher | [`PRISM_VERSION`](PRISM_VERSION) に記載 |
| Cleanroom | GitHub Releases に MMC インスタンス zip（`cleanroom-<version>.zip`）が付いているリリース |

## インストール方法（Windows）

### おすすめ：フォークして GitHub Actions でビルドする

ビルド済み版を配布するには、Microsoft ログイン用のクライアント ID と CurseForge の API キーを自分で用意する必要があり、現在申請中です（[API キーについて](#api-キーについて)）。
それまでは、各自のフォークでビルドする方法をおすすめします。作者自身もこの方法で使っています。

必要なもの：GitHub アカウント（無料）。PC にビルド環境を入れる必要はありません。

1. このリポジトリのページ右上の **Fork** を押し、**Create fork** でフォークを作る
2. フォークしたリポジトリの **Actions** タブを開き、**I understand my workflows, go ahead and enable them** を押す
   （フォーク直後は Actions が無効になっています）
3. 左の一覧から **Build for Windows** を選び、**Run workflow** → ブランチは `main` のまま → **Run workflow** を押す
4. ビルドが終わるまで待つ（時間がかかります。目安は数十分〜1時間以上）
5. 終わった実行を開き、ページ下部の **Artifacts** から `PrismLauncher-Cleanroom-Windows-x64` をダウンロードする
   （zip の中に、さらにポータブル版の zip が入っています）
6. 中の zip を空のフォルダに展開して、`prismlauncher.exe` を起動する

- Artifacts の保存期間は **30 日**です。期限が切れたら、もう一度 Run workflow してください。
- 新しいバージョンに更新するときは、フォークのページで **Sync fork** → **Update branch** を押してから、もう一度 Run workflow します。
- フォークでは Releases の作成や、本家の更新確認（Follow Prism Launcher releases）は動きません。
- **自分でビルドしたものを、他の人に配布しないでください**（理由は [API キーについて](#api-キーについて)）。

本家 Prism のインスタンスを使いたい場合は、本家のデータフォルダ（`instances` など）をコピーしてください。
上書きする前に、データをバックアップしておくことをおすすめします。
<!-- TODO: 本家のアップデーターで上書きされないようにする対応ができたら、ここに書く -->

### ビルド済み版（準備中）

自前のクライアント ID と API キーが用意できたら、このリポジトリの **Releases** でビルド済みのポータブル版を配布する予定です。

## 自分でパッチを当てる場合

`patches/` に、Prism Launcher 本体への変更が `git format-patch` 形式で入っています。
Prism Launcher 本体のソースはこのリポジトリには入っていません。

```sh
git clone https://github.com/PrismLauncher/PrismLauncher.git
cd PrismLauncher
git checkout <PRISM_VERSION に書かれたタグ>
git am /path/to/patches/*.patch
```

パッチを当てたあとのビルド方法は、本家の [ビルド手順](https://prismlauncher.org/wiki/development/build-instructions/) と同じです。
Windows では、同梱の `build.bat` を使うと、必要なツールの準備からビルドまでをまとめて行えます。

開発者向けの情報は [docs/開発の手順.md](docs/開発の手順.md) と [docs/コードの解説.md](docs/コードの解説.md) にあります。

## 本家の更新への追従について

Prism Launcher の新しいバージョンが出たら、パッチが当たるかを毎日自動で確認しています。
パッチがそのまま当たらない場合は手で修正するため、対応が遅れることがあります。

## API キーについて

本家 Prism Launcher の `CMakeLists.txt` には、Microsoft ログイン用のクライアント ID や CurseForge の API キーが入っています。
このリポジトリのパッチは、これらのキーを変更しません。そのため、自分でビルドした場合は本家のキーがそのまま使われます。

本家の [README](https://github.com/PrismLauncher/PrismLauncher#forkingredistributingcustom-builds-policy) にあるとおり、キーを外さずにビルドした場合は、次の規約に同意したことになります。

- [Microsoft Identity Platform Terms of Use](https://docs.microsoft.com/en-us/legal/microsoft-identity-platform/terms-of-use)
- [CurseForge 3rd Party API Terms and Conditions](https://support.curseforge.com/en/support/solutions/articles/9000207405-curse-forge-3rd-party-api-terms-and-conditions)

同意できない場合は、`CMakeLists.txt` の該当するキーを空文字（`""`）にしてからビルドしてください（Microsoft ログインや CurseForge 連携は使えなくなります）。

また、本家はフォークやカスタムビルドを配布する場合、キーを自分のものに替えるか空にするよう求めています。
本家のキーが入ったままのビルドを、他の人に配布しないでください。

## ライセンス

Prism Launcher と同じ GPL-3.0 です（[LICENSE](LICENSE)）。

Cleanroom 本体はこのリポジトリにも Releases にも含まれていません。インストール時に Cleanroom の GitHub Releases から直接ダウンロードします。

ローダー画面で使っている Cleanroom のロゴは、Cleanroom の LGPL-2.1 の部分（`module/forge/`）にあるものを縮小して使っています。
詳しくは [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) と [licenses/LGPL-2.1.txt](licenses/LGPL-2.1.txt) を見てください。
ビルドした zip にも同じファイルが入ります。

## クレジット

- [Prism Launcher](https://prismlauncher.org/) — このフォークの元になったLauncher
- [CleanroomMC](https://cleanroommc.com/) — Cleanroom ローダー、およびローダー画面で使っている Cleanroom のロゴ（LGPL-2.1、[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)）

<!-- TODO: 本家 README のフォーク向けの注意（名前・ロゴ）を確認する。ビルド済み版を出すときは、差し替えたキーをここに書く -->
