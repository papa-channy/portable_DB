#!/bin/bash
# err_check.sh — 내부 오류 사전 차단용 마스터 스크립트
# 모든 필수 조건 미충족 시 즉시 종료(exit 1) 및 로그 기록

source "$(dirname "$0")/../config/env.sh"

###########################################
# 📄 1. .env 존재 여부
###########################################
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env 파일이 존재하지 않습니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 📁 2. 필수 디렉토리 존재 여부
###########################################
REQUIRED_DIRS=(
  "$RECOVERY_BY_TIME_DIR"
  "$LOGS_DIR"
  "$SCRIPTS_DIR"
  "$DB_SSD_PATH"
  "$CONFIG_DIR"
)

for DIR in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$DIR" ]; then
    echo "❌ 필수 디렉토리 없음: $DIR" | tee -a "$ERR_LOG_FILE"
    exit 1
  fi
done

###########################################
# 📄 3. 필수 파일 존재 여부
###########################################
REQUIRED_FILES=(
  "$VERSION_JSON"
  "$ORDER_FILE"
)

for FILE in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "❌ 필수 파일 없음: $FILE" | tee -a "$ERR_LOG_FILE"
    exit 1
  fi
done

###########################################
# 🔐 4. jq 설치 여부
###########################################
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq가 설치되어 있지 않습니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 🐳 5. Docker 실행 여부
###########################################
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker가 실행 중이 아니거나 접근 불가합니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 🐘 6. PostgreSQL 컨테이너 접속 확인
###########################################
for port in "$DB_PORT_LOCAL" "$DB_PORT_SSD"; do
  if ! pg_isready -h localhost -p "$port" >/dev/null 2>&1; then
    echo "❌ PostgreSQL 컨테이너에 연결 불가: port $port" | tee -a "$ERR_LOG_FILE"
    exit 1
  fi
done

###########################################
# 🔎 트리거 함수 및 event trigger 존재 확인
###########################################

# 트리거 함수 존재 확인
TRIGGER_FUNC=$(docker exec "$SSD_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "
  SELECT COUNT(*) FROM pg_proc WHERE proname = 'track_changes';
")

if [ "$TRIGGER_FUNC" -eq 0 ]; then
  echo "❌ 변경감지용 트리거 함수 track_changes()가 존재하지 않습니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

# event trigger 존재 확인
EVENT_TRIGGER=$(docker exec "$SSD_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "
  SELECT COUNT(*) FROM pg_event_trigger WHERE evtname = 'trg_on_create_table';
")

if [ "$EVENT_TRIGGER" -eq 0 ]; then
  echo "❌ event trigger (trg_on_create_table)가 존재하지 않습니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 🧾 8. ver.jsonl 유효성 검사
###########################################
if ! jq empty "$VERSION_JSON" >/dev/null 2>&1; then
  echo "❌ ver.jsonl이 유효한 JSONL 형식이 아닙니다." | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 🛑 9. 컨테이너 paused 상태 확인
###########################################
for con in $(docker ps -q); do
  STATUS=$(docker inspect --format='{{.State.Status}}' "$con")
  if [ "$STATUS" == "paused" ]; then
    echo "❌ paused 상태의 컨테이너 발견됨: $con" | tee -a "$ERR_LOG_FILE"
    exit 1
  fi
done

###########################################
# 🔐 10. SQL 파일 쓰기 가능 여부 (order.txt 기준)
###########################################
if [ -n "$NOW_TIMESTAMP" ]; then
  while read -r line; do
    f="$RECOVERY_DIR/next_ver/${NOW_TIMESTAMP}/${line}.sql"
    if [ -e "$f" ] && [ ! -w "$f" ]; then
      echo "❌ SQL 파일 쓰기 불가: $f" | tee -a "$ERR_LOG_FILE"
      exit 1
    fi
  done < "$ORDER_FILE"
fi

###########################################
# 🧭 11. DESKTOP 폴더 존재 여부
###########################################
if [ ! -d "$DESKTOP_DB_DIR" ]; then
  echo "❌ 바탕화면 작업 폴더가 존재하지 않습니다: $DESKTOP_DB_DIR" | tee -a "$ERR_LOG_FILE"
  exit 1
fi

###########################################
# 🔌 12. 포트 충돌 확인
###########################################
for port in "$DB_PORT_LOCAL" "$DB_PORT_SSD" "$DB_PORT_RECOVERY"; do
  if lsof -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1 && ! docker ps --format '{{.Ports}}' | grep -q "$port"; then
    echo "❌ 포트 $port 가 다른 프로세스에 의해 사용 중입니다." | tee -a "$ERR_LOG_FILE"
    exit 1
  fi
done

echo "✅ 내부 오류 점검 완료"
