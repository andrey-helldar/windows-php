@echo off

cd ..\..\shell

call variables.cmd

call main.cmd "latest" "8.4" "vs17" "update"
