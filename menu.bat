@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title BlueStacks Debloater - Menu

:: ============================================================================
:: Verificacao e Auto-Elevacao para Administrador (UAC)
:: ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios de Administrador (UAC)...
    echo Requesting Administrator privileges (UAC)...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Garante execucao no diretorio do script
cd /d "%~dp0"

:MENU
cls
echo ============================================================================
echo   BLUESTACKS DEBLOATER ^& OPTIMIZER - MENU
echo ============================================================================
echo.
echo   [1] Debloat Completo (Recomendado / 1-Click)
echo   [2] Apenas Host (Configuracoes, Hosts do Windows e Helpers)
echo   [3] Apenas Guest Android (ADB, Hosts Interno e Bloatwares)
echo   [4] Previa / Simulacao (Dry-Run, nao altera nada)
echo   [5] Diagnostico e Status de Instancias
echo   [6] Restaurar Backup Anterior (Undo)
echo   [7] Desbloquear Downloads Oficiais (Remover bloqueio de cloud/eb)
echo   [0] Sair / Exit
echo.
set /p op="Selecione uma opcao / Select an option [0-7]: "

if "%op%"=="1" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Full
    pause
    goto MENU
)
if "%op%"=="2" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action HostOnly
    pause
    goto MENU
)
if "%op%"=="3" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action GuestOnly
    pause
    goto MENU
)
if "%op%"=="4" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Full -DryRun
    pause
    goto MENU
)
if "%op%"=="5" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Status
    pause
    goto MENU
)
if "%op%"=="6" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action Undo
    pause
    goto MENU
)
if "%op%"=="7" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action FixHosts
    pause
    goto MENU
)
if "%op%"=="0" exit /b

goto MENU
