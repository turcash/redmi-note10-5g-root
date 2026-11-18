#!/system/bin/sh
# Camellia Wi-Fi Fix - dusuk gecikmeli Wi-Fi (ev sunucusu).
# Olcum (MIUI, 5 GHz, -56 dBm): ort 9.2 ms / max 206 ms -> ort 2.75 ms / max 6 ms.
# Sebep: surucu uyku modu (SETSUSPENDMODE) + DTIM dinleme + guc tasarrufu.
LOG=/data/local/tmp/camellia-wifi-fix.log
IF=wlan0

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sleep 10

# Android'in ekran kapaninca surucuyu uyku moduna almasini kapat.
settings put global wifi_suspend_optimizations_enabled 0 2>/dev/null
# Wi-Fi kapaliyken de tarama yapma, BLE taramasini kapat (anten paylasimi).
settings put global wifi_scan_always_enabled 0 2>/dev/null
settings put global ble_scan_always_enabled 0 2>/dev/null

apply() {
  iw dev $IF set power_save off 2>/dev/null
  echo 1 > /proc/net/wlan/setCAM 2>/dev/null
  iwpriv $IF driver "SETSUSPENDMODE 0" >/dev/null 2>&1
  iwpriv $IF driver "SET_MDTIM 1" >/dev/null 2>&1
}

{
  date
  getprop | grep -iE "wifi|wlan|connsys|wmt|supplicant"
  ps -A -o USER,PID,NAME | grep -iE "wmt|wlan|wifi|wpa|hostapd"
  ip link
  logcat -d -b all | grep -iE "wifi|wlan|wmt|wpa_supp|WifiHAL" | tail -300
} > "$LOG" 2>&1

# Performans gunlugu: her dakika bir satir (CSV).
# zaman,ekran,power_save,sinyal_dBm,tx_Mbit,frekans,ping_ort,ping_max,kayip%,spike(>30ms),yeniden_uygulama
PERF=/data/local/tmp/camellia-wifi-perf.csv
[ -f "$PERF" ] || echo "zaman,ekran,power_save,sinyal_dBm,tx_Mbit,frekans,ping_ort,ping_max,kayip,spike,yeniden" > "$PERF"

gw() { ip route show table all 2>/dev/null | awk -v i=$IF '$1=="default" && $0 ~ "dev "i {print $3; exit}'; }

REAPPLY=0
perf() {
  L=$(iw dev $IF link 2>/dev/null)
  SIG=$(echo "$L" | awk '/signal:/{print $2}')
  TX=$(echo "$L" | awk '/tx bitrate:/{print $3}')
  FRQ=$(echo "$L" | awk '/freq:/{print $2}')
  PS=$(iw dev $IF get power_save 2>/dev/null | awk '{print $3}')
  SCR=$(dumpsys power 2>/dev/null | awk -F= '/mWakefulness=/{print $2; exit}')
  G=$(gw)
  if [ -n "$G" ]; then
    P=$(ping -c 20 -i 0.2 -W 1 "$G" 2>/dev/null)
    AVG=$(echo "$P" | awk -F/ '/^rtt/{print $5}')
    MAX=$(echo "$P" | awk -F/ '/^rtt/{print $6}')
    LOSS=$(echo "$P" | awk '/packet loss/{for(i=1;i<=NF;i++) if($i ~ /%/) {sub("%","",$i); print $i}}')
    SPK=$(echo "$P" | awk -F'time=' '/time=/{split($2,a," "); if(a[1]+0>30) k++} END{print k+0}')
  else
    AVG=; MAX=; LOSS=100; SPK=
  fi
  echo "$(date '+%F %T'),$SCR,$PS,$SIG,$TX,$FRQ,$AVG,$MAX,$LOSS,$SPK,$REAPPLY" >> "$PERF"
  REAPPLY=0
  # Boyut siniri: ~2 MB (yaklasik 2 hafta); asinca eskisini .1 olarak sakla.
  if [ "$(stat -c %s "$PERF" 2>/dev/null || echo 0)" -gt 2000000 ]; then
    mv "$PERF" "$PERF.1"; echo "zaman,ekran,power_save,sinyal_dBm,tx_Mbit,frekans,ping_ort,ping_max,kayip,spike,yeniden" > "$PERF"
  fi
}

# Watchdog (10 sn) + performans olcumu (60 sn).
N=0
while true; do
  if [ -d /sys/class/net/$IF ] && iw dev $IF get power_save 2>/dev/null | grep -q ": on"; then
    apply
    REAPPLY=$((REAPPLY+1))
    echo "$(date '+%F %T') ayarlar yeniden uygulandi" >> "$LOG"
  fi
  [ $((N % 6)) -eq 0 ] && perf
  N=$((N+1))
  sleep 10
done
