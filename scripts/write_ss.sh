#!/bin/bash
# write_ss.sh — DDL/DML 변화 기반으로 next_ver SQL 생성 및 분류 저장

source "$(dirname "$0")/../config/env.sh"

echo "📝 스냅샷 SQL 파일 생성 중..."

# 📁 작업 디렉토리: next_ver
NEXT_VER_DIR="$RECOVERY_BY_TIME_DIR/next_ver"
mkdir -p "$NEXT_VER_DIR"

# 📄 order.txt 기반 SQL 파일 생성
while IFS= read -r STEP; do
  CLEAN_STEP=$(echo "$STEP" | tr -d '\r')  # 🔥 CR 제거
  STEP_PATH="$NEXT_VER_DIR/$CLEAN_STEP.sql"
  touch "$STEP_PATH"
done < "$ORDER_FILE"

###########################################
# 🏗️ DDL 쿼리 분류 저장 (schema 전체 → 분해 append)
###########################################
# 최신 schema 백업
TMP_SCHEMA="$ROOT_DIR/.tmp/schema_curr.sql"
pg_dump -s -p "$DB_PORT_SSD" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$TMP_SCHEMA"

# DDL: all.sql에 append
cat "$TMP_SCHEMA" >> "$RECOVERY_DDL_ALL"

# DDL: classified 분해
grep -i "^CREATE TABLE" "$TMP_SCHEMA" >> "$RECOVERY_DDL_CLASSIFIED/create.sql"
grep -i "^ALTER TABLE" "$TMP_SCHEMA" >> "$RECOVERY_DDL_CLASSIFIED/alter.sql"
grep -i "^DROP TABLE" "$TMP_SCHEMA" >> "$RECOVERY_DDL_CLASSIFIED/drop.sql"
grep -i "^CREATE INDEX" "$TMP_SCHEMA" >> "$RECOVERY_DDL_CLASSIFIED/index.sql"

# DDL: snapshot용 SQL 파일에도 append
grep -i "^CREATE TABLE" "$TMP_SCHEMA" >> "$NEXT_VER_DIR/schema/table_create.sql"
grep -i "^ALTER TABLE" "$TMP_SCHEMA" >> "$NEXT_VER_DIR/schema/alter.sql"
grep -i "^DROP TABLE" "$TMP_SCHEMA" >> "$NEXT_VER_DIR/schema/drop.sql"
grep -i "^CREATE INDEX" "$TMP_SCHEMA" >> "$NEXT_VER_DIR/index/index_create.sql"

###########################################
# 🧾 DML: 트리거 로그 기반으로 restore 쿼리 파일 분리
###########################################
# 조건: latest_timestamp 이후 로그만
psql -tA -U "$POSTGRES_USER" -d "$POSTGRES_DB" -p "$DB_PORT_SSD" -h localhost \
  -c "SELECT query_text, action_type FROM __change_log WHERE timestamp >= '$LATEST_TIMESTAMP';" \
  | while IFS='|' read -r QUERY ACTION; do
    case "$ACTION" in
      "DELETE")
        echo "$QUERY" >> "$NEXT_VER_DIR/restore/redelete.sql"
        ;;
      "UPDATE")
        echo "$QUERY" >> "$NEXT_VER_DIR/restore/reupdate.sql"
        ;;
      "INSERT")
        echo "$QUERY" >> "$NEXT_VER_DIR/restore/reinsert.sql"
        ;;
      *)
        echo "⚠️ 알 수 없는 액션: $ACTION"
        ;;
    esac
done

###########################################
# 🧭 META 정보 기록
###########################################
META_FILE="$NEXT_VER_DIR/meta/comment_define.sql"
{
  echo "-- Snapshot Timestamp: $NOW_TIMESTAMP"
  echo "-- Created by: $CURRENT_PC"
  echo "-- Latest Ver: $LATEST_VER"
  echo "-- From: $LATEST_TIMESTAMP"
} >> "$META_FILE"

echo "✅ SQL 파일 생성 완료: $NEXT_VER_DIR"
