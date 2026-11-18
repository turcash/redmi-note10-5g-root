# 02-gsi-yaz.ps1 - phh GSI'yi system bolumune yaz
#
# Kullanim:
#   .\scripts\02-gsi-yaz.ps1 -Gsi D:\Yedek\gsi\system-squeak-arm64-ab-vanilla.img -VeriyiSil
#
# Cihaz FASTBOOTD modunda olmalidir:  fastboot reboot fastboot

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Gsi,
    [switch]$VeriyiSil,
    [switch]$SlotAta
)

. "$PSScriptRoot\common.ps1"

Show-Banner
Write-Head "GSI yazimi"

if (-not (Test-Path $Gsi)) {
    Write-Err2 "GSI dosyasi yok: $Gsi"
    exit 1
}

$len = (Get-Item $Gsi).Length
Write-Info "Dosya : $Gsi"
Write-Info "Boyut : $(Format-Bytes $len)"
Write-Info "SHA256: $(Get-Sha256 $Gsi)"

if ($len -lt 500MB) {
    Write-Warn2 "Dosya beklenenden kucuk. Dogru GSI oldugundan emin misiniz?"
}

$null = Assert-Fastboot
Assert-Fastbootd

Write-Warn2 "Bu islem system bolumunu silip yeniden yazar."
Write-Warn2 "Mevcut Android sistemi (MIUI) silinir. Yedeginiz oldugundan emin olun."
Confirm-Step "GSI yazimi baslatilsin mi?"

if ($SlotAta) {
    Write-Head "Slot a seciliyor"
    $null = Invoke-Fastboot @('set_active', 'a')
    Write-Ok "Aktif slot: a"
}

Write-Head "product bolumu siliniyor (yer acmak icin)"
$r = Invoke-Fastboot @('delete-logical-partition', 'product') -AllowFail
if ($r.Code -ne 0) {
    Write-Warn2 "product silinemedi veya zaten yok. Devam ediliyor."
} else {
    Write-Ok "product silindi."
}

Write-Head "system temizleniyor"
$r = Invoke-Fastboot @('erase', 'system') -AllowFail
if ($r.Code -ne 0) {
    Write-Warn2 "erase system basarisiz. flash yine de ustune yazacak."
} else {
    Write-Ok "system temizlendi."
}

Write-Head "GSI yaziliyor (1.8 GB, 1-3 dakika)"
$r = Invoke-Fastboot @('flash', 'system', $Gsi)
if ($r.Code -ne 0) {
    Write-Err2 "GSI yazilamadi. 'Not enough space' hatasi icin docs/06-sorun-giderme.md"
    exit 1
}
Write-Ok "GSI yazildi."

if ($VeriyiSil) {
    Write-Head "Veri temizligi"
    Write-Warn2 "fastboot -w, userdata ve metadata bolumlerini siler. Tum veriler gider."
    Confirm-Step "Veriler silinsin mi?"
    $null = Invoke-Fastboot @('-w')
    Write-Ok "Veri temizlendi."
} else {
    Write-Warn2 "Veri temizligi atlandi. Acilista sorun cikarsa: fastboot -w"
}

Write-Head "Yeniden baslatiliyor"
$null = Invoke-Fastboot @('reboot') -AllowFail
Write-Ok "Cihaz yeniden baslatiliyor."
Write-Info "Ilk acilis 3-5 dakika surebilir. 10 dakikadan uzun surerse docs/06-sorun-giderme.md"
Write-Host ''
