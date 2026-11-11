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
- 変更内容はパッチとしても公開しています。自分でパッチを当ててビルドすることもできますが、Qt などのビルド環境が必要なので、通常はビルド済み版をおすすめします。

### 対応予定の機能

- 1.12.2 のライブラリ mod を、非公式の推奨版に置き換える機能
- MixinBooter への依存を要求しないようにする機能

Fabric や LiteLoader など、ほかのローダーとの衝突チェックには対応していません。

## 対応状況

| OS | 状況 |
|---|---|
| Windows (x64) | 対応。ビルド済みのポータブル版を Releases で配布 |
| Linux | 準備中 |
| macOS | **非対応**（macOS の環境がないため、対応する予定はありません） |

| 項目 | バージョン |
|---|---|
| Prism Launcher | [`PRISM_VERSION`](PRISM_VERSION) に記載 |
| Cleanroom | GitHub Releases に MMC インスタンス zip（`cleanroom-<version>.zip`）が付いているリリース |

## インストール方法（Windows）

1. このリポジトリの **Releases** から、いちばん新しい zip をダウンロードする
2. 空のフォルダに展開して、`prismlauncher.exe` を起動する

本家 Prism のインスタンスを使いたい場合は、本家のデータフォルダ（`instances` など）をコピーしてください。
上書きする前に、データをバックアップしておくことをおすすめします。
<!-- TODO: 本家のアップデーターで上書きされないようにする対応ができたら、ここに書く -->

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

## ライセンス

Prism Launcher と同じ GPL-3.0 です（[LICENSE](LICENSE)）。

Cleanroom 本体はこのリポジトリにも Releases にも含まれていません。インストール時に Cleanroom の GitHub Releases から直接ダウンロードします。

## クレジット

- [Prism Launcher](https://prismlauncher.org/) — このフォークの元になったLauncher
- [CleanroomMC](https://cleanroommc.com/) — Cleanroom ローダー、およびローダー画面で使っている Cleanroom のロゴ

<!-- TODO: 本家 README のフォーク向けの注意（名前・ロゴ、API キー、Microsoft ログイン用のクライアント ID）を確認して、
     ビルド済み版で何を差し替えたかをここに書く -->
