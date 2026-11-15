<#
.SYNOPSIS
  Installa (o aggiorna) WireGuard TV su una Fire TV con Vega OS, da Windows.

.DESCRIPTION
  Scarica l'ultimo .vpkg dalla release pubblica (oppure usa un file locale) e lo installa sulla TV col Vega SDK,
  che su Windows gira dentro WSL (vedi docs/VEGA_SETUP.md). Un'installazione sopra una versione esistente la
  aggiorna e conserva i tunnel.

  Prima volta su una TV: Impostazioni > La mia Fire TV > Opzioni sviluppatore > Developer Mode acceso e
  "Connection Mode" = TCP/IP. Se la TV non è ancora autorizzata, serve il codice mostrato dalla TV:
  esegui in WSL `vega devmode login` e `vega devmode enable-device <codice>`.

.PARAMETER TvIp
  Indirizzo IP della Fire TV (Impostazioni > La mia Fire TV > Informazioni > Rete).

.PARAMETER Arch
  armv7 (Fire TV Stick 4K Select, predefinito), aarch64 o x86_64.

.PARAMETER Path
  Usa questo .vpkg invece di scaricare l'ultima release.

.PARAMETER Distro
  Distribuzione WSL con il Vega SDK (predefinita: Ubuntu).

.PARAMETER Launch
  Avvia l'app dopo l'installazione.

.EXAMPLE
  .\scripts\install-vega.ps1 -TvIp 192.168.1.37 -Launch
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TvIp,
    [ValidateSet('armv7', 'aarch64', 'x86_64')][string]$Arch = 'armv7',
    [string]$Path,
    [string]$Distro = 'Ubuntu',
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
$AppId = 'io.github.tommy052201.tvtunnel.main'
$Repo = 'tommy052201/wireguard-client-releases'

if ($TvIp -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { throw "Indirizzo IP non valido: $TvIp" }
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw 'WSL non trovato. Il Vega SDK su Windows gira in WSL: vedi docs/VEGA_SETUP.md.'
}

# 1. Il pacchetto
if ($Path) {
    if (-not (Test-Path $Path)) { throw "File non trovato: $Path" }
    $vpkg = (Resolve-Path $Path).Path
} else {
    $vpkg = Join-Path ([IO.Path]::GetTempPath()) "wireguard-tv-$Arch.vpkg"
    $url = "https://github.com/$Repo/releases/latest/download/wireguard-tv-$Arch.vpkg"
    Write-Host "Scarico $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $vpkg -UseBasicParsing
    } catch {
        throw "Download non riuscito ($($_.Exception.Message)). Scarica il .vpkg a mano dalla release e usa -Path."
    }
}
Write-Host ("Pacchetto: {0} ({1:N1} MB)" -f $vpkg, ((Get-Item $vpkg).Length / 1MB))

# 2. Installazione dentro WSL (il percorso Windows diventa un percorso Linux)
$wslPath = (& wsl -d $Distro -- wslpath -a ($vpkg -replace '\\', '/')).Trim()
if (-not $wslPath) { throw "WSL '$Distro' non risponde: controlla il nome con 'wsl -l'." }

$launchLine = if ($Launch) { "vega device launch-app --appName $AppId" } else { 'true' }
$script = @"
set -e
. ~/vega/env 2>/dev/null || { echo 'Vega SDK non trovato in WSL (~/vega): vedi docs/VEGA_SETUP.md' >&2; exit 2; }
vega exec vda connect $TvIp
vega device install-app --packagePath '$wslPath' --device ${TvIp}:5555
$launchLine
"@
# Fine riga Unix: bash non accetta \r.
$script = $script -replace "`r", ''
$tmp = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($tmp, $script, (New-Object Text.UTF8Encoding($false)))
$wslScript = (& wsl -d $Distro -- wslpath -a ($tmp -replace '\\', '/')).Trim()
Write-Host "Installo su $TvIp ..."
& wsl -d $Distro -- bash $wslScript
$code = $LASTEXITCODE
Remove-Item $tmp -ErrorAction SilentlyContinue
if ($code -ne 0) {
    throw "Installazione non riuscita (codice $code). Controlla: Developer Mode acceso, Connection Mode = TCP/IP, TV e PC nella stessa rete."
}
Write-Host 'Fatto. Al primo avvio la TV chiede il consenso "aggiungere VPN": accettalo.'
