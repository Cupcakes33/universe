# /universe.5-execute - [Step 5] Task 실행

## 사용법

```
/universe.5-execute              # execute.sh 실행 안내 출력
/universe.5-execute <task-id>    # 특정 task 1개만 직접 실행 (예: P1-03, F001-02)
```

## 전제 조건

- **project 모드**: `tasks/PROGRESS.md`와 `tasks/00-index.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/tasks/PROGRESS.md`와 `docs/features/{NNN}-{name}/tasks/00-index.md`가 존재해야 한다.
- 없으면 `/universe.4-decompose`를 먼저 실행하라고 안내하고 중단.

## 모드 감지

- `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `tasks/PROGRESS.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

## 모드 1: execute.sh (권장 — 자동 루프)

`execute.sh`는 bash 루프로 task를 순차 실행한다. 각 task마다 fresh Claude 세션을 사용하므로 context 오염이 없다.

### execute.sh 설치

프로젝트 루트에 `execute.sh`를 복사한 뒤 실행 권한을 부여한다:

```bash
# universe 플러그인 저장소에서 복사
cp path/to/universe/execute.sh ./execute.sh
chmod +x execute.sh
```

### 실행

```bash
./execute.sh [max-iterations] [sleep-seconds] [model]
```

| 인수 | 기본값 | 설명 |
|------|--------|------|
| max-iterations | 20 | 최대 반복 횟수 |
| sleep-seconds | 2 | task 간 대기 시간(초) |
| model | sonnet | 사용할 Claude 모델 |

**예시:**

```bash
./execute.sh 20 2 sonnet      # 최대 20회, 2초 대기, sonnet 모델
./execute.sh 30 1 haiku       # 최대 30회, 1초 대기, haiku 모델
./execute.sh                  # 기본값으로 실행
./execute.sh --help           # 도움말
```

### execute.sh 동작

1. `tasks/PROGRESS.md` (또는 feature 경로)와 `tasks/00-index.md` 를 읽어 모드 자동 감지
2. 루프마다 fresh `claude --dangerously-skip-permissions` 세션으로 task 1개 실행
3. `tasks/learnings.md` 에 발견사항 누적
4. Phase 완료 감지 시 품질 검토(phase-reviewer) 자동 실행
5. 3회 연속 진행 없으면 stale 감지로 자동 중단
6. `<universe-complete/>` 감지 시 루프 종료

---

## 모드 2: 단일 task 직접 실행

`<task-id>`를 지정하면 Claude가 직접 1개 task를 실행한다 (bash, execute.sh 없이).

### 1단계: 상태 파악

1. PROGRESS.md 읽기
2. 00-index.md 읽기 (Wave 구조 확인)
3. 지정된 task ID가 PROGRESS.md에 존재하는지 확인
   - 없으면 오류 출력 후 중단
4. 선행 의존성이 미완료이면 경고만 출력하고 진행 (사용자 명시 지정이므로)

### 2단계: 실행

1. PROGRESS.md에서 해당 task 상태 → `진행중`으로 변경
2. `tasks/learnings.md` 읽기 (이전 패턴 파악)
3. `tasks/{task-id}*.md` 읽기 (task 상세)
4. TDD 방식으로 구현 (테스트 먼저 → 구현 → 검증)

### 3단계: 완료 처리

**성공 시 (테스트 통과):**
- PROGRESS.md task 상태 → `완료`, 검증 컬럼 업데이트
- git commit: `feat: {task-id} {task-name}`
- `tasks/learnings.md` 에 발견사항 추가 (--- 구분자 이후에)

**실패 시:**
- PROGRESS.md task 상태 → `차단됨`, 비고에 원인 기록
- `tasks/learnings.md` 에 실패 내용 추가

### 4단계: Phase 완료 검증 (해당 시)

방금 완료한 task로 인해 Phase 전체가 완료되었으면 phase-reviewer를 실행한다.

**Phase 완료 조건**: 해당 Phase의 모든 task 상태가 `완료`

**phase-reviewer 실행 내용:**

**4-1. 구현 파일 수집**
- 완료된 Phase의 모든 task 문서를 읽는다
- 각 task가 생성/수정한 파일 목록을 파악한다 (PROGRESS.md 비고, task 문서, git diff 활용)

**4-2. 실제 코드 읽기**
- 해당 Phase에서 생성/수정된 **모든 파일을 직접 읽는다**
- 요약본이나 보고서에 의존하지 않는다

**4-3. 산출물 대조 검증**
다음 문서와 실제 코드를 대조한다:
- `docs/design.md` 또는 `docs/features/{NNN}-{name}/spec.md`: 요구사항이 빠짐없이 구현되었는가?
- `docs/architecture.md` 또는 `docs/features/{NNN}-{name}/plan.md`: 설계한 모듈 구조, 인터페이스, 의존 관계를 따르는가?
- `docs/erd.md`: 데이터 모델이 설계와 일치하는가? (있으면)

**4-4. 코드 품질 검증**
1. **규칙/컨벤션 준수**: CLAUDE.md, CODE-STANDARDS.md의 규칙을 따르는가?
2. **설계 원칙**: 단일 책임, 의존성 역전 등 객체지향 원칙이 지켜지는가?
3. **성능**: 명백한 성능 문제가 있는가? (N+1 쿼리, 불필요한 반복, 메모리 누수 패턴 등)
4. **보안**: 입력 검증, 인증/인가, SQL injection 등 보안 취약점이 있는가?
5. **에러 처리**: 실패 경로가 적절히 처리되는가?
6. **중복**: 기존 코드나 같은 Phase 내에서 중복 구현이 있는가?

**4-5. 검증 결과 처리**
- 문제가 없으면: PROGRESS.md에 `[Phase N 검증 완료]` 기록
- 문제가 있으면:
  - 각 문제를 심각도 (상/중/하)로 분류
  - 심각도 **상**: 수정 task를 생성하고 PROGRESS.md에 추가. 다음 Phase 진행 전 반드시 해결
  - 심각도 **중**: 수정 task를 생성하되, 다음 Phase와 병렬 진행 가능
  - 심각도 **하**: PROGRESS.md에 비고로 기록 (별도 task 불필요)
  - 수정 task ID: `P{Phase}-R{번호}` (예: P1-R01) / feature: `F{NNN}-R{번호}`

### 5단계: 실행 결과 보고

1. PROGRESS.md를 다시 읽어 최신 상태 확인
2. 사용자에게 보고:
   - 완료한 task
   - Phase 검증 결과 (4단계 실행 시)
   - 전체 진행률
3. 다음 착수 가능한 task가 있으면: "계속 실행하려면 `/universe.5-execute`를 다시 실행하거나 `execute.sh`를 사용하세요."
4. 모든 task가 완료되면:
   - project 모드: "모든 task가 완료되었습니다. `/universe.6-sync`로 문서를 동기화하세요."
   - feature 모드: "Feature의 모든 task가 완료되었습니다. `/universe.6-sync`로 feature 문서를 프로젝트에 통합하세요."

---

## 핵심 규칙

1. **매 실행 시 반드시 PROGRESS.md + 00-index.md 읽기**: 이전 대화 기억에 의존하지 않는다.
2. **Wave 단위 의존성 준수**: 00-index.md의 Wave 구성을 따른다.
3. **테스트 통과 없이 완료 금지**: 테스트 기준이 없는 task는 구현 후 직접 검증 기준을 만들어 확인한다.
4. **task 외 작업 금지**: task 문서에 없는 기능을 추가하지 않는다. 필요하면 새 task를 만든다.
5. **Phase 검증 통과 없이 다음 Phase 진행 금지**: 심각도 상 문제가 있으면 수정 task 완료 전까지 다음 Phase 착수 금지.
