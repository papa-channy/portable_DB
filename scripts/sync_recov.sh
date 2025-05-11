#!/bin/bash
# sync_recov.sh — SSD ↔ Local recovery 동기화

source "$(dirname "$0")/../config/env.sh"

###########################################
# 1️⃣ 폴더 존재 보장
###########################################
mkdir -p "$LOCAL_RECOVERY_DIR"
mkdir -p "$RECOVERY_BY_TIME_DIR"

###########################################
# 2️⃣ SSD vs Local 폴더 리스트 정렬해서 비교
###########################################
SSD_FOLDERS=$(ls "$RECOVERY_BY_TIME_DIR" | sort)
LOCAL_FOLDERS=$(ls "$LOCAL_RECOVERY_DIR" | sort)

if [ "$SSD_FOLDERS" != "$LOCAL_FOLDERS" ]; then
  echo "⚠️ recovery 폴더 불일치 → local 복제 진행"

  # 삭제 후 복제
  rm -rf "$LOCAL_RECOVERY_DIR"
  cp -r "$RECOVERY_BY_TIME_DIR" "$LOCAL_RECOVERY_DIR"

  echo "✅ SSD 기준으로 local recovery 복제 완료"
fi
