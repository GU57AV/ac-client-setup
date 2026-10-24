<#
.SYNOPSIS
    Installs an Asheron's Call client for ACEmulator servers on Windows 10/11:
    prerequisites, end-of-retail client, Decal, ThwargLauncher, plugins, and
    (when virindi.net is reachable) the Virindi Bundle plus DemonicControl.

.DESCRIPTION
    Every download comes from the source documented in README.md and is checked
    before use: a pinned SHA-256 for fixed files, a valid Microsoft signature for
    the one Microsoft file that changes over time. A mismatch stops the script.

    Safe to re-run: each step checks whether its part is already installed.
    Run from an elevated Windows PowerShell 5.1 prompt (the script asks to elevate).

.PARAMETER CheckOnly
    Change nothing; only report what is installed and what is missing.

.PARAMETER WorkDir
    Where downloads are stored (each in its own subfolder). Default: %TEMP%\ac-client-setup

.PARAMETER SkipVirindi
    Skip the Virindi Bundle and DemonicControl steps.

.PARAMETER ServerName / ServerHost / ServerPort
    Optional: add this ACE server to ThwargLauncher's server list.

.EXAMPLE
    .\Install-ACClient.ps1 -CheckOnly
.EXAMPLE
    .\Install-ACClient.ps1 -ServerName "My Server" -ServerHost play.example.com -ServerPort 9000
#>
[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [string]$WorkDir = (Join-Path $env:TEMP 'ac-client-setup'),
    [switch]$SkipVirindi,
    [string]$ServerName,
    [string]$ServerHost,
    [int]$ServerPort = 9000
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Paths -------------------------------------------------------------------
$AcDir        = "C:\Turbine\Asheron's Call"
$DecalDir     = 'C:\Program Files (x86)\Decal 3.0'
$ThwargDir    = 'C:\Program Files (x86)\Thwargle Games\ThwargLauncher'
$PluginRoot   = 'C:\Games\Decal Plugins'
$VirindiRoot  = 'C:\Games\VirindiPlugins'
$VTankDir     = Join-Path $VirindiRoot 'VirindiTank'
$DecalReg     = 'HKLM:\SOFTWARE\WOW6432Node\Decal'
$DotNetSurrogate = '{71A69713-6593-47EC-0002-0000000DECA1}'
$UninstallKeys = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'

# --- Downloads (source, pinned SHA-256) --------------------------------------
# Wayback Machine 'id_' URLs return the archived file byte-for-byte.
$Downloads = @{
    VC2005SP1     = @{ File = 'vcredist_x86.exe'; Sha256 = 'EB00F891919D4F894AB725B158459DB8834470C382DC60CD3C3EE2C6DE6DA92C'
                       Url = 'https://web.archive.org/web/20190419092632id_/https://download.microsoft.com/download/e/1/c/e1c773de-73ba-494a-a5ba-f24906ecf088/vcredist_x86.exe' }
    VC2005MFC     = @{ File = 'vcredist_x86.exe'; Sha256 = '8648C5FC29C44B9112FE52F9A33F80E7FC42D10F3B5B42B2121542A13E44ADFD'
                       Url = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE' }
    DirectX       = @{ File = 'directx_Jun2010_redist.exe'; Sha256 = '053F76DCBB28802E23341B6A787E3B0791C0FA5C8D4D011B1044172DBF89C73B'
                       Url = 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' }
    VCx86         = @{ File = 'vc_redist.x86.exe'; Sha256 = $null; MicrosoftSigned = $true
                       Url = 'https://aka.ms/vs/17/release/vc_redist.x86.exe' }
    ACInstaller   = @{ File = 'ac1install.exe'; Sha256 = '251DE0067F9599A2A566CF7B218B2CB9163292B571BD48050CC6B754F61EEFC7'
                       Url = 'https://web.archive.org/web/20201121104423id_/http://content.turbine.com/sites/clientdl/ac1/ac1install.exe' }
    EndOfRetail   = @{ File = 'ac-updates.zip'; Sha256 = '66E90236326C8713BE014B4CD5B0BF7AC7331970D0D3E9A2552C2E78F92ED3D6'
                       Url = 'https://archive.org/download/ac-updates/ac-updates.zip' }
    Decal         = @{ File = 'Decal.msi'; Sha256 = '101365BA4378BE20D9AB57BA9F1C1DEDA5F93BB1B7BDB511DA836C9A69A31F26'
                       Url = 'https://www.decaldev.com/releases/2983/Decal.msi' }
    Thwarg        = @{ File = 'ThwargLauncherInstaller.exe'; Sha256 = 'C5156519695608A8DC57077DD7E4E3DDF29386008AD4B9E06A0C89B422635F61'
                       Url = 'https://thwargle.com/thwarglauncher/updates/ThwargLauncherInstaller.exe' }
    UtilityBelt   = @{ File = 'UtilityBeltInstaller-0.2.7.exe'; Sha256 = '6429C4F744CA7C6842ED8689FA95B6DCBEBA0D5D4A6DB7AAE7DAEF65E1742889'
                       Url = 'https://gitlab.com/utilitybelt/utilitybelt.gitlab.io/uploads/f24f9359893592252815818da7b3b7ba/UtilityBeltInstaller-0.2.7.exe' }
    MagTools      = @{ File = 'MagTools.dll'; Sha256 = '70A629DC1FE1F1FD0416EA3E05AA28E64EC0F23F3E50D4A091FFB4ED17BE7467'
                       Url = 'https://github.com/Mag-nus/Mag-Plugins/releases/download/Mag-Tools-v2.2.0/MagTools.dll' }
    MagFilter     = @{ File = 'MagFilter.dll'; Sha256 = 'BACE3692FCEF8863506609556F4BC8856764878BB826FD073A4D4F7FCBC6A882'
                       Url = 'https://github.com/Mag-nus/Mag-Plugins/releases/download/Mag-Filter-v2.0.3/MagFilter.dll' }
    ChaosHelper   = @{ File = 'chaoshelperv2.2.6.1.zip'; Sha256 = '83D0A3BAD4020DBCFF96F1F5ED05A4D4C21A51D493627EC81B1A2CD5602DA8EC'
                       Url = 'https://github.com/Oonej/ChaosHelper/releases/download/2.2.6.1/chaoshelperv2.2.6.1.zip' }
    TreeStats     = @{ File = 'TreeStats_v1.2.3b.zip'; Sha256 = '583C088C9442C2AE3609648EC05B2B51DC4D041C8D7EC79018520B4E8A9AC078'
                       Url = 'https://github.com/amoeba/treestats/releases/download/v1.2.3b/TreeStats_v1.2.3b.zip' }
    Virindi       = @{ File = 'VirindiInstaller1008.zip'; Sha256 = '55E4C0C242EA4488FA5C84BA02738F29F1A943FF9FF9AB63A40ECF0372D30FA4'
                       Url = 'https://web.archive.org/web/20250820082918id_/http://www.virindi.net/plugins/updates/VirindiInstaller1008.zip' }
}

# DemonicControl, pinned to commit 4a83fe1 (2025-07-18) of github.com/RonGeorge/DemonicControl
$DemonicCommit = '4a83fe1b7ae1501a240de5c1db5242e4afb806d1'
$DemonicFiles = [ordered]@{
    'DemonicControl.met'                              = '6813045EBBD6D5E6D09A103AACFC25A846B2701380DE5F6B0DDEE0E6B4C04F3D'
    'loot-profiles-and-autopack/colors.utl'           = '1EF2EA1EE848B6632D0510F9410D4E886452BBFD7CF6869A05F536653789CFFE'
    'loot-profiles-and-autopack/critabove42.utl'      = 'D1C0DF951F59384C440257B440439E1665C90FC8A33FA83590357224FDCCA4BA'
    'loot-profiles-and-autopack/critbelow38.utl'      = 'F28553AFDFA6F3C20528013434F9DFC9C19E91F0930DD93D006FA59E27C4AEF8'
    'loot-profiles-and-autopack/critchance.utl'       = '45123D7DF2B9DCEEF4B5BB635065F2EBA54CF46A4C7AAF99B3E1685CE7D69FC1'
    'loot-profiles-and-autopack/Ron V.autopack.utl'   = 'E330FE6F85D118B31490D55187905244548CAC5E17E75437D6E06FE997DBE3C0'
    'loot-profiles-and-autopack/Ron VI.autopack.utl'  = '6B1810DFCB8EE1BD1FDBA08C7F5110AFEAB1D821E9D58457FC7A190E54DBBA40'
    'loot-profiles-and-autopack/Ron.autopack.utl'     = '71B9935DB7875DBCBDDDFD15CEBFE3A29856F1D5EE92C6C0930F9834420F718C'
}

# Decal .NET plugins and filters. Key = the class GUID Decal Agent itself uses.
$DecalComponents = @(
    @{ Kind = 'Plugins';        Guid = '{F5993CE9-8A48-3BC6-902A-02344E29393C}'; Name = 'Mag-Tools';    Assembly = 'MagTools.dll';     Object = 'MagTools.PluginCore';     Dir = "$PluginRoot\MagTools" }
    @{ Kind = 'Plugins';        Guid = '{F5D62B09-A69E-3B02-8926-693C0DBC626D}'; Name = 'ChaosHelper';  Assembly = 'ChaosHelper.dll';  Object = 'ChaosHelper.PluginCore';  Dir = "$PluginRoot\ChaosHelper" }
    @{ Kind = 'Plugins';        Guid = '{605424E0-3AB3-38D7-AF51-3FB56431920E}'; Name = 'TreeStats';    Assembly = 'TreeStats.dll';    Object = 'TreeStats.PluginCore';    Dir = "$PluginRoot\TreeStats" }
    @{ Kind = 'NetworkFilters'; Guid = '{0C0CDE6D-87FD-35CA-8235-936710673D98}'; Name = 'Mag-Filter';   Assembly = 'MagFilter.dll';    Object = 'MagFilter.FilterCore';    Dir = "$PluginRoot\MagFilter" }
    @{ Kind = 'NetworkFilters'; Guid = '{234ACA9E-B914-3D98-BB91-391AD563D2FF}'; Name = 'ThwargFilter'; Assembly = 'ThwargFilter.dll'; Object = 'ThwargFilter.FilterCore'; Dir = $ThwargDir }
)

# --- Helpers -----------------------------------------------------------------
$script:Report = New-Object System.Collections.Generic.List[object]
function Step($name)  { Write-Host "`n== $name" -ForegroundColor Cyan }
function Info($msg)   { Write-Host "   $msg" }
function Warn($msg)   { Write-Host "   ! $msg" -ForegroundColor Yellow }
function Record($component, $status, $detail = '') { $script:Report.Add([pscustomobject]@{ Component = $component; Status = $status; Detail = $detail }) }

function Test-Installed($namePattern) {
    Get-ItemProperty $UninstallKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $namePattern } | Select-Object -First 1
}

function Get-VerifiedFile($key) {
    $d = $Downloads[$key]
    $dir = Join-Path $WorkDir $key
    $path = Join-Path $dir $d.File
    New-Item -ItemType Directory -Force $dir | Out-Null
    if (-not (Test-Path $path)) {
        Info "Downloading $($d.File) from $(([uri]$d.Url).Host) ..."
        & curl.exe --http1.1 -L --fail -s -S --retry 5 --retry-all-errors --retry-delay 10 --max-time 3600 -C - -o $path $d.Url
        if ($LASTEXITCODE -ne 0) {
            Remove-Item $path -ErrorAction SilentlyContinue
            throw "Download of $($d.File) failed (curl exit $LASTEXITCODE). If you use a VPN or VPN exit node, see README 'Troubleshooting'."
        }
    }
    if ($d.Sha256) {
        $h = (Get-FileHash $path -Algorithm SHA256).Hash
        if ($h -ne $d.Sha256) { Remove-Item $path; throw "$($d.File): SHA-256 $h does not match the pinned $($d.Sha256). Deleted it; not continuing." }
    }
    if ($d.MicrosoftSigned) {
        $s = Get-AuthenticodeSignature $path
        if ($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') { Remove-Item $path; throw "$($d.File): not validly signed by Microsoft. Deleted it; not continuing." }
    }
    Info "Verified $($d.File)"
    $path
}

function Invoke-Installer($path, [string[]]$arguments, $label) {
    $p = Start-Process $path -ArgumentList $arguments -Wait -PassThru
    # 3010 = success, reboot required
    if ($p.ExitCode -notin 0, 3010) { throw "$label installer exited with code $($p.ExitCode)." }
    if ($p.ExitCode -eq 3010) { Warn "$label asks for a reboot; reboot when the script is done." }
}

function Register-DecalComponent($c) {
    $k = Join-Path $DecalReg "$($c.Kind)\$($c.Guid)"
    New-Item -Path $k -Force | Out-Null
    Set-ItemProperty $k -Name '(default)' -Value $c.Name
    Set-ItemProperty $k -Name 'Assembly'  -Value $c.Assembly
    Set-ItemProperty $k -Name 'Path'      -Value $c.Dir
    Set-ItemProperty $k -Name 'Object'    -Value $c.Object
    Set-ItemProperty $k -Name 'Surrogate' -Value $DotNetSurrogate
    New-ItemProperty $k -Name 'Enabled' -Value 1 -PropertyType DWord -Force | Out-Null
}

function Test-DecalComponent($c) {
    $k = Join-Path $DecalReg "$($c.Kind)\$($c.Guid)"
    (Test-Path $k) -and (Test-Path (Join-Path $c.Dir $c.Assembly))
}

function Test-VirindiOnline {
    $code = & curl.exe -s -o NUL -w '%{http_code}' --max-time 20 'http://www.virindi.net/plugins/updates/updatelist.php'
    "$code" -match '^[23]\d\d$'
}

# --- Elevation ---------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $CheckOnly) {
    Write-Host 'Restarting elevated (accept the UAC prompt)...'
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`"")
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        if ($kv.Value -is [switch]) { if ($kv.Value) { $argList += "-$($kv.Key)" } } else { $argList += "-$($kv.Key)", "`"$($kv.Value)`"" }
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    return
}
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) { throw 'curl.exe not found (it ships with Windows 10 1803 and later).' }
if (-not $CheckOnly) { New-Item -ItemType Directory -Force $WorkDir | Out-Null }

# --- 1. Prerequisites --------------------------------------------------------
Step '1. Prerequisites'
$netfx = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5' -ErrorAction SilentlyContinue).Install -eq 1
if ($netfx) { Record '.NET Framework 3.5' 'present' }
elseif ($CheckOnly) { Record '.NET Framework 3.5' 'MISSING' }
else {
    Info 'Enabling .NET Framework 3.5 (downloads from Windows Update; can take a few minutes)...'
    $p = Start-Process dism.exe -ArgumentList '/Online', '/Enable-Feature', '/FeatureName:NetFx3', '/All', '/NoRestart' -Wait -PassThru -WindowStyle Hidden
    if ($p.ExitCode -notin 0, 3010) { throw "DISM NetFx3 failed with exit code $($p.ExitCode)." }
    Record '.NET Framework 3.5' 'installed'
}

# VC++ 2005 SP1: the original package (8.0.50727.762) is what the Virindi installer checks for;
# the later MFC security update (8.0.50727.6195) is installed too.
$vcItems = @(
    @{ Key = 'VC2005SP1'; Label = 'VC++ 2005 SP1 x86 (762)';  Detect = { Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{7299052b-02a4-4627-81f2-1818da5d550d}' }; Args = @('/q') }
    @{ Key = 'VC2005MFC'; Label = 'VC++ 2005 SP1 x86 (6195)'; Detect = { Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{710f4c1c-cc18-4c49-8cbf-51240c89a1a2}' }; Args = @('/q') }
    @{ Key = 'VCx86';     Label = 'VC++ 2015-2022 x86';       Detect = { [bool](Test-Installed 'Visual C\+\+ (2015-20\d\d|v14) Redistributable \(x86\)') }; Args = @('/install', '/quiet', '/norestart') }
)
foreach ($v in $vcItems) {
    if (& $v.Detect) { Record $v.Label 'present' }
    elseif ($CheckOnly) { Record $v.Label 'MISSING' }
    else { Invoke-Installer (Get-VerifiedFile $v.Key) $v.Args $v.Label; Record $v.Label 'installed' }
}

if (Test-Path "$env:WINDIR\SysWOW64\d3dx9_43.dll") { Record 'DirectX 9.0c (June 2010)' 'present' }
elseif ($CheckOnly) { Record 'DirectX 9.0c (June 2010)' 'MISSING' }
else {
    $dx = Get-VerifiedFile 'DirectX'
    $dxDir = Join-Path (Split-Path $dx) 'extracted'
    New-Item -ItemType Directory -Force $dxDir | Out-Null
    Invoke-Installer $dx @('/Q', "/T:`"$dxDir`"") 'DirectX extract'
    Invoke-Installer (Join-Path $dxDir 'DXSETUP.exe') @('/silent') 'DirectX'
    Record 'DirectX 9.0c (June 2010)' 'installed'
}

# --- 2. Asheron's Call client + end-of-retail files ---------------------------
Step "2. Asheron's Call client"
if (Test-Path "$AcDir\acclient.exe") { Record "AC client ($AcDir)" 'present' }
elseif ($CheckOnly) { Record "AC client ($AcDir)" 'MISSING' }
else {
    $ac = Get-VerifiedFile 'ACInstaller'
    Write-Host "`n   The Turbine installer opens now. Accept the EULA if you agree, keep the default folder" -ForegroundColor Green
    Write-Host "   ($AcDir), and decline launching the game at the end." -ForegroundColor Green
    Invoke-Installer $ac @() 'AC client'
    if (-not (Test-Path "$AcDir\acclient.exe")) { throw "acclient.exe not found in $AcDir after the installer. Was a different folder chosen?" }
    Record "AC client ($AcDir)" 'installed'
}

$eorFiles = [ordered]@{ 'client_portal.dat' = 926941184; 'client_cell_1.dat' = 348127232; 'client_local_English.dat' = 1048576; 'acclient.exe' = 4841472 }
$eorOk = (Test-Path $AcDir) -and -not ($eorFiles.GetEnumerator() | Where-Object { -not (Test-Path "$AcDir\$($_.Key)") -or (Get-Item "$AcDir\$($_.Key)").Length -ne $_.Value })
if ($eorOk) { Record 'End-of-retail dat files' 'present' }
elseif ($CheckOnly) { Record 'End-of-retail dat files' 'MISSING' }
else {
    $zip = Get-VerifiedFile 'EndOfRetail'
    $backup = Join-Path $AcDir '_original-installer-files'
    New-Item -ItemType Directory -Force $backup | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $a = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($e in $a.Entries) {
            if (-not $eorFiles.Contains($e.FullName)) { continue }
            $target = Join-Path $AcDir $e.FullName
            if ((Test-Path $target) -and -not (Test-Path (Join-Path $backup $e.FullName))) { Move-Item $target $backup }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
        }
    } finally { $a.Dispose() }
    Info "Originals kept in $backup"
    Record 'End-of-retail dat files' 'installed'
}

# --- 3. Decal ----------------------------------------------------------------
Step '3. Decal'
if (Test-Installed '^Decal 3\.0') { Record 'Decal 2.9.8.3' 'present' }
elseif ($CheckOnly) { Record 'Decal 2.9.8.3' 'MISSING' }
else {
    $msi = Get-VerifiedFile 'Decal'
    Invoke-Installer msiexec.exe @('/i', "`"$msi`"", '/qn', '/norestart') 'Decal'
    Record 'Decal 2.9.8.3' 'installed'
}

# --- 4. ThwargLauncher -------------------------------------------------------
Step '4. ThwargLauncher'
if (Test-Path "$ThwargDir\ThwargLauncher.exe") { Record 'ThwargLauncher 7.4.0.0' 'present' }
elseif ($CheckOnly) { Record 'ThwargLauncher 7.4.0.0' 'MISSING' }
else {
    Invoke-Installer (Get-VerifiedFile 'Thwarg') @('/exenoui', '/qn', '/norestart') 'ThwargLauncher'
    Record 'ThwargLauncher 7.4.0.0' 'installed'
}

# --- 5. Virindi Bundle (needs virindi.net online) -----------------------------
Step '5. Virindi Bundle'
$virindiPresent = Test-Path $VTankDir
if ($virindiPresent) { Record 'Virindi Bundle' 'present' }
elseif ($SkipVirindi) { Record 'Virindi Bundle' 'skipped' '-SkipVirindi' }
elseif (-not (Test-VirindiOnline)) { Record 'Virindi Bundle' 'MISSING' 'virindi.net unreachable; re-run the script when it is back'; Warn 'virindi.net is not answering; skipping Virindi for now.' }
elseif ($CheckOnly) { Record 'Virindi Bundle' 'MISSING' }
else {
    $vz = Get-VerifiedFile 'Virindi'
    $vx = Join-Path (Split-Path $vz) 'extracted'
    Expand-Archive $vz $vx -Force
    Write-Host "`n   The Virindi Plugin Installer opens now: click 'Check Libs', then 'Install', then close it." -ForegroundColor Green
    Start-Process (Join-Path $vx 'VirindiInstaller.exe') -WorkingDirectory $vx -Wait
    $virindiPresent = Test-Path $VTankDir
    Record 'Virindi Bundle' $(if ($virindiPresent) { 'installed' } else { 'MISSING' }) $(if (-not $virindiPresent) { "no $VTankDir after the installer" })
}

# --- 6. UtilityBelt ----------------------------------------------------------
Step '6. UtilityBelt'
if (Test-Path "$PluginRoot\UtilityBelt\UBLoader.dll") { Record 'UtilityBelt 0.2.7' 'present' }
elseif ($CheckOnly) { Record 'UtilityBelt 0.2.7' 'MISSING' }
else {
    # The NSIS installer registers UtilityBelt in Decal itself.
    Invoke-Installer (Get-VerifiedFile 'UtilityBelt') @('/S') 'UtilityBelt'
    Record 'UtilityBelt 0.2.7' 'installed'
}

# --- 7. MagTools, Mag-Filter, Chaos Helper, TreeStats, ThwargFilter ------------
Step '7. Decal plugins'
$sources = @{ 'Mag-Tools' = 'MagTools'; 'Mag-Filter' = 'MagFilter'; 'ChaosHelper' = 'ChaosHelper'; 'TreeStats' = 'TreeStats' }
foreach ($c in $DecalComponents) {
    if (Test-DecalComponent $c) { Record $c.Name 'present'; continue }
    if ($CheckOnly) { Record $c.Name 'MISSING'; continue }
    if ($sources.ContainsKey($c.Name)) {
        $f = Get-VerifiedFile $sources[$c.Name]
        New-Item -ItemType Directory -Force $c.Dir | Out-Null
        if ($f -like '*.zip') { Expand-Archive $f $c.Dir -Force } else { Copy-Item $f $c.Dir -Force }
    } elseif (-not (Test-Path (Join-Path $c.Dir $c.Assembly))) {
        Warn "$($c.Assembly) not found in $($c.Dir); install ThwargLauncher first."; Record $c.Name 'MISSING'; continue
    }
    Register-DecalComponent $c
    Record $c.Name 'installed'
}

# --- 8. DemonicControl (VTank meta + loot profiles) ---------------------------
Step '8. DemonicControl'
$demonicTarget = if ($virindiPresent) { $VTankDir } else { "$PluginRoot\_staged-for-VTank\DemonicControl" }
if (Test-Path (Join-Path $demonicTarget 'DemonicControl.met')) { Record 'DemonicControl' 'present' $demonicTarget }
elseif ($CheckOnly) { Record 'DemonicControl' 'MISSING' }
elseif ($SkipVirindi) { Record 'DemonicControl' 'skipped' '-SkipVirindi' }
else {
    $dl = Join-Path $WorkDir 'DemonicControl'
    foreach ($kv in $DemonicFiles.GetEnumerator()) {
        $out = Join-Path $dl ($kv.Key -replace '/', '\')
        New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
        $url = "https://raw.githubusercontent.com/RonGeorge/DemonicControl/$DemonicCommit/" + [uri]::EscapeUriString($kv.Key)
        & curl.exe -L --fail -s -S --retry 3 -o $out $url
        if ($LASTEXITCODE -ne 0) { throw "Download of $($kv.Key) failed." }
        if ((Get-FileHash $out).Hash -ne $kv.Value) { throw "$($kv.Key): SHA-256 mismatch; not continuing." }
    }
    # VTank reads metas and loot profiles from its own folder.
    New-Item -ItemType Directory -Force $demonicTarget | Out-Null
    Copy-Item "$dl\DemonicControl.met" $demonicTarget -Force
    Copy-Item "$dl\loot-profiles-and-autopack\*" $demonicTarget -Force
    Record 'DemonicControl' 'installed' $demonicTarget
    if (-not $virindiPresent) { Warn "VTank not installed yet: files staged in $demonicTarget. Re-run the script after Virindi to move them into $VTankDir." }
}

# --- 9. Per-user settings ----------------------------------------------------
Step '9. Settings'
# Dual-logging: each client picks its own UDP port.
$prefs = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Asheron's Call\UserPreferences.ini"
if (-not (Test-Path $prefs)) { Record 'Dual-log (ComputeUniquePort)' 'pending' 'start the game once, then re-run' }
elseif ((Get-Content $prefs) -contains 'ComputeUniquePort=True') { Record 'Dual-log (ComputeUniquePort)' 'present' }
elseif ($CheckOnly) { Record 'Dual-log (ComputeUniquePort)' 'MISSING' }
else {
    Copy-Item $prefs "$prefs.bak-$(Get-Date -Format yyyy-MM-dd)" -Force
    (Get-Content $prefs) -replace '^ComputeUniquePort=False$', 'ComputeUniquePort=True' | Set-Content $prefs -Encoding Default
    Record 'Dual-log (ComputeUniquePort)' 'installed'
}

if ($ServerHost) {
    $serverFile = Join-Path $env:APPDATA 'ThwargLauncher\Servers\UserServerList.xml'
    $connect = "${ServerHost}:$ServerPort"
    $existing = if (Test-Path $serverFile) { [xml](Get-Content $serverFile -Raw) } else { $null }
    $already = $existing -and ($existing.ArrayOfServerItem.ServerItem | Where-Object { $_.connect_string -eq $connect })
    if ($already) { Record "ThwargLauncher server $connect" 'present' }
    elseif ($CheckOnly) { Record "ThwargLauncher server $connect" 'MISSING' }
    elseif (Get-Process ThwargLauncher -ErrorAction SilentlyContinue) { Record "ThwargLauncher server $connect" 'pending' 'close ThwargLauncher and re-run' }
    else {
        if (-not $existing) {
            New-Item -ItemType Directory -Force (Split-Path $serverFile) | Out-Null
            $existing = [xml]'<?xml version="1.0" encoding="utf-8"?><ArrayOfServerItem />'
        } else { Copy-Item $serverFile "$serverFile.bak-$(Get-Date -Format yyyy-MM-dd)" -Force }
        $item = $existing.CreateElement('ServerItem')
        $fields = [ordered]@{ id = [guid]::NewGuid().ToString(); name = $(if ($ServerName) { $ServerName } else { $ServerHost }); alias = ''; description = ''
                              emu = 'ACE'; connect_string = $connect; discord_url = ''; website_url = ''; GameApiUrlKey = ''; LoginServerUrlKey = ''
                              enable_login = 'true'; default_rodat = 'Off'; default_secure = 'Off'; visibility = 'Visible' }
        foreach ($kv in $fields.GetEnumerator()) { $e = $existing.CreateElement($kv.Key); $e.InnerText = $kv.Value; [void]$item.AppendChild($e) }
        [void]$existing.DocumentElement.AppendChild($item)
        $existing.Save($serverFile)
        Record "ThwargLauncher server $connect" 'installed'
    }
}

# --- Summary -----------------------------------------------------------------
Write-Host "`n== Summary" -ForegroundColor Cyan
$script:Report | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
Write-Host @'
Still by hand (see README):
  - In ThwargLauncher: Settings -> tick "Inject Decal"; add your account (you type the password).
  - First launch: check Decal Agent shows every plugin with a tick.
'@
