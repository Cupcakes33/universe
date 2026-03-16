# /universe.2-design - [Step 2] 사용자와 1:1 대화로 설계/Spec 작성

## 사용법
```
/universe.2-design
```

## 전제 조건
- **project 모드**: `docs/research.md`가 존재해야 한다.
- **feature 모드**: `docs/features/{NNN}-{name}/research.md`가 존재해야 한다.
- 없으면 `/universe.1-research`를 먼저 실행하라고 안내하고 중단.

## 모드 감지
- `docs/features/` 디렉토리에 `research.md`가 포함된 서브디렉토리가 있으면 → feature 모드 (가장 최근 수정된 feature 사용)
- `docs/research.md`만 있으면 → project 모드
- 둘 다 있으면 → 사용자에게 어느 모드로 진행할지 질문

---

# project 모드

이 명령은 agent team을 편성하지 않는다. 사용자와 1:1로 대화하며 설계를 다듬는다.

## 실행 흐름 (project 모드)

### 1단계: 리서치 결과 로딩

1. `docs/research.md` 읽기
2. `docs/domain-insights.md` 읽기 (있으면)
3. `docs/lessons.md` 읽기 (있으면)
4. `spec/` 디렉토리가 이미 있으면 기존 spec 읽기 (재실행 시)
5. 리서치 결과를 3~5줄로 요약하여 사용자에게 공유

### 2단계: 설계 대화 시작

사용자에게 다음 질문을 순서대로 던진다. 한번에 모든 질문을 나열하지 말고, 한 질문씩 대화하며 진행한다.

**Q1: 핵심 기능**
> "이 프로젝트에서 가장 중요한 기능 3가지는 무엇인가요?"

**Q2: 사용자/행위자**
> "이 시스템을 사용하는 주체는 누구인가요? (사용자 유형, 외부 시스템 등)"

**Q3: 유저 시나리오**
> "각 사용자 유형별로 핵심 시나리오를 설명해주세요. (예: 관리자가 ~를 하면 ~가 된다)"

**Q4: 데이터 흐름**
> "핵심 데이터는 어디서 들어와서, 어떻게 처리되고, 어디에 저장되나요?"

**Q5: 비기능 요구사항**
> "성능, 보안, 확장성 등에서 특별히 중요한 요구사항이 있나요?"

**Q6: 제약사항**
> "기술적 제약, 일정, 예산, 기존 시스템과의 호환성 등 제약이 있나요?"

**Q7: 우선순위**
> "MVP에 반드시 포함할 것과 나중에 해도 되는 것을 구분해주세요."

각 답변을 받을 때마다:
- 리서치 결과와 대조하여 보완 의견 제시
- lessons.md의 관련 교훈이 있으면 언급
- domain-insights.md의 리스크가 관련되면 경고

### 3단계: Spec 초안 작성

대화가 충분히 진행되면 (최소 Q1~Q4 답변 확보 후):

1. `spec/` 디렉토리 생성 (없으면)
2. `spec/spec.md` 초안 작성 (아래 산출물 포맷 참조)
3. `docs/design.md` 작성 (대화 기록 + 설계 결정 요약 — 과정 문서)
4. 사용자에게 `spec/spec.md` 초안을 보여주고 피드백 요청
5. 피드백 반영하여 수정 (이 과정을 사용자가 만족할 때까지 반복)

### 4단계: 완료

사용자가 spec에 만족하면:
1. 최종 `spec/spec.md` 저장
2. `docs/design.md` 저장 (과정 문서)
3. 다음 단계 안내: `/universe.3-blueprint`로 기술 산출물 생성

---

# feature 모드

기존 프로젝트에 기능을 추가하기 위한 Feature Spec 작성. agent team 없이 1:1 대화.

## 실행 흐름 (feature 모드)

### 1단계: 컨텍스트 로딩

1. `docs/features/{NNN}-{name}/research.md` 읽기
2. `docs/features/{NNN}-{name}/domain-insights.md` 읽기 (있으면)
3. **spec/ 디렉토리 읽기** (필수):
   - `spec/spec.md`: 프로젝트 정의, 유저 시나리오
   - `spec/erd.md`: 현재 데이터 모델
   - `spec/tech-stack.md`: 현재 기술 스택
   - `spec/contracts/*.md`: 현재 API contract
4. 리서치 결과를 3~5줄로 요약하여 사용자에게 공유
   - 특히 영향 분석(Impact Analysis) 결과를 강조

### 2단계: Feature Spec 대화

사용자에게 다음 질문을 순서대로 던진다. 한번에 모든 질문을 나열하지 말고, 한 질문씩 대화하며 진행한다.

**Q1: Motivation**
> "이 기능이 왜 필요한가요? 어떤 문제를 해결하나요?"

**Q2: Current Behavior**
> "현재 이 부분이 어떻게 동작하고 있나요?"
> (spec/의 관련 contract와 리서치의 영향 분석을 참고하여 현재 동작 요약을 먼저 제시하고 확인)

**Q3: Proposed Behavior**
> "변경 후 어떻게 동작하길 원하나요?"

**Q4: Goals / Non-Goals**
> "이 기능이 반드시 해야 하는 것과, 명시적으로 하지 않을 것을 구분해주세요."

**Q5: Spec 영향 범위**
> "기존 spec에서 변경이 필요한 부분이 맞나요?"
> (spec/의 관련 문서를 보여주며 확인: erd.md 변경, contract 변경 등)

**Q6: Rabbit Holes**
> "기술적으로 주의해야 할 함정이 있나요?"
> (리서치의 리스크/회귀 분석 결과를 참고하여 제안)

각 답변을 받을 때마다:
- spec/의 기존 정의와 대조하여 충돌 여부 확인
- research.md의 영향 분석과 대조하여 보완 의견 제시
- domain-insights.md의 리스크가 관련되면 경고
- 범위가 커지면 Non-Goals를 상기시킴

### 3단계: Feature Spec 초안 작성

대화가 충분히 진행되면 (최소 Q1~Q4 답변 확보 후):
1. `docs/features/{NNN}-{name}/spec.md` 초안 작성
2. 사용자에게 초안을 보여주고 피드백 요청
3. 피드백 반영하여 수정 (이 과정을 사용자가 만족할 때까지 반복)

### 4단계: 완료

사용자가 spec에 만족하면:
1. 최종 `docs/features/{NNN}-{name}/spec.md` 저장
2. 다음 단계 안내: `/universe.3-blueprint`로 Impact Analysis + 구현 계획 생성

---

# 산출물 포맷

## project 모드: spec/spec.md (정본 — Single Source of Truth)
```markdown
# Project Spec: {프로젝트명}

**Status**: Draft | Active | Frozen
**Created**: {날짜}
**Last Updated**: {날짜}

## 프로젝트 비전
> 한 문장으로 프로젝트의 목적

## 사용자 및 행위자
| 행위자 | 역할 | 주요 행위 |
|--------|------|-----------|

## 유저 시나리오

### User Story 1 - {시나리오 제목} (Priority: P1)

{시나리오 설명}

**Why this priority**: {우선순위 이유}

**Independent Test**: {독립 테스트 시나리오}

**Acceptance Scenarios**:
1. **Given** {조건}, **When** {행위}, **Then** {결과}
2. ...

---

### User Story 2 - {시나리오 제목} (Priority: P1)
...

## MVP 범위
### 필수 (Must Have)
### 확장 (Nice to Have)
### Out of Scope

## 비기능 요구사항
- 성능:
- 보안:
- 확장성:

## 제약사항

## Clarifications
> 설계 과정에서 확인된 질문/답변을 누적 기록 (maru 프로젝트의 spec.md 방식)
> 새로운 clarification이 생길 때마다 이 섹션에 날짜와 함께 추가

### Session {날짜}
- Q: {질문} → A: {답변}

## Changelog
| 날짜 | 변경 내용 | 변경 이유 |
|------|----------|----------|
```

## project 모드: docs/design.md (과정 문서)
```markdown
# 설계 대화 기록

> 이 문서는 설계 과정의 기록입니다.
> 정본은 `spec/spec.md`입니다.

## 설계 대화 요약
### Q1: 핵심 기능
> 사용자 답변 요약

### Q2: 사용자/행위자
> 사용자 답변 요약

(이하 동일)

## 설계 결정 및 Trade-off
> 대화 중 내린 주요 결정과 그 이유
```

## feature 모드: docs/features/{NNN}-{name}/spec.md
```markdown
# Feature: {기능명}

## Status
Draft | In Progress | Done | Abandoned

## Motivation
왜 이 기능이 필요한가.

## Goals
- 이 기능이 달성해야 하는 것

## Non-Goals
- 이 기능이 명시적으로 하지 않는 것

## Current Behavior
- 현재 코드의 관련 동작

## Proposed Behavior
- 변경 후 기대되는 동작

## Spec 영향 범위
- **spec/erd.md 변경**: [있으면 상세]
- **spec/contracts/ 변경**: [있으면 상세]
- **spec/spec.md 변경**: [있으면 상세]

## Impact Scope
- **변경 파일/모듈**: [목록]
- **설정 변경**: [있으면]
- **영향받는 테스트**: [목록]

## Alternatives Considered
- 검토한 대안과 선택하지 않은 이유

## Rabbit Holes
- 주의해야 할 기술적 함정
```

---

# 대화 규칙 (공통)
- 한번에 질문 하나만. 사용자 답변을 기다린다.
- 사용자가 짧게 답하면 구체적으로 파고든다.
- 사용자가 "잘 모르겠다"고 하면 리서치 결과 기반 제안을 한다.
- 설계 결정마다 trade-off를 명시한다.
- feature 모드에서는 기존 spec/과의 일관성을 항상 확인한다.
- 사용자가 대화 도중 다른 작업을 하더라도, 돌아왔을 때 이전 맥락에서 이어간다.
