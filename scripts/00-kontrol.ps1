# 00-kontrol.ps1 - Ortam, cihaz ve dosya kontrolu
#
# Kullanim:
#   .\scripts\00-kontrol.ps1
#   .\scripts\00-kontrol.ps1 -Yedek D:\Yedek

[CmdletBinding()]
param(
    [string]$Yedek,
    [switch]$Hash
)

. "$PSScriptRoot\common.ps1"

Show-Banner
Write-Head "Araclar"

$adb = Find-Tool 'adb'
$fb  = Find-Tool 'fastboot'

if ($adb) {
    Write-Ok "adb      : $adb"
    $v = Invoke-Exe $adb @('version') -AllowFail -Quiet
    Write-Info (($v.Output -split "`r?`n") | Select-Object -First 1)
} else {
    Write-Err2 "adb bulunamadi"
}

if ($fb) {
    Write-Ok "fastboot : $fb"
    $v = Invoke-Exe $fb @('--version') -AllowFail -Quiet
    Write-Info (($v.Output -split "`r?`n") | Select-Object -First 1)
} else {
    Write-Err2 "fastboot bulunamadi"
}

# ---------------------------------------------------------------------------

Write-Head "ADB cihazlari"

$adbDevices = @()
if ($adb) { $adbDevices = @(Get-AdbDevices) }

if ($adbDevices.Count -eq 0) {
    Write-Info "Bagli adb cihazi yok (normal olabilir; cihaz fastboot'ta olabilir)."
} elseif ($adbDevices.Count -eq 1) {
    Write-Ok "Cihaz: $($adbDevices[0])"
    try {
        $serial = Get-AdbSerial
        Write-Head "Cihaz bilgileri"

        $props = [ordered]@{
            'model'                = Get-Prop 'ro.product.model'
            'vendor.device'        = Get-Prop 'ro.product.vendor.device'
            'boot.hardware'        = Get-Prop 'ro.boot.hardware'
            'android'              = Get-Prop 'ro.build.version.release'
            'sdk'                  = Get-Prop 'ro.build.version.sdk'
            'build.product'        = Get-Prop 'ro.build.product'
            'boot.flash.locked'    = Get-Prop 'ro.boot.flash.locked'
        }

        foreach ($k in $props.Keys) {
            Write-Host ("  {0,-18}: {1}" -f $k, $props[$k])
        }

        if ($props['boot.flash.locked'] -eq '1') {
            Write-Warn2 "Bootloader kilitli gorunuyor (ro.boot.flash.locked=1)."
        }

        $id = Invoke-Root 'id' -AllowFail -Quiet
        if ($id.Output -match 'uid=0') {
            Write-Ok "Root: $($id.Output.Trim())"
        } else {
            Write-Warn2 "Root yok veya su izni verilmedi."
        }
    } catch {
        Write-Warn2 $_.Exception.Message
    }
} else {
    Write-Warn2 "Birden fazla adb cihazi: $($adbDevices -join ', ')"
    Write-Info "Tek cihaz baglayin."
}

# ---------------------------------------------------------------------------

Write-Head "Fastboot cihazlari"

$fbDevices = @()
if ($fb) { $fbDevices = @(Get-FastbootDevices) }

if ($fbDevices.Count -eq 0) {
    Write-Info "Bagli fastboot cihazi yok."
} elseif ($fbDevices.Count -eq 1) {
    Write-Ok "Cihaz: $($fbDevices[0])"
    try {
        Write-Host ("  {0,-18}: {1}" -f 'product',     (Get-FastbootVar 'product'))
        Write-Host ("  {0,-18}: {1}" -f 'current-slot',(Get-FastbootVar 'current-slot'))
        Write-Host ("  {0,-18}: {1}" -f 'unlocked',    (Get-FastbootVar 'unlocked'))
        Write-Host ("  {0,-18}: {1}" -f 'is-userspace',(Get-FastbootVar 'is-userspace'))

        $unlocked = Get-FastbootVar 'unlocked'
        if ($unlocked -and $unlocked -ne 'yes') {
            Write-Warn2 "Bootloader kilitli. Yazma islemleri basarisiz olur."
        }
    } catch {
        Write-Warn2 $_.Exception.Message
    }
} else {
    Write-Warn2 "Birden fazla fastboot cihazi: $($fbDevices -join ', ')"
}

# ---------------------------------------------------------------------------

if ($Yedek) {
    Write-Head "Yedek dosyalari: $Yedek"

    if (-not (Test-Path $Yedek)) {
        Write-Err2 "Klasor yok: $Yedek"
    } else {
        $files = [ordered]@{
            'GSI'                 = Join-Path $Yedek 'gsi\system-squeak-arm64-ab-vanilla.img'
            'vbmeta'              = Join-Path $Yedek 'gsi\vbmeta.img'
            'Magisk'              = Join-Path $Yedek 'apk\Magisk.apk'
            'super yedegi'        = Join-Path $Yedek 'bolumler\super.img.gz'
            'boot_a yedegi'       = Join-Path $Yedek 'bolumler\boot_a.img.gz'
            'vbmeta_a yedegi'     = Join-Path $Yedek 'bolumler\vbmeta_a.img.gz'
        }

        foreach ($k in $files.Keys) {
            $p = $files[$k]
            if (Test-Path $p) {
                $len = (Get-Item $p).Length
                Write-Ok ("{0,-18}: {1} ({2})" -f $k, $p, (Format-Bytes $len))
                if ($Hash -and $len -lt 8MB) {
                    Write-Info ("  sha256: {0}" -f (Get-Sha256 $p))
                }
            } else {
                Write-Warn2 ("{0,-18}: eksik -> {1}" -f $k, $p)
            }
        }
    }
}

# ---------------------------------------------------------------------------

Write-Head "Ozet"
if ($adbDevices.Count -eq 0 -and $fbDevices.Count -eq 0) {
    Write-Info "Cihaz bagli degil. Kontrol icin cihazi acin (adb) veya FASTBOOT'a alin."
    Write-Info "Sonraki adim: docs/01-bootloader.md (bootloader kapaliysa) veya docs/02-magisk-root.md"
} elseif ($adbDevices.Count -eq 1) {
    Write-Ok "Cihaz adb modunda hazir."
    Write-Info "Sonraki adim: .\scripts\04-dogrula.ps1"
} elseif ($fbDevices.Count -eq 1) {
    Write-Ok "Cihaz fastboot modunda hazir."
    Write-Info "Sonraki adim: .\scripts\01-vbmeta.ps1 -Vbmeta <vbmeta.img>"
}
Write-Host ''
