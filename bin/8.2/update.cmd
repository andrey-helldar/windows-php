@echo off

cd ..\..\shell

call variables.cmd

call main.cmd "latest" "8.2" "vs16" "update"
