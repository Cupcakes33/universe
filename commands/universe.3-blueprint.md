# /universe.3-blueprint - [Step 3] 아키텍처 + ERD + 기술 스택 생성 (agent 4개)

## 사용법
```
/universe.3-blueprint
```

## 전제 조건
- **project 모드**: `docs/design.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/spec.md`가 존재해야 한다.
- 없으면 `/universe.2-design`을 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/spec.md`가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `docs/design.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

# project 모드

## 실행 흐름 (project 모드)

### 1단계: 입력 문서 로딩

다음 문서를 읽는다:
- `docs/design.md` (필수)
- `docs/research.md` (있으면)
- `docs/domain-insights.md` (있으면)
- `docs/lessons.md` (있으면)

### 2단계: 팀 편성

`universe-blueprint` 팀을 생성하고, 4개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 | 산출물 |
|-----------|------|------|--------|
| `architect` | 생성 1 | 모듈 구조, 데이터 흐름, 의존성 | `docs/architecture.md` |
| `data-modeler` | 생성 2 | 엔티티 관계도, 데이터 모델 | `docs/erd.md` |
| `tech-selector` | 생성 3 | 기술 선택 + 대안 비교 평가표 | `docs/tech-stack.md` |
| `consistency-checker` | 일관성 검증 | 3개 문서의 모순/불일치 검출 | 검증 보고 |

### 3단계: 생성 agent 3개 병렬 실행

**architect에게 할당할 task:**
- design.md의 기능, 데이터 흐름, 제약사항을 기반으로 아키텍처 설계
- 모듈/컴포넌트 분해: 각 모듈의 책임, 인터페이스, 의존 관계
- 시스템 전체 데이터 흐름도 (텍스트 기반)
- 배포 구조 (있으면)
- 산출물: `docs/architecture.md`

**data-modeler에게 할당할 task:**
- design.md의 데이터 흐름과 행위자를 기반으로 데이터 모델 설계
- 핵심 엔티티 정의: 속성, 타입, 제약 조건
- 엔티티 간 관계: 1:1, 1:N, N:M
- 텍스트 기반 ERD (Mermaid 또는 ASCII)
- 인덱스 전략, 마이그레이션 고려사항
- 산출물: `docs/erd.md`

**tech-selector에게 할당할 task:**
- design.md의 요구사항 + research.md의 도메인 분석을 기반으로 기술 선택
- 각 카테고리별 (언어, 프레임워크, DB, 인프라 등) 2~3개 후보 비교
- 평가 기준: 성숙도, 커뮤니티, 학습 곡선, 성능, 프로젝트 적합성
- 평가표 형식으로 비교하고 최종 추천 명시
- 산출물: `docs/tech-stack.md`

### 4단계: 일관성 검증

**consistency-checker에게 할당할 task:**
생성 agent 3개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- `docs/architecture.md`, `docs/erd.md`, `docs/tech-stack.md` 3개를 모두 읽는다
- `docs/design.md`와도 대조한다
- 다음 관점에서 검증:
  1. **용어 일관성**: 같은 개념이 다른 이름으로 불리고 있지 않은가?
  2. **데이터 모델-아키텍처 정합성**: architecture의 모듈이 erd의 엔티티와 매핑되는가?
  3. **기술 스택-아키텍처 적합성**: 선택한 기술이 아키텍처를 지원하는가?
  4. **design.md 누락**: 설계 요구사항 중 반영되지 않은 것이 있는가?
  5. **모순 검출**: 문서 간 서로 다른 주장이 있는가?
- 불일치가 있으면 해당 문서에 `> [일관성 검토] ...` 블록쿼트로 표시
- 심각한 모순이 있으면 사용자에게 결정을 요청

### 5단계: 완료 보고

모든 agent 완료 후:
1. 산출물 3개 파일 존재 확인
2. 팀 종료
3. 사용자에게 요약:
   - 아키텍처 개요 (주요 모듈 목록)
   - 핵심 엔티티 목록
   - 선택된 기술 스택
   - 일관성 검증 결과 (불일치 있으면 명시)
4. 다음 단계: `/universe.4-decompose`로 task 분해 안내

---

# feature 모드

## 실행 흐름 (feature 모드)

### 1단계: 입력 문서 로딩

다음 문서를 읽는다:
- `docs/features/{NNN}-{name}/spec.md` (필수)
- `docs/features/{NNN}-{name}/research.md` (있으면)
- 기존 프로젝트 문서: `docs/architecture.md`, `docs/erd.md`, `docs/tech-stack.md` (있으면)

### 2단계: 팀 편성

`universe-blueprint` 팀을 생성하고, 4개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 | 산출물 |
|-----------|------|------|--------|
| `delta-designer` | 생성 1 | spec의 Proposed Behavior를 기존 아키텍처에 통합하는 변경 계획 | `docs/features/{NNN}/plan.md` |
| `impact-mapper` | 생성 2 | 파일별 변경 사항 목록, dependency graph, 테스트 영향 매핑 | plan.md의 "변경 파일 상세" 섹션 |
| `adr-writer` | 생성 3 | feature 구현에 필요한 아키텍처 결정 기록 | `docs/adr/NNNN-*.md` (필요 시) |
| `consistency-checker` | 검증 | spec, plan, 기존 docs의 모순/불일치 검출 | 검증 보고 |

### 3단계: 생성 agent 3개 병렬 실행

**delta-designer에게 할당할 task:**
- spec.md의 Current vs Proposed를 분석
- 기존 architecture.md가 있으면 읽고, 어떤 모듈이 변경되는지 식별
- 변경되는 모듈의 인터페이스 변경 사항 기술
- 새로 추가되는 모듈이 있으면 책임, 인터페이스, 의존 관계 정의
- 산출물: `docs/features/{NNN}-{name}/plan.md`

**impact-mapper에게 할당할 task:**
- 프로젝트 코드를 실제로 탐색하여 spec의 Impact Scope를 검증/보완
- 파일별 변경 액션 리스트 (추가/수정/삭제)
- 각 변경의 리스크 등급 (상/중/하)
- 영향받는 테스트 파일 목록
- delta-designer의 plan.md에 "변경 파일 상세" 섹션으로 추가

**adr-writer에게 할당할 task:**
- 아키텍처 수준의 결정이 필요한 경우에만 ADR 생성
- MADR 포맷 사용:
```markdown
# ADR-NNNN: {제목}

## Status
Proposed

## Context and Problem Statement
{2-3 문장}

## Considered Options
- Option 1
- Option 2

## Decision Outcome
Chosen option: "{option}", because {이유}

### Consequences
- Good: {긍정}
- Bad: {부정}
```
- `docs/adr/` 디렉토리의 기존 번호를 확인하여 다음 번호 할당
- 아키텍처 결정이 없으면 "ADR 불필요" 보고

### 4단계: 일관성 검증

**consistency-checker에게 할당할 task:**
생성 agent 3개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- spec.md ↔ plan.md 정합성 확인
- plan.md ↔ 기존 architecture.md 정합성 확인 (있으면)
- 불일치 발견 시 해당 문서에 `> [일관성 검토] ...` 블록쿼트로 표시
- 심각한 모순이 있으면 사용자에게 결정을 요청

### 5단계: 완료 보고

모든 agent 완료 후:
1. 산출물 존재 확인
2. 팀 종료
3. 사용자에게 요약:
   - 변경 파일 수, 리스크 분포
   - ADR 생성 여부
   - 일관성 검증 결과
4. 다음 단계: `/universe.4-decompose`로 task 분해 안내

---

# 산출물 포맷

## project 모드

### docs/architecture.md
```markdown
# 아키텍처

## 시스템 개요
## 모듈 구조
### [모듈명]
- 책임:
- 인터페이스:
- 의존:
## 데이터 흐름
## 배포 구조
```

### docs/erd.md
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

### docs/tech-stack.md
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

## feature 모드

### docs/features/{NNN}-{name}/plan.md
```markdown
# Feature Plan: {기능명}

## 개요
> spec.md의 Motivation 요약

## 아키텍처 변경
### 변경되는 모듈
### 새로 추가되는 모듈
### 인터페이스 변경

## 변경 파일 상세
| 파일 | 액션 | 변경 내용 | 리스크 |
|------|------|----------|--------|

## 테스트 계획
### 영향받는 기존 테스트
### 추가 필요 테스트

## Rabbit Holes
> spec.md에서 가져오기

## ADR 참조
> docs/adr/NNNN-*.md 링크 (있으면)
```

### docs/adr/NNNN-{title}.md
```markdown
# ADR-NNNN: {제목}

## Status
Proposed

## Context and Problem Statement

## Considered Options

## Decision Outcome

### Consequences
```
