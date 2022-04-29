powershell -Command "Invoke-WebRequest https://curl.se/ca/cacert.pem -OutFile %phpPath%\cacert.pem"

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(curl\.cainfo)\s?=(.*)', '$1 = \"%phpPath%\cacert.pem\"' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
