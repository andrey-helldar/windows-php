@echo off

cd ..\..\shell

call variables.cmd

call php-only.cmd "latest" "8.0" "vs16"
