# /universe.4-decompose - [Step 4] 79% 크기 Task 분해 (agent 3~5개)

## 사용법
```
/universe.4-decompose
```

## 전제 조건
- **project 모드**: `spec/spec.md`가 존재해야 한다. (`spec/erd.md`, `spec/tech-stack.md`, `spec/contracts/`도 권장)
- **feature 모드**: `docs/features/{NNN}-{name}/spec.md`와 `docs/features/{NNN}-{name}/plan.md`가 존재해야 한다.
- 없으면 `/universe.3-blueprint`를 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/plan.md`가 있으면 → feature 모드
- `spec/spec.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

# project 모드

## 실행 흐름 (project 모드)

### 1단계: 입력 문서 로딩

다음 문서를 모두 읽는다:
- `spec/spec.md` (필수 — 유저 시나리오, 아키텍처, MVP 범위)
- `spec/erd.md` (있으면 — 데이터 모델)
- `spec/tech-stack.md` (있으면 — 기술 스택)
- `spec/contracts/*.md` (있으면 — API contract)
- `docs/research.md` (있으면)
- `docs/lessons.md` (있으면)

### 2단계: 팀 편성

`universe-decompose` 팀을 생성하고, 5개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `decomposer-infra` | 분해 1 | 인프라/설정/공통 모듈 task |
| `decomposer-core` | 분해 2 | 핵심 비즈니스 로직 task |
| `decomposer-api` | 분해 3 | API/인터페이스/통합 task |
| `decomposer-quality` | 분해 4 | 테스트/품질/배포 task |
| `decompose-reviewer` | 리뷰 | task 품질 검증 |

### 3단계: 분해 agent 4개 병렬 실행

모든 분해 agent는 `docs/` 전체 문서를 읽고 자기 담당 영역의 task를 생성한다.

**공통 규칙:**
- 각 task는 30분~1시간 크기 (79% 확률로 성공 가능한 크기)
- 하나의 task = 하나의 파일/기능/모듈에 집중
- task 간 의존성을 명확히 표시
- Phase를 논리적으로 구분 (기반 -> 핵심 -> 통합 -> 품질)
- 각 task의 "컨텍스트" 섹션에서 `spec/` 문서의 관련 섹션을 참조 (예: "spec/contracts/patient.md의 POST /api/v1/questionnaire 참조")
- task에서 spec과 다른 구현이 필요하면, task 문서에 "[Spec 변경 필요]" 표시를 추가하고 변경 이유를 기술

**각 task 문서의 필수 포맷:**
```markdown
# P{Phase}-{번호}: {task 이름}

## 메타정보
- Phase: {N}
- 의존성: {선행 task ID 목록, 없으면 "없음"}
- 예상 소요: {30분|45분|1시간}
- 난이도: {하|중|상}

## 목표
> 이 task가 완료되면 무엇이 달라지는가? (한 문장)

## 컨텍스트
> 이 task가 전체 시스템에서 어떤 위치인가?
> 관련 spec/ 문서 참조 (예: spec/contracts/patient.md, spec/erd.md#엔티티명)

## 상세 요구사항
1. [구체적 구현 항목]
2. [구체적 구현 항목]
...

## 설정 참조
> config 파일이나 환경 변수 관련 사항 (있으면)

## 테스트 기준
- [ ] [검증 가능한 테스트 항목]
- [ ] [검증 가능한 테스트 항목]

## 주의사항
> lessons.md나 domain-insights.md에서 관련된 경고
```

**decomposer-infra:**
- 프로젝트 초기화, 디렉토리 구조, 설정 파일, 공통 유틸리티
- DB 스키마, 마이그레이션
- CI/CD 파이프라인, 환경 설정

**decomposer-core:**
- 핵심 도메인 로직, 엔티티, 서비스
- 비즈니스 규칙 구현

**decomposer-api:**
- API 엔드포인트, 인터페이스
- 외부 시스템 통합, 인증/인가

**decomposer-quality:**
- 단위 테스트, 통합 테스트
- E2E 테스트, 성능 테스트
- 문서화, 배포 준비

### 4단계: 리뷰 agent 실행

**decompose-reviewer에게 할당할 task:**
분해 agent 4개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- `tasks/` 디렉토리의 모든 task 파일을 읽는다
- 다음 관점에서 검증:
  1. **크기 적절성**: 이 task가 정말 30분~1시간 크기인가? 너무 크면 분할 제안
  2. **누락 검출**: docs/의 요구사항 중 어떤 task에도 할당되지 않은 것은?
  3. **Spec 정합성**: 각 task의 요구사항이 spec/ 문서와 일치하는가? 불일치하면 task에 "[Spec 변경 필요]" 표시 추가
  4. **의존성 검증**: 순환 의존이 없는가? 의존성 순서가 논리적인가?
  5. **모호성 검출**: "상세 요구사항"이 구현 시 해석의 여지 없이 명확한가?
  6. **테스트 기준 검증**: 테스트 기준이 검증 가능한가? (자동화 가능 우선)
  7. **병렬 Wave 구성**: 의존성 없는 task끼리 Wave로 묶어 병렬 실행 가능하게 구성
- 문제 발견 시 해당 task 파일을 직접 수정
- `tasks/00-index.md`에 전체 의존성 맵과 병렬 Wave 정리

### 5단계: PROGRESS.md 및 인덱스 생성

리뷰 완료 후, 다음 파일을 생성/갱신한다:

**tasks/00-index.md:**
```markdown
# Task 인덱스

## Phase 구성
| Phase | 설명 | Task 수 |
|-------|------|---------|

## 의존성 맵
(각 task의 선행/후행 관계)

## 병렬 Wave
### Wave 1: [의존성 없는 task들]
### Wave 2: [Wave 1 완료 후 착수 가능한 task들]
...
```

**tasks/PROGRESS.md:**
```markdown
# 진행 상황

> 이 파일이 작업 진행의 유일한 진실의 원천입니다.

## 규칙
1. task 착수 전: 이 파일을 읽어 현재 진행 상태 확인
2. task 완료 후: 상태를 `완료`로 변경하고, 완료 시각과 검증 결과 기록
3. 컨텍스트가 압축되었더라도 이 파일만 읽으면 현재 위치를 알 수 있음
4. `완료` 표시가 없으면 절대 완료로 간주하지 말 것

## 상세
| Task ID | 이름 | Phase | 상태 | 검증 | 비고 |
|---------|------|-------|------|------|------|
```

상태 값: `대기`, `진행중`, `완료`, `차단됨`

### 6단계: 완료 보고

1. 팀 종료
2. 사용자에게 요약:
   - 총 task 수, Phase별 분포
   - 병렬 Wave 구성
   - 즉시 착수 가능한 task 목록
3. 다음 단계: `/universe.5-execute`로 구현 시작 안내

---

# feature 모드

## 실행 흐름 (feature 모드)

### 1단계: 입력 문서 로딩

다음 문서를 읽는다:
- `docs/features/{NNN}-{name}/spec.md`
- `docs/features/{NNN}-{name}/plan.md`
- `docs/features/{NNN}-{name}/research.md` (있으면)
- `spec/` 디렉토리 전체 (기존 project spec 참조)

### 2단계: 팀 편성

`universe-decompose` 팀을 생성하고, 3개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `feature-decomposer` | 분해 | plan.md의 변경 파일 목록을 79% 크기 task로 분해 |
| `test-planner` | 테스트 | 테스트/검증 task 생성 |
| `decompose-reviewer` | 리뷰 | task 품질 검증 |

### 3단계: 분해 agent 2개 병렬 실행

**feature-decomposer에게 할당할 task:**
- plan.md의 "변경 파일 상세" 테이블을 기반으로 task 분해
- 각 task는 30분~1시간 크기
- 의존성 순서 (기반 코드 → 핵심 로직 → 통합 → 검증)
- 산출물: `docs/features/{NNN}-{name}/tasks/` 디렉토리에 task 파일

**test-planner에게 할당할 task:**
- 기존 테스트 수정 task 생성 (plan.md의 "영향받는 기존 테스트" 기반)
- 새 테스트 작성 task 생성 (plan.md의 "추가 필요 테스트" 기반)
- 회귀 테스트 task 생성
- 산출물: `docs/features/{NNN}-{name}/tasks/` 디렉토리에 테스트 task 파일

### feature 모드 Task ID 규칙

- `F{NNN}-{번호}` (예: F001-01, F001-02, F001-03)
- NNN = feature 번호 (`docs/features/{NNN}-{name}/`)

### feature 모드 task 문서 포맷

```markdown
# F{NNN}-{번호}: {task 이름}

## 메타정보
- Feature: {NNN}-{name}
- 의존성: {선행 task ID, 없으면 "없음"}
- 예상 소요: {30분|45분|1시간}

## 목표
> 한 문장

## 컨텍스트
> plan.md의 관련 섹션 참조

## 상세 요구사항
1. [구현 항목]
2. [구현 항목]

## 테스트 기준
- [ ] [검증 항목]
- [ ] [검증 항목]

## 주의사항
> spec.md의 Rabbit Holes 중 관련 항목
```

### 4단계: 리뷰 agent 실행

**decompose-reviewer에게 할당할 task:**
분해 agent 2개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- project 모드와 동일한 6가지 관점으로 검증
- `docs/features/{NNN}-{name}/tasks/00-index.md`에 의존성 맵과 병렬 Wave 정리

### 5단계: Feature PROGRESS.md 생성

```markdown
# Feature {NNN}: {기능명} - 진행 상황

> 이 파일이 이 feature 작업의 유일한 진실의 원천입니다.

## 규칙
1. task 착수 전: 이 파일을 읽어 현재 진행 상태 확인
2. task 완료 후: 상태를 `완료`로 변경하고, 완료 시각과 검증 결과 기록
3. 컨텍스트가 압축되었더라도 이 파일만 읽으면 현재 위치를 알 수 있음
4. `완료` 표시가 없으면 절대 완료로 간주하지 말 것

## Tasks

| ID | Task | 상태 | 검증 | 비고 |
|----|------|------|------|------|
```

### 6단계: 완료 보고

1. 팀 종료
2. 사용자에게 요약:
   - 총 task 수
   - 병렬 Wave 구성
   - 즉시 착수 가능한 task
3. 다음 단계: `/universe.5-execute`로 구현 시작 안내

---

# 핵심 원칙 (공통)
- PROGRESS.md가 유일한 진실의 원천 (Single Source of Truth)
- project 모드 task 파일명: `P{Phase}-{번호 두자리}-{kebab-case-이름}.md`
- feature 모드 task 파일명: `F{NNN}-{번호 두자리}-{kebab-case-이름}.md`
- 모든 task는 PROGRESS.md에 등록되어야 한다
- 컨텍스트 압축 후에도 PROGRESS.md만 읽으면 현재 상태를 알 수 있어야 한다
- task는 spec/에서 파생된다. 구현 중 spec과 다른 결정이 필요하면 spec을 먼저 변경한다.
