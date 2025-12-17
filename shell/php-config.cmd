set version=%1

set version=%version:"=%

set source=%modulesPath%\php%version%\php.ini-development
set target=%modulesPath%\php%version%\php.ini

if not exist %target% (
    copy %source% %target%
)
