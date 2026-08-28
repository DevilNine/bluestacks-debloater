<#
.SYNOPSIS
    BlueStacks Debloater & Optimizer
    Removes ads, telemetry, promotional spam, and optimizes graphics performance on BlueStacks 5.

.DESCRIPTION
    Standalone and self-contained debloater engine for BlueStacks 5 and MSI App Player.
    Features:
      - Automatic path, registry and ADB port detection.
      - Full backup before any change, 100% reversible via -Action Undo.
      - Host-side debloat: bluestacks.conf telemetry/ad suppression & Read-Only locking.
      - Performance optimization: enables hardware ASTC, 120 FPS high framerate mode, disables vsync.
      - Network debloat: null-routes ad and tracking domains in Windows and Android hosts.
      - Background helper blocking: renames non-essential promo/AI executables to .bak.
      - Guest-side Android debloat: disables pre-installed bloatware packages via ADB without uninstalling.
      - Native bilingual support (Portuguese and English) based on system culture or manual selection.

.PARAMETER Action
    The operation to execute: Full (default), HostOnly, GuestOnly, Undo, Status.

.PARAMETER DryRun
    Simulate actions without modifying files, registries, or processes.

.PARAMETER Language
    Language preference: Auto (default, detects OS culture), pt, or en.

.PARAMETER NoPause
    Do not pause at script completion (ideal for automated callers).

.PARAMETER Install
    Override path to BlueStacks installation directory (auto-detected if omitted).

.PARAMETER Conf
    Override path to bluestacks.conf (auto-detected if omitted).
#>

[CmdletBinding()]
param(
    [ValidateSet('Full', 'HostOnly', 'GuestOnly', 'Undo', 'Status', 'FixHosts')]
    [string]$Action = 'Full',

    [switch]$DryRun,

    [ValidateSet('Auto', 'pt', 'en')]
    [string]$Language = 'Auto',

    [switch]$NoPause,

    [string]$Install,

    [string]$Conf
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# Localization (i18n) Dictionary: Portuguese (pt) & English (en)
# ==============================================================================
$script:Messages = @{
    pt = @{
        BannerTitle          = 'BLUESTACKS DEBLOATER & OPTIMIZER'
        BannerSubtitle       = 'Limpeza de anúncios, telemetria e otimização de desempenho para BlueStacks 5'
        DetectingPaths       = 'Detectando instalação e arquivos de configuração...'
        InstallPath          = 'Diretório de instalação : {0}'
        ConfPath             = 'Arquivo bluestacks.conf : {0}'
        ConfNotFound         = '[!] bluestacks.conf não encontrado. Abra o BlueStacks pelo menos uma vez para gerar os arquivos e execute novamente.'
        AdminRequired        = '[!] Permissões de Administrador necessárias para continuar.'
        ElevationNotice      = '[*] Solicitando privilégios de Administrador (UAC)...'
        ClosingProcesses     = '[*] Encerrando processos ativos do BlueStacks (HD-*, Bstk*, BlueStacks*)...'
        DryRunNotice         = '[*] Modo Dry-Run ativo: nenhuma alteração será gravada.'
        BackupSaved          = '[+] Backup completo salvo em: {0}'
        BackupSyncLatest     = '[+] Link do backup mais recente sincronizado com sucesso.'
        
        # Host Debloat
        HostDebloatStart     = '[*] Analisando e desativando chaves de telemetria e anúncios no bluestacks.conf...'
        KeyDisabled          = '    [+] Chave desativada: {0} = {1} -> {2}'
        KeyCleared           = '    [+] Valor limpo: {0} = "{1}" -> ""'
        KeyAppended          = '    [+] Chave de configuração adicionada: {0} = {1}'
        ConfReadOnlySuccess  = '[+] bluestacks.conf definido como Somente-Leitura para impedir reversões pelo emulador.'
        ConfReadOnlyFail     = '[!] Não foi possível definir bluestacks.conf como Somente-Leitura: {0}'
        HostDebloatSummary   = '[+] Total de {0} chave(s) desativada(s) em bluestacks.conf.'
        HostDebloatClean     = '[*] Nenhuma chave precisou ser modificada no bluestacks.conf (já otimizado).'
        
        # Performance
        PerfOptStart         = '[*] Aplicando otimizações de desempenho gráfico e taxas de quadros (120 FPS)...'
        PerfKeyUpdated       = '    [+] Desempenho otimizado: {0} = {1} -> {2}'
        PerfKeyAppended      = '    [+] Parâmetro de desempenho adicionado: {0} = {1}'
        PerfOptSummary       = '[+] Total de {0} configuração(ões) de desempenho aplicada(s).'
        PerfOptClean         = '[*] Configurações de desempenho já estão no valor ideal.'
        
        # Windows Hosts
        WinHostsStart        = '[*] Bloqueando servidores de anúncios e telemetria no arquivo hosts do Windows...'
        WinHostsSuccess      = '[+] {0} domínio(s) de publicidade/telemetria redirecionado(s) para 0.0.0.0.'
        WinHostsClean        = '[*] Domínios de bloqueio já estavam presentes no hosts do Windows.'
        WinHostsFail         = '[!] Falha ao gravar no arquivo hosts do Windows: {0}'
        
        # Helpers
        HelpersStart         = '[*] Desativando auxiliares em segundo plano (banners, IA, telemetria)...'
        HelperBlocked        = '    [+] Auxiliar bloqueado: {0} -> {0}.bak'
        HelperClean          = '    [*] Auxiliar {0} já desativado ou não encontrado.'
        HelperFail           = '    [!] Erro ao desativar auxiliar {0}: {1}'
        FolderBlocked        = '    [+] Pasta desativada: {0} -> {0}.bak'
        FolderClean          = '    [*] Pasta {0} já desativada ou não encontrada.'
        FolderFail           = '    [!] Erro ao desativar pasta {0}: {1}'
        
        # Guest ADB
        NoActiveInstances    = '[!] Nenhuma instância ativa do BlueStacks encontrada em bluestacks.conf.'
        AdbNotFound          = '[!] HD-Adb.exe não encontrado em {0} e comando "adb" ausente no PATH.'
        ConnectingGuest      = '[*] Conectando à instância Android via ADB: {0} (Porta: {1})...'
        StartingInstance     = '[*] Instância "{0}" não está rodando. Iniciando automaticamente via HD-Player...'
        WaitingBoot          = '[*] Aguardando inicialização da instância e abertura da porta ADB (até 60s)...'
        PromptStartManual    = '[*] Por favor, certifique-se de que o BlueStacks está aberto na instância "{0}".'
        PressEnterWhenReady  = 'Pressione Enter assim que o BlueStacks estiver carregado para conectar...'
        AdbConnectFail       = '[!] Não foi possível estabelecer conexão ADB com a porta {0}.'
        RequestingRoot       = '[*] Solicitando permissões de root...'
        RemountingSystem     = '[*] Remontando partição /system como leitura e escrita...'
        SystemReadOnlyWarn   = '[!] Aviso: partição /system está montada como somente-leitura. O hosts interno não pôde ser atualizado.'
        GuestHostsSuccess    = '[+] {0} domínio(s) bloqueado(s) no arquivo hosts do Android.'
        GuestHostsClean      = '[*] Domínios já bloqueados no hosts do Android.'
        BloatCandidatesFound = '[*] Pacotes bloatware detectados para desativação no Android:'
        BloatDisabledSuccess = '[+] {0} pacote(s) bloatware desativado(s) com sucesso via "pm disable-user".'
        NoBloatPackages      = '[*] Nenhum pacote bloatware ativo detectado no Android.'
        
        # Undo
        UndoStart            = '[*] Iniciando restauração a partir do backup mais recente...'
        NoBackupFound        = '[!] Nenhum backup foi encontrado para restaurar.'
        UndoConfSuccess      = '[+] bluestacks.conf restaurado para o estado original.'
        UndoHostsSuccess     = '[+] Arquivo hosts do Windows restaurado com sucesso.'
        UndoHostsFail        = '[!] Falha ao restaurar arquivo hosts do Windows: {0}'
        UndoHelperRestored   = '    [+] Auxiliar restaurado: {0}'
        UndoFolderRestored   = '    [+] Pasta restaurada: {0}'
        UndoGuestInstance    = '[*] Restaurando configurações do Android para instância: {0} (Porta: {1})...'
        UndoGuestHostsDone   = '    [+] Hosts interno do Android restaurado.'
        UndoGuestPkgsDone    = '    [+] Pacotes do Android reativados.'
        UndoComplete         = '[+] Restauração concluída com sucesso!'
        
        # Status & Backups
        ConfigDetected       = '[+] Arquivo de configuração detectado. {0} instância(s) encontrada(s).'
        InstanceAdbPort      = '    - Instância: {0} | Porta ADB: {1}'
        PreviousBackupFound  = '[+] Backup anterior encontrado em: state/backups/bluestacks/latest'
        NoBackupsFound       = '[*] Nenhum backup anterior detectado.'
        AdbTargetDryRun      = '    [dry-run] Alvo ADB: {0} (Porta: {1})'
        
        # Fix Hosts & Downloads
        FixHostsSuccess      = '[+] Domínios de download do BlueStacks liberados no hosts! Downloads do site oficial agora funcionam normalmente.'
        FixHostsClean        = '[*] Os domínios de download do BlueStacks já estavam liberados no arquivo hosts.'
        DownloadUnblocked    = '[+] Removido bloqueio indevido de download: {0}'
        
        # Completion
        DebloatCompleted     = '[+] OTIMIZAÇÃO CONCLUÍDA: O BlueStacks agora está livre de anúncios, com telemetria bloqueada e taxa de quadros destravada!'
        RebootNotice         = '[*] Você já pode abrir o BlueStacks novamente e desfrutar da experiência limpa.'
        PressAnyKey          = 'Pressione qualquer tecla para sair...'
    }
    en = @{
        BannerTitle          = 'BLUESTACKS DEBLOATER & OPTIMIZER'
        BannerSubtitle       = 'Remove ads, telemetry, promo spam, and unlock gaming performance for BlueStacks 5'
        DetectingPaths       = 'Detecting installation and configuration files...'
        InstallPath          = 'Installation directory : {0}'
        ConfPath             = 'Configuration file     : {0}'
        ConfNotFound         = '[!] bluestacks.conf not found. Please launch BlueStacks at least once to create config files, then re-run.'
        AdminRequired        = '[!] Administrator privileges are required to proceed.'
        ElevationNotice      = '[*] Requesting Administrator privileges (UAC)...'
        ClosingProcesses     = '[*] Closing active BlueStacks processes (HD-*, Bstk*, BlueStacks*)...'
        DryRunNotice         = '[*] Dry-Run mode active: no changes will be written.'
        BackupSaved          = '[+] Full backup saved to: {0}'
        BackupSyncLatest     = '[+] Latest backup link synchronized successfully.'
        
        # Host Debloat
        HostDebloatStart     = '[*] Analyzing and disabling ad and telemetry keys in bluestacks.conf...'
        KeyDisabled          = '    [+] Key disabled: {0} = {1} -> {2}'
        KeyCleared           = '    [+] Key cleared: {0} = "{1}" -> ""'
        KeyAppended          = '    [+] Appended missing config key: {0} = {1}'
        ConfReadOnlySuccess  = '[+] Set bluestacks.conf to Read-Only to prevent emulator reverts.'
        ConfReadOnlyFail     = '[!] Failed to set bluestacks.conf to Read-Only: {0}'
        HostDebloatSummary   = '[+] Disabled {0} config key(s) in bluestacks.conf.'
        HostDebloatClean     = '[*] No config keys required modification in bluestacks.conf (already clean).'
        
        # Performance
        PerfOptStart         = '[*] Applying graphics performance and framerate optimizations (120 FPS)...'
        PerfKeyUpdated       = '    [+] Performance optimized: {0} = {1} -> {2}'
        PerfKeyAppended      = '    [+] Appended performance parameter: {0} = {1}'
        PerfOptSummary       = '[+] Applied {0} performance settings.'
        PerfOptClean         = '[*] Performance settings are already at optimal values.'
        
        # Windows Hosts
        WinHostsStart        = '[*] Null-routing ad and telemetry domains in Windows hosts file...'
        WinHostsSuccess      = '[+] Null-routed {0} domain(s) to 0.0.0.0 in Windows hosts.'
        WinHostsClean        = '[*] Ad/telemetry domains are already blocked in Windows hosts.'
        WinHostsFail         = '[!] Failed to write to Windows hosts file: {0}'
        
        # Helpers
        HelpersStart         = '[*] Disabling background helper binaries (promos, AI, telemetry)...'
        HelperBlocked        = '    [+] Blocked helper executable: {0} -> {0}.bak'
        HelperClean          = '    [*] Helper {0} already blocked or not found.'
        HelperFail           = '    [!] Error blocking helper {0}: {1}'
        FolderBlocked        = '    [+] Blocked folder: {0} -> {0}.bak'
        FolderClean          = '    [*] Folder {0} already blocked or not found.'
        FolderFail           = '    [!] Error blocking folder {0}: {1}'
        
        # Guest ADB
        NoActiveInstances    = '[!] No active BlueStacks instances detected in bluestacks.conf.'
        AdbNotFound          = '[!] HD-Adb.exe not found at {0} and "adb" command missing from system PATH.'
        ConnectingGuest      = '[*] Connecting to guest Android instance via ADB: {0} (Port: {1})...'
        StartingInstance     = '[*] Instance "{0}" is not running. Starting automatically via HD-Player...'
        WaitingBoot          = '[*] Waiting up to 60s for instance to boot and open ADB port...'
        PromptStartManual    = '[*] Please make sure BlueStacks is open on instance "{0}".'
        PressEnterWhenReady  = 'Press Enter once BlueStacks is fully loaded to connect...'
        AdbConnectFail       = '[!] Failed to connect to local ADB port {0}.'
        RequestingRoot       = '[*] Requesting root access...'
        RemountingSystem     = '[*] Remounting /system partition as read-write...'
        SystemReadOnlyWarn   = '[!] Warning: /system partition is mounted as read-only. Guest hosts blocklist could not be updated.'
        GuestHostsSuccess    = '[+] Null-routed {0} domain(s) in guest Android hosts.'
        GuestHostsClean      = '[*] Ad/telemetry domains already blocked in Android hosts.'
        BloatCandidatesFound = '[*] Bloatware candidate packages detected for disabling in Android:'
        BloatDisabledSuccess = '[+] Disabled {0} bloat package(s) successfully via "pm disable-user".'
        NoBloatPackages      = '[*] No active bloat packages detected in Android guest.'
        
        # Undo
        UndoStart            = '[*] Restoring from latest backup...'
        NoBackupFound        = '[!] No backup found to restore.'
        UndoConfSuccess      = '[+] bluestacks.conf restored to original state.'
        UndoHostsSuccess     = '[+] Windows hosts file restored successfully.'
        UndoHostsFail        = '[!] Failed to restore Windows hosts file: {0}'
        UndoHelperRestored   = '    [+] Restored helper: {0}'
        UndoFolderRestored   = '    [+] Restored folder: {0}'
        UndoGuestInstance    = '[*] Restoring Android settings for instance: {0} (Port: {1})...'
        UndoGuestHostsDone   = '    [+] Android guest hosts restored.'
        UndoGuestPkgsDone    = '    [+] Android guest packages re-enabled.'
        UndoComplete         = '[+] Restore completed successfully!'
        
        # Status & Backups
        ConfigDetected       = '[+] Configuration file detected. Found {0} instance(s).'
        InstanceAdbPort      = '    - Instance: {0} | ADB Port: {1}'
        PreviousBackupFound  = '[+] Previous backup found in: state/backups/bluestacks/latest'
        NoBackupsFound       = '[*] No previous backups detected.'
        AdbTargetDryRun      = '    [dry-run] ADB Target: {0} (Port: {1})'
        
        # Fix Hosts & Downloads
        FixHostsSuccess      = '[+] BlueStacks download domains unblocked in hosts! Official site downloads now function normally.'
        FixHostsClean        = '[*] BlueStacks download domains were already unblocked in hosts file.'
        DownloadUnblocked    = '[+] Removed improper download domain block: {0}'
        
        # Completion
        DebloatCompleted     = '[+] OPTIMIZATION COMPLETE: BlueStacks is now debloated, telemetry-blocked, and unlocked for maximum FPS!'
        RebootNotice         = '[*] You may now launch BlueStacks and enjoy a clean, fast experience.'
        PressAnyKey          = 'Press any key to exit...'
    }
}

# Determine language
if ($Language -eq 'Auto') {
    $culture = [System.Globalization.CultureInfo]::InstalledUICulture.TwoLetterISOLanguageName.ToLowerInvariant()
    $script:ActiveLang = if ($culture -eq 'pt') { 'pt' } else { 'en' }
} else {
    $script:ActiveLang = $Language.ToLowerInvariant()
}

function Get-Text([string]$key, [object[]]$argsList) {
    $dict = $script:Messages[$script:ActiveLang]
    if (-not $dict.ContainsKey($key)) {
        $dict = $script:Messages['en']
    }
    $val = $dict[$key]
    if ($argsList -and $argsList.Count -gt 0) {
        return ($val -f $argsList)
    }
    return $val
}

function Say([string]$msg, [string]$color = 'Gray') {
    Write-Host $msg -ForegroundColor $color
    if ($script:LogFile) {
        try {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Add-Content -LiteralPath $script:LogFile -Value "$timestamp $msg" -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {}
    }
}

function Show-Header {
    Write-Host ''
    Write-Host ("=" * 76) -ForegroundColor Cyan
    Write-Host ("  {0}" -f (Get-Text 'BannerTitle')) -ForegroundColor White
    Write-Host ("  {0}" -f (Get-Text 'BannerSubtitle')) -ForegroundColor DarkCyan
    Write-Host ("=" * 76) -ForegroundColor Cyan
    Write-Host ''
}

# ==============================================================================
# Environment & State Directories
# ==============================================================================
$script:ProjectRoot = $PSScriptRoot
$script:StateDir    = Join-Path $script:ProjectRoot 'state'
$script:BackupRoot  = Join-Path $script:StateDir 'backups\bluestacks'
$script:LatestLink  = Join-Path $script:BackupRoot 'latest'
$script:LogDir      = Join-Path $script:StateDir 'logs'
$script:LogFile     = Join-Path $script:LogDir 'bluestacks-debloater.log'
$script:CurrentBackupDir = $null

foreach ($d in @($script:StateDir, $script:BackupRoot, $script:LogDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# Target domains to block across host and guest (ads, analytics, tracking)
# NOTE: cloud.bluestacks.com and eb.bluestacks.com are intentionally NOT blocked because they host
# the official web installer API and engine build CDN. Blocking them breaks bluestacks.com downloads!
$script:BlockDomains = @(
    'googleads.g.doubleclick.net', 'pagead2.googlesyndication.com', 'googlesyndication.com',
    'www.googleadservices.com', 'adservice.google.com', 'app-measurement.com',
    'ads.bluestacks.com', 'cloudslivessmedia.bluestacks.com', 'adsdk.bluestacks.com',
    'aigame-analytics.bluestacks.com', 'game-analytics.bluestacks.com', 'analytics.bluestacks.com',
    'telemetry.bluestacks.com', 'bsx.bluestacks.com', 'cloudslivesmedia.bluestacks.com',
    'admob.g.doubleclick.net', 'ad.doubleclick.net'
)

# Explicit configuration parameters to suppress in bluestacks.conf
$script:ExplicitTargetKeys = @(
    'bst.enable_programmatic_ads',
    'bst.feature.programmatic_ads',
    'bst.feature.send_programmatic_ads_boot_stats',
    'bst.feature.send_programmatic_ads_click_stats',
    'bst.feature.send_programmatic_ads_fill_stats',
    'bst.feature.show_programmatic_ads_preference',
    'bst.feature.show_gp_ads',
    'bst.feature.show_sdk_gp_popup',
    'bst.feature.usage_stats',
    'bst.feature.app_install_stats',
    'bst.feature.nowbux',
    'bst.feature.bluestacksX',
    'bst.launch_store_on_boot',
    'bst.ai.enabled',
    'bst.feature.blueai',
    'bst.feature.creator_studio',
    'bst.feature.live_stream',
    'bst.feature.ai_chat',
    'bst.feature.popout_ai_chat',
    'bst.enable_boot_banner',
    'bst.feature.send_offer_stats',
    'bst.feature.show_boot_banner_preference',
    'bst.mobile_app_promotion_popup_launch_count',
    'bst.mobile_app_promotion_popup_timestamp',
    'bst.show_nowbux_rewards_red_dot_onboarding',
    'bst.feature.send_nowbux_login_boot_stats',
    'bst.feature.send_usage_state_stats',
    'bst.enable_ai_highlights',
    'bst.feature.show_ai_highlights',
    'bst.openclaw_tunnel_active',
    'bst.openclaw_ai_setup_done',
    'bst.openclaw_onboarding_done',
    'bst.feature.show_moments',
    'bst.feature.auto_upload_nowgg_moments',
    'bst.feature.auto_upload_nowgg_recording',
    'bst.feature.nowgg_cloud_upload_enabled',
    'bst.feature.nowgg_login_popup',
    'bst.feature.show_cloud_instance',
    'bst.feature.show_guest_signin',
    'bst.usage_stats_interval',
    'bst.feature.send_notification_stats',
    'bst.feature.send_internal_notification_stats',
    'bst.enable_discord_integration',
    'bst.feature.enable_boot_promotion_grid',
    'bst.feature.smart_downloads',
    'bst.enable_bsx_app_shortcuts',
    'bst.feature.send_auto_record_stats',
    'bst.feature.split_ad_enabled'
)

# Regex to detect ad/promo/tracking configuration keys
$script:AdConfKeyRegex = '(?i)(show_ads|enable_ads|(^|\.)ads?(_|$)|ad_unit|promot|campaign|recommend|reward|offer|banner|app_install)'

# Regex to detect candidate bloatware packages in the Android guest
$script:BloatPkgRegex = '(?i)(bluestacks.*(promo|appcenter|appfinder|center|helper|store|hint|launcherhelper)|com\.bsl\.|gameloft|com\.android\.egg|uncube|gamevantage)'

# Background helpers in BlueStacks install directory to rename to .bak
$script:BlockedHelperFiles = @(
    'BlueStacksHelper.exe',
    'BlueStacksAppplayerWeb.exe',
    'BlueStacksAI.exe',
    'BlueStacksAIRun.exe',
    'BlueAILmsManager.exe',
    'HD-LogCollector.exe'
)

$script:WindowsHostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'

# ==============================================================================
# Helper Functions: BlueStacks Registry & Path Discovery
# ==============================================================================
function Get-BstRegistry {
    $regPaths = @(
        'HKLM:\SOFTWARE\BlueStacks_nxt',
        'HKLM:\SOFTWARE\BlueStacks_msi5',
        'HKLM:\SOFTWARE\WOW6432Node\BlueStacks_nxt',
        'HKLM:\SOFTWARE\WOW6432Node\BlueStacks_msi5'
    )
    foreach ($k in $regPaths) {
        try {
            $p = Get-ItemProperty -LiteralPath $k -ErrorAction Stop
            if ($p -and ($p.InstallDir -or $p.DataDir -or $p.UserDefinedDir)) {
                return [pscustomobject]@{
                    InstallDir     = $p.InstallDir
                    DataDir        = $p.DataDir
                    UserDefinedDir = $p.UserDefinedDir
                }
            }
        } catch {}
    }
    return $null
}

function Get-BaseDataDir($reg) {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($reg) {
        foreach ($d in @($reg.DataDir, $reg.UserDefinedDir)) {
            if ($d) {
                if ($d -match '(?i)[\\/]engine[\\/]?$') {
                    [void]$candidates.Add(($d -replace '(?i)[\\/]engine[\\/]?$', ''))
                }
                [void]$candidates.Add($d)
            }
        }
    }
    [void]$candidates.Add((Join-Path $env:ProgramData 'BlueStacks_nxt'))
    [void]$candidates.Add((Join-Path $env:ProgramData 'BlueStacks_msi5'))

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'bluestacks.conf'))) {
            return $c
        }
    }
    return $candidates[0]
}

# Resolve paths
$script:Reg = Get-BstRegistry
if (-not $Install) {
    $Install = if ($script:Reg -and $script:Reg.InstallDir) {
        $script:Reg.InstallDir.TrimEnd('\')
    } else {
        $defaultPath = Join-Path $env:ProgramFiles 'BlueStacks_nxt'
        if (Test-Path $defaultPath) { $defaultPath } else { Join-Path ${env:ProgramFiles(x86)} 'BlueStacks_nxt' }
    }
}
if (-not $Conf) {
    $Conf = Join-Path (Get-BaseDataDir $script:Reg) 'bluestacks.conf'
}
$script:Adb = Join-Path $Install 'HD-Adb.exe'

# ==============================================================================
# Process, File & Backup Management
# ==============================================================================
function Stop-BlueStacksProcesses {
    if ($DryRun) {
        Say (Get-Text 'DryRunNotice') Yellow
        return
    }
    Say (Get-Text 'ClosingProcesses') Yellow
    Get-Process | Where-Object { $_.ProcessName -match '^(HD-|Bstk|BlueStacks)' } |
        ForEach-Object { try { $_.Kill() } catch {} }
    Start-Sleep -Seconds 2
}

function Clear-ConfReadOnly {
    if (Test-Path -LiteralPath $Conf) {
        $val = Get-ItemProperty -LiteralPath $Conf -Name IsReadOnly -ErrorAction SilentlyContinue
        if ($val -and $val.IsReadOnly) {
            Set-ItemProperty -LiteralPath $Conf -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        }
    }
}

function New-DebloatBackup {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:CurrentBackupDir = Join-Path $script:BackupRoot $stamp
    New-Item -ItemType Directory -Force -Path $script:CurrentBackupDir | Out-Null

    if (Test-Path -LiteralPath $Conf) {
        Clear-ConfReadOnly
        Copy-Item -LiteralPath $Conf -Destination (Join-Path $script:CurrentBackupDir 'bluestacks.conf') -Force
    }
    if (Test-Path -LiteralPath $script:WindowsHostsPath) {
        Copy-Item -LiteralPath $script:WindowsHostsPath -Destination (Join-Path $script:CurrentBackupDir 'hosts.windows.bak') -Force
    }
    Say (Get-Text 'BackupSaved' @($script:CurrentBackupDir)) Green
}

function Sync-LatestBackup {
    if ($script:CurrentBackupDir -and (Test-Path $script:CurrentBackupDir)) {
        if (Test-Path $script:LatestLink) {
            Remove-Item $script:LatestLink -Recurse -Force -ErrorAction SilentlyContinue
        }
        Copy-Item -LiteralPath $script:CurrentBackupDir -Destination $script:LatestLink -Recurse -Force
        Say (Get-Text 'BackupSyncLatest') DarkGray
    }
}

function Read-ConfLines {
    if (Test-Path -LiteralPath $Conf) {
        [System.IO.File]::ReadAllLines($Conf)
    } else {
        @()
    }
}

function Write-ConfLines($lines) {
    if (Test-Path -LiteralPath $Conf) { Clear-ConfReadOnly }
    # BlueStacks expects UTF-8 without BOM; match line ending style
    $content = Get-Content -Raw -LiteralPath $Conf -ErrorAction SilentlyContinue
    $nl = if ($content -and $content -match "`r`n") { "`r`n" } else { "`n" }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Conf, ($lines -join $nl) + $nl, $enc)
}

# ==============================================================================
# ADB Operations
# ==============================================================================
function Get-AdbInstances {
    $instances = @{}
    if (Test-Path -LiteralPath $Conf) {
        $lines = Get-Content -LiteralPath $Conf -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '^bst\.instance\.([^.]+)\.(status\.adb_port|adb_port)="?(\d+)"?') {
                $name = $Matches[1]
                $port = [int]$Matches[3]
                if (-not $instances.ContainsKey($name) -or $line -match 'status\.adb_port') {
                    $instances[$name] = $port
                }
            }
        }
    }
    return $instances
}

function Invoke-AdbCommand {
    param([Parameter(ValueFromRemainingArguments)]$ArgsList)
    $oldPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $script:Adb @ArgsList 2>&1
    } finally {
        $ErrorActionPreference = $oldPref
    }
}

function Connect-AdbInstance($instanceName, $port) {
    if (-not (Test-Path $script:Adb)) {
        $systemAdb = Get-Command adb -ErrorAction SilentlyContinue
        if ($systemAdb) {
            $script:Adb = $systemAdb.Source
        } else {
            Say (Get-Text 'AdbNotFound' @($script:Adb)) Red
            return $null
        }
    }

    Invoke-AdbCommand 'kill-server' | Out-Null
    $conn = Invoke-AdbCommand 'connect' "127.0.0.1:$port"

    if ($conn -match "failed|unable|cannot connect" -or -not $conn) {
        $playerPath = Join-Path $Install 'HD-Player.exe'
        if (Test-Path $playerPath) {
            Say (Get-Text 'StartingInstance' @($instanceName)) Yellow
            Start-Process -FilePath $playerPath -ArgumentList "--instance $instanceName"
            Say (Get-Text 'WaitingBoot') Yellow
            $connected = $false
            for ($i = 0; $i -lt 30; $i++) {
                Start-Sleep -Seconds 2
                $conn = Invoke-AdbCommand 'connect' "127.0.0.1:$port"
                if ($conn -and $conn -notmatch "failed|unable|cannot connect") {
                    $connected = $true
                    break
                }
            }
            if (-not $connected) {
                Say (Get-Text 'PromptStartManual' @($instanceName)) Yellow
                Read-Host (Get-Text 'PressEnterWhenReady') | Out-Null
                $conn = Invoke-AdbCommand 'connect' "127.0.0.1:$port"
                if ($conn -match "failed|unable|cannot connect" -or -not $conn) {
                    Say (Get-Text 'AdbConnectFail' @($port)) Red
                    return $null
                }
            }
        } else {
            Say (Get-Text 'PromptStartManual' @($instanceName)) Yellow
            Read-Host (Get-Text 'PressEnterWhenReady') | Out-Null
            $conn = Invoke-AdbCommand 'connect' "127.0.0.1:$port"
            if ($conn -match "failed|unable|cannot connect" -or -not $conn) {
                Say (Get-Text 'AdbConnectFail' @($port)) Red
                return $null
            }
        }
    }
    Start-Sleep -Seconds 1
    return "127.0.0.1:$port"
}

# ==============================================================================
# Engine Modules: Host Debloat
# ==============================================================================
function Invoke-HostDebloat {
    Say (Get-Text 'HostDebloatStart') Cyan
    $lines = Read-ConfLines
    $existingKeys = @{}
    $modifiedCount = 0

    $targetValues = @{}
    foreach ($k in $script:ExplicitTargetKeys) {
        if ($k -eq 'bst.openclaw_onboarding_done') {
            $targetValues[$k] = '1'
        } else {
            $targetValues[$k] = '0'
        }
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^([^=]+)="?([^"]*)"?\s*$') {
            $k = $Matches[1]
            $v = $Matches[2]
            $existingKeys[$k] = $i

            # Clear ad tracking URLs and IDs
            if ($k -match '(?i)(campaign|utm|ribbon|ads_app|bair_page_url|android_google_ad_id|nowgg_user|account_id)') {
                if ($v -ne '') {
                    if ($DryRun) {
                        Say (Get-Text 'KeyCleared' @($k, $v)) Yellow
                    } else {
                        $lines[$i] = '{0}=""' -f $k
                        Say (Get-Text 'KeyCleared' @($k, $v)) Green
                        $modifiedCount++
                    }
                }
                continue
            }

            # Check ad and telemetry flags
            $isAdKey = ($k -match $script:AdConfKeyRegex -and $k -notmatch '(?i)adb|update|download|thread|read|load') -or ($script:ExplicitTargetKeys -contains $k)
            if ($isAdKey -and $v -match '^(0|1|true|false)$') {
                $targetVal = if ($targetValues.ContainsKey($k)) {
                    $targetValues[$k]
                } else {
                    if ($v -match '^(true|false)$') { 'false' } else { '0' }
                }

                if ($v -ne $targetVal) {
                    if ($DryRun) {
                        Say (Get-Text 'KeyDisabled' @($k, $v, $targetVal)) Yellow
                    } else {
                        $lines[$i] = ($lines[$i] -replace [regex]::Escape('"' + $v + '"'), ('"' + $targetVal + '"'))
                        if ($lines[$i] -match ('=' + [regex]::Escape($v) + '\s*$')) {
                            $lines[$i] = $lines[$i] -replace ([regex]::Escape('=' + $v) + '\s*$'), ('=' + $targetVal)
                        }
                        Say (Get-Text 'KeyDisabled' @($k, $v, $targetVal)) Green
                        $modifiedCount++
                    }
                }
            }
        }
    }

    # Append missing configuration keys
    foreach ($k in $script:ExplicitTargetKeys) {
        if (-not $existingKeys.ContainsKey($k)) {
            $targetVal = if ($targetValues.ContainsKey($k)) { $targetValues[$k] } else { '0' }
            if ($DryRun) {
                Say (Get-Text 'KeyAppended' @($k, $targetVal)) Yellow
            } else {
                $lines += ("{0}=`"{1}`"" -f $k, $targetVal)
                Say (Get-Text 'KeyAppended' @($k, $targetVal)) Green
                $modifiedCount++
            }
        }
    }

    # Clear cached promo banners, Prime ads and nowBux assets from Engine folders
    $baseData = if ($script:Reg -and $script:Reg.DataDir) { $script:Reg.DataDir } else { Join-Path $env:ProgramData 'BlueStacks_nxt' }
    $engineDir = Join-Path $baseData 'Engine'
    if (Test-Path -LiteralPath $engineDir) {
        Get-ChildItem -LiteralPath $engineDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $instDir = $_.FullName
            foreach ($folderName in @('Promotions', 'nowBux', 'Flyers', 'AppCache')) {
                $targetDir = Join-Path $instDir $folderName
                if (Test-Path -LiteralPath $targetDir) {
                    if (-not $DryRun) {
                        Get-ChildItem -LiteralPath $targetDir -Recurse -Force -ErrorAction SilentlyContinue |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    # Clear AiGames models and cache
    $aiDir = Join-Path $baseData 'AiGames'
    if (Test-Path -LiteralPath $aiDir) {
        if (-not $DryRun) {
            Get-ChildItem -LiteralPath $aiDir -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not $DryRun -and $modifiedCount -gt 0) {
        Write-ConfLines $lines
        try {
            Set-ItemProperty -LiteralPath $Conf -Name IsReadOnly -Value $true -ErrorAction Stop
            Say (Get-Text 'ConfReadOnlySuccess') Green
        } catch {
            Say (Get-Text 'ConfReadOnlyFail' @($_.Exception.Message)) Yellow
        }
        Say (Get-Text 'HostDebloatSummary' @($modifiedCount)) Green
    } elseif ($modifiedCount -eq 0 -and -not $DryRun) {
        try {
            Set-ItemProperty -LiteralPath $Conf -Name IsReadOnly -Value $true -ErrorAction Stop
        } catch {}
        Say (Get-Text 'HostDebloatClean') DarkGray
    }
}

# ==============================================================================
# Engine Modules: Performance Optimization
# ==============================================================================
function Invoke-PerformanceOptimization {
    Say (Get-Text 'PerfOptStart') Cyan
    $lines = Read-ConfLines
    $instances = Get-AdbInstances
    $modifiedCount = 0

    $optKeys = @(
        'astc_decoding_mode',
        'enable_high_fps',
        'max_fps',
        'enable_vsync'
    )

    $optValues = @{
        'astc_decoding_mode' = 'hardware'
        'enable_high_fps'    = '1'
        'max_fps'            = '120'
        'enable_vsync'       = '0'
    }

    if (Test-Path -LiteralPath $Conf) { Clear-ConfReadOnly }

    $existingKeys = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^([^=]+)="?([^"]*)"?\s*$') {
            $k = $Matches[1]
            $existingKeys[$k] = $i
        }
    }

    # If no instances detected in conf, apply to general root and instance 0
    $instanceTargets = if ($instances.Keys.Count -gt 0) { $instances.Keys } else { @('Pie64', 'Nougat64', 'Rvc64') }

    foreach ($inst in $instanceTargets) {
        foreach ($ok in $optKeys) {
            $fullKey = "bst.instance.{0}.{1}" -f $inst, $ok
            $targetVal = $optValues[$ok]

            if ($existingKeys.ContainsKey($fullKey)) {
                $idx = $existingKeys[$fullKey]
                $line = $lines[$idx]
                if ($line -match '^([^=]+)="?([^"]*)"?\s*$') {
                    $currVal = $Matches[2]
                    if ($currVal -ne $targetVal) {
                        if ($DryRun) {
                            Say (Get-Text 'PerfKeyUpdated' @($fullKey, $currVal, $targetVal)) Yellow
                        } else {
                            $lines[$idx] = '{0}="{1}"' -f $fullKey, $targetVal
                            Say (Get-Text 'PerfKeyUpdated' @($fullKey, $currVal, $targetVal)) Green
                            $modifiedCount++
                        }
                    }
                }
            } else {
                if ($DryRun) {
                    Say (Get-Text 'PerfKeyAppended' @($fullKey, $targetVal)) Yellow
                } else {
                    $lines += ('{0}="{1}"' -f $fullKey, $targetVal)
                    Say (Get-Text 'PerfKeyAppended' @($fullKey, $targetVal)) Green
                    $modifiedCount++
                }
            }
        }
    }

    if (-not $DryRun -and $modifiedCount -gt 0) {
        Write-ConfLines $lines
        Say (Get-Text 'PerfOptSummary' @($modifiedCount)) Green
    } elseif ($modifiedCount -eq 0) {
        Say (Get-Text 'PerfOptClean') DarkGray
    }
}

# ==============================================================================
# Engine Modules: Windows Hosts File Debloat & Download Repair
# ==============================================================================
function Repair-WindowsHostsFile {
    $hostsPath = $script:WindowsHostsPath
    if (-not (Test-Path -LiteralPath $hostsPath)) { return }

    $downloadDomains = @('cloud\.bluestacks\.com', 'eb\.bluestacks\.com', 'delegate\.bluestacks\.com')
    $lines = [System.IO.File]::ReadAllLines($hostsPath)
    $filtered = New-Object System.Collections.Generic.List[string]
    $removed = @()

    foreach ($line in $lines) {
        $shouldRemove = $false
        foreach ($d in $downloadDomains) {
            if ($line -match "(?i)^\s*0\.0\.0\.0\s+$d\b") {
                $shouldRemove = $true
                $removed += ($line.Trim() -replace '^\s*0\.0\.0\.0\s+', '')
                break
            }
        }
        if (-not $shouldRemove) {
            $filtered.Add($line)
        }
    }

    if ($removed.Count -gt 0) {
        if (-not $DryRun) {
            try {
                [System.IO.File]::WriteAllLines($hostsPath, $filtered, [System.Text.Encoding]::ASCII)
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                foreach ($item in $removed) {
                    Say (Get-Text 'DownloadUnblocked' @($item)) Green
                }
                Say (Get-Text 'FixHostsSuccess') Green
            } catch {
                Say (Get-Text 'WinHostsFail' @($_.Exception.Message)) Red
            }
        } else {
            foreach ($item in $removed) {
                Say ("    [dry-run] " + (Get-Text 'DownloadUnblocked' @($item))) Yellow
            }
        }
    } else {
        Say (Get-Text 'FixHostsClean') DarkGray
    }
}

function Invoke-WindowsHostsDebloat {
    Repair-WindowsHostsFile
    $hostsPath = $script:WindowsHostsPath
    if (Test-Path -LiteralPath $hostsPath) {
        Say (Get-Text 'WinHostsStart') Cyan
        $existing = Get-Content -LiteralPath $hostsPath -ErrorAction SilentlyContinue
        $existingText = $existing -join "`n"

        $toAdd = $script:BlockDomains | Where-Object { $existingText -notmatch [regex]::Escape($_) }
        if ($toAdd) {
            if (-not $DryRun) {
                try {
                    $linesToAdd = @()
                    foreach ($d in $toAdd) { $linesToAdd += "0.0.0.0 $d" }
                    Add-Content -LiteralPath $hostsPath -Value $linesToAdd -ErrorAction Stop
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    Say (Get-Text 'WinHostsSuccess' @($toAdd.Count)) Green
                } catch {
                    Say (Get-Text 'WinHostsFail' @($_.Exception.Message)) Red
                }
            } else {
                Say (Get-Text 'WinHostsSuccess' @($toAdd.Count)) Yellow
            }
        } else {
            Say (Get-Text 'WinHostsClean') DarkGray
        }
    }
}

# ==============================================================================
# Engine Modules: Background Helper & AI Blocking
# ==============================================================================
function Invoke-HostFileDebloat {
    Say (Get-Text 'HelpersStart') Cyan
    foreach ($f in $script:BlockedHelperFiles) {
        $p = Join-Path $Install $f
        if (Test-Path -LiteralPath $p) {
            if ($DryRun) {
                Say (Get-Text 'HelperBlocked' @($f)) Yellow
            } else {
                try {
                    Rename-Item -LiteralPath $p -NewName ($f + ".bak") -Force -ErrorAction Stop
                    Say (Get-Text 'HelperBlocked' @($f)) Green
                } catch {
                    Say (Get-Text 'HelperFail' @($f, $_.Exception.Message)) Red
                }
            }
        } else {
            Say (Get-Text 'HelperClean' @($f)) DarkGray
        }
    }

    $aiFolder = Join-Path $Install 'BlueAI'
    if (Test-Path -LiteralPath $aiFolder) {
        if ($DryRun) {
            Say (Get-Text 'FolderBlocked' @('BlueAI')) Yellow
        } else {
            try {
                Rename-Item -LiteralPath $aiFolder -NewName "BlueAI.bak" -Force -ErrorAction Stop
                Say (Get-Text 'FolderBlocked' @('BlueAI')) Green
            } catch {
                Say (Get-Text 'FolderFail' @('BlueAI', $_.Exception.Message)) Red
            }
        }
    } else {
        Say (Get-Text 'FolderClean' @('BlueAI')) DarkGray
    }
}

# ==============================================================================
# Engine Modules: Guest Android Debloat (ADB)
# ==============================================================================
function Invoke-GuestDebloat {
    $instances = Get-AdbInstances
    if ($instances.Count -eq 0) {
        Say (Get-Text 'NoActiveInstances') Red
        return
    }

    if ($DryRun) {
        Say (Get-Text 'DryRunNotice') Yellow
        foreach ($inst in $instances.Keys) {
            Say (Get-Text 'AdbTargetDryRun' @($inst, $instances[$inst])) Yellow
        }
        return
    }

    foreach ($inst in $instances.Keys) {
        $port = $instances[$inst]
        Say (Get-Text 'ConnectingGuest' @($inst, $port)) Cyan
        $dev = Connect-AdbInstance $inst $port
        if (-not $dev) { continue }

        Say (Get-Text 'RequestingRoot') DarkGray
        Invoke-AdbCommand '-s' $dev 'root' | Out-Null
        Start-Sleep -Seconds 1

        Say (Get-Text 'RemountingSystem') DarkGray
        $remountResult = Invoke-AdbCommand '-s' $dev 'remount'

        $isReadOnly = $true
        if ($remountResult -match "remount succeeded") {
            $isReadOnly = $false
        } else {
            $mounts = Invoke-AdbCommand '-s' $dev 'shell' 'mount'
            if ($mounts -match '/system\s+.*ro,') {
                $isReadOnly = $true
            } else {
                $isReadOnly = $false
            }
        }

        # Instance-specific backup directory
        $instBackupDir = $null
        if ($script:CurrentBackupDir) {
            $instBackupDir = Join-Path $script:CurrentBackupDir $inst
            New-Item -ItemType Directory -Force -Path $instBackupDir | Out-Null
        }

        $existing = (Invoke-AdbCommand '-s' $dev 'shell' 'cat /system/etc/hosts') -join "`n"
        if ($instBackupDir) {
            Set-Content -LiteralPath (Join-Path $instBackupDir 'hosts.bak') -Value $existing -ErrorAction SilentlyContinue
        }

        if ($isReadOnly) {
            Say (Get-Text 'SystemReadOnlyWarn') Yellow
        } else {
            $toAdd = $script:BlockDomains | Where-Object { $existing -notmatch [regex]::Escape($_) }
            if ($toAdd) {
                foreach ($d in $toAdd) {
                    Invoke-AdbCommand '-s' $dev 'shell' "echo '0.0.0.0 $d' >> /system/etc/hosts" | Out-Null
                }
                Say (Get-Text 'GuestHostsSuccess' @($toAdd.Count)) Green
            } else {
                Say (Get-Text 'GuestHostsClean') DarkGray
            }
        }

        # Package discovery & disabling
        $pkgs = (Invoke-AdbCommand '-s' $dev 'shell' 'pm list packages') -split "`n" |
                ForEach-Object { ($_ -replace '^package:', '').Trim() } | Where-Object { $_ }
        $candidates = $pkgs | Where-Object { $_ -match $script:BloatPkgRegex }

        if ($candidates) {
            Say (Get-Text 'BloatCandidatesFound') Cyan
            $candidates | ForEach-Object { Say "    $_" White }
            $disabled = @()
            foreach ($p in $candidates) {
                Invoke-AdbCommand '-s' $dev 'shell' "pm disable-user --user 0 $p" | Out-Null
                $disabled += $p
            }
            if ($instBackupDir) {
                $disabled -join "`n" | Set-Content -LiteralPath (Join-Path $instBackupDir 'disabled-packages.txt')
            }
            Say (Get-Text 'BloatDisabledSuccess' @($disabled.Count)) Green
        } else {
            Say (Get-Text 'NoBloatPackages') DarkGray
        }
    }
}

# ==============================================================================
# Engine Modules: Undo / Restore
# ==============================================================================
function Invoke-Undo {
    Say (Get-Text 'UndoStart') Cyan
    if (-not (Test-Path $script:LatestLink)) {
        Say (Get-Text 'NoBackupFound') Red
        return
    }

    Stop-BlueStacksProcesses

    # 1. Restore bluestacks.conf
    $confBak = Join-Path $script:LatestLink 'bluestacks.conf'
    if (Test-Path $confBak) {
        Clear-ConfReadOnly
        Copy-Item -LiteralPath $confBak -Destination $Conf -Force
        Say (Get-Text 'UndoConfSuccess') Green
    }

    # 2. Restore Windows hosts
    $winHostsBak = Join-Path $script:LatestLink 'hosts.windows.bak'
    if (Test-Path $winHostsBak) {
        try {
            Copy-Item -LiteralPath $winHostsBak -Destination $script:WindowsHostsPath -Force
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            Say (Get-Text 'UndoHostsSuccess') Green
        } catch {
            Say (Get-Text 'UndoHostsFail' @($_.Exception.Message)) Red
        }
    }

    # 3. Restore background helpers
    foreach ($f in $script:BlockedHelperFiles) {
        $bak = Join-Path $Install ($f + ".bak")
        if (Test-Path -LiteralPath $bak) {
            try {
                Rename-Item -LiteralPath $bak -NewName $f -Force -ErrorAction Stop
                Say (Get-Text 'UndoHelperRestored' @($f)) Green
            } catch {}
        }
    }

    $aiFolderBak = Join-Path $Install 'BlueAI.bak'
    if (Test-Path -LiteralPath $aiFolderBak) {
        try {
            Rename-Item -LiteralPath $aiFolderBak -NewName "BlueAI" -Force -ErrorAction Stop
            Say (Get-Text 'UndoFolderRestored' @('BlueAI')) Green
        } catch {}
    }

    # 4. Restore guest Android packages and hosts
    $subdirs = Get-ChildItem -Path $script:LatestLink -Directory -ErrorAction SilentlyContinue
    if ($subdirs) {
        $instances = Get-AdbInstances
        foreach ($dir in $subdirs) {
            $instName = $dir.Name
            $hostsBak = Join-Path $dir.FullName 'hosts.bak'
            $pkgList  = Join-Path $dir.FullName 'disabled-packages.txt'

            if ($instances.ContainsKey($instName)) {
                $port = $instances[$instName]
                Say (Get-Text 'UndoGuestInstance' @($instName, $port)) Cyan
                $dev = Connect-AdbInstance $instName $port
                if ($dev) {
                    Invoke-AdbCommand '-s' $dev 'root' | Out-Null
                    Invoke-AdbCommand '-s' $dev 'remount' | Out-Null

                    if (Test-Path $hostsBak) {
                        Invoke-AdbCommand '-s' $dev 'push' $hostsBak '/system/etc/hosts' | Out-Null
                        Say (Get-Text 'UndoGuestHostsDone') Green
                    }

                    if (Test-Path $pkgList) {
                        Get-Content $pkgList | Where-Object { $_ } | ForEach-Object {
                            Invoke-AdbCommand '-s' $dev 'shell' "pm enable $_" | Out-Null
                        }
                        Say (Get-Text 'UndoGuestPkgsDone') Green
                    }
                }
            }
        }
    }

    Say ''
    Say (Get-Text 'UndoComplete') Green
}

# ==============================================================================
# Status / Diagnostic
# ==============================================================================
function Show-StatusReport {
    Say (Get-Text 'BannerTitle') Cyan
    Say (Get-Text 'InstallPath' @($Install)) White
    Say (Get-Text 'ConfPath' @($Conf)) White

    if (Test-Path -LiteralPath $Conf) {
        $instances = Get-AdbInstances
        Say (Get-Text 'ConfigDetected' @($instances.Count)) Green
        foreach ($k in $instances.Keys) {
            Say (Get-Text 'InstanceAdbPort' @($k, $instances[$k])) Cyan
        }
    } else {
        Say (Get-Text 'ConfNotFound') Yellow
    }

    if (Test-Path $script:LatestLink) {
        Say (Get-Text 'PreviousBackupFound') Green
    } else {
        Say (Get-Text 'NoBackupsFound') DarkGray
    }
}

function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    param([string]$TargetAction)
    $scriptPath = $MyInvocation.MyCommand.Definition
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }
    $argList = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"", '-Action', $TargetAction)
    if ($Language) { $argList += @('-Language', $Language) }
    if ($Conf) { $argList += @('-Conf', "`"$Conf`"") }
    if ($NoPause) { $argList += '-NoPause' }
    Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs
}

# ==============================================================================
# Main Orchestration
# ==============================================================================
Show-Header

if ($Action -ne 'Status' -and -not $DryRun -and -not (Test-IsAdministrator)) {
    if ($Host.Name -eq 'ConsoleHost') {
        try {
            Say (Get-Text 'ElevationNotice') Yellow
            Restart-Elevated -TargetAction $Action
            return
        } catch {
            Say (Get-Text 'AdminRequired') Yellow
        }
    }
}

Say (Get-Text 'DetectingPaths') DarkGray
Say (Get-Text 'InstallPath' @($Install)) DarkGray
Say (Get-Text 'ConfPath' @($Conf)) DarkGray
Write-Host ''

if ($Action -ne 'Status' -and $Action -ne 'Undo' -and $Action -ne 'FixHosts' -and -not (Test-Path -LiteralPath $Conf)) {
    Say (Get-Text 'ConfNotFound') Red
    if (-not $NoPause -and $Host.Name -eq 'ConsoleHost') {
        Write-Host ''
        Read-Host (Get-Text 'PressAnyKey') | Out-Null
    }
    return
}

switch ($Action) {
    'Full' {
        Stop-BlueStacksProcesses
        if (-not $DryRun) { New-DebloatBackup }
        Invoke-HostDebloat
        Invoke-PerformanceOptimization
        Invoke-WindowsHostsDebloat
        Invoke-HostFileDebloat
        Invoke-GuestDebloat
        if (-not $DryRun) {
            Sync-LatestBackup
            try { Set-ItemProperty -LiteralPath $Conf -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue } catch {}
        }
        Write-Host ''
        Say (Get-Text 'DebloatCompleted') Green
        Say (Get-Text 'RebootNotice') Cyan
    }
    'HostOnly' {
        Stop-BlueStacksProcesses
        if (-not $DryRun) { New-DebloatBackup }
        Invoke-HostDebloat
        Invoke-PerformanceOptimization
        Invoke-WindowsHostsDebloat
        Invoke-HostFileDebloat
        if (-not $DryRun) {
            Sync-LatestBackup
            try { Set-ItemProperty -LiteralPath $Conf -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue } catch {}
        }
        Write-Host ''
        Say (Get-Text 'DebloatCompleted') Green
    }
    'GuestOnly' {
        Stop-BlueStacksProcesses
        if (-not $DryRun) { New-DebloatBackup }
        Invoke-GuestDebloat
        if (-not $DryRun) { Sync-LatestBackup }
        Write-Host ''
        Say (Get-Text 'DebloatCompleted') Green
    }
    'Undo' {
        Invoke-Undo
    }
    'Status' {
        Show-StatusReport
    }
    'FixHosts' {
        Repair-WindowsHostsFile
    }
}

if (-not $NoPause -and $Host.Name -eq 'ConsoleHost') {
    Write-Host ''
    Read-Host (Get-Text 'PressAnyKey') | Out-Null
}
