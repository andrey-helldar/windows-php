@echo off

cd ..\..\shell

call variables.cmd

call php-only.cmd "archives" "7.4.33" "vc15"
