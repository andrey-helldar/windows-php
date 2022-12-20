set type=%1
set version=%2
set vc=%3

set version=%version:"=%
set minorVersion=%version:"=%
set vc=%vc:"=%

set xdebugVersion=3.2.0
set redisVersion=5.3.7
set yamlVersion=2.2.2
set sqlsrvVersion=5.10.0
    
if /I %version%==7.4.32 (
    set xdebugVersion=3.1.5
    set minorVersion=7.4
)

set tmp=%mainPath%\data\tmp

if exist %tmp% ( rmdir /Q/S %tmp% )
if exist %phpPath% ( rmdir /Q/S %phpPath% )

if not exist %tmp% ( mkdir %tmp% )

call download/php.cmd
call download/redis.cmd
call download/sqlsrv.cmd
call download/xdebug.cmd
call download/yaml.cmd

call php-config.cmd %cleanVersion%

if exist %tmp% ( rmdir /Q/S %tmp% )
