#!/bin/bash
# fallback.sh — 로컬 컨테이너 초기화 + SSD 컨테이너 복제

source "$(dirname "$0")/../config/env.sh"

echo "♻️ fallback 시작: 로컬 컨테이너 초기화 + SSD 복제"

# 1. 로컬 컨테이너 삭제
if docker ps -a --format '{{.Names}}' | grep -q "^$LOCAL_CONTAINER$"; then
  echo "🗑 기존 로컬 컨테이너 중지 및 삭제"
  docker stop "$LOCAL_CONTAINER" >/dev/null 2>&1
  docker rm "$LOCAL_CONTAINER" >/dev/null 2>&1
else
  echo "✅ 기존 로컬 컨테이너 없음 (삭제 불필요)"
fi

# 2. SSD 컨테이너 복제 (volume은 동일하게 마운트, 포트만 로컬용으로 변경)
docker run -d \
  --name "$LOCAL_CONTAINER" \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -p "$DB_PORT_LOCAL":5432 \
  -v "${DB_SSD_PATH}:/var/lib/postgresql/data" \
  "$DB_IMAGE_VERSION" >/dev/null

# 3. 로그 기록
echo "[FALLBACK] 로컬 컨테이너 초기화 완료 → SSD 복제됨" >> "$ERR_LOG_FILE"
echo "✅ fallback 성공: 새 컨테이너 $LOCAL_CONTAINER"

