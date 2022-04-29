@echo off

cd ..\..\shell

call variables.cmd

call php-only.cmd "7.4" "vc15"
