@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title BlueStacks Debloater - Desbloquear Downloads

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

:: ============================================================================
:: Desbloqueio e Reparacao do Hosts para Downloads do BlueStacks
:: ============================================================================
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlueStacksDebloater.ps1" -Action FixHosts

if %errorlevel% neq 0 (
    echo.
    echo [!] Ocorreu um erro durante a liberacao.
    echo [!] An error occurred during hosts repair.
    pause
)
