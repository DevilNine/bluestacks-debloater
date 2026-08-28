@echo off
setlocal
chcp 65001 >nul
title BlueStacks Debloater - Restaurar Backup

:: Verificacao e auto-elevacao transparente
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "powershell.exe", "-NoLogo -NoProfile -ExecutionPolicy Bypass -File """"%~dp0BlueStacksDebloater.ps1"""" -Action Undo", "", "runas", 1 >> "%temp%\elevate.vbs"
    cscript //nologo "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)

cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Undo %*
