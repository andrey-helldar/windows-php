set version=%1
set vc=%2

set version=%version:"=%
set vc=%vc:"=%

set xdebugVersion=3.1.4
set redisVersion=5.3.7
set yamlVersion=2.2.2

set tmp=%mainPath%\data\tmp

if exist %tmp% ( rmdir /Q/S %tmp% )
if exist %phpPath% ( rmdir /Q/S %phpPath% )

if not exist %tmp% ( mkdir %tmp% )

call download/php.cmd
call download/xdebug.cmd
call download/redis.cmd
call download/yaml.cmd

call php-config.cmd %cleanVersion%

if exist %tmp% ( rmdir /Q/S %tmp% )
