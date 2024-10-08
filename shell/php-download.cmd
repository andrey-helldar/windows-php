set type=%1
set version=%2
set vc=%3

set version=%version:"=%
set minorVersion=%version:"=%
set vc=%vc:"=%

set xdebugVersion=3.3.1

set tmp=%mainPath%\data\tmp

if exist %tmp% ( rmdir /Q/S %tmp% )
if exist %phpPath% ( rmdir /Q/S %phpPath% )

if not exist %tmp% ( mkdir %tmp% )

call download/php.cmd
call php-config.cmd %cleanVersion%

call download/imagick.cmd
call download/redis.cmd
call download/xdebug.cmd
rem call download/rdkafka.cmd


if exist %tmp% ( rmdir /Q/S %tmp% )
