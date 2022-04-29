set version=%1

set version=%version:"=%

set source=%mainPath%\config\php%version%.ini
set target=%modulesPath%\php%version%\php.ini

if not exist %target% (
    copy %source% %target%
)
