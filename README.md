# Android SDK & JDK Setup for Unreal Engine

> **TL;DR:** An unofficial Windows batch script that automates the setup of Android SDK, NDK, and JDK components needed for Android development with Unreal Engine. I created it because, in my experience, Unreal Engine's built-in **Turnkey** setup did not successfully complete the required Android environment setup on my system.

**Not affiliated with or endorsed by Epic Games, Unreal Engine, Google, Oracle, or other third parties.**

## Usage

1. Download or clone this repository.
2. Run the batch file from Windows.
3. Follow the instructions displayed by the script.
4. Allow the script to install/configure the required Android development components.
5. Done! Open Unreal Engine and verify the Android SDK settings.


> **Tip:** If you are running the script from a fresh Unreal Engine installation, you may want to run it before attempting Unreal Engine's Android/Turnkey setup.

**Important:** Administrator privileges may be required for some installation steps. Always review a `.bat` file before running it with administrator privileges.

<br>

<br>

<br>

## Why this exists

I created this script because, in my experience, Unreal Engine's built-in **Turnkey** Android setup did not successfully complete the required Android SDK/JDK installation on my system.

Instead of manually installing and configuring each component, this script provides a simple, repeatable setup process using the standard Android and Java development tools.

The goal is to make setting up a fresh Unreal Engine Android development environment easier, particularly when the built-in setup process does not work as expected.

## What it does

Depending on the version of the script, it may install or configure components such as:
* Android Studio as required by Turnkey
* Android SDK Command-Line Tools
* Android SDK Platform Tools
* Android SDK Build Tools
* Android SDK Platforms
* Android NDK
* Java Development Kit (JDK)
* Environment/configuration settings required for Android development

The exact versions installed are determined by the script and may change as Unreal Engine's Android requirements change.

## Requirements

* Windows
* Internet connection
* Sufficient disk space for the Android development tools
* Administrator privileges may be required for some installation steps
* Unreal Engine installed or intended to be used for Android development

## Important: Unreal Engine / Epic Games

This project is **not affiliated with, sponsored by, endorsed by, or officially associated with Epic Games or Unreal Engine**.

"Unreal Engine", "Unreal", "Epic Games", and related trademarks are the property of their respective owners.

This project merely provides a community-created setup utility intended for use with Unreal Engine.

## Third-Party Software

This script may download, install, or configure software and components provided by third parties, including but not limited to:

* Android SDK components
* Android NDK
* Android SDK Command-Line Tools
* Java/JDK components
* Other tools required by the Android development environment

These components are **not part of this project and are not licensed under this project's MIT License**.

Each third-party component remains subject to its own license terms and conditions. Users are responsible for reviewing and complying with the applicable licenses and terms of the software they install.

This project does not redistribute proprietary third-party software unless explicitly stated.

## Disclaimer

This software is provided **"as is"**, without warranty of any kind, express or implied.

The author makes no guarantees that the script will work with every version of Windows, Unreal Engine, Android SDK, Android NDK, JDK, or other third-party software.

The Android development ecosystem and Unreal Engine requirements may change over time. A version of this script that works today may require modification for future versions.

Use this script at your own risk.

The author is not responsible for:

* Damage to your operating system or development environment
* Incorrect configuration of environment variables
* Loss of files or data
* Installation of incompatible software versions
* Changes made to your system by third-party installers
* Problems resulting from using the script with unsupported software versions
* Any costs, licensing obligations, or third-party software terms associated with installed components

## No Affiliation

This project is an independent community project.

It is not affiliated with or endorsed by:

* Epic Games
* Unreal Engine
* Google
* Android
* Oracle
* OpenJDK
* Microsoft

Any references to third-party products or trademarks are for identification and compatibility purposes only.

## License

Copyright (c) 2026 Syazani Suhaifi

This project is licensed under the **MIT License**.

See the [`LICENSE`](LICENSE) file for the full license text.

The MIT License applies only to the original code and documentation contained in this repository. It does **not** grant any rights to third-party software, trademarks, SDKs, JDKs, Unreal Engine, Android, or other third-party materials.

## Contributions

Issues and improvements are welcome.

Before submitting a pull request, please ensure that contributed code does not include proprietary third-party software or material that you do not have permission to distribute.
