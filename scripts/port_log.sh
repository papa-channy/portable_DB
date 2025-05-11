#!/bin/bash
# port_log.sh — 컨테이너 상태 + 디스크 정보 + 경로 정보 출력

source "$(dirname "$0")/../config/env.sh"

mkdir -p "$(dirname "$LOCAL_PORT_LOG")"

###########################################
# 1️⃣ 컨테이너 분류
###########################################
ALL_CONTAINERS=$(docker ps --format '{{.Names}} {{.Ports}}' | grep '->')

POSTGRESDB=""
OTHER_DB_5432=""
OTHER_CONTAINERS=""

while read -r line; do
  NAME=$(echo "$line" | awk '{print $1}')
  PORT=$(echo "$line" | sed -E 's/.* ([0-9]+)->.*/\1/' || true)

  if [ -z "$PORT" ]; then
    continue
  fi

  if [[ "$PORT" == "$DB_PORT_SSD" || "$PORT" == "$DB_PORT_LOCAL" ]]; then
    POSTGRESDB+="$NAME | port: $PORT"$'\n'
  elif [[ "$PORT" == 5432 ]]; then
    OTHER_DB_5432+="$NAME | port: $PORT"$'\n'
  else
    OTHER_CONTAINERS+="$NAME | port: $PORT"$'\n'
  fi
done <<< "$ALL_CONTAINERS"

###########################################
# 2️⃣ 디스크 용량 계산
###########################################
if df_output=$(df -k "$DB_SSD_PATH" 2>/dev/null | tail -1); then
  total_kb=$(echo "$df_output" | awk '{print $2}')
  free_kb=$(echo "$df_output" | awk '{print $4}')
  used_kb=$((total_kb - free_kb))

  used_percent=$((100 * used_kb / total_kb))
  used_gb=$(awk "BEGIN {printf \"%.1f\", $used_kb / (1024*1024)}")
  free_gb=$(awk "BEGIN {printf \"%.1f\", $free_kb / (1024*1024)}")
  total_gb=$(awk "BEGIN {printf \"%.1f\", $total_kb / (1024*1024)}")
else
  used_percent=0
  used_gb="0.0"
  free_gb="0.0"
  total_gb="0.0"
fi

###########################################
# 3️⃣ 개별 폴더/컨테이너 용량
###########################################
CON_SSD=$(docker inspect --format='{{.SizeRootFs}}' "$SSD_CONTAINER" 2>/dev/null)
CON_LOCAL=$(docker inspect --format='{{.SizeRootFs}}' "$LOCAL_CONTAINER" 2>/dev/null)
CON_SSD=${CON_SSD:-0}
CON_LOCAL=${CON_LOCAL:-0}

CON_SSD_GB=$(awk "BEGIN {printf \"%.2f\", $CON_SSD / (1024*1024*1024)}")
CON_LOCAL_GB=$(awk "BEGIN {printf \"%.2f\", $CON_LOCAL / (1024*1024*1024)}")

REC_SSD_GB=$(du -sh "$RECOVERY_BY_TIME_DIR" 2>/dev/null | awk '{print $1}')
REC_LOCAL_GB=$(du -sh "$LOCAL_RECOVERY_DIR" 2>/dev/null | awk '{print $1}')

###########################################
# 4️⃣ 출력
###########################################
{
  echo "📦 Docker Port info"
  echo "[Generated: $(date '+%Y-%m-%d %H:%M')]"
  echo ""
  echo "🖴 로컬 컨테이너 저장 경로: $DB_LOCAL_PATH"
  echo "📁 $STORAGE_TYPE snapshot 저장 경로: $RECOVERY_BY_TIME_DIR"
  echo "📁 Local snapshot 저장 경로: $LOCAL_RECOVERY_DIR"
  echo ""
  echo "🧮 디스크 사용률: ${used_percent}%"
  echo "(now : ${used_gb}GB / all : ${total_gb}GB, rest : ${free_gb}GB)"
  echo ""
  echo "💾 $SSD_CONTAINER 컨테이너 용량: ${CON_SSD_GB}GB"
  echo "💾 $LOCAL_CONTAINER 컨테이너 용량: ${CON_LOCAL_GB}GB"
  echo "📂 $STORAGE_TYPE recovery 용량: ${REC_SSD_GB}"
  echo "📂 Local recovery 용량: ${REC_LOCAL_GB}"
  echo ""
  echo "📦 $POSTGRES_DB 컨테이너"
  echo -n "$POSTGRESDB"
  echo ""
  echo "📦 다른 5432 포트 컨테이너"
  echo -n "$OTHER_DB_5432"
  echo ""
  echo "📦 기타 컨테이너"
  echo -n "$OTHER_CONTAINERS"
} > "$OUTPUT_FILE"

echo "✅ port_log 바탕화면 생성 완료: $OUTPUT_FILE"
