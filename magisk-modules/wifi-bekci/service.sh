#!/system/bin/sh
# wifi-bekci: Wi-Fi koparsa (ya da acilista baglanmazsa) tarama yapip KAYITLI aga
# otomatik baglanir. Android kayitli aglara taramadan sonra kendisi baglanir; bekci
# yalnizca Wi-Fi'yi acik tutar, tarama tetikler, takilirsa Wi-Fi'yi kapat/ac yapar.
# camellia-wifi-fix (guc tasarrufu) ile cakismaz; o modul yeniden baglama yapmaz.
#
# Adimlar (15 sn'de bir kontrol):
#   Wi-Fi kapali           -> ac
#   bagli degil            -> tarama (her tur)
#   ~45 sn hala yok        -> Wi-Fi kapat/ac + tarama (sonra her ~2 dk tekrar)
#   bagli ama ag gecidi 3 tur ping vermiyor (bayat baglanti) -> kapat/ac
LOG=/data/local/tmp/wifi-bekci.log
IF=wlan0

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sleep 20

log() {
  echo "$(date '+%F %T') $*" >> "$LOG"
  if [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 500000 ]; then mv "$LOG" "$LOG.1"; fi
}

bagli() { cmd wifi status 2>/dev/null | grep -q "Wifi is connected to"; }
acik()  { cmd wifi status 2>/dev/null | grep -q "^Wifi is enabled"; }
gecit() { ip route show table all 2>/dev/null | awk -v i=$IF '$1=="default" && $0 ~ "dev "i {print $3; exit}'; }
tara()  { cmd wifi start-scan >/dev/null 2>&1; }
kapat_ac() {
  log "Wi-Fi kapat/ac"
  cmd wifi set-wifi-enabled disabled >/dev/null 2>&1
  sleep 3
  cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
  sleep 5
  tara
}

log "basladi"
YOK=0      # ard arda baglantisiz tur
BAYAT=0    # bagli ama gecit yanitsiz tur
while true; do
  if ! acik; then
    log "Wi-Fi kapali -> aciliyor"
    cmd wifi set-wifi-enabled enabled >/dev/null 2>&1
    sleep 5; tara
  fi

  if bagli; then
    [ "$YOK" -gt 0 ] && log "baglandi ($YOK tur sonra): $(cmd wifi status 2>/dev/null | sed -n 's/.*connected to //p' | head -1)"
    YOK=0
    G=$(gecit)
    if [ -n "$G" ] && ! ping -c 2 -W 2 "$G" >/dev/null 2>&1; then
      BAYAT=$((BAYAT+1))
      if [ "$BAYAT" -ge 3 ]; then log "gecit $G yanit vermiyor"; kapat_ac; BAYAT=0; fi
    else
      BAYAT=0
    fi
  else
    YOK=$((YOK+1))
    [ "$YOK" -eq 1 ] && log "baglanti yok -> tarama"
    tara
    # 3. turda (~45 sn) ve sonra her 8 turda (~2 dk) kapat/ac
    if [ "$YOK" -eq 3 ] || { [ "$YOK" -gt 3 ] && [ $(( (YOK - 3) % 8 )) -eq 0 ]; }; then kapat_ac; fi
  fi
  sleep 15
done
