powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(max_execution_time)\s?=(.*)', '$1 = %php_max_execution_time%' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(max_input_time)\s?=(.*)', '$1 = %php_max_input_time%' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(memory_limit)\s?=(.*)', '$1 = %php_memory_limit%' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(post_max_size)\s?=(.*)', '$1 = %php_post_max_size%' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(upload_max_filesize)\s?=(.*)', '$1 = %php_upload_max_filesize%' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?(extension_dir)\s?=(.*)', '$1 = \"%php_extension_dir%\"' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?zend_extension\s?=\s?opcache.*', 'zend_extension=opcache' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"

for %%i in (%php_extensions%) do (
    powershell -Command "(Get-Content %phpPath%\php.ini) -replace ';?extension\s?=\s?%%i.*', 'extension=%%i' | Out-File -Encoding \"UTF8\" %phpPath%\php.ini"
)
