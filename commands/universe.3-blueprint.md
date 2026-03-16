# /universe.3-blueprint - [Step 3] 아키텍처 + ERD + 기술 스택 생성 (agent 4개)

## 사용법
```
/universe.3-blueprint
```

## 전제 조건
- **project 모드**: `spec/spec.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/spec.md`가 존재해야 한다.
- 없으면 `/universe.2-design`을 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/spec.md`가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `spec/spec.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

# project 모드

## 실행 흐름 (project 모드)

### 1단계: 입력 문서 로딩

다음 문서를 읽는다:
- `spec/spec.md` (필수 — 정본)
- `docs/research.md` (있으면)
- `docs/domain-insights.md` (있으면)
- `docs/lessons.md` (있으면)

### 2단계: 팀 편성

`universe-blueprint` 팀을 생성하고, 5개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 | 산출물 |
|-----------|------|------|--------|
| `architect` | 생성 1 | 모듈 구조, 데이터 흐름, 의존성 | `spec/spec.md`의 아키텍처 섹션 업데이트 |
| `data-modeler` | 생성 2 | 엔티티 관계도, 데이터 모델 | `spec/erd.md` |
| `tech-selector` | 생성 3 | 기술 선택 + 대안 비교 평가표 | `spec/tech-stack.md` |
| `contract-designer` | 생성 4 | 도메인별 API contract 설계 | `spec/contracts/*.md` |
| `consistency-checker` | 일관성 검증 | 모든 spec 문서의 모순/불일치 검출 | 검증 보고 |

### 3단계: 생성 agent 4개 병렬 실행

**architect에게 할당할 task:**
- spec/spec.md의 유저 시나리오, 기능, 데이터 흐름, 제약사항을 기반으로 아키텍처 설계
- 모듈/컴포넌트 분해: 각 모듈의 책임, 인터페이스, 의존 관계
- 시스템 전체 데이터 흐름도 (텍스트 기반)
- 배포 구조 (있으면)
- 산출물: `spec/spec.md`의 "아키텍처" 섹션을 **추가/업데이트** (기존 유저 시나리오 등은 건드리지 않음)

**data-modeler에게 할당할 task:**
- spec/spec.md의 유저 시나리오와 데이터 흐름을 기반으로 데이터 모델 설계
- 핵심 엔티티 정의: 속성, 타입, 제약 조건
- 엔티티 간 관계: 1:1, 1:N, N:M
- 텍스트 기반 ERD (Mermaid 또는 ASCII)
- 인덱스 전략, 마이그레이션 고려사항
- 산출물: `spec/erd.md`

**tech-selector에게 할당할 task:**
- spec/spec.md의 요구사항 + docs/research.md의 도메인 분석을 기반으로 기술 선택
- 각 카테고리별 (언어, 프레임워크, DB, 인프라 등) 2~3개 후보 비교
- 평가 기준: 성숙도, 커뮤니티, 학습 곡선, 성능, 프로젝트 적합성
- 평가표 형식으로 비교하고 최종 추천 명시
- 산출물: `spec/tech-stack.md`

**contract-designer에게 할당할 task:**
- spec/spec.md의 유저 시나리오에서 API 엔드포인트를 도출한다
- 도메인별로 API contract를 분리한다 (참고: maru 프로젝트의 `spec/contracts/` 구조)
- 각 도메인 contract에 포함할 내용:
  - 엔드포인트 목록 (메서드, 경로, 설명, 권한)
  - 각 엔드포인트의 요청/응답 예시 (JSON)
  - 비즈니스 규칙 및 유효성 검증 규칙
  - 에러 케이스
- `spec/contracts/README.md` 작성 (API 설계 원칙, 공통 규칙, 인증 방식, 응답 형식, 공통 에러 코드)
- 산출물: `spec/contracts/README.md` + `spec/contracts/{domain}.md` (도메인당 1개)

### 4단계: 일관성 검증

**consistency-checker에게 할당할 task:**
생성 agent 4개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- `spec/` 디렉토리의 모든 파일을 읽는다:
  - `spec/spec.md` (유저 시나리오 + 아키텍처)
  - `spec/erd.md` (데이터 모델)
  - `spec/tech-stack.md` (기술 스택)
  - `spec/contracts/*.md` (API contract)
- 다음 관점에서 검증:
  1. **용어 일관성**: 같은 개념이 다른 이름으로 불리고 있지 않은가?
  2. **데이터 모델-contract 정합성**: contract의 요청/응답 필드가 erd의 엔티티와 매핑되는가?
  3. **유저 시나리오-contract 커버리지**: 모든 유저 시나리오가 contract의 API로 구현 가능한가?
  4. **기술 스택-아키텍처 적합성**: 선택한 기술이 아키텍처를 지원하는가?
  5. **spec.md-contract 일관성**: spec.md의 MVP 범위에 있는 기능이 contract에 모두 있는가?
  6. **필드명/타입 일관성**: erd.md의 컬럼명과 contract의 JSON 필드명이 일관되는가?
- 불일치가 있으면 **해당 spec 파일을 직접 수정**하여 일관성을 맞춘다
- 수정한 내용을 `spec/spec.md`의 Changelog에 기록
- 심각한 모순이 있으면 (양쪽 중 어느 것이 맞는지 판단 불가) 사용자에게 결정을 요청

### 5단계: 완료 보고

모든 agent 완료 후:
1. spec/ 디렉토리 산출물 확인:
   - `spec/spec.md` (아키텍처 섹션 추가됨)
   - `spec/erd.md`
   - `spec/tech-stack.md`
   - `spec/contracts/README.md`
   - `spec/contracts/{domain}.md` (1개 이상)
2. 팀 종료
3. 사용자에게 요약:
   - 아키텍처 개요 (주요 모듈 목록)
   - 핵심 엔티티 목록
   - 선택된 기술 스택
   - API contract 도메인 목록
   - 일관성 검증 결과 (수정 사항 있으면 명시)
4. 다음 단계: `/universe.4-decompose`로 task 분해 안내

---

# feature 모드

## 실행 흐름 (feature 모드)

### Spec-First Protocol

feature 모드는 반드시 기존 spec/을 먼저 읽는다:
1. `spec/spec.md`, `spec/erd.md`, `spec/tech-stack.md`, `spec/contracts/*.md` 전체 읽기
2. feature spec과 기존 project spec의 관계를 파악

### 1단계: 입력 문서 로딩

다음 문서를 읽는다:
- `docs/features/{NNN}-{name}/spec.md` (필수)
- `docs/features/{NNN}-{name}/research.md` (있으면)
- `spec/` 디렉토리 전체 (필수 — 기존 project spec)

### 2단계: 팀 편성

`universe-blueprint` 팀을 생성하고, 4개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 | 산출물 |
|-----------|------|------|--------|
| `delta-designer` | 생성 1 | feature spec의 Proposed Behavior를 기존 아키텍처에 통합하는 변경 계획 | `docs/features/{NNN}/plan.md` |
| `impact-mapper` | 생성 2 | 파일별 변경 사항 목록, dependency graph, 테스트 영향 매핑 | plan.md의 "변경 파일 상세" 섹션 |
| `spec-updater` | 생성 3 | feature로 인해 변경이 필요한 spec/ 파일 식별 및 변경 초안 | spec/ 변경 초안 |
| `consistency-checker` | 검증 | feature spec, plan, 기존 spec의 모순/불일치 검출 | 검증 보고 |

### 3단계: 생성 agent 3개 병렬 실행

**delta-designer에게 할당할 task:**
- feature spec.md의 Current vs Proposed를 분석
- spec/spec.md의 아키텍처 섹션을 읽고, 어떤 모듈이 변경되는지 식별
- 변경되는 모듈의 인터페이스 변경 사항 기술
- 새로 추가되는 모듈이 있으면 책임, 인터페이스, 의존 관계 정의
- 산출물: `docs/features/{NNN}-{name}/plan.md`

**impact-mapper에게 할당할 task:**
- 프로젝트 코드를 실제로 탐색하여 feature spec의 Impact Scope를 검증/보완
- 파일별 변경 액션 리스트 (추가/수정/삭제)
- 각 변경의 리스크 등급 (상/중/하)
- 영향받는 테스트 파일 목록
- delta-designer의 plan.md에 "변경 파일 상세" 섹션으로 추가

**spec-updater에게 할당할 task:**
- feature spec.md의 "Spec 영향 범위" 섹션을 기반으로:
  - `spec/erd.md`에 추가/변경이 필요한 엔티티/필드 식별
  - `spec/contracts/`에 추가/변경이 필요한 API 엔드포인트 식별
  - `spec/spec.md`에 추가/변경이 필요한 유저 시나리오 식별
- 각 변경에 대한 초안 작성 (아직 적용하지 않음 — consistency-checker 후 적용)
- 산출물: `docs/features/{NNN}-{name}/spec-changes.md` (변경 초안)

### 4단계: 일관성 검증 및 Spec 업데이트

**consistency-checker에게 할당할 task:**
생성 agent 3개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- feature spec.md ↔ plan.md 정합성 확인
- spec-changes.md의 변경 초안 ↔ 기존 spec/ 정합성 확인
- 불일치 발견 시:
  - 해결 가능하면 직접 수정
  - 판단 필요하면 사용자에게 결정 요청
- 검증 통과 후: spec-changes.md의 내용을 **spec/ 파일에 실제 적용**
  - `spec/erd.md` 업데이트
  - `spec/contracts/{domain}.md` 업데이트 또는 신규 생성
  - `spec/spec.md` 업데이트 (유저 시나리오, 아키텍처 등)
  - `spec/spec.md`의 Changelog에 변경 기록
- `docs/features/{NNN}-{name}/spec-changes.md` 삭제 (spec/에 반영 완료)

### 5단계: 완료 보고

모든 agent 완료 후:
1. 산출물 존재 확인
2. 팀 종료
3. 사용자에게 요약:
   - 변경 파일 수, 리스크 분포
   - spec/ 변경 내역 (어떤 spec 파일이 업데이트되었는지)
   - 일관성 검증 결과
4. 다음 단계: `/universe.4-decompose`로 task 분해 안내

---

# 산출물 포맷

## project 모드

### spec/spec.md (아키텍처 섹션 — 이 Step에서 추가)
```markdown
## 아키텍처

### 시스템 개요
> 전체 시스템 구조 설명

### 모듈 구조
#### [모듈명]
- 책임:
- 인터페이스:
- 의존:

### 데이터 흐름
> 시스템 전체 데이터 흐름도

### 디렉토리 구조
> 프로젝트 디렉토리 구조

### 배포 구조
> 배포 환경 및 구성
```

### spec/erd.md
```markdown
# 데이터 모델

## 엔티티 목록
### [엔티티명]
| 속성 | 타입 | 제약 | 설명 |
|------|------|------|------|

## 관계도
(Mermaid erDiagram 또는 텍스트)

## 인덱스 전략
## 마이그레이션 고려사항
```

### spec/tech-stack.md
```markdown
# 기술 스택

## 선택 요약
| 카테고리 | 선택 | 대안 |
|----------|------|------|

## 상세 비교
### [카테고리]
| 기준 | 후보 A | 후보 B | 후보 C |
|------|--------|--------|--------|
| 성숙도 | | | |
| 커뮤니티 | | | |
| 학습 곡선 | | | |
| 성능 | | | |
| 적합성 | | | |
**추천**: [후보] - 이유

## 의존성 호환성 확인
```

### spec/contracts/README.md
```markdown
# API Contracts: {프로젝트명}

**Created**: {날짜}
**Last Updated**: {날짜}

## API 설계 원칙
### 1. RESTful 규칙
### 2. 응답 상태 코드
### 3. 인증 방식
### 4. 응답 형식
### 5. 에러 응답

## API 도메인 목록
| 파일명 | 도메인 | 설명 |
|--------|--------|------|

## 공통 에러 코드
| 코드 | 메시지 | HTTP 상태 |
|------|--------|-----------|
```

### spec/contracts/{domain}.md
```markdown
# API: {도메인명}

**Domain**: {도메인 설명}
**Base Path**: `/api/v1/{domain}`
**권한**: {필요 권한}

## 엔드포인트 목록
| 메서드 | 경로 | 설명 | 권한 |
|--------|------|------|------|

## 1. {엔드포인트명}

**Endpoint**: `{METHOD} {path}`
**설명**: {설명}

**Request**:
```http
{요청 예시}
```

**Response** ({상태코드}):
```json
{응답 예시}
```

**비즈니스 규칙**:
- {규칙 1}
- {규칙 2}

**에러 케이스**:
| 상황 | 코드 | HTTP 상태 |
|------|------|-----------|
```

## feature 모드

### docs/features/{NNN}-{name}/plan.md
```markdown
# Feature Plan: {기능명}

## 개요
> feature spec.md의 Motivation 요약

## 아키텍처 변경
### 변경되는 모듈
### 새로 추가되는 모듈
### 인터페이스 변경

## Spec 변경 요약
> 이 feature로 인해 변경된 spec/ 파일 목록과 변경 내용 요약
- spec/erd.md: {변경 내용}
- spec/contracts/{domain}.md: {변경 내용}

## 변경 파일 상세
| 파일 | 액션 | 변경 내용 | 리스크 |
|------|------|----------|--------|

## 테스트 계획
### 영향받는 기존 테스트
### 추가 필요 테스트

## Rabbit Holes
> feature spec.md에서 가져오기
```
