# 04-dogrula.ps1 - Root, sistem ve ag dogrulamasi
#
# Kullanim:
#   .\scripts\04-dogrula.ps1
#   .\scripts\04-dogrula.ps1 -Strict     # hata varsa exit 1

[CmdletBinding()]
param(
    [switch]$Strict
)

. "$PSScriptRoot\common.ps1"

Show-Banner

$script:pass = 0
$script:fail = 0

function Check {
    param(
        [string]$Label,
        [bool]$Ok,
        [string]$Value
    )
    if ($Ok) {
        $script:pass++
        Write-Host ("[OK]    {0,-22}: {1}" -f $Label, $Value) -ForegroundColor Green
    } else {
        $script:fail++
        Write-Host ("[FAIL]  {0,-22}: {1}" -f $Label, $Value) -ForegroundColor Red
    }
}

try {
    $null = Get-AdbSerial
} catch {
    Write-Err2 $_.Exception.Message
    exit 1
}

# ---------------------------------------------------------------------------

Write-Head "Cihaz"

$model   = Get-Prop 'ro.product.model'
$vendor  = Get-Prop 'ro.product.vendor.device'
$hw      = Get-Prop 'ro.boot.hardware'
$android = Get-Prop 'ro.build.version.release'
$sdk     = Get-Prop 'ro.build.version.sdk'
$product = Get-Prop 'ro.build.product'
$device  = Get-Prop 'ro.product.device'

Check 'model'          ($model -ne '')                $model
Check 'vendor.device'  ($vendor -eq 'camellia')       $vendor
Check 'boot.hardware'  ($hw -eq 'mt6833')             $hw
Check 'android'        ($android -eq '12')            $android
Check 'sdk'            ($sdk -ne '')                  $sdk
Check 'build.product'  ($product -ne '')              $product
Check 'product.device' ($device -ne '')               $device

# ---------------------------------------------------------------------------

Write-Head "Root"

$id = Invoke-Root 'id' -AllowFail -Quiet
$rootOk = ($id.Output -match 'uid=0') -and ($id.Output -match 'magisk:s0')
Check 'su -c id' $rootOk $id.Output.Trim()

$magisk = Invoke-Root 'magisk -v' -AllowFail -Quiet
Check 'magisk -v' ($magisk.Output.Trim() -ne '') $magisk.Output.Trim()

$adbTcp = Invoke-Root 'getprop persist.adb.tcp.port' -AllowFail -Quiet
Check 'adb.tcp.port' ($adbTcp.Output.Trim() -eq '5555') $adbTcp.Output.Trim()

# ---------------------------------------------------------------------------

Write-Head "Moduller"

$modules = Invoke-Root 'ls -1 /data/adb/modules' -AllowFail -Quiet
$moduleList = @(($modules.Output -split "`r?`n") | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() })

if ($moduleList.Count -eq 0) {
    Check 'modul listesi' $false '(bos veya okunamadi)'
} else {
    foreach ($m in $moduleList) {
        Write-Ok ("modul: {0}" -f $m.Trim())
        $script:pass++
    }
}

foreach ($beklenen in @('camellia-wifi-fix', 'wifi-bekci')) {
    Check "modul/$beklenen" ($moduleList -contains $beklenen) $(if ($moduleList -contains $beklenen) { 'var' } else { 'yok' })
}

# ---------------------------------------------------------------------------

Write-Head "Wi-Fi"

$ps = Invoke-Root 'iw dev wlan0 get power_save' -AllowFail -Quiet
$psOk = ($ps.Output -match 'off')
Check 'wlan0 power_save' $psOk $ps.Output.Trim()

$link = Invoke-Root 'iw dev wlan0 link' -AllowFail -Quiet
$linkOk = ($link.Output -match 'Connected to')
Check 'wlan0 link' $linkOk (($link.Output -split "`r?`n") | Select-Object -First 1)

# ---------------------------------------------------------------------------

Write-Head "Ozet"

$total = $script:pass + $script:fail
Write-Host ("SONUC: {0}/{1} PASS, {2} FAIL" -f $script:pass, $total, $script:fail) `
    -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Yellow' })

if ($script:fail -gt 0) {
    Write-Info "Ayrinti icin: docs/04-dogrulama.md ve docs/06-sorun-giderme.md"
    if ($Strict) { exit 1 }
}

Write-Host ''
