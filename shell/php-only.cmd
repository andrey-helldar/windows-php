set type=%1
set version=%2
set vc=%3

set cleanVersion=%version:.=%

set currentPath=%~dp0

set modulesPath=%currentPath%..\..\modules

set phpPath=%modulesPath%\php%cleanVersion%

rd %modulesPath%\php

if not exist %phpPath% (
    call php-download.cmd %type% %version% %vc%
)

call cacert.cmd

mklink /J %modulesPath%\php %modulesPath%\php%cleanVersion%
