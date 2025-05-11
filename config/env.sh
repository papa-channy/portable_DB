#!/bin/bash
# env.sh — 모든 전역 경로 및 변수 export

###########################################
# 📌 .env import (.env 파일은 반드시 존재해야 함)
###########################################
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "❌ .env 파일이 존재하지 않습니다: $ENV_FILE"
    exit 1
fi

###########################################
# 📁 프로젝트 내부 기본 디렉토리 경로
###########################################
export ROOT_DIR="$ROOT_DIR"
export CONFIG_DIR="$ROOT_DIR/config"
export DOCS_DIR="$ROOT_DIR/docs"
export LOGS_DIR="$ROOT_DIR/logs"
export SCRIPTS_DIR="$ROOT_DIR/scripts"
export RECOVERY_DIR="$ROOT_DIR/recovery"
export RECOVERY_BY_TIME_DIR="$RECOVERY_DIR/by_time"
export RECOVERY_DDL_DIR="$RECOVERY_DIR/DDL"
export RECOVERY_DDL_CLASSIFIED_DIR="$RECOVERY_DDL_DIR/classified"

###########################################
# 📄 고정 파일 경로
###########################################
export VERSION_JSON="$LOGS_DIR/ver.jsonl"
export ERR_LOG_FILE="$LOGS_DIR/err_logs.txt"
export ORDER_FILE="$CONFIG_DIR/order.txt"
export RECOVERY_SCRIPT="$RECOVERY_DIR/recovery.sh"

export RECOVERY_DDL_ALL="$RECOVERY_DDL_DIR/all.sql"
export RECOVERY_DDL_ALTER="$RECOVERY_DDL_CLASSIFIED_DIR/alter.sql"
export RECOVERY_DDL_CREATE="$RECOVERY_DDL_CLASSIFIED_DIR/create.sql"
export RECOVERY_DDL_DROP="$RECOVERY_DDL_CLASSIFIED_DIR/drop.sql"
export RECOVERY_DDL_INDEX="$RECOVERY_DDL_CLASSIFIED_DIR/index.sql"

export DETECT_CHANGE_SCRIPT="$SCRIPTS_DIR/detect_change.sh"
export WRITE_SS_SCRIPT="$SCRIPTS_DIR/write_ss.sh"
export APPLY_SS_SCRIPT="$SCRIPTS_DIR/apply_ss.sh"
export SYNC_RECOV_SCRIPT="$SCRIPTS_DIR/sync_recov.sh"
export VERIFY_SYNC_SCRIPT="$SCRIPTS_DIR/verify_sync.sh"
export FALLBACK_SCRIPT="$SCRIPTS_DIR/fallback.sh"
export MKSS_SCRIPT="$SCRIPTS_DIR/mkss.sh"
export LOCAL_SYNC_SCRIPT="$SCRIPTS_DIR/local_sync.sh"
export VER_COMPARE_SCRIPT="$SCRIPTS_DIR/ver_compare.sh"
export REQ_SET_SCRIPT="$SCRIPTS_DIR/req_set.sh"
export ERR_CHECK_SCRIPT="$SCRIPTS_DIR/err_check.sh"
export PORT_LOG_SCRIPT="$SCRIPTS_DIR/port_log.sh"
export CRON_SCRIPT="$SCRIPTS_DIR/cron.sh"
export RUNDB_SCRIPT="$SCRIPTS_DIR/rundb.sh"

###########################################
# 🖥️ 바탕화면 경로 (사용자 .env 기반)
###########################################
export DESKTOP_DB_DIR="$DESKTOP_BASE/$DESKTOP_DB_NAME"
export LOCAL_RECOVERY_DIR="$DESKTOP_DB_DIR/recovery"
export LOCAL_PORT_LOG="$DESKTOP_DB_DIR/port_log.txt"
export DB_LOCAL_PATH="$DESKTOP_DB_DIR/db_local_con"
###########################################
# 📂 로그 동기화용 SSD 내부 로그 저장소
###########################################
export PORT_LOG_DIR="$LOGS_DIR/p_logs"

###########################################
# 📦 .env 변수 export 확인용 (명시적)
###########################################
export POSTGRES_USER POSTGRES_DB
export DB_PORT_SSD DB_PORT_LOCAL DB_PORT_RECOVERY
export DB_IMAGE_VERSION DB_SSD_PATH
export DESKTOP_BASE DESKTOP_DB_NAME
export PGPASSWORD="$POSTGRES_PASSWORD"
###########################################
# 🕒 최신 스냅샷 경로 자동 계산
###########################################
export LATEST_SNAPSHOT=$(ls "$RECOVERY_BY_TIME_DIR" 2>/dev/null | sort -r | head -n 1)
export LATEST_SNAPSHOT_PATH="$RECOVERY_BY_TIME_DIR/$LATEST_SNAPSHOT"

export STORAGE_TYPE=${STORAGE_TYPE}  # 기본값 ssd
export SSD_CONTAINER="${STORAGE_TYPE}_${POSTGRES_DB}"
export LOCAL_CONTAINER="local_${POSTGRES_DB}"
