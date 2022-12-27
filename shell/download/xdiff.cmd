set xdiffOutputFile=%tmp%\xdiff.zip

powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/pecl/releases/xdiff/%xdiffVersion%/php_xdiff-%xdiffVersion%-%minorVersion%-nts-%vc%-x64.zip -OutFile %xdiffOutputFile%"

call %mainPath%\7zip\7za e "%xdiffOutputFile%" -o"%tmp%\xdiff" -y

move /y %tmp%\xdiff\php_xdiff.dll %phpPath%\ext\php_xdiff.dll
