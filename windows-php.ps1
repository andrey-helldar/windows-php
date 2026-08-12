[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('8.2', '8.3', '8.4', '8.5')]
    [string] $Version,

    [switch] $Update
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:ProjectRoot = $PSScriptRoot
$script:ModulesRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\modules'))
$script:CompilerByVersion = @{
    '8.2' = 'vs16'
    '8.3' = 'vs16'
    '8.4' = 'vs17'
    '8.5' = 'vs17'
}
$script:XdebugVersion = '3.5.3'
$script:StandardExtensions = @(
    'bz2', 'curl', 'ftp', 'fileinfo', 'gd', 'intl', 'imap', 'ldap', 'mbstring', 'odbc', 'openssl',
    'pdo_mysql', 'pdo_pgsql', 'pdo_sqlite', 'pgsql', 'soap', 'sockets', 'sodium', 'sqlite3', 'xsl', 'zip', 'exif'
)
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-ChildByName
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $ParentPath,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (-not (Test-Path -LiteralPath $ParentPath -PathType Container))
    {
        return $null
    }

    Get-ChildItem -LiteralPath $ParentPath -Force |
            Where-Object { [string]::Equals($_.Name, $Name, [System.StringComparison]::OrdinalIgnoreCase) } |
            Select-Object -First 1
}

function Remove-SafeDirectory
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetFullPath($script:ModulesRoot).TrimEnd([char[]]"\/")
    $prefix = $root + [System.IO.Path]::DirectorySeparatorChar

    if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase))
    {
        throw "Refusing to remove a directory outside '$root': '$fullPath'."
    }

    if (Test-Path -LiteralPath $fullPath)
    {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
}

function Invoke-Download
{
    param(
        [Parameter(Mandatory = $true)]
        [uri] $Uri,

        [Parameter(Mandatory = $true)]
        [string] $Destination
    )

    Write-Host "Downloading $Uri"
    Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing

    if ((Get-Item -LiteralPath $Destination).Length -eq 0)
    {
        throw "Downloaded file is empty: '$Destination'."
    }
}

function Assert-CaBundle
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $content = [System.IO.File]::ReadAllText($Path)
    if (-not $content.Contains('-----BEGIN CERTIFICATE-----') -or -not $content.Contains('-----END CERTIFICATE-----'))
    {
        throw "Downloaded CA bundle has an unexpected format: '$Path'."
    }
}

function Expand-ExtensionArchive
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $ArchivePath,

        [Parameter(Mandatory = $true)]
        [string] $InstallPath,

        [Parameter(Mandatory = $true)]
        [string] $WorkPath
    )

    $extractPath = Join-Path $WorkPath "extract-$Name"
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extractPath
    $dlls = @(Get-ChildItem -LiteralPath $extractPath -Filter '*.dll' -File -Recurse)

    if ($dlls.Count -eq 0)
    {
        throw "No DLL files found in '$ArchivePath'."
    }

    foreach ($dll in $dlls)
    {
        $destinationDirectory = $InstallPath
        if ( $dll.Name.StartsWith('php_', [System.StringComparison]::OrdinalIgnoreCase))
        {
            $destinationDirectory = Join-Path $InstallPath 'ext'
        }

        Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $destinationDirectory $dll.Name) -Force
    }

    $extensionPath = Join-Path (Join-Path $InstallPath 'ext') "php_$Name.dll"
    if (-not (Test-Path -LiteralPath $extensionPath -PathType Leaf))
    {
        throw "Extension '$Name' was not found after extracting '$ArchivePath'."
    }
}

function Write-PhpConfiguration
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallPath,

        [Parameter(Mandatory = $true)]
        [string] $ProfilerPath,

        [Parameter(Mandatory = $true)]
        [string] $CaCertPath
    )

    $templatePath = Join-Path $InstallPath 'php.ini-development'
    $iniPath = Join-Path $InstallPath 'php.ini'
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf))
    {
        throw "PHP configuration template not found: '$templatePath'."
    }

    $settings = @(
        'max_execution_time=300',
        'max_input_time=300',
        'memory_limit=-1',
        'post_max_size=256M',
        'upload_max_filesize=50M',
        'extension_dir="ext"'
    )

    $opcachePath = Join-Path (Join-Path $InstallPath 'ext') 'php_opcache.dll'
    if (Test-Path -LiteralPath $opcachePath -PathType Leaf)
    {
        $settings += 'zend_extension=opcache'
    }

    $settings += 'opcache.enable=1', 'opcache.enable_cli=1'

    foreach ($extension in $script:StandardExtensions)
    {
        $extensionPath = Join-Path (Join-Path $InstallPath 'ext') "php_$extension.dll"
        if (Test-Path -LiteralPath $extensionPath -PathType Leaf)
        {
            $settings += "extension=$extension"
        }
    }

    foreach ($extension in @('redis', 'imagick', 'rdkafka'))
    {
        $settings += "extension=$extension"
    }

    $profiler = $ProfilerPath.Replace('\', '/')
    $caCert = $CaCertPath.Replace('\', '/')
    $settings += @(
        'zend_extension=xdebug',
        'xdebug.mode=off',
        'xdebug.start_with_request=trigger',
        'xdebug.client_host=127.0.0.1',
        'xdebug.client_port=9003',
        "xdebug.output_dir=`"$profiler`"",
        "curl.cainfo=`"$caCert`"",
        "openssl.cafile=`"$caCert`""
    )

    $template = [System.IO.File]::ReadAllText($templatePath)
    $content = $template.TrimEnd([char[]]"`r`n") + "`r`n" + ($settings -join "`r`n") + "`r`n"
    [System.IO.File]::WriteAllText($iniPath, $content, $script:Utf8NoBom)
}

function Assert-PhpInstallation
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $InstallPath,

        [Parameter(Mandatory = $true)]
        [string] $ExpectedVersion
    )

    foreach ($relativePath in @(
        'php.exe',
        'php.ini',
        'cacert.pem',
        'ext\php_redis.dll',
        'ext\php_imagick.dll',
        'ext\php_rdkafka.dll',
        'ext\php_xdebug.dll'
    ))
    {
        $path = Join-Path $InstallPath $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf))
        {
            throw "Incomplete PHP installation. Missing '$path'."
        }
    }

    $phpPath = Join-Path $InstallPath 'php.exe'
    $iniPath = Join-Path $InstallPath 'php.ini'
    $command = 'echo PHP_MAJOR_VERSION,chr(46),PHP_MINOR_VERSION,PHP_EOL,implode(chr(44),get_loaded_extensions());'
    $output = @(& $phpPath -c $iniPath -r $command 2>&1)
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { "$_" }) -join "`n"

    if ($exitCode -ne 0)
    {
        throw "PHP validation failed with exit code $exitCode.`n$text"
    }

    $lines = @($text -split "`r?`n")
    if ($lines.Count -ne 2)
    {
        throw "PHP validation returned unexpected output.`n$text"
    }

    if ($lines[0] -ne $ExpectedVersion)
    {
        throw "Expected PHP $ExpectedVersion, got $( $lines[0] )."
    }

    $loadedExtensions = @($lines[1] -split ',')
    foreach ($extension in @('redis', 'imagick', 'rdkafka', 'xdebug', 'Zend OPcache'))
    {
        if ($loadedExtensions -notcontains $extension)
        {
            throw "PHP extension '$extension' failed to load."
        }
    }
}

function Publish-PhpInstallation
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $StagedPath,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $parentPath = Split-Path -Parent $TargetPath
    $targetName = Split-Path -Leaf $TargetPath
    $existing = Get-ChildByName -ParentPath $parentPath -Name $targetName
    $backupPath = "$TargetPath.windows-php-backup"
    $movedExisting = $false

    if ($null -ne $existing)
    {
        $isReparsePoint = ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
        if (-not $existing.PSIsContainer -or $isReparsePoint)
        {
            throw "Expected a regular PHP directory at '$TargetPath'."
        }

        if (Test-Path -LiteralPath $backupPath)
        {
            throw "Stale update backup found at '$backupPath'."
        }
    }

    try
    {
        if ($null -ne $existing)
        {
            Move-Item -LiteralPath $TargetPath -Destination $backupPath
            $movedExisting = $true
        }

        Move-Item -LiteralPath $StagedPath -Destination $TargetPath
    }
    catch
    {
        if ($movedExisting -and -not (Test-Path -LiteralPath $TargetPath) -and (Test-Path -LiteralPath $backupPath))
        {
            Move-Item -LiteralPath $backupPath -Destination $TargetPath
        }

        throw
    }

}

function Restore-InterruptedInstallation
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $backupPath = "$TargetPath.windows-php-backup"
    if (Test-Path -LiteralPath $TargetPath)
    {
        return
    }

    if (Test-Path -LiteralPath $backupPath -PathType Container)
    {
        Write-Warning "Restoring an interrupted update from '$backupPath'."
        Move-Item -LiteralPath $backupPath -Destination $TargetPath
    }
}

function Remove-CompletedUpdateBackup
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $backupPath = "$TargetPath.windows-php-backup"
    if (Test-Path -LiteralPath $backupPath -PathType Container)
    {
        Write-Warning "Removing the backup left by a completed update at '$backupPath'."
        Remove-SafeDirectory -Path $backupPath
    }
}

function Restore-UpdateBackup
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $backupPath = "$TargetPath.windows-php-backup"
    if (-not (Test-Path -LiteralPath $backupPath -PathType Container))
    {
        return $false
    }

    $failedPath = "$TargetPath.windows-php-failed-$([guid]::NewGuid().ToString('N') )"

    if (Test-Path -LiteralPath $TargetPath)
    {
        Move-Item -LiteralPath $TargetPath -Destination $failedPath
    }

    try
    {
        Move-Item -LiteralPath $backupPath -Destination $TargetPath
    }
    catch
    {
        if (-not (Test-Path -LiteralPath $TargetPath) -and (Test-Path -LiteralPath $failedPath))
        {
            Move-Item -LiteralPath $failedPath -Destination $TargetPath
        }

        throw
    }

    return $true
}

function Install-Php
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $PhpVersion,

        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $compiler = $script:CompilerByVersion[$PhpVersion]
    $imagickArchive = Join-Path (Join-Path $script:ProjectRoot 'extensions\imagick') "$PhpVersion.zip"
    $redisDll = Join-Path (Join-Path $script:ProjectRoot 'extensions\redis') "$PhpVersion.dll"
    $rdkafkaArchive = Join-Path (Join-Path $script:ProjectRoot 'extensions\rdkafka') "$PhpVersion.zip"

    foreach ($artifact in @($imagickArchive, $redisDll, $rdkafkaArchive))
    {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf))
        {
            throw "Required extension artifact not found: '$artifact'."
        }
    }

    $cleanVersion = $PhpVersion.Replace('.', '')
    $workPath = Join-Path $script:ModulesRoot ".windows-php-$cleanVersion-$([guid]::NewGuid().ToString('N') )"
    $stagedPath = Join-Path $workPath 'php'
    $phpArchive = Join-Path $workPath 'php.zip'

    Write-Host "Preparing PHP $PhpVersion"
    New-Item -ItemType Directory -Path $stagedPath -Force | Out-Null

    try
    {
        $phpUri = "https://downloads.php.net/~windows/releases/latest/php-$PhpVersion-nts-Win32-$compiler-x64-latest.zip"
        Invoke-Download -Uri $phpUri -Destination $phpArchive
        Expand-Archive -LiteralPath $phpArchive -DestinationPath $stagedPath -Force

        $extensionPath = Join-Path $stagedPath 'ext'
        if (-not (Test-Path -LiteralPath (Join-Path $stagedPath 'php.exe') -PathType Leaf) -or
                -not (Test-Path -LiteralPath $extensionPath -PathType Container))
        {
            throw "The PHP archive for $PhpVersion has an unexpected structure."
        }

        Copy-Item -LiteralPath $redisDll -Destination (Join-Path $extensionPath 'php_redis.dll') -Force
        Expand-ExtensionArchive -Name 'imagick' -ArchivePath $imagickArchive -InstallPath $stagedPath -WorkPath $workPath
        Expand-ExtensionArchive -Name 'rdkafka' -ArchivePath $rdkafkaArchive -InstallPath $stagedPath -WorkPath $workPath

        $xdebugPath = Join-Path $extensionPath 'php_xdebug.dll'
        $xdebugUri = "https://xdebug.org/files/php_xdebug-$script:XdebugVersion-$PhpVersion-nts-$compiler-x86_64.dll"
        Invoke-Download -Uri $xdebugUri -Destination $xdebugPath

        $caCertPath = Join-Path $stagedPath 'cacert.pem'
        Invoke-Download -Uri 'https://curl.se/ca/cacert.pem' -Destination $caCertPath
        Assert-CaBundle -Path $caCertPath

        $profilerPath = Join-Path $script:ModulesRoot 'xdebug\profiler'
        New-Item -ItemType Directory -Path $profilerPath -Force | Out-Null
        $configuredCaCertPath = Join-Path $TargetPath 'cacert.pem'
        Write-PhpConfiguration -InstallPath $stagedPath -ProfilerPath $profilerPath -CaCertPath $configuredCaCertPath
        Assert-PhpInstallation -InstallPath $stagedPath -ExpectedVersion $PhpVersion
        Publish-PhpInstallation -StagedPath $stagedPath -TargetPath $TargetPath
    }
    finally
    {
        try
        {
            Remove-SafeDirectory -Path $workPath
        }
        catch
        {
            Write-Warning "Temporary files remain at '$workPath': $( $_.Exception.Message )"
        }
    }
}

function Set-ActivePhp
{
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    $activePath = Join-Path $script:ModulesRoot 'php'
    $active = Get-ChildByName -ParentPath $script:ModulesRoot -Name 'php'
    $previousTarget = $null

    if ($null -ne $active)
    {
        $isReparsePoint = ($active.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
        if (-not $isReparsePoint)
        {
            throw "Refusing to replace '$activePath' because it is not a link."
        }

        if ($null -ne $active.PSObject.Properties['Target'])
        {
            $targets = @($active.Target)
            if ($targets.Count -gt 0)
            {
                $previousTarget = [string]$targets[0]
                if (-not [System.IO.Path]::IsPathRooted($previousTarget))
                {
                    $previousTarget = Join-Path $script:ModulesRoot $previousTarget
                }

                $previousTarget = [System.IO.Path]::GetFullPath($previousTarget)
                if ( [string]::Equals($previousTarget.TrimEnd([char[]]"\/"),$TargetPath.TrimEnd([char[]]"\/"), [System.StringComparison]::OrdinalIgnoreCase))
                {
                    return
                }
            }
        }

        [System.IO.Directory]::Delete($active.FullName)
    }

    try
    {
        New-Item -ItemType Junction -Path $activePath -Target $TargetPath | Out-Null
    }
    catch
    {
        if ($null -ne $previousTarget -and (Test-Path -LiteralPath $previousTarget -PathType Container) -and
                $null -eq (Get-ChildByName -ParentPath $script:ModulesRoot -Name 'php'))
        {
            New-Item -ItemType Junction -Path $activePath -Target $previousTarget | Out-Null
        }

        throw
    }
}

function Invoke-WindowsPhp
{
    New-Item -ItemType Directory -Path $script:ModulesRoot -Force | Out-Null
    $lockPath = Join-Path $script:ModulesRoot '.windows-php.lock'

    try
    {
        $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    }
    catch [System.IO.IOException]
    {
        throw "Could not acquire '$lockPath'. Another operation may be running: $( $_.Exception.Message )"
    }

    try
    {
        $cleanVersion = $Version.Replace('.', '')
        $targetPath = Join-Path $script:ModulesRoot "php$cleanVersion"
        Restore-InterruptedInstallation -TargetPath $targetPath
        $target = Get-ChildByName -ParentPath $script:ModulesRoot -Name "php$cleanVersion"

        if ($null -ne $target)
        {
            $isReparsePoint = ($target.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
            if (-not $target.PSIsContainer -or $isReparsePoint)
            {
                throw "Expected a regular PHP directory at '$targetPath'."
            }

            if (Test-Path -LiteralPath "$targetPath.windows-php-backup" -PathType Container)
            {
                try
                {
                    Assert-PhpInstallation -InstallPath $targetPath -ExpectedVersion $Version
                }
                catch
                {
                    Write-Warning "The interrupted update is invalid. Restoring the previous installation."
                    Restore-UpdateBackup -TargetPath $targetPath | Out-Null
                    Assert-PhpInstallation -InstallPath $targetPath -ExpectedVersion $Version
                    $target = Get-ChildByName -ParentPath $script:ModulesRoot -Name "php$cleanVersion"
                }

                Remove-CompletedUpdateBackup -TargetPath $targetPath
            }
        }

        if ($Update -or $null -eq $target)
        {
            Install-Php -PhpVersion $Version -TargetPath $targetPath
        }

        try
        {
            Assert-PhpInstallation -InstallPath $targetPath -ExpectedVersion $Version
        }
        catch
        {
            if (-not (Restore-UpdateBackup -TargetPath $targetPath))
            {
                throw
            }

            throw "The new PHP $Version installation failed validation. The previous installation was restored: $( $_.Exception.Message )"
        }

        Remove-CompletedUpdateBackup -TargetPath $targetPath
        Set-ActivePhp -TargetPath $targetPath
        Write-Host "PHP $Version is active at '$targetPath'."
    }
    finally
    {
        $lock.Dispose()
    }
}

if ($MyInvocation.InvocationName -ne '.')
{
    try
    {
        Invoke-WindowsPhp
        exit 0
    }
    catch
    {
        Write-Error -Message $_.Exception.Message -ErrorAction Continue
        exit 1
    }
}
