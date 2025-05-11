#!/bin/bash
# detect_change.sh — DDL + DML 변경 감지

source "$(dirname "$0")/../config/env.sh"

echo "🔍 스냅샷 변경 감지 시작..."

# 경로 설정
TMP_DIR="$ROOT_DIR/.tmp"
mkdir -p "$TMP_DIR"

# DDL 비교 대상 파일
PREV_SCHEMA="$TMP_DIR/schema_prev.sql"
CURR_SCHEMA="$TMP_DIR/schema_curr.sql"

# PostgreSQL 접속 정보
PG_CONN="psql -U $POSTGRES_USER -d $POSTGRES_DB -p $DB_PORT_SSD -h localhost"

###########################################
# 🏗️ DDL 변화 감지
###########################################
# 최신 schema 백업
pg_dump -s -p $DB_PORT_SSD -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$CURR_SCHEMA"

# 이전 schema 불러오기 (RECOVERY_DDL_ALL 기준)
cp "$RECOVERY_DDL_ALL" "$PREV_SCHEMA"

# diff 비교
DDL_DIFF=$(diff -q "$PREV_SCHEMA" "$CURR_SCHEMA")
DDL_CHANGED=0
if [ -n "$DDL_DIFF" ]; then
    echo "📐 DDL 변경 감지됨"
    DDL_CHANGED=1
else
    echo "📐 DDL 변경 없음"
fi

###########################################
# 🧾 DML 변화 감지
###########################################
# 트리거 로그 테이블에서 timestamp 기준 이후 로그 확인
DML_COUNT=$(
  psql -tA -U "$POSTGRES_USER" -d "$POSTGRES_DB" -p "$DB_PORT_SSD" -h localhost \
  -c "SELECT COUNT(*) FROM __change_log WHERE timestamp >= '$LATEST_TIMESTAMP';"
)

DML_CHANGED=0
if [ "$DML_COUNT" -gt 0 ]; then
    echo "🧩 DML 변경 감지됨 ($DML_COUNT 쿼리)"
    DML_CHANGED=1
else
    echo "🧩 DML 변경 없음"
fi

###########################################
# ✅ 결과 export
###########################################
if [ "$DDL_CHANGED" -eq 1 ] || [ "$DML_CHANGED" -eq 1 ]; then
    export SNAPSHOT_REQUIRED=1
else
    export SNAPSHOT_REQUIRED=0
fi
