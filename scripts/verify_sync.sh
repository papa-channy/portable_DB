#!/bin/bash
# verify_sync.sh — SSD vs Local 동기화 검증

source "$(dirname "$0")/../config/env.sh"

echo "🧪 Verify Sync"

TMP_DIR="$ROOT_DIR/.tmp"
mkdir -p "$TMP_DIR"

# 1. 스키마 비교
SSD_SCHEMA="$TMP_DIR/schema_ssd.sql"
LOCAL_SCHEMA="$TMP_DIR/schema_local.sql"

pg_dump -s -p "$DB_PORT_SSD" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$SSD_SCHEMA"
pg_dump -s -p "$DB_PORT_LOCAL" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$LOCAL_SCHEMA"

# 🔥 트리거/함수 제외된 스키마 버전으로 필터링
# 필터 기준을 우리가 만든 것만 지정
grep -v -E '^CREATE TRIGGER change_tracker_trigger_|^CREATE FUNCTION track_changes|^CREATE EVENT TRIGGER trg_on_create_table' "$SSD_SCHEMA" > "$SSD_SCHEMA.clean"
grep -v -E '^CREATE TRIGGER change_tracker_trigger_|^CREATE FUNCTION track_changes|^CREATE EVENT TRIGGER trg_on_create_table' "$LOCAL_SCHEMA" > "$LOCAL_SCHEMA.clean"

SCHEMA_DIFF=$(diff -q "$SSD_SCHEMA.clean" "$LOCAL_SCHEMA.clean")

# 2. 데이터 비교
SSD_DATA="$TMP_DIR/data_ssd.sql"
LOCAL_DATA="$TMP_DIR/data_local.sql"

pg_dump -a --inserts -p "$DB_PORT_SSD" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$SSD_DATA"
pg_dump -a --inserts -p "$DB_PORT_LOCAL" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$LOCAL_DATA"

DATA_DIFF=$(diff -q "$SSD_DATA" "$LOCAL_DATA")

# 3. 결과 판정
if [ -z "$SCHEMA_DIFF" ] && [ -z "$DATA_DIFF" ]; then
  echo "✅ SSD ↔ Local 컨테이너 완벽 일치"
  export VERIFY_SYNC_RESULT=pass
else
  echo "❌ 컨테이너 불일치 발생 → fallback 필요"
  echo "[VERIFY ERROR] schema or data mismatch" >> "$ERR_LOG_FILE"
  export VERIFY_SYNC_RESULT=fail
fi
