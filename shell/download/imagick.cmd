set sqlsrvOutputFile=%tmp%\sqlsrv.zip

powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/pecl/releases/imagick/%imagickVersion%/php_imagick-%imagickVersion%-%minorVersion%-nts-%vc%-x64.zip -OutFile %sqlsrvOutputFile%"

call %mainPath%\7zip\7za e "%sqlsrvOutputFile%" -o"%tmp%\imagick" -y

move /y %tmp%\imagick\php_imagick.dll %phpPath%\ext\php_imagick.dll
