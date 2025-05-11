#!/bin/bash
# first_set.sh — 최초 1회 실행용 초기 세팅 스크립트

source "$(dirname "$0")/env.sh"

echo "🔧 프로젝트 초기 세팅 시작"

###########################################
# 0. jq 설치 여부 확인 + fallback 등록
###########################################
if ! command -v jq &>/dev/null; then
    echo "⚠️ jq가 시스템에 설치되어 있지 않습니다."

    export JQ_PATH="$ROOT_DIR/bin/jq"

    if [ -x "$JQ_PATH" ]; then
        export PATH="$(dirname "$JQ_PATH"):$PATH"
        echo "✅ SSD 내부 jq 경로 등록 완료: $JQ_PATH"
    else
        echo "❌ jq 실행 파일이 SSD 내부에도 존재하지 않습니다."
        echo "👉 /bin 디렉토리에 jq binary를 복사하거나 시스템에 설치해 주세요."
        exit 1
    fi
fi

if ! command -v jq &>/dev/null; then
    echo "❌ 최종 확인: jq 여전히 실행 불가"
    exit 1
else
    echo "✅ jq 실행 확인됨"
fi

###########################################
# 1. 필수 디렉토리 생성
###########################################
mkdir -p "$LOGS_DIR"
mkdir -p "$RECOVERY_BY_TIME_DIR"
mkdir -p "$RECOVERY_DDL_CLASSIFIED_DIR"
mkdir -p "$DESKTOP_DB_DIR"

###########################################
# 2. 필수 로그/쿼리 파일 생성
###########################################
touch "$VERSION_JSON"
touch "$ERR_LOG_FILE"
touch "$RECOVERY_DDL_ALL"
touch "$RECOVERY_DDL_ALTER"
touch "$RECOVERY_DDL_CREATE"
touch "$RECOVERY_DDL_DROP"
touch "$RECOVERY_DDL_INDEX"

###########################################
# 3. order.txt 샘플 생성 (비어있을 때만)
###########################################
if [ ! -s "$ORDER_FILE" ]; then
  cat <<EOF > "$ORDER_FILE"
schema/type_define
schema/table_create
schema/sequence_define
schema/add_column
schema/constraint_define
data/insert_static
data/insert_relational
data/update_values
data/delete_direct
data/delete_cascade
restore/reinsert
restore/reupdate
restore/redelete
sequence_reset
index/index_create
meta/comment_define
EOF
fi

###########################################
# 4. 바탕화면 로그 파일 생성
###########################################
touch "$LOCAL_PORT_LOG"

###########################################
# 5. SSD 컨테이너 존재 여부 확인
###########################################
if ! docker ps -a --format '{{.Names}}' | grep -q "ssd_${POSTGRES_DB}"; then
    echo "⚠️ SSD 컨테이너가 존재하지 않습니다. rundb 최초 실행 시 자동 생성됩니다."
fi

###########################################
# 6. rundb alias 등록
###########################################
if ! grep -q "alias rundb=" ~/.bashrc; then
    echo "alias rundb='bash $RUNDB_SCRIPT'" >> ~/.bashrc
    echo "✅ rundb alias 등록 완료 (터미널 재시작 후 사용 가능)"
fi

echo "🎉 first_set.sh 초기 세팅 완료"
