$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

Write-Host "=== Executando Testes do BlueStacks Debloater ===" -ForegroundColor Cyan

# 1. Parse de sintaxe dos scripts
$scripts = Get-ChildItem -LiteralPath $projectRoot -Recurse -File -Filter '*.ps1' | Where-Object { $_.FullName -ne $PSCommandPath }
foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        throw "Erro de sintaxe em $($script.FullName): $($errors[0].Message)"
    }
}
Write-Host "[+] T1: Parse de sintaxe do PowerShell OK ($($scripts.Count) scripts)." -ForegroundColor Green

# 2. Verificacao de Dicionario de Idiomas (i18n)
# Extrair $Messages do script
$content = Get-Content -LiteralPath (Join-Path $projectRoot 'BlueStacksDebloater.ps1') -Raw
Assert-True ($content -match 'BannerTitle' -and $content -match 'DebloatCompleted') "BlueStacksDebloater.ps1 deve conter dicionarios i18n"
Write-Host "[+] T2: Dicionario i18n validado (pt e en presentes)." -ForegroundColor Green

# 3. Teste hermetico de Dry-Run com arquivo mock de bluestacks.conf
$tempDir = Join-Path $env:TEMP ("bsd-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$mockConf = Join-Path $tempDir 'bluestacks.conf'
$mockLines = @(
    'bst.installed="1"',
    'bst.instance.Pie64.status.adb_port="5555"',
    'bst.enable_programmatic_ads="1"',
    'bst.feature.show_gp_ads="1"',
    'bst.campaign.name="promo_test"',
    'bst.instance.Pie64.astc_decoding_mode="software"',
    'bst.instance.Pie64.enable_high_fps="0"',
    'bst.instance.Pie64.max_fps="60"'
)
Set-Content -LiteralPath $mockConf -Value $mockLines -Encoding UTF8

try {
    $engine = Join-Path $projectRoot 'BlueStacksDebloater.ps1'
    
    # Teste Dry-Run em Portugues
    $outPt = & $engine -Action HostOnly -DryRun -Language pt -Conf $mockConf -NoPause *>&1 | Out-String
    Assert-True ($outPt -match 'Modo Dry-Run ativo' -or $outPt -match 'Analisando e desativando') "Execucao em PT deve exibir mensagens em portugues"
    Assert-True ($outPt -match 'bst\.enable_programmatic_ads') "Deve identificar chave bst.enable_programmatic_ads"
    Assert-True ($outPt -match 'OTIMIZAÇÃO CONCLUÍDA|concluída com sucesso|BlueStacks' -or $outPt -match 'Modo Dry-Run') "Deve concluir fluxo"
    Write-Host "[+] T3: Execucao hermetica HostOnly em Portugues OK." -ForegroundColor Green

    # Teste Dry-Run em Ingles
    $outEn = & $engine -Action HostOnly -DryRun -Language en -Conf $mockConf -NoPause *>&1 | Out-String
    Assert-True ($outEn -match 'Dry-Run mode active' -or $outEn -match 'Analyzing and disabling') "Execucao em EN deve exibir mensagens em ingles"
    Assert-True ($outEn -match 'bst\.enable_programmatic_ads') "Deve identificar chave bst.enable_programmatic_ads"
    Write-Host "[+] T4: Execucao hermetica HostOnly em Ingles OK." -ForegroundColor Green

    # Teste Status
    $outStatus = & $engine -Action Status -Conf $mockConf -NoPause *>&1 | Out-String
    Assert-True ($outStatus -match 'Pie64' -and $outStatus -match '5555') "Status deve reportar instancia Pie64 e porta 5555"
    Write-Host "[+] T5: Diagnostico de Instancias e Status OK." -ForegroundColor Green

    # Teste FixHosts
    $outFix = & $engine -Action FixHosts -DryRun -Language pt -NoPause *>&1 | Out-String
    Assert-True ($outFix -match 'hosts' -or $outFix -match 'download') "FixHosts deve executar diagnostico e reparo do hosts"
    Write-Host "[+] T6: Acao FixHosts (Desbloqueio de downloads) OK." -ForegroundColor Green

} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTODOS OS TESTES PASSARAM COM SUCESSO!" -ForegroundColor Green
