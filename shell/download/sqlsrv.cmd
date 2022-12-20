set sqlsrvOutputFile=%tmp%\sqlsrv.zip

powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/pecl/releases/pdo_sqlsrv/%sqlsrvVersion%/php_pdo_sqlsrv-%sqlsrvVersion%-%minorVersion%-nts-%vc%-x64.zip -OutFile %sqlsrvOutputFile%"

call %mainPath%\7zip\7za e "%sqlsrvOutputFile%" -o"%tmp%\sqlsrv" -y

move /y %tmp%\sqlsrv\php_pdo_sqlsrv.dll %phpPath%\ext\php_pdo_sqlsrv.dll
