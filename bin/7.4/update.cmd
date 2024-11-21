@echo off

cd ..\..\shell

call variables.cmd

call main.cmd "archives" "7.4.33" "vc15" "update"
