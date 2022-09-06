set type=%1
set version=%2
set vc=%3
set action=%4

set cleanVersion=%version:.=%

set phpPath=%modulesPath%\php%cleanVersion%

if /I %action%=="update" (
    call php-download.cmd %type% %version% %vc%
)

call php-only.cmd %type% %version% %vc%
