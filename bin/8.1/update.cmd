@echo off

cd ..\..\shell

call variables.cmd

call main.cmd "8.1" "vs16" "update"
