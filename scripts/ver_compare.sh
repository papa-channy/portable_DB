#!/bin/bash
# ver_compare.sh — 버전 기준점 계산 및 export

source "$(dirname "$0")/../config/env.sh"

###########################################
# 🧑 현재 PC 이름
###########################################
CURRENT_PC=$(hostname)

###########################################
# 🧾 ver.jsonl 마지막 라인 가져오기 (최신 실행 기록)
###########################################
LATEST_LINE=$(tail -n 1 "$VERSION_JSON")

# 버전과 타임스탬프 추출
LATEST_VER=$(echo "$LATEST_LINE" | jq -r '.version')
LATEST_TIMESTAMP=$(echo "$LATEST_LINE" | jq -r '.timestamp')

###########################################
# 🧾 현재 PC 기준 마지막 실행 기록 가져오기
###########################################
LOCAL_LAST_LINE=$(grep "\"pc\": \"$CURRENT_PC\"" "$VERSION_JSON" | tail -n 1)

if [ -z "$LOCAL_LAST_LINE" ]; then
  LOCAL_LAST_VER="1.00"
  LOCAL_LAST_TIMESTAMP="250501_0000"
else
  LOCAL_LAST_VER=$(echo "$LOCAL_LAST_LINE" | jq -r '.version')
  LOCAL_LAST_TIMESTAMP=$(echo "$LOCAL_LAST_LINE" | jq -r '.timestamp')
fi

###########################################
# 🕒 현재 timestamp 계산
###########################################
NOW_TIMESTAMP=$(date +%y%m%d_%H%M)

###########################################
# ✅ export 변수 설정
###########################################
export CURRENT_PC
export LATEST_VER
export LATEST_TIMESTAMP
export LOCAL_LAST_VER
export LOCAL_LAST_TIMESTAMP
export NOW_TIMESTAMP

echo "🧭 기준 버전: $LATEST_VER ($LATEST_TIMESTAMP)"
echo "🧭 현재 PC 기준 마지막 버전: $LOCAL_LAST_VER ($LOCAL_LAST_TIMESTAMP)"
echo "🕒 현재 실행 timestamp: $NOW_TIMESTAMP"
