set yamlOutputFile=%tmp%\yaml.zip

echo "https://windows.php.net/downloads/pecl/releases/yaml/%yamlVersion%/php_yaml-%yamlVersion%-%minorVersion%-nts-%vc%-x64.zip"
powershell -Command "Invoke-WebRequest https://windows.php.net/downloads/pecl/releases/yaml/%yamlVersion%/php_yaml-%yamlVersion%-%minorVersion%-nts-%vc%-x64.zip -OutFile %yamlOutputFile%"

call %mainPath%\7zip\7za e "%yamlOutputFile%" -o"%tmp%\yaml" -y

move /y %tmp%\yaml\php_yaml.dll %phpPath%\ext\php_yaml.dll
