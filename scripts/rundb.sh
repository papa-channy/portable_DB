#!/bin/bash
# rundb.sh — 전체 동기화/백업 오케스트레이터

set -e
source "$(dirname "$0")/../config/env.sh"

###########################################
# 🔐 Lock 파일 설정
###########################################

LOCK_FILE="$ROOT_DIR/.rundb_lock"

if [ -f "$LOCK_FILE" ]; then
    echo "⚠️ 이미 실행 중이거나 이전 rundb가 비정상 종료됨: $LOCK_FILE"
    echo "필요 시 수동 삭제 후 재시도: rm -f $LOCK_FILE"
    exit 1
fi

touch "$LOCK_FILE"

# 종료 시 Lock 해제 트랩
trap 'echo "⚠️ 강제 종료 감지 → Lock 해제"; rm -f "$LOCK_FILE"; exit 1' INT TERM
trap 'rm -f "$LOCK_FILE"' EXIT

###########################################
# ✅ 실행 순서
###########################################

echo "⚙️ [1] Set Requirements"
bash "$REQ_SET_SCRIPT" || { echo "❌ req_set.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "🧪 [2] Check Possible Errors"
bash "$ERR_CHECK_SCRIPT" || { echo "❌ err_check.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "🔍 [3] Compare Version"
source "$VER_COMPARE_SCRIPT" || { echo "❌ ver_compare.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "📦 [4] Detect Changes"
bash "$MKSS_SCRIPT" || { echo "❌ mkss.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "🔁 [5] Syncronize DB"
bash "$LOCAL_SYNC_SCRIPT" || { echo "❌ local_sync.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "⏱️ [6] Setup Cron jobs"
bash "$CRON_SCRIPT" || { echo "❌ cron.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

echo "📊 [7] Save log"
bash "$PORT_LOG_SCRIPT" || { echo "❌ port_log.sh 실패"| tee -a "$ERR_LOG_FILE"; exit 1; }

###########################################
# 🚀 작업 도구 자동 실행
###########################################

echo "🚀 [8] VSCode + DBeaver 실행..."
code "$DESKTOP_DB_DIR" &
dbeaver &

###########################################
# 🧹 실행 후 메모리 최소화
###########################################

echo "🧹 [9] 로컬 컨테이너 정지..."
docker stop "local_${POSTGRES_DB}" >/dev/null 2>&1 || true

echo "✅ DB 동기화 및 백업 완료"

