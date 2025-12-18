call %~d0

set currentPath=%~dp0

set mainPath=%currentPath%..
set modulesPath=%currentPath%..\..\modules

set php_max_execution_time=300
set php_max_input_time=300
set php_memory_limit=-1
set php_post_max_size=256M
set php_extension_dir="ext"
set php_upload_max_filesize=50M

set php_extensions=bz2 curl fileinfo gd intl ldap mbstring odbc openssl pdo_mysql pdo_pgsql pdo_sqlite pgsql soap sockets sqlite3 xsl zip
