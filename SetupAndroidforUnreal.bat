@echo off
setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION

rem ============================================================
rem  UE 5.8 Android setup
rem
rem  UE's Turnkey still requires Android Studio itself to be
rem  present, and at the exact version its Turnkey config pins - so this
rem  script downloads and installs that specific version silently first
rem  (never launched), then does everything else entirely from the
rem  command line:
rem   - Android CLI (Google's standalone "android" tool, a separate
rem     download from developer.android.com/tools/agents - it is
rem     NOT part of the cmdline-tools bundle)
rem   - Android SDK platforms/build-tools/cmake/NDK via the Android CLI
rem   - OpenJDK 21 (Eclipse Temurin)
rem  and points ANDROID_HOME / NDKROOT / NDK_ROOT / JAVA_HOME at them.
rem
rem  Arguments (all optional, same order as Epic's SetupAndroid.bat):
rem    SetupAndroid.bat [platform] [build-tools] [cmake] [ndk] [-noninteractive]
rem ============================================================

rem ---- custom locations ----------------------------------------------
set "SDK_DIR=%USERPROFILE%\Prerequisite\sdk"
set "NDK_DIR=%USERPROFILE%\Prerequisite\ndk"
set "JDK_DIR=%USERPROFILE%\Prerequisite\jdk"
rem --------------------------------------------------------------------

IF "%5" == "-noninteractive" (
	set PAUSE=
) ELSE (
	set PAUSE=pause
)

rem ---- ensure Android Studio itself is installed ----------------------
rem Unreal's Turnkey checks the HKLM\SOFTWARE\Android Studio registry key
rem AND expects this specific version, per UE 5.8's Turnkey config. This
rem downloads and installs it silently - it is never launched.
rem Update this pair if a future UE version pins a different release.
set "STUDIO_VERSION=2024.1.2.13"
set "STUDIO_INSTALLER_URL=https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.2.13/android-studio-2024.1.2.13-windows.exe"

set "STUDIO_KEY=HKLM\SOFTWARE\Android Studio"
set "STUDIO_PATH="
FOR /F "tokens=2*" %%A IN ('REG.exe query "%STUDIO_KEY%" /v "Path" 2^>nul') DO (set "STUDIO_PATH=%%B")

if defined STUDIO_PATH goto studio_ready

echo Android Studio %STUDIO_VERSION% was not found. Unreal's Turnkey requires
echo this exact version, even though this script manages the SDK/NDK/JDK itself.
echo.

net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
	echo This step needs to run elevated to install Android Studio.
	echo Right-click this script and choose "Run as administrator", then rerun it.
	%PAUSE%
	exit /b 7
)

where.exe /Q curl.exe
IF /I "%ERRORLEVEL%" NEQ "0" (
	echo curl.exe was not found. It ships with Windows 10 ^(1803+^) and Windows 11.
	echo Download this installer manually and run it with /S:
	echo   %STUDIO_INSTALLER_URL%
	%PAUSE%
	exit /b 7
)

set "STUDIO_INSTALLER=%TEMP%\android-studio-%STUDIO_VERSION%-windows.exe"
if exist "%STUDIO_INSTALLER%" goto studio_install

echo Downloading Android Studio %STUDIO_VERSION%...
curl.exe -fsSL "%STUDIO_INSTALLER_URL%" -o "%STUDIO_INSTALLER%"
if not exist "%STUDIO_INSTALLER%" (
	echo Download failed. Check your network settings, or download it manually from:
	echo   %STUDIO_INSTALLER_URL%
	%PAUSE%
	exit /b 7
)

for %%S in ("%STUDIO_INSTALLER%") do if %%~zS LSS 100000000 (
	echo Downloaded file looks too small to be the real installer ^(%%~zS bytes^).
	echo This usually means the download failed or was blocked.
	del /q "%STUDIO_INSTALLER%"
	%PAUSE%
	exit /b 7
)

:studio_install
echo Installing Android Studio %STUDIO_VERSION% silently ^(this can take a while^)...
"%STUDIO_INSTALLER%" /S
echo.

set "STUDIO_PATH="
FOR /F "tokens=2*" %%A IN ('REG.exe query "%STUDIO_KEY%" /v "Path" 2^>nul') DO (set "STUDIO_PATH=%%B")

if not defined STUDIO_PATH goto studio_failed
goto studio_ready

:studio_failed
echo Android Studio %STUDIO_VERSION% install could not be verified.
echo Please check that Android Studio was installed correctly, or install it manually from:
echo   %STUDIO_INSTALLER_URL%
echo and rerun this script.
%PAUSE%
exit /b 7

:studio_ready
echo Android Studio %STUDIO_VERSION% found at: %STUDIO_PATH%
echo ^(it will not be launched - SDK/NDK/JDK are still handled below.^)
echo.

rem ---- Android CLI direct download (separate product from cmdline-tools) --
rem Source: https://developer.android.com/tools/agents/android-cli/download
set "ANDROID_CLI_URL=https://dl.google.com/android/cli/latest/windows_x86_64/android.exe"
rem --------------------------------------------------------------------

SET PLATFORMS_VERSION=%1
SET BUILDTOOLS_VERSION=%2
SET CMAKE_VERSION=%3
SET NDK_VERSION=%4

rem hardcoded versions for compatibility with non-Turnkey manual running
if "%PLATFORMS_VERSION%" == "" SET PLATFORMS_VERSION=android-36
if "%BUILDTOOLS_VERSION%" == "" SET BUILDTOOLS_VERSION=36.1.0
if "%CMAKE_VERSION%" == "" SET CMAKE_VERSION=3.22.1
if "%NDK_VERSION%" == "" SET NDK_VERSION=27.2.12479018

echo.
echo Install target SDK: %SDK_DIR%
echo Install target NDK: %NDK_DIR%\%NDK_VERSION%
echo Install target JDK: %JDK_DIR%
echo.

set "NDKINSTALLPATH=%NDK_DIR%\%NDK_VERSION%"
set "PLATFORMTOOLS=%SDK_DIR%\platform-tools"
set "ANDROID_CLI_DIR=%SDK_DIR%\cli"
set "ANDROID_CLI=%ANDROID_CLI_DIR%\android.exe"

if not exist "%SDK_DIR%" mkdir "%SDK_DIR%"
if not exist "%SDK_DIR%\licenses" mkdir "%SDK_DIR%\licenses"
if not exist "%NDK_DIR%" mkdir "%NDK_DIR%"
if not exist "%ANDROID_CLI_DIR%" mkdir "%ANDROID_CLI_DIR%"

rem ---- download the Android CLI (android.exe) if not already there ----
if exist "%ANDROID_CLI%" goto cli_ready

where.exe /Q curl.exe
IF /I "%ERRORLEVEL%" NEQ "0" (
	echo curl.exe was not found. It ships with Windows 10 ^(1803+^) and Windows 11.
	echo Download Android CLI manually from https://developer.android.com/tools/agents/android-cli/download
	echo and place android.exe at: %ANDROID_CLI%
	%PAUSE%
	exit /b 2
)

echo Downloading Android CLI...
curl.exe -fsSL "%ANDROID_CLI_URL%" -o "%ANDROID_CLI%"
if not exist "%ANDROID_CLI%" (
	echo Download failed. Check your network settings, or download it manually from:
	echo   https://developer.android.com/tools/agents/android-cli/download
	%PAUSE%
	exit /b 2
)

rem sanity check: file should be a real, runnable executable, not an error page
for %%S in ("%ANDROID_CLI%") do if %%~zS LSS 1000000 (
	echo Downloaded file looks too small to be the real android.exe ^(%%~zS bytes^).
	echo This usually means the download failed or was blocked. Check %ANDROID_CLI%
	del /q "%ANDROID_CLI%"
	%PAUSE%
	exit /b 2
)

:cli_ready
echo Using Android CLI: %ANDROID_CLI%
echo.

rem ---- Android SDK license ---------------------------------------------
if exist "%SDK_DIR%\licenses\android-sdk-license" goto license_done

if defined PAUSE goto license_ask
echo Android SDK license has not been accepted yet. Run this script without -noninteractive to accept it.
exit /b 6

:license_ask
echo ------------------------------------------------------------
echo  Android SDK License Agreement
echo  Read it at: https://developer.android.com/studio/terms
echo  It covers the SDK, NDK, build-tools and platform-tools.
echo ------------------------------------------------------------
set "ACCEPT="
set /p "ACCEPT=Type Y to accept the license and continue: "
if /i not "%ACCEPT%"=="Y" (
	echo License not accepted, nothing was installed.
	%PAUSE%
	exit /b 6
)

rem record the acceptance the same way sdkmanager/android CLI does
(
echo.
echo 24333f8a63b6825ea9c5514f83c2829b004d1fee
echo 8933bad161af4178b1185d1a37fbf41ea5269c55
echo d56f5187479451eabf01fb78af6dfcb131a6481e
) > "%SDK_DIR%\licenses\android-sdk-license"

:license_done
echo License accepted.
echo.

rem ---- install packages with the Android CLI ---------------------------
call "%ANDROID_CLI%" --sdk="%SDK_DIR%" sdk install platform-tools platforms/%PLATFORMS_VERSION% build-tools/%BUILDTOOLS_VERSION% cmake/%CMAKE_VERSION% ndk/%NDK_VERSION%

IF /I "%ERRORLEVEL%" NEQ "0" (
	echo Android CLI returned error code %ERRORLEVEL%, checking what was actually installed...
)

rem the exit code is not always reliable, so verify the folders instead
set "MISSING="
if not exist "%SDK_DIR%\platform-tools" set "MISSING=!MISSING! platform-tools"
if not exist "%SDK_DIR%\platforms\%PLATFORMS_VERSION%" set "MISSING=!MISSING! platforms/%PLATFORMS_VERSION%"
if not exist "%SDK_DIR%\build-tools\%BUILDTOOLS_VERSION%" set "MISSING=!MISSING! build-tools/%BUILDTOOLS_VERSION%"
if not exist "%SDK_DIR%\cmake\%CMAKE_VERSION%" set "MISSING=!MISSING! cmake/%CMAKE_VERSION%"
if not exist "%SDK_DIR%\ndk\%NDK_VERSION%" set "MISSING=!MISSING! ndk/%NDK_VERSION%"

if defined MISSING (
	echo Update failed. Not found after install:!MISSING!
	echo Check the exact package IDs with:
	echo   "%ANDROID_CLI%" --sdk="%SDK_DIR%" sdk list ndk
	echo   "%ANDROID_CLI%" --sdk="%SDK_DIR%" sdk list cmake
	%PAUSE%
	exit /b 4
)

rem ---- expose the NDK at NDK_DIR (junction, no duplicate copy) ---------
if not exist "%NDKINSTALLPATH%" mklink /J "%NDKINSTALLPATH%" "%SDK_DIR%\ndk\%NDK_VERSION%"

if not exist "%NDKINSTALLPATH%\ndk-build.cmd" (
	echo Update failed. ndk-build.cmd not found in %NDKINSTALLPATH%
	%PAUSE%
	exit /b 5
)

echo Success.

rem ---- environment variables (user level) ------------------------------
set "ANDROID_HOME=%SDK_DIR%"
powershell -command "[Environment]::SetEnvironmentVariable('ANDROID_HOME', '%SDK_DIR%', 'User')"
if defined ANDROID_SDK_HOME (
	set "ANDROID_SDK_HOME="
	powershell -command "[Environment]::SetEnvironmentVariable('ANDROID_SDK_HOME', [NullString]::Value, 'User')"
)

rem ---- download and install OpenJDK 21 (Eclipse Temurin) --------------
set "JDK21_HOME="
if exist "%JDK_DIR%" for /d %%D in ("%JDK_DIR%\jdk-21*") do set "JDK21_HOME=%%D"
if defined JDK21_HOME echo Found existing JDK 21 at !JDK21_HOME!
if defined JDK21_HOME goto jdk_done

echo Downloading OpenJDK 21 ^(Eclipse Temurin^)...
if not exist "%JDK_DIR%" mkdir "%JDK_DIR%"
powershell -command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk' -OutFile '%JDK_DIR%\temurin21.zip'"
if not exist "%JDK_DIR%\temurin21.zip" (
	echo JDK download failed. Check your network settings or download it manually from https://adoptium.net
	goto jdk_done
)
powershell -command "Expand-Archive -Path '%JDK_DIR%\temurin21.zip' -DestinationPath '%JDK_DIR%' -Force"
del /q "%JDK_DIR%\temurin21.zip"
for /d %%D in ("%JDK_DIR%\jdk-21*") do set "JDK21_HOME=%%D"

:jdk_done
if defined JDK21_HOME (
	set "JAVA_HOME=!JDK21_HOME!"
	powershell -command "[Environment]::SetEnvironmentVariable('JAVA_HOME', '!JDK21_HOME!', 'User')"
	echo JAVA_HOME set to !JDK21_HOME!
	if exist "!JDK21_HOME!\bin\java.exe" "!JDK21_HOME!\bin\java.exe" -version
) else (
	echo WARNING: no JDK was installed. Set JAVA_HOME manually before opening Unreal.
)

powershell -command "[Environment]::SetEnvironmentVariable('NDKROOT', '%NDKINSTALLPATH%', 'User')"
powershell -command "[Environment]::SetEnvironmentVariable('NDK_ROOT', '%NDKINSTALLPATH%', 'User')"

set KEY_NAME=HKCU\Environment
set VALUE_NAME=Path
set "USERPATH="

FOR /F "tokens=2*" %%A IN ('REG.exe query "%KEY_NAME%" /v "%VALUE_NAME%"') DO (set "USERPATH=%%B")

where.exe /Q adb.exe
IF /I "%ERRORLEVEL%" NEQ "0" (
	echo Current user path: "!USERPATH!"
	powershell -command "[Environment]::SetEnvironmentVariable('PATH', '!USERPATH!;%PLATFORMTOOLS%', 'User')"
	echo Added %PLATFORMTOOLS% to path
)

echo.
echo ANDROID_HOME = %SDK_DIR%
echo NDKROOT      = %NDKINSTALLPATH%
echo JAVA_HOME    = %JAVA_HOME%
echo.
echo Restart Unreal Editor so the new variables apply.

%PAUSE%
exit /b 0
