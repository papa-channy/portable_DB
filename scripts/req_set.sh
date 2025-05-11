#!/bin/bash
# req_set.sh — 매 실행 시 필수 환경 자동 보정 스크립트

source "$(dirname "$0")/../config/env.sh"

###########################################
# 📌 필수 도구 설치 보조 로직
###########################################
# [1] jq 확인 + 보조 설치
###########################################
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq가 설치되어 있지 않습니다."

    echo ""
    echo "📦 선택하세요: [jq] 설치 방식"
    echo "1. 내 PC에 설치 후 자동 세팅 도움받기"
    echo "2. SSD 내 bin 폴더에만 경로 추가하여 사용"
    echo -n "선택 (1 or 2): "
    read -r jq_choice

    while [[ "$jq_choice" != "1" && "$jq_choice" != "2" ]]; do
        echo -n "❗ 다시 입력하세요 (1 or 2): "
        read -r jq_choice
    done

    if [ "$jq_choice" = "1" ]; then
        echo ""
        echo "📘 jq 설치 안내:"
        echo "1. https://stedolan.github.io/jq/download/ 접속"
        echo "2. Windows용 jq.exe 다운로드"
        echo "3. 시스템 PATH에 jq.exe 위치 추가"
        echo ""
        echo "📌 설치 완료 후 다시 실행해주세요."
        exit 1

    elif [ "$jq_choice" = "2" ]; then
        TOOL_PATH="$ROOT_DIR/bin"
        if [ -f "$TOOL_PATH/jq.exe" ]; then
            echo "export PATH=\"\$PATH:$TOOL_PATH\"" >> ~/.bashrc
            echo "✅ ~/.bashrc에 jq 경로 추가 완료"
            echo "📌 현재 세션에서는 다음 명령 실행 필요: source ~/.bashrc"
            exit 1
        else
            echo "❌ $TOOL_PATH/jq.exe 가 존재하지 않습니다. bin 폴더에 jq를 넣어주세요."
            exit 1
        fi
    fi
fi

###########################################
# [2] pg_isready 확인 + 보조 설치
###########################################
if ! command -v pg_isready >/dev/null 2>&1; then
    echo "❌ pg_isready가 설치되어 있지 않습니다."

    echo ""
    echo "📦 선택하세요: [pg_isready] 설치 방식"
    echo "1. 내 PC에 설치 후 자동 세팅 도움받기"
    echo "2. SSD 내 bin 폴더에만 경로 추가하여 사용"
    echo -n "선택 (1 or 2): "
    read -r pg_choice

    while [[ "$pg_choice" != "1" && "$pg_choice" != "2" ]]; do
        echo -n "❗ 다시 입력하세요 (1 or 2): "
        read -r pg_choice
    done

    if [ "$pg_choice" = "1" ]; then
        echo ""
        echo "📘 pg_isready 설치 안내:"
        echo "1. https://www.enterprisedb.com/downloads/postgres-postgresql-downloads 접속"
        echo "2. PostgreSQL 설치 시 'Command Line Tools' 체크"
        echo "3. 설치 후 'C:\\Program Files\\PostgreSQL\\16\\bin'을 시스템 PATH에 등록"
        echo ""
        echo "📌 설치 완료 후 다시 실행해주세요."
        exit 1

    elif [ "$pg_choice" = "2" ]; then
        TOOL_PATH="$ROOT_DIR/bin"
        if [ -f "$TOOL_PATH/pg_isready.exe" ]; then
            echo "export PATH=\"\$PATH:$TOOL_PATH\"" >> ~/.bashrc
            echo "✅ ~/.bashrc에 pg_isready 경로 추가 완료"
            echo "📌 현재 세션에서는 다음 명령 실행 필요: source ~/.bashrc"
            exit 1
        else
            echo "❌ $TOOL_PATH/pg_isready.exe 가 존재하지 않습니다. bin 폴더에 파일을 넣어주세요."
            exit 1
        fi
    fi
fi

SSD_CREATED=0
LOCAL_CREATED=0
NEED_WAIT=0

###########################################
# SSD 컨테이너 생성 여부 확인
###########################################
# SSD 컨테이너 체크
if ! docker ps -a --format '{{.Names}}' | grep -q "^$SSD_CONTAINER$"; then
    echo "⚠️ SSD 컨테이너($SSD_CONTAINER)가 존재하지 않습니다. 생성을 시작합니다..."

    docker run -d \
      --name "$SSD_CONTAINER" \
      -e POSTGRES_USER="$POSTGRES_USER" \
      -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
      -e POSTGRES_DB="$POSTGRES_DB" \
      -p "$DB_PORT_SSD":5432 \
      -v "${DB_SSD_PATH}:/var/lib/postgresql/data" \
      "$DB_IMAGE_VERSION" >/dev/null

    echo "✅ SSD 컨테이너 생성 완료: $SSD_CONTAINER"
    SSD_CREATED=1
    NEED_WAIT=1
fi


###########################################
# LOCAL 컨테이너 생성 여부 확인
###########################################
if ! docker ps -a --format '{{.Names}}' | grep -q "^$LOCAL_CONTAINER$"; then
    echo "⚠️ 로컬 컨테이너가 존재하지 않습니다. SSD 컨테이너를 복제합니다..."

    docker create \
        --name "$LOCAL_CONTAINER" \
        -e POSTGRES_USER="$POSTGRES_USER" \
        -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -e POSTGRES_DB="$POSTGRES_DB" \
        -p "$DB_PORT_LOCAL":5432 \
        -v "${DB_LOCAL_PATH}:/var/lib/postgresql/data" \
        "$DB_IMAGE_VERSION"

    echo "✅ 로컬 컨테이너 생성 완료: $LOCAL_CONTAINER"
    LOCAL_CREATED=1
    NEED_WAIT=1
fi

###########################################
# 둘 중 하나라도 새로 생성됐으면 대기
###########################################
if [ "$NEED_WAIT" = 1 ]; then
    echo "⏳ PostgreSQL 컨테이너 초기화 대기 중..."
    sleep 15
fi

###########################################
# 2. 컨테이너가 꺼져 있으면 자동 시작 + 대기
###########################################
if ! docker ps --format '{{.Names}}' | grep -q "^$LOCAL_CONTAINER$"; then
    echo "🔄 로컬 컨테이너 실행 중 아님 → 시작 시도..."
    docker start "$LOCAL_CONTAINER"
fi
# 최종 확인 (컨테이너가 이미 켜져 있던 경우도 포함)
if ! pg_isready -p "$DB_PORT_LOCAL" &>/dev/null; then
    echo "❌ 로컬 컨테이너 통신 불가 (pg_isready 실패)"
    exit 1
fi

###########################################
# 3. pg_isready 통신 점검
###########################################
if ! pg_isready -p "$DB_PORT_LOCAL" &>/dev/null; then
    echo "❌ 로컬 컨테이너 통신 불가 (pg_isready 실패)"
    exit 1
fi

###########################################
# 4. 바탕화면 로그 폴더 점검
###########################################
if [ ! -d "$DESKTOP_DB_DIR" ]; then
    echo "📁 바탕화면 DB 폴더가 없습니다 → 생성 중..."
    mkdir -p "$DESKTOP_DB_DIR"
fi

docker exec -i "$SSD_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'EOSQL'
CREATE TABLE IF NOT EXISTS __change_log (
  id SERIAL PRIMARY KEY,
  table_name TEXT,
  action_type TEXT,
  query_text TEXT,
  timestamp TIMESTAMP
);
EOSQL
sleep 3

###########################################
# 5. 트리거 없는 테이블에 자동 생성
###########################################
echo "🔍 테이블별 트리거 점검 및 자동 생성 중..."

psql -U "$POSTGRES_USER" -p "$DB_PORT_SSD" -d "$POSTGRES_DB" -t -c "
DO \$\$
DECLARE
  r RECORD;
BEGIN
  -- 트리거 함수 존재 확인 및 생성
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'track_changes'
  ) THEN
    CREATE OR REPLACE FUNCTION track_changes()
    RETURNS trigger AS \$BODY\$
    BEGIN
      INSERT INTO __change_log (table_name, action_type, query_text, timestamp)
      VALUES (TG_RELNAME, TG_OP, current_query(), now());

      NEW.updated_at := NOW();
      RETURN NEW;
    END;
    \$BODY\$ LANGUAGE plpgsql;
  END IF;

  -- 모든 사용자 테이블에 트리거 생성
  FOR r IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger
      WHERE tgname = 'change_tracker_trigger_' || r.tablename
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER change_tracker_trigger_%1\$s
         BEFORE UPDATE OR DELETE ON %1\$I
         FOR EACH ROW EXECUTE FUNCTION track_changes()',
        r.tablename
      );
    END IF;
  END LOOP;
END
\$\$;
"

if [ $? -ne 0 ]; then
    echo "❌ 트리거 생성 실패 (오류 기록됨)" | tee -a "$ERR_LOG_FILE"
else
    echo "✅ 트리거 생성 완료"
fi
###########################################
# 6. event trigger 자동 설치 (CREATE TABLE 감지용)
###########################################
if ! docker exec "$SSD_CONTAINER" pg_isready -U "$POSTGRES_USER" -p 5432 >/dev/null; then
  echo "❌ SSD 컨테이너에 접속할 수 없습니다. event trigger 설치 스킵됨."
else
  EXISTS=$(docker exec "$SSD_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "
    SELECT COUNT(*) FROM pg_event_trigger WHERE evtname = 'trg_on_create_table';
  ")

  if [ "$EXISTS" -eq 0 ]; then

    docker exec -i "$SSD_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'EOF'
    CREATE OR REPLACE FUNCTION auto_attach_change_tracker()
    RETURNS event_trigger AS $$
    DECLARE
        obj RECORD;
    BEGIN
        FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        LOOP
            IF obj.object_type = 'table' AND obj.schema_name = 'public' THEN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_trigger
                    WHERE tgrelid = obj.object_identity::regclass
                    AND tgname = 'change_tracker_trigger_' || obj.object_name
                ) THEN
                    EXECUTE format('
                        CREATE TRIGGER change_tracker_trigger_%1$s
                        BEFORE UPDATE OR DELETE ON public.%1$I
                        FOR EACH ROW EXECUTE FUNCTION track_changes()',
                        split_part(obj.object_identity::text, '.', 2)
                    );
                END IF;
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

    CREATE EVENT TRIGGER trg_on_create_table
    ON ddl_command_end
    WHEN TAG IN ('CREATE TABLE')
    EXECUTE FUNCTION auto_attach_change_tracker();
EOF

    if [ $? -ne 0 ]; then
      echo "❌ event trigger 생성 실패 (오류 기록됨)" | tee -a "$ERR_LOG_FILE"
    else
      echo "✅ event trigger 자동 설치 완료"
    fi
  fi
fi

###########################################
# 6. 디스크 용량 부족 경고 (선택적)
###########################################
DISK_PATH=$(echo "$DB_SSD_PATH" | cut -d'/' -f2)
df_output=$(df -k "/$DISK_PATH" 2>/dev/null | tail -1)
free_kb=$(echo "$df_output" | awk '{print $4}')
if [ "$free_kb" -lt 1048576 ]; then  # 1GB 미만
    echo "⚠️ 경고: 디스크 여유 공간 1GB 미만"
fi

echo "✅ req_set.sh 완료: 환경 보정 성공"
