set xdebugOutputFile=%tmp%\xdebug.dll

powershell -Command "Invoke-WebRequest https://xdebug.org/files/php_xdebug-%xdebugVersion%-%minorVersion%-%vc%-nts-x86_64.dll -OutFile %xdebugOutputFile%"

move /y %tmp%\xdebug.dll %phpPath%\ext\php_xdebug.dll
