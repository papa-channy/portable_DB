#!/bin/bash
# local_sync.sh — 로컬 컨테이너 recovery 동기화 + snapshot 적용 + 검증

source "$(dirname "$0")/../config/env.sh"

###########################################
# 1️⃣ recovery 폴더 동기화 (SSD → Local)
###########################################
bash "$SYNC_RECOV_SCRIPT"

###########################################
# 2️⃣ snapshot SQL 적용 (LOCAL_LAST_TIMESTAMP → LATEST_TIMESTAMP)
###########################################
bash "$APPLY_SS_SCRIPT"

###########################################
# 3️⃣ 컨테이너 검증 (SSD ↔ Local dump 비교)
###########################################
bash "$VERIFY_SYNC_SCRIPT"

###########################################
# 4️⃣ fallback (불일치 시 → 로컬 초기화 + SSD 복제)
###########################################
if [ "$VERIFY_SYNC_RESULT" == "fail" ]; then
  echo "🚨 fallback 트리거됨 (동기화 실패)"
  bash "$FALLBACK_SCRIPT"
fi
