set version=%1

set version=%version:"=%

set source=%modulesPath%\php%version%\php.ini-development
set target=%modulesPath%\php%version%\php.ini

if not exist %target% (
    copy %source% %target%
)

set php_max_execution_time=300
set php_max_input_time=300
set php_memory_limit=-1
set php_post_max_size=256M
set php_extension_dir="ext"
set php_upload_max_filesize=50M
