#!/bin/bash
# --- Configurable variables ---
SCRIPT_USER=$(last -w | grep -v "reboot\|wtmp\|^$" | head -1 | awk '{print $1}')
SERVER_ID=$(cat /home/$SCRIPT_USER/scripts/id.conf)
TOPIC="$SERVER_ID/docker"
DOCKER="$(cat /home/$SCRIPT_USER/scripts/docker.conf)"

# --- Timestamp ---
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# --- Check docker daemon is reachable ---
if ! docker info &>/dev/null 2>&1; then
    exit 0
fi

# --- Collect stats snapshot ---
CONTAINERS_JSON="["
FIRST=1

while IFS='|' read -r NAME CPU_PERC MEM_USED MEM_PERC NET_IN NET_OUT BLOCK_READ BLOCK_WRITE; do
    [[ -z "$NAME" ]] && continue

    # Strip % signs
    CPU_VAL="${CPU_PERC//%/}"
    MEM_PERC_VAL="${MEM_PERC//%/}"

    [[ $FIRST -eq 0 ]] && CONTAINERS_JSON+=","
    FIRST=0

    CONTAINERS_JSON+="{\"name\":\"$NAME\",\"cpu_perc\":\"$CPU_VAL\",\"mem_used\":\"$MEM_USED\",\"mem_perc\":\"$MEM_PERC_VAL\",\"net_in\":\"$NET_IN\",\"net_out\":\"$NET_OUT\",\"block_read\":\"$BLOCK_READ\",\"block_write\":\"$BLOCK_WRITE\"}"

done < <(docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}' 2>/dev/null | \
    awk -F'|' '{
        split($3, mem, " / ");
        split($5, net, " / ");
        split($6, blk, " / ");
        print $1 "|" $2 "|" mem[1] "|" $4 "|" net[1] "|" net[2] "|" blk[1] "|" blk[2]
    }')

CONTAINERS_JSON+="]"

# --- Build final JSON payload ---
JSON="{\"server\":\"$SERVER_ID\",\"last_run\":\"$TIMESTAMP\",\"containers\":$CONTAINERS_JSON}"

echo "$JSON" > "${DOCKER}${SERVER_ID}.txt"
