# Windows PHP Helper

Installs and switches PHP versions on Windows. It supports PHP 8.2, 8.3, 8.4, and 8.5.

Each version is installed in a separate directory. The active version is exposed through the stable `modules\php`
junction, so applications only need one PHP path.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7
- HTTPS access to `downloads.php.net`, `xdebug.org`, and `curl.se`
- Write access to the `modules` directory next to this repository

If Windows blocks local scripts, allow signed remote scripts for the current user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

A machine or group policy can override this setting.

## Directory structure

```text
your-folder/
├── windows-php/
│   ├── bin/                 Convenience entrypoints by PHP version
│   ├── extensions/          Bundled Redis, Imagick, and rdkafka builds
│   ├── tests/
│   └── windows-php.ps1      Main script
└── modules/
    ├── php82/
    ├── php83/
    ├── php84/
    ├── php85/
    └── php -> phpXX         Active directory junction
```

Add `your-folder\modules\php` to the user `PATH` once:

```powershell
$phpPath = 'C:\dev\modules\php'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$userPath;$phpPath", 'User')
```

Replace `C:\dev` with the actual parent directory. Open a new terminal after changing `PATH`.

## Usage

Activate a version. It is installed first when missing:

```powershell
.\windows-php.ps1 8.5
```

Download the latest patch release, replace the selected installation, and activate it:

```powershell
.\windows-php.ps1 8.5 -Update
```

The version-specific entrypoints provide the same commands:

```powershell
.\bin\8.5\activate.ps1
.\bin\8.5\update.ps1
```

Commands can be started from any current directory. An update is prepared and validated before the existing installation
is replaced. A failed download or validation leaves the existing version unchanged. Treat each `phpXX` directory as
disposable:
an update replaces its `php.ini` and any files added manually. Xdebug output is kept separately in
`modules\xdebug\profiler`.

PHP is installed as NTS x64. The configuration enables the bundled PHP extensions plus Redis, Imagick, rdkafka, Xdebug,
and OPcache. Xdebug is disabled by default and listens on `127.0.0.1:9003` when enabled.

## Verification

Run the smoke test in both shells when changing the scripts:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\smoke.ps1
pwsh.exe -NoProfile -File .\tests\smoke.ps1
```

## Updating this project

```powershell
git pull
```
