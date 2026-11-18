# geri-donus.ps1 - MIUI'ye geri donus (yalnizca 7 bolum yazilir)
#
# Kullanim:
#   .\scripts\geri-donus.ps1 -Yedek D:\Yedek
#
# ZORUNLU: bolumler\super.img.gz, vbmeta_a.img.gz, vbmeta_system_a.img.gz,
#          vbmeta_vendor_a.img.gz, boot_a.img.gz, dtbo_a.img.gz, vendor_boot_a.img.gz
#
# Cihaz normal FASTBOOT modunda olmalidir (fastbootd degil).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Yedek,
    [ValidateSet('a', 'b')][string]$Slot = 'a',
    [switch]$VeriyiSil
)

. "$PSScriptRoot\common.ps1"

Show-Banner
Write-Head "MIUI'ye geri donus"

# ---------------------------------------------------------------------------
# Guvenlik: yalnizca bu liste yazilir.
# ---------------------------------------------------------------------------

$bolumler = @(
    @{ Ad = 'super';           Dosya = 'super.img.gz';           Hedef = 'super' },
    @{ Ad = 'vbmeta';          Dosya = "vbmeta_$Slot.img.gz";    Hedef = "vbmeta_$Slot" },
    @{ Ad = 'vbmeta_system';   Dosya = "vbmeta_system_$Slot.img.gz";  Hedef = "vbmeta_system_$Slot" },
    @{ Ad = 'vbmeta_vendor';   Dosya = "vbmeta_vendor_$Slot.img.gz";  Hedef = "vbmeta_vendor_$Slot" },
    @{ Ad = 'boot';            Dosya = "boot_$Slot.img.gz";      Hedef = "boot_$Slot" },
    @{ Ad = 'dtbo';            Dosya = "dtbo_$Slot.img.gz";      Hedef = "dtbo_$Slot" },
    @{ Ad = 'vendor_boot';     Dosya = "vendor_boot_$Slot.img.gz"; Hedef = "vendor_boot_$Slot" }
)

$kaynak = Join-Path $Yedek 'bolumler'
if (-not (Test-Path $kaynak)) {
    Write-Err2 "Yedek klasoru yok: $kaynak"
    exit 1
}

Write-Head "Dosya kontrolu"

$eksik = @()
foreach ($b in $bolumler) {
    $p = Join-Path $kaynak $b.Dosya
    if (Test-Path $p) {
        Write-Ok ("{0,-16}: {1} ({2})" -f $b.Ad, $p, (Format-Bytes (Get-Item $p).Length))
    } else {
        Write-Warn2 ("{0,-16}: EKSIK -> {1}" -f $b.Ad, $p)
        $eksik += $b.Ad
    }
}

if ($eksik.Count -gt 0) {
    Write-Err2 "Eksik bolum yedekleri: $($eksik -join ', ')"
    Write-Info "Eksik yedekle geri donus YAPILMAZ."
    exit 1
}

$null = Assert-Fastboot
$userspace = Get-FastbootVar 'is-userspace'
if ($userspace -eq 'yes') {
    Write-Err2 "Cihaz fastbootd modunda. Normal fastboot gerekli."
    Write-Info "Su komutu kullanin: fastboot reboot bootloader"
    exit 1
}
Write-Ok "Normal fastboot modu dogrulandi."

$slot = Get-FastbootVar 'current-slot'
Write-Info "Aktif slot: $slot"

# ---------------------------------------------------------------------------
# Gzip acma
# ---------------------------------------------------------------------------

$acik = Join-Path $env:TEMP ("redmi-geri-donus-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $acik | Out-Null

function Expand-Gzip {
    param([string]$Src, [string]$Dst)
    $in = [IO.File]::OpenRead($Src)
    try {
        $os = [IO.File]::Create($Dst)
        try {
            $gz = New-Object IO.Compression.GZipStream($in, [IO.Compression.CompressionMode]::Decompress)
            try { $gz.CopyTo($os) } finally { $gz.Dispose() }
        } finally { $os.Dispose() }
    } finally { $in.Dispose() }
}

try {
    Write-Head "Arsivler aciliyor"
    $yazilacak = @()

    foreach ($b in $bolumler) {
        $src = Join-Path $kaynak $b.Dosya
        $dst = Join-Path $acik ($b.Dosya -replace '\.gz$', '')
        Write-Info "Aciliyor: $($b.Dosya)"
        Expand-Gzip -Src $src -Dst $dst
        Write-Ok ("{0} -> {1}" -f $b.Ad, (Format-Bytes (Get-Item $dst).Length))
        $yazilacak += [pscustomobject]@{ Ad = $b.Ad; Hedef = $b.Hedef; Dosya = $dst }
    }

    # -----------------------------------------------------------------------
    # Son onay
    # -----------------------------------------------------------------------

    Write-Head "Yazilacak bolumler"
    foreach ($y in $yazilacak) {
        Write-Host ("  flash {0,-16} <- {1}" -f $y.Hedef, (Split-Path -Leaf $y.Dosya))
    }

    Write-Warn2 "Bu islem tum verileri siler ve cihazi stok MIUI'ye dondurur."
    Write-Warn2 "Yanlis imaj kalici hasara yol acabilir."
    Confirm-Phrase -Phrase 'GERI DON' -Message "Son onay: geri donus baslatilsin mi?"

    # -----------------------------------------------------------------------
    # Yazma
    # -----------------------------------------------------------------------

    foreach ($y in $yazilacak) {
        Write-Head "Yaziliyor: $($y.Hedef)"
        $r = Invoke-Fastboot @('flash', $y.Hedef, $y.Dosya)
        if ($r.Code -ne 0) {
            Write-Err2 "Basarisiz: $($y.Hedef). Durduruluyor."
            exit 1
        }
        Write-Ok "$($y.Hedef) yazildi."
    }

    if ($VeriyiSil) {
        Write-Head "Veri temizligi"
        Confirm-Step "fastboot -w calistirilsin mi? Tum veriler silinecek."
        $null = Invoke-Fastboot @('-w')
        Write-Ok "Veri temizlendi."
    } else {
        Write-Warn2 "Veri temizligi atlandi. Acilista sorun olursa: fastboot -w"
    }

    Write-Head "Yeniden baslatiliyor"
    $null = Invoke-Fastboot @('reboot') -AllowFail
    Write-Ok "Cihaz yeniden baslatiliyor. Ilk acilis 5-10 dakika surebilir."
} finally {
    Write-Info "Gecici dosyalar siliniyor: $acik"
    Remove-Item $acik -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
