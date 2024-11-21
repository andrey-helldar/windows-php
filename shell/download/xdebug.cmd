set xdebugOutputFile=%tmp%\xdebug.dll

set xdebugProfilerDir=%phpPath%\xdebug\profiler

if /I %minorVersion%==8.4 (
    powershell -Command "Invoke-WebRequest https://xdebug.org/files/php_xdebug-%xdebugVersion%-%minorVersion%-nts-x86_64.dll -OutFile %xdebugOutputFile%"
) else (
    powershell -Command "Invoke-WebRequest https://xdebug.org/files/php_xdebug-%xdebugVersion%-%minorVersion%-%vc%-nts-x86_64.dll -OutFile %xdebugOutputFile%"
)

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(xdebug\.output_dir)\s?=(.*)', '$1 = \"%xdebugProfilerDir%\"' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

if not exist "%xdebugProfilerDir%" ( mkdir "%xdebugProfilerDir%" )

move /y %tmp%\xdebug.dll %phpPath%\ext\php_xdebug.dll
