set phpOutputFile=%tmp%\php.zip

if /I %type%=="latest" (
    powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/releases/latest/php-%version%-nts-Win32-%vc%-x64-latest.zip -OutFile %phpOutputFile%"
) else (
    powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/releases/archives/php-%version%-nts-Win32-%vc%-x64.zip -OutFile %phpOutputFile%"
)

call %mainPath%\7zip\7za x "%phpOutputFile%" -o"%phpPath%" -y
