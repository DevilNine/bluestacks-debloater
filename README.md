# BlueStacks Debloater & Optimizer

[Português](#português) | [English](#english)

---

<a name="português"></a>
## Português

Ferramenta autocontida para remoção de anúncios, bloqueio de telemetria e otimização de desempenho gráfico para **BlueStacks 5** e **MSI App Player** no Windows.

Projetada para funcionar de forma direta e sem atritos: para a maioria dos usuários, basta executar o inicializador em lote (`.bat`), que solicita automaticamente elevação de privilégios de Administrador e realiza todo o processo de forma autônoma.

### Principais Recursos

- **Execução em 1 Clique (`iniciar.bat`):** Auto-elevação via UAC para Administrador, detecção do idioma do sistema e aplicação automática de todas as otimizações.
- **Remoção de Anúncios e Banners (Host):**
  - Desativação de chaves de propaganda programática, pop-ups promocionais, banners de boot, NowBux e BlueStacks X em `bluestacks.conf`.
  - Limpeza de identificadores de campanha, IDs de rastreamento UTM e URLs de promoção.
  - Bloqueio do arquivo `bluestacks.conf` como Somente-Leitura para evitar que o emulador reescreva os anúncios ao reiniciar.
- **Otimização de Desempenho e FPS:**
  - Desbloqueio da taxa de quadros para **120 FPS** (`enable_high_fps="1"`, `max_fps="120"`).
  - Ativação de decodificação de texturas ASTC por hardware (`astc_decoding_mode="hardware"`).
  - Desativação de V-Sync interno para redução de input lag (`enable_vsync="0"`).
- **Bloqueio de Rede (Hosts Windows e Android):**
  - Redirecionamento de domínios de publicidade, analytics e telemetria da BlueStacks e Google Ads para `0.0.0.0`.
  - **Preservação de Downloads Oficiais:** os domínios de download e entrega de instaladores (`cloud.bluestacks.com` e `eb.bluestacks.com`) são mantidos 100% liberados, garantindo que o usuário possa baixar o BlueStacks pelo site oficial e atualizar instâncias sem erros de servidor.
  - Limpeza automática do cache DNS local (`Clear-DnsClientCache`).
  - Atualização do arquivo `/system/etc/hosts` na instância Android quando montável como gravação.
- **Bloqueio de Processos Auxiliares em Segundo Plano:**
  - Renomeação de executáveis desnecessários para extensão `.bak` (`BlueStacksHelper.exe`, `BlueStacksAI.exe`, `BlueStacksAIRun.exe`, `BlueAILmsManager.exe`, `HD-LogCollector.exe` e pasta `BlueAI`).
- **Desativação de Bloatwares no Android (ADB):**
  - Conexão automática via ADB local (`HD-Adb.exe` ou `adb` no PATH).
  - Identificação de pacotes promocionais e aplicativos pré-instalados desnecessários (Game Center, App Finder, promoções de terceiros).
  - Desativação segura via `pm disable-user --user 0` (sem desinstalação agressiva, preservando a estabilidade da ROM).
- **Backup Automático e Restauração Segura (`restaurar.bat`):**
  - Backup completo com registro de data/hora salvo em `state/backups/bluestacks/` antes de qualquer alteração.
  - Reversão de todas as configurações, arquivos modificados e pacotes do Android com um clique.

### Como Usar

#### Modo Simplificado (Recomendado para usuários finais)
1. Certifique-se de que o BlueStacks já foi aberto pelo menos uma vez no computador.
2. Feche o BlueStacks por completo.
3. Dê dois cliques no arquivo **`iniciar.bat`**.
4. Confirme a permissão de Administrador quando solicitado.
5. Aguarde a finalização do processo e a mensagem de conclusão.

#### Modo de Restauração (Rollback)
- Dê dois cliques em **`restaurar.bat`** para restaurar a cópia de segurança mais recente (`bluestacks.conf`, hosts do Windows e reativar pacotes do Android).

#### Desbloqueio Rápido de Downloads do Site Oficial
- Se você já teve o site do BlueStacks bloqueado por versões antigas ou scripts externos, dê dois cliques em **`desbloquear-downloads.bat`**. Ele remove automaticamente qualquer bloqueio aos servidores de download (`cloud.bluestacks.com` / `eb.bluestacks.com`) e limpa o cache DNS.

#### Modo Avançado / Menu Interativo
- Dê dois cliques em **`menu.bat`** para escolher entre:
  - `[1]` Debloat Completo
  - `[2]` Apenas Host (Configurações, Hosts Windows e Helpers)
  - `[3]` Apenas Guest Android (ADB, Hosts Interno e Bloatwares)
  - `[4]` Prévia / Simulação (Dry-Run sem alterações)
  - `[5]` Diagnóstico de Instâncias e Portas ADB
  - `[6]` Restaurar Backup Anterior
  - `[7]` Desbloquear Downloads Oficiais

#### Automação via Linha de Comando (PowerShell)
```powershell
# Execução completa em modo silencioso
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Full -NoPause

# Apenas simulação (Dry-Run) em inglês ou português
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Full -DryRun -Language pt
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Full -DryRun -Language en

# Somente modificações no Windows (Host)
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action HostOnly

# Diagnóstico de instâncias
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Status
```

### Requisitos e Compatibilidade
- **Sistema Operacional:** Windows 10 ou Windows 11 (64-bit).
- **Emulador Suportado:** BlueStacks 5.x (todas as versões recentes de 64-bit) e MSI App Player.
- **Privilégios:** Acesso de Administrador (solicitado automaticamente pelo `.bat`).
- **Dependências Externas:** Nenhuma. O projeto roda nativamente sobre o PowerShell do Windows.

---

<a name="english"></a>
## English

A standalone Windows utility to remove ads, block telemetry, disable background helpers, and optimize graphics performance for **BlueStacks 5** and **MSI App Player**.

Designed for zero friction: standard users only need to double-click the batch launcher (`iniciar.bat`), which self-elevates to Administrator and performs the entire debloat and optimization routine autonomously.

### Key Features

- **1-Click Execution (`iniciar.bat`):** Automatic UAC elevation, system language detection, and full unattended execution.
- **Host-Side Ad & Telemetry Suppression:**
  - Disables programmatic ads, promotional popups, boot banners, NowBux rewards, and BlueStacks X integrations in `bluestacks.conf`.
  - Clears promotional campaign strings, UTM tracking tags, and ad URLs.
  - Locks `bluestacks.conf` with a Read-Only attribute to prevent BlueStacks from restoring ads upon launch.
- **Graphics & Framerate Optimizations:**
  - Unlocks up to **120 FPS** high framerate mode (`enable_high_fps="1"`, `max_fps="120"`).
  - Enables hardware-accelerated ASTC texture decoding (`astc_decoding_mode="hardware"`).
  - Disables internal v-sync for reduced input latency (`enable_vsync="0"`).
- **Network Level Blocking (Windows & Android Hosts):**
  - Null-routes (`0.0.0.0`) known BlueStacks and Google ad/telemetry domains in `%SystemRoot%\System32\drivers\etc\hosts`.
  - **Official Downloads Preserved:** Download infrastructure and CDN domains (`cloud.bluestacks.com` and `eb.bluestacks.com`) are intentionally preserved and never blocked, ensuring users can download BlueStacks from the official site and update instances without server errors.
  - Automatically flushes local DNS resolver cache (`Clear-DnsClientCache`).
  - Updates guest Android `/system/etc/hosts` on writable system partitions.
- **Background Helper Blocking:**
  - Renames non-essential background helpers and AI daemons to `.bak` (`BlueStacksHelper.exe`, `BlueStacksAI.exe`, `BlueStacksAIRun.exe`, `BlueAILmsManager.exe`, `HD-LogCollector.exe`, and folder `BlueAI`).
- **Guest Android Bloatware Disabling (ADB):**
  - Connects to active instances over local ADB (`HD-Adb.exe` or system `adb`).
  - Scans and detects bloatware packages (Game Center, App Finder, pre-installed sponsored shortcuts).
  - Disables candidates safely via `pm disable-user --user 0` without risking partition corruption.
- **Automated Backups & 1-Click Rollback (`restaurar.bat`):**
  - Creates a timestamped backup in `state/backups/bluestacks/` before touching any file.
  - One-click restore restores original configuration, hosts file, helpers, and re-enables Android packages.

### How to Use

#### Simple Mode (Recommended)
1. Ensure BlueStacks has been launched at least once on the system.
2. Fully exit BlueStacks.
3. Double-click **`iniciar.bat`**.
4. Accept the Administrator prompt (UAC) when asked.
5. Wait for the process to complete and show the finished message.

#### Rollback Mode
- Double-click **`restaurar.bat`** to restore the latest backup (`bluestacks.conf`, Windows hosts file, helpers, and Android packages).

#### Quick Official Download Unblock
- If official BlueStacks downloads were blocked by earlier scripts, double-click **`desbloquear-downloads.bat`**. It instantly removes any blocks on `cloud.bluestacks.com` or `eb.bluestacks.com` and flushes the DNS cache.

#### Interactive Menu
- Double-click **`menu.bat`** to access granular options:
  - `[1]` Full Debloat & Optimization
  - `[2]` Host-only Debloat
  - `[3]` Guest Android-only Debloat
  - `[4]` Dry-Run Preview (No changes made)
  - `[5]` Status & Instance Diagnostics
  - `[6]` Restore from Backup
  - `[7]` Unblock Official Downloads

#### Command Line Automation (PowerShell)
```powershell
# Unattended full run
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Full -NoPause

# Dry-Run preview in English
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Full -DryRun -Language en

# Host-only debloat
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action HostOnly

# Instance diagnostics
powershell -ExecutionPolicy Bypass -File .\BlueStacksDebloater.ps1 -Action Status
```

### Requirements & Compatibility
- **Operating System:** Windows 10 or Windows 11 (64-bit).
- **Supported Emulators:** BlueStacks 5.x (64-bit releases) and MSI App Player.
- **Privileges:** Administrator permissions (auto-prompted via `.bat`).
- **External Dependencies:** None. Runs entirely on native Windows PowerShell components.

### License
Distributed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0). See [LICENSE](LICENSE) for details.
