# common.ps1 - Redmi Note 10 5G root araclari icin ortak fonksiyonlar
#
# Not: Bu dosya bilincli olarak ASCII karakterlerle yazildi. Windows PowerShell
# 5.1, BOM'suz UTF-8 dosyalarda Turkce karakterleri bozabilir.

$ErrorActionPreference = 'Stop'

$script:RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Head([string]$Text) {
    Write-Host ''
    Write-Host "== $Text" -ForegroundColor Cyan
}

function Write-Ok([string]$Text) {
    Write-Host "[OK]    $Text" -ForegroundColor Green
}

function Write-Warn2([string]$Text) {
    Write-Host "[UYARI] $Text" -ForegroundColor Yellow
}

function Write-Err2([string]$Text) {
    Write-Host "[HATA]  $Text" -ForegroundColor Red
}

function Write-Info([string]$Text) {
    Write-Host "[BILGI] $Text" -ForegroundColor Gray
}

function Find-Tool {
    param([Parameter(Mandatory)][string]$Name)

    $envName = $Name.ToUpper()
    $envItem = Get-Item "env:$envName" -ErrorAction SilentlyContinue
    if ($envItem -and $envItem.Value -and (Test-Path $envItem.Value)) {
        return $envItem.Value
    }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }

    $candidates = @(
        (Join-Path $script:RepoRoot "tools\platform-tools\$Name.exe"),
        (Join-Path $script:RepoRoot "platform-tools\$Name.exe"),
        'C:\platform-tools\' + $Name + '.exe',
        (Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\$Name.exe")
    )
    if ($env:ANDROID_HOME) { $candidates += (Join-Path $env:ANDROID_HOME "platform-tools\$Name.exe") }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }

    return $null
}

function Get-Tool {
    param([Parameter(Mandatory)][string]$Name)
    $p = Find-Tool -Name $Name
    if (-not $p) {
        Write-Err2 "$Name bulunamadi."
        Write-Info "platform-tools kurun, PATH'e ekleyin veya $($Name.ToUpper()) ortam degiskenini tanimlayin."
        throw "$Name bulunamadi"
    }
    return $p
}

function Invoke-Exe {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Arguments = @(),
        [switch]$AllowFail,
        [switch]$Quiet
    )

    if (-not $Quiet) {
        Write-Host ("> {0} {1}" -f (Split-Path -Leaf $Exe), ($Arguments -join ' ')) -ForegroundColor DarkGray
    }

    $out = & $Exe @Arguments 2>&1
    $code = $LASTEXITCODE

    if ($out -and -not $Quiet) {
        $out | ForEach-Object { Write-Host $_ }
    }

    if ($code -ne 0 -and -not $AllowFail) {
        throw "Komut basarisiz (kod $code): $Exe $($Arguments -join ' ')"
    }

    return [pscustomobject]@{
        Code   = $code
        Output = (($out | ForEach-Object { "$_" }) -join "`n")
    }
}

function Get-AdbDevices {
    $adb = Get-Tool adb
    $r = Invoke-Exe $adb @('devices') -Quiet
    $devices = @()
    foreach ($line in ($r.Output -split "`r?`n")) {
        if ($line -match '^(\S+)\s+device(\s|$)') { $devices += $matches[1] }
    }
    return $devices
}

function Get-AdbSerial {
    $devices = @(Get-AdbDevices)
    if ($devices.Count -eq 0) {
        throw "Bagli adb cihazi yok. USB hata ayiklamayi acin ve kabloyu kontrol edin."
    }
    if ($devices.Count -gt 1) {
        throw "Birden fazla adb cihazi var: $($devices -join ', '). Tek cihaz baglayin."
    }
    return $devices[0]
}

function Invoke-Adb {
    param(
        [string[]]$Arguments = @(),
        [switch]$AllowFail,
        [switch]$Quiet,
        [switch]$NoSerial
    )
    $adb = Get-Tool adb
    $prefix = @()
    if (-not $NoSerial) { $prefix = @('-s', (Get-AdbSerial)) }
    return Invoke-Exe $adb ($prefix + $Arguments) -AllowFail:$AllowFail -Quiet:$Quiet
}

function Get-Prop {
    param([Parameter(Mandatory)][string]$Name)
    $r = Invoke-Adb @('shell', 'getprop', $Name) -Quiet -AllowFail
    return (($r.Output -split "`r?`n") | Where-Object { $_ -ne '' } | Select-Object -First 1)
}

function Invoke-Root {
    param(
        [Parameter(Mandatory)][string]$Command,
        [switch]$AllowFail,
        [switch]$Quiet
    )
    return Invoke-Adb @('shell', 'su', '-c', $Command) -AllowFail:$AllowFail -Quiet:$Quiet
}

function Assert-Root {
    $r = Invoke-Root 'id' -AllowFail -Quiet
    if ($r.Output -notmatch 'uid=0') {
        Write-Err2 "Root yok veya su izni verilmedi."
        Write-Info "Magisk uygulamasini acin ve izin verin. Ayrintili kontrol: .\scripts\04-dogrula.ps1"
        throw "Root dogrulanamadi"
    }
    return $r.Output
}

function Get-FastbootDevices {
    $fb = Get-Tool fastboot
    $r = Invoke-Exe $fb @('devices') -Quiet
    $devices = @()
    foreach ($line in ($r.Output -split "`r?`n")) {
        if ($line -match '^(\S+)\s+(fastboot|fastbootd)\s*$') { $devices += $matches[1] }
    }
    return $devices
}

function Get-FastbootSerial {
    $devices = @(Get-FastbootDevices)
    if ($devices.Count -eq 0) {
        throw "Fastboot cihazi yok. Cihazi kapatip Ses Kis + Guc ile FASTBOOT moduna alin."
    }
    if ($devices.Count -gt 1) {
        throw "Birden fazla fastboot cihazi var: $($devices -join ', ')."
    }
    return $devices[0]
}

function Invoke-Fastboot {
    param(
        [string[]]$Arguments = @(),
        [switch]$AllowFail,
        [switch]$Quiet
    )
    $fb = Get-Tool fastboot
    $serial = Get-FastbootSerial
    return Invoke-Exe $fb (@('-s', $serial) + $Arguments) -AllowFail:$AllowFail -Quiet:$Quiet
}

function Get-FastbootVar {
    param([Parameter(Mandatory)][string]$Name)
    $r = Invoke-Fastboot @('getvar', $Name) -AllowFail -Quiet
    $m = [regex]::Match($r.Output, "(?m)^$([regex]::Escape($Name)):\s*(.+?)\s*$")
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Assert-Fastbootd {
    $u = Get-FastbootVar 'is-userspace'
    if ($u -ne 'yes') {
        Write-Err2 "Cihaz fastbootd modunda degil (is-userspace=$u)."
        Write-Info "Su komutu calistirin: fastboot reboot fastboot"
        throw "fastbootd gerekli"
    }
    Write-Ok "fastbootd modu dogrulandi."
}

function Assert-Fastboot {
    $null = Get-FastbootSerial
    $u = Get-FastbootVar 'unlocked'
    if ($u -and $u -ne 'yes') {
        Write-Err2 "Bootloader kilitli gorunuyor (unlocked=$u)."
        throw "Bootloader kilitli"
    }
    return $u
}

function Confirm-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Warn2 $Message
    $answer = Read-Host "Devam etmek icin 'evet' yazin (baska bir sey = iptal)"
    if ($answer -ne 'evet') {
        throw "Kullanici iptal etti."
    }
}

function Confirm-Phrase {
    param(
        [Parameter(Mandatory)][string]$Phrase,
        [Parameter(Mandatory)][string]$Message
    )
    Write-Warn2 $Message
    $answer = Read-Host "Onay icin tam olarak '$Phrase' yazin"
    if ($answer -ne $Phrase) {
        throw "Onay metni eslesmedi. Islem iptal edildi."
    }
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N2} GiB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MiB' -f ($Bytes / 1MB)) }
    return "$Bytes B"
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
}

function Show-Banner {
    Write-Host ''
    Write-Host '==============================================' -ForegroundColor DarkCyan
    Write-Host ' Redmi Note 10 5G (camellia) - root araclari' -ForegroundColor White
    Write-Host '==============================================' -ForegroundColor DarkCyan
    Write-Host ''
}
