set imagickOutputFile=%tmp%\imagick.zip

copy %mainPath%\extensions\imagick\%minorVersion%.zip %imagickOutputFile%

call %mainPath%\7zip\7za e "%imagickOutputFile%" -o"%tmp%\imagick" -y

move /y %tmp%\imagick\php_imagick.dll %phpPath%\ext\php_imagick.dll

move /y %tmp%\imagick\* %phpPath%
