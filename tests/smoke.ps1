$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$projectRoot = Split-Path -Parent $PSScriptRoot
$scripts = @(Get-ChildItem -LiteralPath $projectRoot -Filter '*.ps1' -File -Recurse)

foreach ($scriptFile in $scripts)
{
    $tokens = $null
    $errors = $null
    [void] [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0)
    {
        throw "PowerShell syntax error in '$( $scriptFile.FullName )': $( $errors[0].Message )"
    }
}

. (Join-Path $projectRoot 'windows-php.ps1') -Version '8.5'

foreach ($version in $script:CompilerByVersion.Keys)
{
    foreach ($action in 'activate', 'update')
    {
        $entrypoint = Join-Path $projectRoot "bin\$version\$action.ps1"
        if (-not (Test-Path -LiteralPath $entrypoint -PathType Leaf))
        {
            throw "Missing entrypoint '$entrypoint'."
        }

        $entrypointContent = [System.IO.File]::ReadAllText($entrypoint)
        if (-not $entrypointContent.Contains("-Version '$version'"))
        {
            throw "Entrypoint '$entrypoint' selects the wrong version."
        }

        if (($action -eq 'update') -ne $entrypointContent.Contains('-Update'))
        {
            throw "Entrypoint '$entrypoint' has the wrong update mode."
        }
    }

    foreach ($artifact in @(
        "extensions\imagick\$version.zip",
        "extensions\redis\$version.dll",
        "extensions\rdkafka\$version.zip"
    ))
    {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $artifact) -PathType Leaf))
        {
            throw "Missing version artifact '$artifact'."
        }
    }
}

$testRoot = Join-Path (Join-Path $projectRoot 'data') "smoke-$([guid]::NewGuid().ToString('N') )"
$script:ModulesRoot = Join-Path $testRoot 'modules'
$installPath = Join-Path $testRoot 'install'
$extensionPath = Join-Path $installPath 'ext'

try
{
    New-Item -ItemType Directory -Path $extensionPath -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $installPath 'php.ini-development'), '', $script:Utf8NoBom)
    foreach ($dll in @('php_curl.dll', 'php_redis.dll', 'php_imagick.dll', 'php_rdkafka.dll', 'php_xdebug.dll'))
    {
        New-Item -ItemType File -Path (Join-Path $extensionPath $dll) | Out-Null
    }

    $publishedPath = Join-Path $testRoot 'published\php85'
    $profilerPath = Join-Path $publishedPath 'xdebug\profiler'
    $caCertPath = Join-Path $publishedPath 'cacert.pem'
    Write-PhpConfiguration -InstallPath $installPath -ProfilerPath $profilerPath -CaCertPath $caCertPath
    $lines = [System.IO.File]::ReadAllLines((Join-Path $installPath 'php.ini'))

    $configuredCaCert = $caCertPath.Replace('\', '/')
    foreach ($expected in @('max_execution_time=300', 'extension=curl', 'extension=redis', 'zend_extension=xdebug', "curl.cainfo=`"$configuredCaCert`""))
    {
        if ($lines -notcontains $expected)
        {
            throw "Generated php.ini is missing '$expected'."
        }
    }

    if ($lines -contains 'extension=imap' -or $lines -contains 'zend_extension=opcache')
    {
        throw 'Generated php.ini enabled a missing extension.'
    }

    New-Item -ItemType File -Path (Join-Path $extensionPath 'php_opcache.dll') | Out-Null
    Write-PhpConfiguration -InstallPath $installPath -ProfilerPath $profilerPath -CaCertPath $caCertPath
    $lines = [System.IO.File]::ReadAllLines((Join-Path $installPath 'php.ini'))
    if ($lines -notcontains 'zend_extension=opcache')
    {
        throw 'Generated php.ini did not enable available OPcache.'
    }

    $caBundlePath = Join-Path $testRoot 'cacert.pem'
    [System.IO.File]::WriteAllText($caBundlePath, "-----BEGIN CERTIFICATE-----`nvalue`n-----END CERTIFICATE-----", $script:Utf8NoBom)
    Assert-CaBundle -Path $caBundlePath
    [System.IO.File]::WriteAllText($caBundlePath, '<html>error</html>', $script:Utf8NoBom)
    try
    {
        Assert-CaBundle -Path $caBundlePath
        throw 'Invalid CA bundle was accepted.'
    }
    catch
    {
        if ($_.Exception.Message -eq 'Invalid CA bundle was accepted.')
        {
            throw
        }
    }

    New-Item -ItemType Directory -Path $script:ModulesRoot -Force | Out-Null
    $targetPath = Join-Path $script:ModulesRoot 'php85'
    $stagedPath = Join-Path $script:ModulesRoot 'staged'
    New-Item -ItemType Directory -Path $targetPath, $stagedPath | Out-Null
    Set-Content -LiteralPath (Join-Path $targetPath 'old.txt') -Value 'old'
    Set-Content -LiteralPath (Join-Path $stagedPath 'new.txt') -Value 'new'
    Publish-PhpInstallation -StagedPath $stagedPath -TargetPath $targetPath

    if (-not (Test-Path -LiteralPath (Join-Path $targetPath 'new.txt')) -or (Test-Path -LiteralPath (Join-Path $targetPath 'old.txt')))
    {
        throw 'Publishing did not replace the installation.'
    }

    if (-not (Test-Path -LiteralPath "$targetPath.windows-php-backup"))
    {
        throw 'Publishing removed the backup before the new installation was validated.'
    }

    Remove-CompletedUpdateBackup -TargetPath $targetPath

    $rollbackTarget = Join-Path $script:ModulesRoot 'rollback-target'
    $rollbackStage = Join-Path $script:ModulesRoot 'rollback-stage'
    New-Item -ItemType Directory -Path $rollbackTarget | Out-Null
    Set-Content -LiteralPath (Join-Path $rollbackTarget 'keep.txt') -Value 'keep'
    try
    {
        Publish-PhpInstallation -StagedPath $rollbackStage -TargetPath $rollbackTarget
        throw 'Publish failure was not propagated.'
    }
    catch
    {
        if ($_.Exception.Message -eq 'Publish failure was not propagated.')
        {
            throw
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $rollbackTarget 'keep.txt')))
    {
        throw 'Publishing did not restore the previous installation.'
    }

    $interruptedTarget = Join-Path $script:ModulesRoot 'interrupted'
    $interruptedBackup = "$interruptedTarget.windows-php-backup"
    New-Item -ItemType Directory -Path $interruptedBackup | Out-Null
    Set-Content -LiteralPath (Join-Path $interruptedBackup 'keep.txt') -Value 'keep'
    Restore-InterruptedInstallation -TargetPath $interruptedTarget
    if (-not (Test-Path -LiteralPath (Join-Path $interruptedTarget 'keep.txt')))
    {
        throw 'Interrupted installation was not restored.'
    }

    $completedTarget = Join-Path $script:ModulesRoot 'completed'
    $completedBackup = "$completedTarget.windows-php-backup"
    New-Item -ItemType Directory -Path $completedTarget, $completedBackup | Out-Null
    Restore-InterruptedInstallation -TargetPath $completedTarget
    if (-not (Test-Path -LiteralPath $completedBackup))
    {
        throw 'Recovery removed a backup before validating its target.'
    }

    Remove-CompletedUpdateBackup -TargetPath $completedTarget
    if (Test-Path -LiteralPath $completedBackup)
    {
        throw 'Completed update backup was not removed after validation.'
    }

    $invalidTarget = Join-Path $script:ModulesRoot 'invalid'
    $invalidBackup = "$invalidTarget.windows-php-backup"
    New-Item -ItemType Directory -Path $invalidTarget, $invalidBackup | Out-Null
    Set-Content -LiteralPath (Join-Path $invalidTarget 'bad.txt') -Value 'bad'
    Set-Content -LiteralPath (Join-Path $invalidBackup 'good.txt') -Value 'good'
    if (-not (Restore-UpdateBackup -TargetPath $invalidTarget))
    {
        throw 'Invalid update backup was not restored.'
    }

    if (-not (Test-Path -LiteralPath (Join-Path $invalidTarget 'good.txt')) -or (Test-Path -LiteralPath (Join-Path $invalidTarget 'bad.txt')))
    {
        throw 'Invalid update rollback left the wrong target.'
    }

    $failedInstallations = @(Get-ChildItem -LiteralPath $script:ModulesRoot -Directory -Force | Where-Object Name -Like 'invalid.windows-php-failed-*')
    if ($failedInstallations.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $failedInstallations[0].FullName 'bad.txt')))
    {
        throw 'Invalid update rollback did not preserve the failed installation.'
    }

    try
    {
        Remove-SafeDirectory -Path $installPath
        throw 'Path guard accepted a directory outside modules.'
    }
    catch
    {
        if ($_.Exception.Message -eq 'Path guard accepted a directory outside modules.')
        {
            throw
        }
    }

    Set-ActivePhp -TargetPath $targetPath
    $otherTarget = Join-Path $script:ModulesRoot 'php84'
    New-Item -ItemType Directory -Path $otherTarget | Out-Null
    Set-ActivePhp -TargetPath $otherTarget

    if (-not (Test-Path -LiteralPath (Join-Path $targetPath 'new.txt')))
    {
        throw 'Switching the active junction changed its previous target.'
    }
}
finally
{
    if (Test-Path -LiteralPath $testRoot)
    {
        $activePath = Join-Path $script:ModulesRoot 'php'
        $active = Get-ChildByName -ParentPath $script:ModulesRoot -Name 'php'
        if ($null -ne $active)
        {
            [System.IO.Directory]::Delete($activePath)
        }

        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Host "Smoke test passed in PowerShell $( $PSVersionTable.PSVersion )."
