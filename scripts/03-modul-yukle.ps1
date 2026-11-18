# 03-modul-yukle.ps1 - Magisk modulu kur
#
# Kullanim:
#   .\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\wifi-bekci
#   .\scripts\03-modul-yukle.ps1 -Zip .\modul.zip -YenidenBaslat
#   .\scripts\03-modul-yukle.ps1 -Zip .\magisk-modules\camellia-wifi-fix,.\magisk-modules\wifi-bekci
#
# Klasor verilirse otomatik olarak zip'lenir (module.prop kokte olacak sekilde).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Zip,
    [switch]$YenidenBaslat
)

. "$PSScriptRoot\common.ps1"

Show-Banner
Write-Head "Magisk modulu kurulumu"

$null = Get-AdbSerial
$id = Assert-Root
Write-Ok "Root: $($id.Trim())"

Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$gecici = Join-Path $env:TEMP ("redmi-modul-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $gecici | Out-Null

$kurulacak = @()

try {
    foreach ($girdi in $Zip) {
        if (-not (Test-Path $girdi)) {
            Write-Err2 "Bulunamadi: $girdi"
            continue
        }

        $item = Get-Item $girdi
        $zipPath = $null

        if ($item.PSIsContainer) {
            $ad = $item.Name
            $zipPath = Join-Path $gecici "$ad.zip"
            Write-Info "Klasor zip'leniyor: $ad"
            Compress-Archive -Path (Join-Path $item.FullName '*') -DestinationPath $zipPath -Force
        } else {
            $zipPath = $item.FullName
        }

        # module.prop zip kokunde mi?
        $z = [IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $kokte = $z.Entries | Where-Object { $_.FullName -eq 'module.prop' }
            $adlar = ($z.Entries | ForEach-Object { $_.FullName }) -join ', '
        } finally {
            $z.Dispose()
        }

        if (-not $kokte) {
            Write-Err2 "Gecersiz modul (module.prop kokte yok): $zipPath"
            Write-Info "Zip icerigi: $adlar"
            continue
        }

        $kurulacak += $zipPath
    }

    if ($kurulacak.Count -eq 0) {
        Write-Err2 "Kurulacak gecerli modul yok."
        exit 1
    }

    foreach ($zipPath in $kurulacak) {
        $ad = Split-Path -Leaf $zipPath
        $remote = "/data/local/tmp/$ad"

        Write-Head "Kuruluyor: $ad"
        $null = Invoke-Adb @('push', $zipPath, $remote)
        Write-Ok "Yuplandi: $remote"

        $r = Invoke-Root "magisk --install-module $remote" -AllowFail
        if ($r.Code -ne 0 -or $r.Output -match '(?i)error|failed') {
            Write-Err2 "Modul kurulumu basarisiz: $ad"
            Write-Info $r.Output
            continue
        }
        Write-Ok "Modul kuruldu: $ad"

        $null = Invoke-Root "rm -f $remote" -AllowFail -Quiet
    }

    Write-Head "Kurulu moduller"
    $ls = Invoke-Root 'ls -1 /data/adb/modules' -AllowFail
    Write-Host $ls.Output

    if ($YenidenBaslat) {
        Write-Head "Yeniden baslatiliyor"
        $null = Invoke-Adb @('reboot')
        Write-Ok "Cihaz yeniden baslatiliyor."
    } else {
        Write-Info "Modullerin aktif olmasi icin cihazi yeniden baslatin."
    }
} finally {
    Remove-Item $gecici -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
