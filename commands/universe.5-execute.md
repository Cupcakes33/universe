# /universe.5-execute - [Step 5] Task 병렬 실행 (worker 최대 4개)

## 사용법
```
/universe.5-execute
```

## 전제 조건
- **project 모드**: `tasks/PROGRESS.md`와 `tasks/00-index.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 존재해야 한다.
- 없으면 `/universe.4-decompose`를 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `tasks/PROGRESS.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

## 실행 흐름 (공통)

### 1단계: 현재 상태 파악 (매 실행마다 반드시)

1. PROGRESS.md 읽기
   - project 모드: `tasks/PROGRESS.md`
   - feature 모드: `docs/features/{NNN}-{name}/tasks/PROGRESS.md`
2. 현재 상태 요약 출력:
   - 전체 진행률
   - 완료된 task 수
   - 현재 진행중인 task
   - 착수 가능한 task (상태=대기, 선행 의존성 모두 완료)
3. 착수 가능한 task가 없으면 차단 원인 분석 후 사용자에게 보고

### 2단계: 실행 대상 결정

착수 가능한 task 목록에서:
- 1개면: 바로 실행
- 2~4개면: agent team으로 병렬 실행
- 5개 이상이면: 우선순위 상위 4개를 선택하여 병렬 실행

병렬 실행 시 `universe-execute` 팀을 생성한다.

| Agent 이름 | 역할 |
|-----------|------|
| `worker-1` ~ `worker-N` | 각각 1개의 task 담당 (최대 4개) |
| `phase-reviewer` | Phase 완료 시 구현 검증 (devil's advocate). 항상 편성하되, Phase 완료 시에만 실행 |

단일 task면 팀 없이 직접 실행하되, Phase 완료 시에는 `phase-reviewer`를 별도 실행한다.

### 3단계: Task 실행 (각 worker 공통)

각 worker(또는 직접 실행 시)는 다음 순서를 반드시 따른다:

**3-1. Task 문서 읽기**
- project 모드: `tasks/P{N}-{XX}-{이름}.md`
- feature 모드: `docs/features/{NNN}-{name}/tasks/F{NNN}-{XX}-{이름}.md`
- 메타정보, 목표, 상세 요구사항, 테스트 기준 확인

**3-2. PROGRESS.md 상태 변경**
- 해당 task 상태를 `진행중`으로 변경

**3-3. 구현**
- task 문서의 상세 요구사항을 하나씩 구현
- 기존 코드 구조와 스타일을 따름
- CLAUDE.md, CODE-STANDARDS.md 규칙 준수
- 구현 중 예상치 못한 복잡성 발견 시:
  - task 크기가 79%를 초과하면 task를 분할하고 PROGRESS.md에 새 task 추가
  - 사용자에게 분할 사실 보고

**3-4. 테스트 기준 검증**
- task 문서의 "테스트 기준" 항목을 하나씩 확인
- 자동화된 테스트가 있으면 실행
- 수동 검증이 필요한 항목은 검증 결과 기록
- 모든 테스트 기준을 통과해야 완료

**3-5. PROGRESS.md 업데이트**
- 테스트 통과 시: 상태를 `완료`로 변경
- 테스트 실패 시: 상태를 `차단됨`으로 변경, 실패 원인 기록
- **완료 표시가 없으면 절대 완료로 간주하지 않음**

### 4단계: Phase 완료 검증 (Devil's Advocate)

모든 worker 완료 후, PROGRESS.md를 확인하여 **Phase 전체가 완료되었는지** 판단한다.

**Phase 완료 조건**: 해당 Phase에 속하는 모든 task의 상태가 `완료`

Phase가 완료되지 않았으면 이 단계를 건너뛰고 5단계로 이동한다.

Phase가 완료되었으면 `phase-reviewer`를 실행한다.

**phase-reviewer에게 할당할 task:**

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
  - 수정 task ID: `P{Phase}-R{번호}` (예: P1-R01, P2-R01) / feature: `F{NNN}-R{번호}`

### 5단계: 실행 결과 보고

모든 worker 완료 후 (팀 실행 시 팀 종료):
1. PROGRESS.md를 다시 읽어 최신 상태 확인
2. 사용자에게 보고:
   - 이번 실행에서 완료한 task 목록
   - 차단된 task (있으면, 원인 포함)
   - Phase 검증 결과 (4단계 실행 시):
     - 발견된 문제 수 (상/중/하별)
     - 생성된 수정 task 목록
   - 새로 착수 가능해진 task 목록
   - 전체 진행률
3. 다음 착수 가능한 task가 있으면: "계속 실행하려면 `/universe.5-execute`를 다시 실행하세요."
4. 모든 task가 완료되면:
   - project 모드: "모든 task가 완료되었습니다. `/universe.6-sync`로 문서를 동기화하세요."
   - feature 모드: "Feature의 모든 task가 완료되었습니다. `/universe.6-sync`로 feature 문서를 프로젝트에 통합하세요."

---

## 핵심 규칙

1. **매 실행 시작 시 반드시 PROGRESS.md 읽기**: 컨텍스트 압축 방어. 이전 대화 기억에 의존하지 않는다.
2. **테스트 통과 없이 완료 금지**: 테스트 기준이 없는 task는 구현 후 직접 검증 기준을 만들어 확인한다.
3. **task 외 작업 금지**: task 문서에 없는 기능을 추가하지 않는다. 필요하면 새 task를 만든다.
4. **task 분할 시 PROGRESS.md 즉시 반영**: 분할된 새 task를 PROGRESS.md에 추가하고 의존성을 설정한다.
5. **병렬 실행 시 파일 충돌 주의**: 같은 파일을 수정하는 task는 병렬 실행하지 않는다. 00-index.md의 Wave 구성을 따른다.
6. **Phase 검증 통과 없이 다음 Phase 진행 금지**: 심각도 상 문제가 있는 수정 task가 완료되기 전까지 다음 Phase의 task를 착수하지 않는다. 심각도 중 이하는 병렬 진행 가능.
