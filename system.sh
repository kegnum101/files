#!/bin/bash

# --- Configurable variables ---
SCRIPT_USER=$(last -w | grep -v "reboot\|wtmp\|^$" | head -1 | awk '{print $1}')
SERVER_ID=$(cat /home/$SCRIPT_USER/scripts/id.conf)
TOPIC="$SERVER_ID/drives"
BROKER="mosquitto.lan"

# --- Timestamp for this run ---
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# --- OS - Distro ---
OS=$(grep "PRETTY_NAME" /etc/os-release | sed 's/PRETTY_NAME="//;s/"//')

# --- Local IP ---
IP=$(hostname -I | awk '{print $1}')

# --- Uptime --
UP=$(uptime -p | sed 's/up //g')

# --- Cron Jobs ---
CRON=$(ps aux | grep -c CRON)

# --- Detect disks ---
DISKS_JSON="["
FIRST=1
for DISK in $(lsblk -d -n -o NAME,TYPE | awk '$2=="disk" && ($1 ~ /^nvme/ || $1 ~ /^sd/){print "/dev/"$1}'); do

    # --- SMART / life calculation ---
    LIFE_PERCENT=""
    TEMP_C=""
    SMART_INFO=$(sudo smartctl -A "$DISK" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        PERC_USED=$(echo "$SMART_INFO" | grep -i "Percentage Used" | awk '{gsub("%",""); print $NF}')
        WEAR=$(echo "$SMART_INFO" | grep -i "Wear_Leveling_Count" | awk '{print $4}' | sed 's/^0*//')
        HOURS=$(echo "$SMART_INFO" | grep -i "Power_On_Hours" | awk '{print $NF}')
        CYCLES=$(echo "$SMART_INFO" | grep -i "Power_Cycle_Count" | awk '{print $NF}')

        if [[ -n "$PERC_USED" ]]; then
            LIFE_PERCENT=$PERC_USED
        elif [[ -n "$WEAR" ]]; then
            LIFE_PERCENT=$((100 - WEAR))
        elif [[ "$HOURS" =~ ^[0-9]+$ && "$CYCLES" =~ ^[0-9]+$ ]]; then
            expected_hours=30000
            expected_cycles=50000
            hours_used_pct=$((100 * HOURS / expected_hours))
            cycles_used_pct=$((100 * CYCLES / expected_cycles))
            hdd_life_used=$(( (hours_used_pct + cycles_used_pct)/2 ))
            (( hdd_life_used>100 )) && hdd_life_used=100
            LIFE_PERCENT=$hdd_life_used
        fi

        # --- Temperature extraction ---
        TEMP_C=""
        if [[ -n "$PERC_USED" ]]; then
            TEMP_C=$(echo "$SMART_INFO" | grep -i "Temperature:" | awk '{print $2}' | sed 's/[^0-9]//g')
        elif [[ -n "$WEAR" ]]; then
            TEMP_C=$(echo "$SMART_INFO" | grep -i "Temperature_Celsius" | awk '{print $10}')
        elif [[ "$HOURS" =~ ^[0-9]+$ && "$CYCLES" =~ ^[0-9]+$ ]]; then
            TEMP_C=$(echo "$SMART_INFO" | grep -i "Temperature_Celsius" | awk '{print $10}')
        fi
    fi

    # --- Disk usage: pick largest partition from df -h ---
    USAGE="null"
    largest_size=0
    while read -r FS SIZE USED AVAIL PCT MOUNT; do
        if [[ $FS == ${DISK}* ]]; then
            # Convert SIZE to a number in G for comparison
            unit=${SIZE: -1}      # last character
            num=${SIZE%?}         # numeric part
            case $unit in
                T) num=$(awk "BEGIN{printf \"%f\", $num*1024}") ;;
                G) num=$num ;;
                M) num=$(awk "BEGIN{printf \"%f\", $num/1024}") ;;
                K) num=$(awk "BEGIN{printf \"%f\", $num/1024/1024}") ;;
            esac
            # Update largest partition
            if (( $(awk "BEGIN{print ($num>$largest_size)}") )); then
                largest_size=$num
                USAGE="$PCT $USED/$SIZE"
            fi
        fi
    done < <(df -h | tail -n +2)

    [[ $FIRST -eq 0 ]] && DISKS_JSON+=","
    FIRST=0
    DISKS_JSON+="{\"disk\":\"$DISK\",\"life_percent\":${LIFE_PERCENT:-null},\"temp_c\":${TEMP_C:-null},\"usage\":\"${USAGE}\"}"
done
DISKS_JSON+="]"

# --- RAM usage ---
RAM_INFO=$(free -h | awk '/^Mem:/ {print $2, $3, $3/$2*100}')
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
USED_RAM=$(free -h | awk '/^Mem:/ {print $3}')
PERCENT_RAM=$(free | awk '/^Mem:/ {printf "%d", $3/$2*100}')

RAM_USAGE="${TOTAL_RAM} ${USED_RAM} ${PERCENT_RAM}%"

# --- Load averages ---
read LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
LOAD_USAGE="$LOAD1 $LOAD5 $LOAD15"

# --- Detect CPU temperature universally ---
CPU_TEMP="N/A"

if command -v sensors >/dev/null 2>&1; then
    # Intel/AMD: Get Package temp from coretemp (remove °C)
    TEMP=$(sensors 2>/dev/null | grep "Package id 0:" | cut -d'+' -f2 | cut -d' ' -f1 | tr -d '°C')
    
    # Raspberry Pi: Get temp from cpu_thermal (remove °C)
    if [[ -z "$TEMP" ]]; then
        TEMP=$(sensors 2>/dev/null | awk '
            /^cpu_thermal-virtual-/ {in_section=1; next}
            in_section && /^$/ {in_section=0}
            in_section && /temp1:/ {
                gsub(/[+°C]/, "", $2)
                print $2
            }
        ')
    fi
    
    if [[ -n "$TEMP" ]]; then
        CPU_TEMP="$TEMP"
    fi
fi


# --- Build JSON payload ---
JSON="{\"server\":\"$SERVER_ID\",\"disks\":$DISKS_JSON,\"ram\":\"$RAM_USAGE\",\"load\":\"$LOAD_USAGE\",\"cpu\":\"$CPU_TEMP\",\"last_run\":\"$TIMESTAMP\",\"OS\":\"$OS\",\"IP\":\"$IP\",\"Uptime\":\"$UP\",\"Cron\":\"$CRON\"}"

# --- Echo instead of sending ---
mosquitto_pub -h "$BROKER" -t "$TOPIC" -m "$JSON" -r
