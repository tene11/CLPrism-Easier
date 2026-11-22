# CLPrism Easier

**English** | [日本語](README.ja.md)

> [!IMPORTANT]
> This is an **unofficial** modified version of [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher).
> It is not affiliated with Prism Launcher or CleanroomMC. Please report problems with this version to this repository's Issues, not to Prism Launcher.

A fork of Prism Launcher that lets you choose [Cleanroom](https://github.com/CleanroomMC/Cleanroom)
(a Forge-based mod loader for Minecraft 1.12.2) in Prism Launcher's "Install Loader" dialog.

## Features

- Adds a "Cleanroom" tab to the Install Loader dialog, where you can pick and install any version from Cleanroom's GitHub Releases.
- On the New Instance dialog ("Custom"), you can choose Cleanroom as the mod loader and create an instance with Cleanroom from the start.
- From the Version page, you can change the Cleanroom version or reinstall (repair) it.
- Only the Cleanroom-related parts are changed, so your existing Prism Launcher instances and settings work as they are.
- The changes are published as patches. For now, the recommended way to get it is to fork this repository and build it with GitHub Actions (see [Installation](#installation-windows)).

### Planned features

- Replace 1.12.2 library mods with recommended unofficial versions
- Stop requiring MixinBooter as a dependency

Conflict checks with other loaders such as Fabric or LiteLoader are not supported.

## Support

| OS | Status |
|---|---|
| Windows (x64) | Supported. Building it yourself with a fork + GitHub Actions is recommended (prebuilt version coming later) |
| Linux | In preparation |
| macOS | **Not supported** (no macOS environment to test on, and no plans to support it) |

| Item | Version |
|---|---|
| Prism Launcher | See [`PRISM_VERSION`](PRISM_VERSION) |
| Cleanroom | Releases on GitHub that include an MMC instance zip (`cleanroom-<version>.zip`) |

## Installation (Windows)

### Recommended: fork and build with GitHub Actions

Distributing prebuilt versions requires our own Microsoft login client ID and CurseForge API key, which are still being applied for (see [About the API keys](#about-the-api-keys)).
Until then, we recommend building it in your own fork. The author uses it this way too.

What you need: a GitHub account (free). You don't need to install any build tools on your PC.

1. Click **Fork** at the top right of this repository's page, then **Create fork**
2. Open the **Actions** tab of your fork and click **I understand my workflows, go ahead and enable them**
   (Actions are disabled right after forking)
3. Select **Build for Windows** in the list on the left, click **Run workflow**, keep the branch as `main`, and click **Run workflow**
4. Wait for the build to finish (it takes a while — roughly tens of minutes to over an hour)
5. Open the finished run and download `PrismLauncher-Cleanroom-Windows-x64` from **Artifacts** at the bottom of the page
   (the download is a zip that contains the portable zip)
6. Extract the inner zip into an empty folder and run `prismlauncher.exe`

- Artifacts are kept for **30 days**. After they expire, just run the workflow again.
- To update to a new version, click **Sync fork** → **Update branch** on your fork's page, then run the workflow again.
- In a fork, creating Releases and the daily check for new Prism versions (Follow Prism Launcher releases) don't run.
- **Please don't share your build with other people** (see [About the API keys](#about-the-api-keys) for why).

To use your instances from the official Prism Launcher, copy its data folders (such as `instances`).
We recommend backing up your data before overwriting anything.
<!-- TODO: once overwriting by Prism's updater is handled, describe it here -->

### Prebuilt version (coming later)

Once our own client ID and API key are ready, we plan to distribute a prebuilt portable version in this repository's **Releases**.

## Applying the patches yourself

`patches/` contains the changes to Prism Launcher in `git format-patch` format.
The Prism Launcher source code itself is not included in this repository.

```sh
git clone https://github.com/PrismLauncher/PrismLauncher.git
cd PrismLauncher
git checkout <the tag written in PRISM_VERSION>
git am /path/to/patches/*.patch
```

After applying the patches, build it the same way as the official [build instructions](https://prismlauncher.org/wiki/development/build-instructions/).
On Windows, the included `build.bat` sets up the required tools and builds it in one go.

Information for developers is in [docs/開発の手順.md](docs/開発の手順.md) and [docs/コードの解説.md](docs/コードの解説.md) (Japanese only).

## Keeping up with Prism Launcher updates

When a new version of Prism Launcher is released, a daily automated check tests whether the patches still apply.
If they don't apply cleanly, they need to be fixed by hand, so support for the new version may be delayed.

## About the API keys

Prism Launcher's `CMakeLists.txt` contains a Microsoft login client ID and a CurseForge API key.
The patches in this repository don't change these keys, so if you build it yourself, Prism Launcher's keys are used as they are.

As stated in Prism Launcher's [README](https://github.com/PrismLauncher/PrismLauncher#forkingredistributingcustom-builds-policy), building without removing the keys means you accept the following terms:

- [Microsoft Identity Platform Terms of Use](https://docs.microsoft.com/en-us/legal/microsoft-identity-platform/terms-of-use)
- [CurseForge 3rd Party API Terms and Conditions](https://support.curseforge.com/en/support/solutions/articles/9000207405-curse-forge-3rd-party-api-terms-and-conditions)

If you don't agree, set the corresponding keys in `CMakeLists.txt` to empty strings (`""`) before building (Microsoft login or CurseForge integration will then be unavailable).

Prism Launcher also asks that forks and custom builds that are distributed replace the keys with their own or set them to empty.
Please don't distribute builds that still contain Prism Launcher's keys.

## License

GPL-3.0, the same as Prism Launcher ([LICENSE](LICENSE)).

Cleanroom itself is included neither in this repository nor in Releases. It is downloaded directly from Cleanroom's GitHub Releases at install time.

The Cleanroom logo shown in the loader dialog is a resized copy of the one in Cleanroom's LGPL-2.1 part (`module/forge/`).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [licenses/LGPL-2.1.txt](licenses/LGPL-2.1.txt) for details.
The same files are included in the built zip.

## Credits

- [Prism Launcher](https://prismlauncher.org/) — the launcher this fork is based on
- [CleanroomMC](https://cleanroommc.com/) — the Cleanroom loader, and the Cleanroom logo used in the loader dialog (LGPL-2.1, [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md))

<!-- TODO: check Prism Launcher's README notes for forks (name and logo). When releasing prebuilt versions, list the replaced keys here -->
