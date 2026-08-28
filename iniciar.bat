@echo off
setlocal
chcp 65001 >nul
title BlueStacks Debloater ^& Optimizer

cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Full %*
