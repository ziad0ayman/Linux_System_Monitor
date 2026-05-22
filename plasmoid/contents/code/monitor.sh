#!/bin/bash
# PC Monitor — auto-discovers sensors across Linux laptops and desktops.
# Outputs KEY=VALUE lines parsed by the QML widget.

# Helper: normalize a string to a valid key suffix
norm() { echo "$1" | tr ' ()/.' '_' | tr -s '_' | sed 's/_$//'; }

# Read current CPU counters; diff against previous run (cached in /tmp) gives
# accurate load over the full 5-second polling interval with no sleep penalty.
CPU_CACHE="/tmp/pc-monitor-cpu.cache"
read -r cpu_now < /proc/stat

# ── BATTERY (first BAT* found) ─────────────────────────────────────────────
BAT_PATH=""
for b in /sys/class/power_supply/BAT*; do
    [ -d "$b" ] && BAT_PATH="$b" && break
done
if [ -n "$BAT_PATH" ]; then
    echo "HAS_BAT=1"
    { read -r v < "$BAT_PATH/cycle_count"; }       2>/dev/null && echo "CYCLES=$v"   || echo "CYCLES=0"
    { read -r v < "$BAT_PATH/capacity"; }          2>/dev/null && echo "CAPACITY=$v" || echo "CAPACITY=0"
    if { read -r v < "$BAT_PATH/energy_full"; } 2>/dev/null; then
        echo "EFULL=$v"
        echo "BAT_UNIT=Wh"
    elif { read -r v < "$BAT_PATH/charge_full"; } 2>/dev/null; then
        echo "EFULL=$v"
        echo "BAT_UNIT=mAh"
    else
        echo "EFULL=0"
        echo "BAT_UNIT=Wh"
    fi
    if { read -r v < "$BAT_PATH/energy_full_design"; } 2>/dev/null; then
        echo "EDESIGN=$v"
    elif { read -r v < "$BAT_PATH/charge_full_design"; } 2>/dev/null; then
        echo "EDESIGN=$v"
    else
        echo "EDESIGN=0"
    fi
    { read -r v < "$BAT_PATH/status"; }            2>/dev/null && echo "STATUS=$v"   || echo "STATUS=Unknown"
    { read -r v < "$BAT_PATH/voltage_now"; }       2>/dev/null && echo "VOLTAGE=$v"  || echo "VOLTAGE=0"
fi

# ── SYSTEM ─────────────────────────────────────────────────────────────────
free -m | awk '/^Mem:/{print "RAMUSED=" $3; print "RAMTOTAL=" $2}'
awk '/^cpu MHz/{s+=$4;c++} END{printf "CPUFREQ=%.1f\n",s/c/1000}' /proc/cpuinfo

# ── HWMON auto-discovery ───────────────────────────────────────────────────
shopt -s nullglob

for h in /sys/class/hwmon/hwmon*; do
    [ -d "$h" ] || continue
    { read -r n < "$h/name"; } 2>/dev/null || continue
    [ -z "$n" ] && continue

    # ── CPU temperatures ──
    case "$n" in
        coretemp|k10temp|zenpower|k8temp)
            labels=("$h"/temp*_label)
            if [ ${#labels[@]} -gt 0 ]; then
                for f in "${labels[@]}"; do
                    base="${f%_label}"
                    { read -r lbl_raw < "$f"; }          2>/dev/null || continue
                    { read -r val < "${base}_input"; }   2>/dev/null || val=0
                    echo "CPUTEMP_$(norm "$lbl_raw")=${val}"
                done
            else
                { read -r val < "$h/temp1_input"; } 2>/dev/null && echo "CPUTEMP_Tdie=$val"
                { read -r val < "$h/temp2_input"; } 2>/dev/null && echo "CPUTEMP_Tccd1=$val"
            fi
            ;;

        # ── GPU temperatures ──
        amdgpu|radeon|nouveau|nvidia)
            labels=("$h"/temp*_label)
            if [ ${#labels[@]} -gt 0 ]; then
                for f in "${labels[@]}"; do
                    base="${f%_label}"
                    { read -r lbl_raw < "$f"; }          2>/dev/null || continue
                    { read -r val < "${base}_input"; }   2>/dev/null || val=0
                    echo "GPUTEMP_$(norm "$lbl_raw")=${val}"
                done
            else
                { read -r val < "$h/temp1_input"; } 2>/dev/null && echo "GPUTEMP_GPU=$val"
            fi
            ;;

        # ── Other sensors (acpitz/pch/iwlwifi/nvme) — mapped to fan section for reference
        acpitz|pch_*|pch|iwlwifi*|ath*|mt76*|nvme*)
            # silently skip — these were in the removed "Other Sensors" section
            ;;
    esac

    # ── Fans (all hwmon nodes that expose fan*_input) ──
    for f in "$h"/fan*_input; do
        [ -f "$f" ] || continue
        fname="$(basename "$f")"
        idx="${fname#fan}"; idx="${idx%_input}"
        { read -r rpm < "$f"; } 2>/dev/null || rpm=0
        label_f="$h/fan${idx}_label"
        if [ -f "$label_f" ]; then
            { read -r raw < "$label_f"; } 2>/dev/null || raw="${n}_fan${idx}"
            echo "$raw" | grep -qE '^fan[0-9]*$' && lbl="${n}_${raw}" || lbl="$raw"
        else
            lbl="${n}_fan${idx}"
        fi
        echo "FAN_$(norm "$lbl")=${rpm}"
    done
done

# ── CPU load (diff /proc/stat across polling interval — no sleep, no self-pollution) ──
# /proc/stat line: cpu user nice system idle iowait irq softirq ...
if [ -f "$CPU_CACHE" ]; then
    read -r cpu_prev < "$CPU_CACHE"
    set -- $cpu_prev; u1=$2 n1=$3 s1=$4 i1=$5 w1=$6 r1=$7 f1=$8
    set -- $cpu_now;  u2=$2 n2=$3 s2=$4 i2=$5 w2=$6 r2=$7 f2=$8
    total1=$((u1+n1+s1+i1+w1+r1+f1))
    total2=$((u2+n2+s2+i2+w2+r2+f2))
    delta=$((total2-total1))
    didle=$((i2-i1))
    [ "$delta" -gt 0 ] && echo "CPULOAD=$(( (delta-didle)*100/delta ))" || echo "CPULOAD=0"
else
    echo "CPULOAD=0"
fi
echo "$cpu_now" > "$CPU_CACHE"

# ── GPU (nvidia-smi) ────────────────────────────────────────────────────────
if command -v nvidia-smi &>/dev/null; then
    IFS="," read -r gtemp gload gmemused gmemtotal < <(
        nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total \
                   --format=csv,noheader,nounits 2>/dev/null
    )
    gtemp="${gtemp// /}"
    gload="${gload// /}"
    gmemused="${gmemused// /}"
    gmemtotal="${gmemtotal// /}"
    [ -n "$gload" ]      && echo "GPULOAD=${gload}"
    [ -n "$gmemused" ]   && echo "GPUMEMUSED=${gmemused}"
    [ -n "$gmemtotal" ]  && echo "GPUMEMTOTAL=${gmemtotal}"
    [ -n "$gtemp" ]      && echo "GPUTEMP_Temp=$((gtemp * 1000))"
fi

# ── NETWORK speed (diff /sys/class/net counters) ───────────────────────────
NET_CACHE="/tmp/pc-monitor-net.cache"
IFACE=""
for iface in /sys/class/net/*; do
    name="$(basename "$iface")"
    [ "$name" = "lo" ] && continue
    { read -r state < "$iface/operstate"; } 2>/dev/null || continue
    [ "$state" = "up" ] && IFACE="$iface" && break
done
if [ -n "$IFACE" ]; then
    read -r rx_now < "$IFACE/statistics/rx_bytes" 2>/dev/null || rx_now=0
    read -r tx_now < "$IFACE/statistics/tx_bytes" 2>/dev/null || tx_now=0
    if [ -f "$NET_CACHE" ]; then
        read -r rx_prev tx_prev < "$NET_CACHE" 2>/dev/null || { rx_prev=0; tx_prev=0; }
        # rate = bytes in 5 seconds = bytes / 5 → bytes/s
        rx_rate=$(( (rx_now - rx_prev) / 5 ))
        tx_rate=$(( (tx_now - tx_prev) / 5 ))
        [ "$rx_rate" -lt 0 ] && rx_rate=0
        [ "$tx_rate" -lt 0 ] && tx_rate=0
        echo "NETDOWN=$rx_rate"
        echo "NETUP=$tx_rate"
    fi
    echo "$rx_now $tx_now" > "$NET_CACHE"
fi
