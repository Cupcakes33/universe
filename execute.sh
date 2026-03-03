#!/bin/bash
# execute.sh - Universe Ralph Loop 실행기
# universe.4-decompose로 분해된 task를 bash 루프로 자동 실행합니다.
# 각 task마다 fresh Claude 세션을 사용하여 context 오염을 방지합니다.

# ============================================================
# usage
# ============================================================
usage() {
  cat << 'EOF'
사용법: ./execute.sh [max-iterations] [sleep-seconds] [model]

  max-iterations  최대 반복 횟수 (기본값: 20)
  sleep-seconds   task 간 대기 시간(초) (기본값: 2)
  model           Claude 모델 이름 (기본값: sonnet)

예시:
  ./execute.sh 20 2 sonnet      # 최대 20회, 2초 대기, sonnet 모델
  ./execute.sh 30 1 haiku       # 최대 30회, 1초 대기, haiku 모델
  ./execute.sh                  # 기본값으로 실행 (20회, 2초, sonnet)

전제 조건:
  - tasks/PROGRESS.md 또는 docs/features/{NNN}-{name}/tasks/PROGRESS.md 존재
  - tasks/00-index.md 또는 docs/features/{NNN}-{name}/tasks/00-index.md 존재
  - /universe.4-decompose 로 task 분해 완료 후 실행할 것

동작:
  - 각 task마다 fresh Claude 세션으로 실행 (context 오염 없음)
  - stale 감지: 3회 연속 진행 없으면 자동 중단
  - Phase 완료 시 품질 검토(phase-reviewer) 자동 실행
  - tasks/learnings.md 에 발견사항 누적
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

# ============================================================
# 설정
# ============================================================
MAX_ITER="${1:-20}"
SLEEP_SEC="${2:-2}"
MODEL="${3:-sonnet}"

# ============================================================
# 모드 감지 (project vs feature)
# ============================================================
detect_mode() {
  local latest_feature
  latest_feature=$(find docs/features -name PROGRESS.md -path "*/tasks/PROGRESS.md" 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -1)

  if [[ -n "$latest_feature" ]]; then
    local feature_dir
    feature_dir=$(dirname "$(dirname "$latest_feature")")
    echo "feature:$feature_dir"
  elif [[ -f "tasks/PROGRESS.md" ]]; then
    echo "project"
  else
    echo "none"
  fi
}

MODE_RESULT=$(detect_mode)

if [[ "$MODE_RESULT" == "none" ]]; then
  echo "❌ PROGRESS.md를 찾을 수 없습니다."
  echo "   tasks/PROGRESS.md 또는 docs/features/{NNN}-{name}/tasks/PROGRESS.md 가 필요합니다."
  echo "   /universe.4-decompose 를 먼저 실행하세요."
  exit 1
fi

if [[ "$MODE_RESULT" == "project" ]]; then
  PROGRESS_FILE="tasks/PROGRESS.md"
  INDEX_FILE="tasks/00-index.md"
  TASK_DIR="tasks"
  MODE_LABEL="project"
else
  FEATURE_DIR="${MODE_RESULT#feature:}"
  PROGRESS_FILE="${FEATURE_DIR}/tasks/PROGRESS.md"
  INDEX_FILE="${FEATURE_DIR}/tasks/00-index.md"
  TASK_DIR="${FEATURE_DIR}/tasks"
  MODE_LABEL="feature ($(basename "$FEATURE_DIR"))"
fi

LEARNINGS_FILE="${TASK_DIR}/learnings.md"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "❌ $INDEX_FILE 을 찾을 수 없습니다."
  echo "   /universe.4-decompose 를 먼저 실행하세요."
  exit 1
fi

# ============================================================
# learnings.md 초기화
# ============================================================
if [[ ! -f "$LEARNINGS_FILE" ]]; then
  cat > "$LEARNINGS_FILE" << 'EOF'
# learnings.md - 실행 중 발견된 패턴 및 교훈

이 파일은 execute.sh 루프가 자동으로 업데이트합니다.
각 Claude 세션은 `---` 구분자 이후에 발견사항을 추가합니다.

---
EOF
  echo "✅ ${LEARNINGS_FILE} 초기화됨"
fi

# ============================================================
# 유틸 함수
# ============================================================

# PROGRESS.md에서 task 행은 "| P1-01 |" 또는 "| F001-01 |" 형태로 시작
count_total() {
  local n
  n=$(grep -cE '^\| [PF][0-9]' "$PROGRESS_FILE" 2>/dev/null) || n=0
  echo "$n"
}

count_done() {
  local n
  n=$(grep -E '^\| [PF][0-9]' "$PROGRESS_FILE" 2>/dev/null | grep -c '완료') || n=0
  echo "$n"
}

count_blocked() {
  local n
  n=$(grep -E '^\| [PF][0-9]' "$PROGRESS_FILE" 2>/dev/null | grep -c '차단됨') || n=0
  echo "$n"
}

count_incomplete() {
  local n
  n=$(grep -E '^\| [PF][0-9]' "$PROGRESS_FILE" 2>/dev/null \
    | grep -v '완료\|차단됨' | wc -l | tr -d ' ') || n=0
  echo "$n"
}

# phase: "P1", "P2", "F001" 등 (task ID 접두사)
check_phase_complete() {
  local phase="$1"
  local total done
  total=$(grep -cE "^\| ${phase}-" "$PROGRESS_FILE" 2>/dev/null) || total=0
  done=$(grep -E "^\| ${phase}-" "$PROGRESS_FILE" 2>/dev/null | grep -c '완료') || done=0
  [[ "$total" -gt 0 && "$total" -eq "$done" ]]
}

# 모든 phase 목록 (P1, P2, F001 등)
get_all_phases() {
  grep -oE '^\| [PF][0-9]+-' "$PROGRESS_FILE" 2>/dev/null \
    | grep -oE '[PF][0-9]+' | sort -u || true
}

# macOS bash 3.x 호환: 스페이스 구분 문자열로 phase 추적
REVIEWED_PHASES=""

phase_already_reviewed() {
  [[ " $REVIEWED_PHASES " == *" $1 "* ]]
}

mark_phase_reviewed() {
  REVIEWED_PHASES="${REVIEWED_PHASES} $1"
}

# ============================================================
# Phase Reviewer (Phase 완료 시 품질 검토)
# ============================================================
run_phase_review() {
  local phase="$1"
  local prompt_file
  prompt_file=$(mktemp /tmp/universe-review-XXXXXX.md)

  cat > "$prompt_file" << EOF
너는 Universe Phase Reviewer다. Phase ${phase}의 구현 품질을 비판적으로 검토하라.

## 검토 대상
Phase ${phase}에 속하는 모든 task (task ID가 '${phase}-'로 시작)

## 파일 경로
- PROGRESS 파일: ${PROGRESS_FILE}
- task 디렉토리: ${TASK_DIR}

## 절차

### 1. 구현 파일 수집
- Phase ${phase}의 모든 task 문서를 ${TASK_DIR}에서 읽어라
- 각 task가 생성/수정한 파일 목록을 파악하라 (PROGRESS.md 비고, task 문서, git diff 활용)

### 2. 실제 코드 읽기
- 해당 Phase에서 생성/수정된 모든 파일을 직접 읽어라
- 요약본이나 보고서에 의존하지 말라

### 3. 산출물 대조 검증
- docs/design.md 또는 spec.md: 요구사항이 빠짐없이 구현되었는가?
- docs/architecture.md 또는 plan.md: 설계한 모듈 구조, 인터페이스, 의존 관계를 따르는가?
- docs/erd.md: 데이터 모델이 설계와 일치하는가? (있으면)

### 4. 코드 품질 검증
1. 규칙/컨벤션 준수: CLAUDE.md, CODE-STANDARDS.md 규칙을 따르는가?
2. 설계 원칙: 단일 책임, 의존성 역전 등 객체지향 원칙이 지켜지는가?
3. 성능: 명백한 성능 문제가 있는가? (N+1 쿼리, 불필요한 반복, 메모리 누수 패턴 등)
4. 보안: 입력 검증, 인증/인가, SQL injection 등 보안 취약점이 있는가?
5. 에러 처리: 실패 경로가 적절히 처리되는가?
6. 중복: 기존 코드나 같은 Phase 내에서 중복 구현이 있는가?

### 5. 결과 처리
- 문제가 없으면: ${PROGRESS_FILE}에 '[Phase ${phase} 검증 완료]' 기록
- 문제가 있으면:
  - 각 문제를 심각도 (상/중/하)로 분류
  - 심각도 상: 수정 task를 ${PROGRESS_FILE}에 추가 (ID: ${phase}-R{번호}), 다음 Phase 진행 전 필수 해결
  - 심각도 중: 수정 task 추가, 다음 Phase와 병렬 진행 가능
  - 심각도 하: ${PROGRESS_FILE} 비고에 기록 (별도 task 불필요)
EOF

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Phase ${phase} 완료 감지 — 품질 검토 시작..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  claude --model "$MODEL" --dangerously-skip-permissions \
    -p "@${PROGRESS_FILE} @${INDEX_FILE} @${prompt_file}" 2>&1

  rm -f "$prompt_file"
  echo ""
  echo "✅ Phase ${phase} 품질 검토 완료"
}

# ============================================================
# 메인 실행 프롬프트 (temp file로 전달)
# ============================================================
build_execute_prompt() {
  local prompt_file="$1"
  cat > "$prompt_file" << EOF
너는 Universe 실행 agent다. 정확히 ONE task를 실행하라.

## 금지
- EnterPlanMode 사용 금지 (task 문서에 상세 지침 있음)
- task 문서에 없는 기능 추가 금지

## 다음 task 결정
1. ${PROGRESS_FILE} 을 읽어라
2. ${INDEX_FILE} 을 읽어 Wave 구조를 파악하라
3. 상태가 '대기'이면서 의존성(Wave 기준)이 모두 '완료'인 task 중 첫 번째를 선택하라
4. 선택 가능한 task가 없으면 (모두 '완료' 또는 '차단됨'): <universe-complete/> 출력 후 종료

## 실행 절차
1. ${PROGRESS_FILE} 에서 해당 task 상태를 '진행중'으로 변경
2. ${LEARNINGS_FILE} 읽기 (이전 패턴 파악)
3. ${TASK_DIR}/{task-id}*.md 읽기 (task 상세)
4. TDD 방식으로 구현 (테스트 먼저 → 구현 → 검증)

## 완료 조건 (테스트 통과 시)
- PROGRESS.md task 상태 → '완료'
- 검증 컬럼 업데이트
- git commit: 'feat: {task-id} {task-name}'
- ${LEARNINGS_FILE} 에 발견사항 추가 (--- 구분자 이후에)
- 완료 후: <universe-task-done task-id="{ID}"/>

## 실패 시
- PROGRESS.md task 상태 → '차단됨', 비고에 원인 기록
- ${LEARNINGS_FILE} 에 실패 내용 추가

## 전체 완료 확인
모든 task가 '완료' 또는 '차단됨'이면:
- ${PROGRESS_FILE} 를 다시 읽어 '대기' task가 없는지 최종 확인
- <universe-complete/>
EOF
}

# ============================================================
# 실행 루프
# ============================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌌 Universe Execute Loop"
echo "   모드      : ${MODE_LABEL}"
echo "   최대 반복  : ${MAX_ITER}회"
echo "   대기 시간  : ${SLEEP_SEC}s"
echo "   모델      : ${MODEL}"
echo "   PROGRESS  : ${PROGRESS_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STALE_COUNT=0
STALE_LIMIT=3

# 실행 프롬프트 파일 (루프 전체에서 재사용)
EXEC_PROMPT_FILE=$(mktemp /tmp/universe-execute-XXXXXX.md)
trap "rm -f $EXEC_PROMPT_FILE" EXIT
build_execute_prompt "$EXEC_PROMPT_FILE"

for (( i=1; i<=MAX_ITER; i++ )); do
  BEFORE_DONE=$(count_done)
  BEFORE_INCOMPLETE=$(count_incomplete)
  TOTAL=$(count_total)

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 반복 ${i} / ${MAX_ITER}  |  진행률: ${BEFORE_DONE} / ${TOTAL}  |  미완료: ${BEFORE_INCOMPLETE}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ "$BEFORE_INCOMPLETE" -eq 0 ]]; then
    echo ""
    echo "🎉 모든 task가 완료 또는 차단됨 상태입니다."
    break
  fi

  # Claude 실행 (fresh 세션)
  EXEC_OUTPUT=$(claude --model "$MODEL" --dangerously-skip-permissions \
    -p "@${PROGRESS_FILE} @${INDEX_FILE} @${LEARNINGS_FILE} @${EXEC_PROMPT_FILE}" 2>&1)

  echo "$EXEC_OUTPUT"

  # 전체 완료 감지
  if echo "$EXEC_OUTPUT" | grep -q '<universe-complete/>'; then
    REMAINING=$(count_incomplete)
    echo ""
    if [[ "$REMAINING" -eq 0 ]]; then
      echo "✅ <universe-complete/> 감지 — 모든 task 처리 완료!"
    else
      echo "⚠️  <universe-complete/> 감지되었으나 미완료 task ${REMAINING}개 남아 있음"
      echo "   ${PROGRESS_FILE} 를 확인하여 차단 원인을 파악하세요."
    fi
    break
  fi

  # stale 감지 (진행 없음 방어)
  AFTER_DONE=$(count_done)
  AFTER_INCOMPLETE=$(count_incomplete)

  if [[ "$AFTER_DONE" -le "$BEFORE_DONE" && "$AFTER_INCOMPLETE" -ge "$BEFORE_INCOMPLETE" ]]; then
    STALE_COUNT=$((STALE_COUNT + 1))
    echo ""
    echo "⚠️  진행 없음 감지 (${STALE_COUNT} / ${STALE_LIMIT})"
    if [[ "$STALE_COUNT" -ge "$STALE_LIMIT" ]]; then
      echo "❌ ${STALE_LIMIT}회 연속 진행 없음 — 루프 중단"
      echo "   ${PROGRESS_FILE} 를 확인하여 차단 원인을 파악하세요."
      break
    fi
  else
    STALE_COUNT=0
  fi

  # Phase 완료 감지 및 품질 검토
  while IFS= read -r phase; do
    [[ -z "$phase" ]] && continue
    if ! phase_already_reviewed "$phase"; then
      if check_phase_complete "$phase"; then
        mark_phase_reviewed "$phase"
        run_phase_review "$phase"
      fi
    fi
  done < <(get_all_phases)

  [[ "$SLEEP_SEC" -gt 0 ]] && sleep "$SLEEP_SEC"
done

# ============================================================
# 최종 보고
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 최종 결과"
FINAL_TOTAL=$(count_total)
FINAL_DONE=$(count_done)
FINAL_BLOCKED=$(count_blocked)
FINAL_INCOMPLETE=$(count_incomplete)
echo "   완료    : ${FINAL_DONE} / ${FINAL_TOTAL}"
echo "   차단됨  : ${FINAL_BLOCKED}"
echo "   미완료  : ${FINAL_INCOMPLETE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$FINAL_INCOMPLETE" -eq 0 && "$FINAL_BLOCKED" -eq 0 ]]; then
  echo ""
  echo "🎉 모든 task 완료!"
  echo "   다음 단계: /universe.6-sync 로 문서를 동기화하세요."
elif [[ "$FINAL_INCOMPLETE" -eq 0 && "$FINAL_BLOCKED" -gt 0 ]]; then
  echo ""
  echo "⚠️  일부 task가 차단됨 상태입니다."
  echo "   ${PROGRESS_FILE} 에서 차단된 task와 원인을 확인하세요."
fi
