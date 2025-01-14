# AltTab for AeroSpace

This project is a fork of the original AltTab, a fascinating work of task switcher on macOS. 
This fork uses AeroSpace's spaces to replace the vanilla macOS space for AltTab.

This fork includes the following changes:
- Use AeroSpace's implementation for multispace functionality in AltTab
- Change the spaceId in AltTab to reflect what shown in AeroSpace
- Limit the number displayed recently-used windows to 8 for my personal use

If you don't like my personal modification, you can use `git reset` or similar commands to revert that single commit.

## How to Install

You need to build your own binary to bypass the macOS codesign requirement.

1. Make sure XCode is installed correctly.
2. Run `scripts/codesign/setup_local.sh` to generate a local-signed certificates.
3. Run `xcodebuild -workspace alt-tab-macos.xcworkspace -scheme Debug` to build the binary. The path of the output application will be printed in the log.
4. Move the application to `/Applications` to finish the installation.

Note that I have enable the compiler optimization for debug build, so the performance won't be hurt.

## Original Contents Below

[![Screenshot](docs/public/demo/frontpage.jpg)](docs/public/demo/frontpage.jpg)

**AltTab** brings the power of Windows alt-tab to macOS

[Find out more on the official website](https://alt-tab-macos.netlify.app/)
