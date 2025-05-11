#!/bin/bash
# mkss.sh — 변경 감지 → snapshot 생성 → 버전 확정

source "$(dirname "$0")/../config/env.sh"

###########################################
# 1️⃣ detect_change 실행
###########################################
bash "$DETECT_CHANGE_SCRIPT"

if [ "$SNAPSHOT_REQUIRED" = "1" ]; then
  if [ "$DDL_FILE_LINES" -eq 0 ] && [ "$DML_FILE_LINES" -eq 0 ]; then
    echo "ℹ️ 변경 감지되었으나 반영할 내용이 없음 (빈 쿼리) -> 스냅샷 생략"
  else
    echo "✅ 변경 사항 존재"
    # 실제 copy + ver append
  fi
else
  echo "✅ 변경 사항 없음"
fi

###########################################
# 2️⃣ write_ss 실행
###########################################
bash "$WRITE_SS_SCRIPT"

###########################################
# 3️⃣ snapshot 확정: next_ver → timestamp 폴더로 이름 변경
###########################################
FINAL_SS_DIR="$RECOVERY_BY_TIME_DIR/$NOW_TIMESTAMP"
mv "$RECOVERY_BY_TIME_DIR/next_ver" "$FINAL_SS_DIR"

###########################################
# 4️⃣ ver.jsonl에 버전 append
###########################################
# 다음 버전 계산 (ex: 1.03 → 1.04)
IFS='.' read -r MAJOR MINOR <<< "$LATEST_VER"
NEW_MINOR=$((10#$MINOR + 1))
NEW_VER=$(printf "%d.%02d" "$MAJOR" "$NEW_MINOR")

# 버전 JSON 객체 생성
# 📦 사용된 SQL 파일 리스트 추출
USED_FILES=()
while IFS= read -r STEP; do
  CLEAN_STEP=$(echo "$STEP" | tr -d '\r')  # 🔥 줄 끝 CR 제거
  FILE="$FINAL_SS_DIR/$CLEAN_STEP.sql"
  if [ -s "$FILE" ]; then
    USED_FILES+=("$CLEAN_STEP.sql")
  fi
done < "$ORDER_FILE"

# 📄 JSON 배열 생성
FILES_JSON=$(printf '%s\n' "${USED_FILES[@]}" | jq -R . | jq -s .)

# 🔐 최종 버전 JSON 객체 생성
NEW_JSON=$(jq -n \
  --arg ver "$NEW_VER" \
  --arg time "$NOW_TIMESTAMP" \
  --arg pc "$CURRENT_PC" \
  --argjson files "$FILES_JSON" \
  '{version: $ver, timestamp: $time, pc: $pc, files: $files}')


# append
echo "$NEW_JSON" >> "$VERSION_JSON"

echo "📦 스냅샷 확정: 버전 $NEW_VER ($NOW_TIMESTAMP)"
echo "📂 위치: $FINAL_SS_DIR"
