# 01-vbmeta.ps1 - AVB dogrulamasini kapat (vbmeta yaz)
#
# Kullanim:
#   .\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img
#   .\scripts\01-vbmeta.ps1 -Vbmeta D:\Yedek\gsi\vbmeta.img -Slot a
#
# Cihaz FASTBOOT modunda olmalidir.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Vbmeta,
    [ValidateSet('a', 'b')][string]$Slot
)

. "$PSScriptRoot\common.ps1"

Show-Banner
Write-Head "vbmeta dogrulamasini kapat"

if (-not (Test-Path $Vbmeta)) {
    Write-Err2 "Dosya yok: $Vbmeta"
    exit 1
}

$len = (Get-Item $Vbmeta).Length
Write-Info "Dosya : $Vbmeta"
Write-Info "Boyut : $(Format-Bytes $len)"
Write-Info "SHA256: $(Get-Sha256 $Vbmeta)"

$null = Assert-Fastboot
Write-Ok "Fastboot cihazi hazir."

$slot = Get-FastbootVar 'current-slot'
Write-Info "Aktif slot: $slot"

$target = 'vbmeta'
if ($Slot) { $target = "vbmeta_$Slot" }

Write-Warn2 "Bu islem AVB dogrulamasini kapatir. Acilista 'orange state' uyarisi normaldir."
Write-Warn2 "Yanlis vbmeta imaji cihazi acilmaz hale getirebilir."
Confirm-Step "Devam edilsin mi? Hedef bolum: $target"

$r = Invoke-Fastboot @(
    '--disable-verity',
    '--disable-verification',
    'flash',
    $target,
    $Vbmeta
)

if ($r.Code -ne 0) {
    Write-Err2 "vbmeta yazilamadi."
    exit 1
}

Write-Ok "vbmeta yazildi ($target)."
Write-Info "Sonraki adim: fastboot reboot fastboot"
Write-Info "Ardindan: .\scripts\02-gsi-yaz.ps1 -Gsi <gsi.img> -VeriyiSil"
Write-Host ''
