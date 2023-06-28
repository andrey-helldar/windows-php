set xdebugOutputFile=%tmp%\xdebug.dll

powershell -Command "Invoke-WebRequest https://xdebug.org/files/php_xdebug-%xdebugVersion%-%minorVersion%-%vc%-nts-x86_64.dll -OutFile %xdebugOutputFile%"

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(xdebug\.output_dir)\s?=(.*)', '$1 = \"%phpPath%\data\xdebug\profiling"' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

if not exist "%phpPath%\data\xdebug\profiling" mkdir "%phpPath%\data\xdebug\profiling"

move /y %tmp%\xdebug.dll %phpPath%\ext\php_xdebug.dll
