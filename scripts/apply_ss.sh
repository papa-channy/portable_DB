#!/bin/bash
# apply_ss.sh — LOCAL 컨테이너에 snapshot SQL을 순차 적용

source "$(dirname "$0")/../config/env.sh"

###########################################
# 1. ver.jsonl에서 LOCAL_LAST_TIMESTAMP ~ LATEST_TIMESTAMP 사이 버전 추출
###########################################

# timestamps between LOCAL_LAST_TIMESTAMP and LATEST_TIMESTAMP
TARGET_TIMESTAMPS=$(awk -v start="$LOCAL_LAST_TIMESTAMP" -v end="$LATEST_TIMESTAMP" '
  BEGIN { FS="[:,\"]+" }
  /timestamp/ {
    ts = $(NF-1)
    if (ts > start && ts <= end) {
      print ts
    }
  }
' "$VERSION_JSON" | sort)

if [ -z "$TARGET_TIMESTAMPS" ]; then
  echo "✅ 이미 최신 상태입니다"
  exit 0
fi

###########################################
# 2. 각 timestamp 폴더를 오래된 순서대로 순회
###########################################
for ts in $TARGET_TIMESTAMPS; do
  SNAP_DIR="$RECOVERY_BY_TIME_DIR/$ts"
  if [ ! -d "$SNAP_DIR" ]; then
    echo "⚠️ snapshot 폴더 없음: $SNAP_DIR → 건너뜀"
    continue
  fi

  echo "📂 snapshot 적용 중: $ts"

  # 3. order.txt 순서에 따라 SQL 순차 실행
  while read -r step; do
    clean_step=$(echo "$step" | tr -d '\r')  # 🔥 CR 제거
    sql_file="$SNAP_DIR/$clean_step.sql"
    if [ -s "$sql_file" ]; then
      echo "  ▶️ 적용 중: $clean_step.sql"
      psql -U "$POSTGRES_USER" -p "$DB_PORT_LOCAL" -d "$POSTGRES_DB" -f "$sql_file" >/dev/null 2>>"$ERR_LOG_FILE"
      if [ $? -ne 0 ]; then
        echo "  ❌ 실행 실패: $sql_file (오류 기록됨)" | tee -a "$ERR_LOG_FILE"
      fi
    else
      echo "  ⚪️ 비어있음: $clean_step.sql → 건너뜀"
    fi
  done < "$ORDER_FILE"

done

echo "✅ apply_ss.sh 완료: 모든 snapshot 적용 시도 완료"
