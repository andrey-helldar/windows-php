set xdebugOutputFile=%tmp%\xdebug.dll

set xdebugProfilerDir=%phpPath%\xdebug\profiler

powershell -Command "Invoke-WebRequest https://xdebug.org/files/php_xdebug-%xdebugVersion%-%minorVersion%-nts-%vc%-x86_64.dll -OutFile %xdebugOutputFile%"

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(xdebug\.output_dir)\s?=(.*)', '$1 = \"%xdebugProfilerDir%\"' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

powershell -Command "(Get-Content %phpPath%\php.ini) + \"`nzend_extension=xdebug`nxdebug.mode=debug,develop,profile,coverage`nxdebug.start_with_request=yes`nxdebug.client_host=127.0.0.1`nxdebug.client_port=9003\" | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

if not exist "%xdebugProfilerDir%" ( mkdir "%xdebugProfilerDir%" )

move /y %tmp%\xdebug.dll %phpPath%\ext\php_xdebug.dll
