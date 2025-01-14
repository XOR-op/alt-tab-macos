# AltTab for AeroSpace

This project is a fork of the original AltTab, a fascinating work of task switcher on macOS.
This fork uses AeroSpace's spaces to replace the vanilla macOS space for AltTab.

This fork includes the following changes:
- Use AeroSpace's implementation for multispace functionality in AltTab
- Change the spaceId in AltTab to reflect what shown in AeroSpace

If you don't like my personal modification, you can use `git reset` or similar commands to revert that single commit.

Older version is available in other branches.

## How to Install

You need to build your own binary to bypass the macOS codesign requirement.

1. Make sure XCode is installed correctly.
2. Run `scripts/codesign/setup_local.sh` to generate a local-signed certificates.
3. Run `scripts/generate_local_xcconfig_from_branch.sh` to generate `config/local.xcconfig` from the current git branch name. If `APPCENTER_SECRET` is set in the environment, it will be included; otherwise AppCenter stays disabled for local builds.
4. Run `xcodebuild -project alt-tab-macos.xcodeproj -scheme Debug -derivedDataPath DerivedData` to build the binary. The path of the output application will be printed in the log.
5. Move the application to `/Applications` to finish the installation.

Note that I have enable the compiler optimization for debug build, so the performance won't be hurt.

## Original Contents Below

<div align="center">

<a href="https://alt-tab.app/"><img src="docs/readme/main.svg" alt="AltTab Pro — 7.4M downloads — 15K GitHub stars — Get AltTab"/></a>

<a href="https://jb.gg/OpenSource"><img src="docs/readme/sponsor.svg" alt="Sponsored by JetBrains" width="900"/></a>

</div>
