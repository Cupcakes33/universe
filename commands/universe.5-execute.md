# /universe.5-execute - [Step 5] Task 병렬 실행 (worker 최대 4개)

## 사용법
```
/universe.5-execute              # 현재 Wave만 실행 (1회)
/universe.5-execute --auto       # 모든 task 완료까지 Wave 단위 자동 반복
/universe.5-execute <task-id>    # 특정 task 1개만 실행 (예: P1-03, F001-02)
```

## 전제 조건
- **project 모드**: `tasks/PROGRESS.md`와 `tasks/00-index.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/tasks/PROGRESS.md`와 `docs/features/{NNN}-{name}/tasks/00-index.md`가 존재해야 한다.
- 없으면 `/universe.4-decompose`를 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `tasks/PROGRESS.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

## 옵션 감지
- 사용자 입력에 `--auto`가 포함되어 있으면 → 자동 반복 모드
- 사용자 입력에 task ID(`P{N}-{XX}` 또는 `F{NNN}-{XX}` 패턴)가 포함되어 있으면 → 단일 task 모드
- 둘 다 없으면 → 현재 Wave 1회 실행 (기본)

---

## 실행 흐름 (공통)

### 1단계: 현재 상태 파악 (매 실행/반복마다 반드시)

1. PROGRESS.md 읽기
   - project 모드: `tasks/PROGRESS.md`
   - feature 모드: `docs/features/{NNN}-{name}/tasks/PROGRESS.md`
2. 00-index.md 읽기 (병렬 Wave 구성 확인)
   - project 모드: `tasks/00-index.md`
   - feature 모드: `docs/features/{NNN}-{name}/tasks/00-index.md`
3. 현재 상태 요약 출력:
   - 전체 진행률 (완료/전체)
   - 현재 Wave 번호
   - 현재 Wave의 착수 가능한 task 목록
4. 착수 가능한 task가 없으면 차단 원인 분석 후 사용자에게 보고하고 중단

### 2단계: 실행 대상 결정 및 팀 편성

**단일 task 모드일 때:**
- 지정된 task ID가 PROGRESS.md에 존재하는지 확인한다
- 존재하지 않으면 오류를 출력하고 중단한다
- 해당 task의 상태를 `진행중`으로 변경하고, 팀 없이 3단계를 직접 수행한다
- 선행 의존성이 미완료여도 사용자가 명시적으로 지정했으므로 실행한다 (경고만 출력)

**Wave 모드일 때 (기본 / --auto):**

**현재 Wave 결정:**
- PROGRESS.md에서 `대기` 상태이면서 선행 의존성이 모두 `완료`인 task들을 찾는다
- 00-index.md의 "병렬 Wave" 섹션과 대조하여 현재 Wave를 확정한다

**PROGRESS.md 일괄 상태 변경:**
- 현재 Wave의 모든 대상 task 상태를 `진행중`으로 변경한다 (worker spawn 전에 팀 리드가 직접)

**편성 및 실행:**

#### Case A: task 1개 → 직접 실행
- 팀 없이 3단계를 직접 수행한다.

#### Case B: task 2~4개 → 팀 병렬 실행

1. `TeamCreate`로 `universe-execute` 팀 생성
2. `TaskCreate`로 각 worker의 task를 팀 task list에 등록
3. 각 worker를 `Task` tool로 **하나의 메시지에서 동시에** spawn:
   ```
   Task tool 호출 (worker 수만큼 병렬로 한 번에):
     subagent_type: "general-purpose"
     team_name: "universe-execute"
     name: "worker-1" (~ "worker-N")
     prompt: 아래 Worker Prompt 템플릿 사용
   ```
4. 모든 worker의 완료 메시지를 기다린다

#### Case C: task 5개 이상 → 상위 4개만 선택
- 우선순위: Phase 번호 낮은 것 → task 번호 낮은 것
- 4개를 Case B와 동일하게 실행
- 나머지는 다음 반복(또는 다음 `/universe.5-execute`)에서 처리

**팀 구성:**

| Agent 이름 | 역할 |
|-----------|------|
| `worker-1` ~ `worker-N` | 각각 1개의 task 담당 (최대 4개) |

---

### Worker Prompt 템플릿

각 worker spawn 시 아래 prompt를 사용한다. `{변수}`는 실제 값으로 치환.

```
너는 universe-execute 팀의 {worker-name}이다.

## 담당 Task
- Task ID: {task-id}
- Task 문서: {task-file-path}

## 실행 절차
1. Task 문서를 읽고 목표, 상세 요구사항, 테스트 기준을 확인하라
2. 상세 요구사항을 하나씩 구현하라
   - 기존 코드 구조와 스타일을 따라라
   - CLAUDE.md, CODE-STANDARDS.md 규칙을 준수하라
3. 테스트 기준을 하나씩 검증하라
   - 자동화된 테스트가 있으면 실행
   - 수동 검증이 필요하면 직접 확인
4. 완료 시 팀 리드에게 결과를 SendMessage로 보고하라:
   - 성공: 구현/수정한 파일 목록, 통과한 테스트 기준
   - 실패: 실패 원인, 차단된 항목

## 주의사항
- PROGRESS.md는 수정하지 마라 (팀 리드가 관리)
- task 문서에 없는 기능을 추가하지 마라
- 구현 중 task 크기가 너무 크다고 판단되면 팀 리드에게 보고하라
```

---

### 3단계: 실행 결과 수집 및 PROGRESS.md 업데이트

모든 worker(또는 직접 실행) 완료 후:

1. 각 worker의 보고 내용을 수집한다
2. PROGRESS.md 일괄 업데이트:
   - 성공한 task → 상태를 `완료`로 변경
   - 실패한 task → 상태를 `차단됨`으로 변경, 실패 원인을 비고에 기록
3. 팀이 있었으면 모든 worker에게 `shutdown_request` → `TeamDelete`

### 4단계: Phase 완료 검증 (Devil's Advocate)

PROGRESS.md를 확인하여 **방금 완료한 Wave로 인해 Phase 전체가 완료되었는지** 판단한다.

**Phase 완료 조건**: 해당 Phase에 속하는 모든 task의 상태가 `완료`

Phase가 완료되지 않았으면 이 단계를 건너뛰고 5단계로 이동한다.

Phase가 완료되었으면 `phase-reviewer`를 별도 agent로 실행한다:

```
Task tool 호출:
  subagent_type: "general-purpose"
  name: "phase-reviewer"
  prompt: 아래 Phase Reviewer Prompt 템플릿 사용
```

**phase-reviewer 실행 내용:**

**4-1. 구현 파일 수집**
- 완료된 Phase의 모든 task 문서를 읽는다
- 각 task가 생성/수정한 파일 목록을 파악한다 (PROGRESS.md의 비고, task 문서의 상세 요구사항, git diff 활용)

**4-2. 실제 코드 읽기**
- 해당 Phase에서 생성/수정된 **모든 파일을 직접 읽는다**
- 요약본이나 보고서에 의존하지 않는다

**4-3. 산출물 대조 검증**
다음 문서와 실제 코드를 대조한다:
- `docs/design.md` 또는 `docs/features/{NNN}-{name}/spec.md`: 요구사항이 빠짐없이 구현되었는가?
- `docs/architecture.md` 또는 `docs/features/{NNN}-{name}/plan.md`: 설계한 모듈 구조, 인터페이스, 의존 관계를 따르는가?
- `docs/erd.md`: 데이터 모델이 설계와 일치하는가? (있으면)

**4-4. 코드 품질 검증**
다음 관점에서 실제 코드를 비판적으로 검토한다:
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

### 5단계: 반복 판단

**`--auto` 모드가 아닌 경우:**
- 이 단계를 건너뛰고 6단계로 이동한다.

**`--auto` 모드인 경우:**
다음 중 하나에 해당하면 **자동 반복 중단**, 6단계로 이동:
- 모든 task가 `완료` 상태 (성공 완료)
- Phase 검증에서 심각도 **상** 문제 발견 (수정 필요)
- 착수 가능한 task가 없음 (전부 `차단됨` 또는 의존성 미해소)

위 조건에 해당하지 않으면: **1단계로 돌아가 다음 Wave를 실행한다.**

### 6단계: 실행 결과 보고

1. PROGRESS.md를 다시 읽어 최신 상태 확인
2. 사용자에게 보고:
   - 이번 실행에서 완료한 task 목록
   - 차단된 task (있으면, 원인 포함)
   - Phase 검증 결과 (4단계 실행 시):
     - 발견된 문제 수 (상/중/하별)
     - 생성된 수정 task 목록
   - 새로 착수 가능해진 task 목록
   - 전체 진행률
3. `--auto` 모드로 완료된 경우: 총 실행한 Wave 수, 완료한 task 수 요약
4. 다음 착수 가능한 task가 있으면: "계속 실행하려면 `/universe.5-execute`를 다시 실행하세요."
   - `--auto`로 중단된 경우: 중단 원인과 함께 안내
5. 모든 task가 완료되면:
   - project 모드: "모든 task가 완료되었습니다. `/universe.6-sync`로 문서를 동기화하세요."
   - feature 모드: "Feature의 모든 task가 완료되었습니다. `/universe.6-sync`로 feature 문서를 프로젝트에 통합하세요."

---

## 핵심 규칙

1. **매 실행/반복 시작 시 반드시 PROGRESS.md + 00-index.md 읽기**: 컨텍스트 압축 방어. 이전 대화 기억에 의존하지 않는다.
2. **Wave 단위 실행**: 00-index.md의 병렬 Wave 구성을 따른다. Wave 내 task들은 의존성이 없으므로 병렬 실행 안전.
3. **PROGRESS.md는 팀 리드만 수정**: worker는 구현과 결과 보고만. PROGRESS.md 동시 편집 충돌을 방지.
4. **테스트 통과 없이 완료 금지**: 테스트 기준이 없는 task는 구현 후 직접 검증 기준을 만들어 확인한다.
5. **task 외 작업 금지**: task 문서에 없는 기능을 추가하지 않는다. 필요하면 새 task를 만든다.
6. **task 분할 시 PROGRESS.md 즉시 반영**: 분할된 새 task를 PROGRESS.md에 추가하고 의존성을 설정한다.
7. **병렬 실행 시 파일 충돌 주의**: 같은 파일을 수정하는 task는 병렬 실행하지 않는다.
8. **Phase 검증 통과 없이 다음 Phase 진행 금지**: 심각도 상 문제가 있으면 수정 task 완료 전까지 다음 Phase 착수 금지. 심각도 중 이하는 병렬 진행 가능.
