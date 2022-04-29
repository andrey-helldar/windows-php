set phpOutputFile=%tmp%\php.zip

powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/releases/latest/php-%version%-nts-Win32-%vc%-x64-latest.zip -OutFile %phpOutputFile%"

call %mainPath%\7zip\7za x "%phpOutputFile%" -o"%phpPath%" -y
