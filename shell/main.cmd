set version=%1
set vc=%2
set action=%3

set cleanVersion=%version:.=%

set phpPath=%modulesPath%\php%cleanVersion%

if /I %action%=="update" (
    call php-download.cmd %version% %vc%
)

call php-only.cmd %version% %vc%
