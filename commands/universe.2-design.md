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
4. 리서치 결과를 3~5줄로 요약하여 사용자에게 공유

### 2단계: 설계 대화 시작

사용자에게 다음 질문을 순서대로 던진다. 한번에 모든 질문을 나열하지 말고, 한 질문씩 대화하며 진행한다.

**Q1: 핵심 기능**
> "이 프로젝트에서 가장 중요한 기능 3가지는 무엇인가요?"

**Q2: 사용자/행위자**
> "이 시스템을 사용하는 주체는 누구인가요? (사용자 유형, 외부 시스템 등)"

**Q3: 데이터 흐름**
> "핵심 데이터는 어디서 들어와서, 어떻게 처리되고, 어디에 저장되나요?"

**Q4: 비기능 요구사항**
> "성능, 보안, 확장성 등에서 특별히 중요한 요구사항이 있나요?"

**Q5: 제약사항**
> "기술적 제약, 일정, 예산, 기존 시스템과의 호환성 등 제약이 있나요?"

**Q6: 우선순위**
> "MVP에 반드시 포함할 것과 나중에 해도 되는 것을 구분해주세요."

각 답변을 받을 때마다:
- 리서치 결과와 대조하여 보완 의견 제시
- lessons.md의 관련 교훈이 있으면 언급
- domain-insights.md의 리스크가 관련되면 경고

### 3단계: 설계 초안 작성

대화가 충분히 진행되면 (최소 Q1~Q3 답변 확보 후):
1. `docs/design.md` 초안 작성
2. 사용자에게 초안을 보여주고 피드백 요청
3. 피드백 반영하여 수정 (이 과정을 사용자가 만족할 때까지 반복)

### 4단계: 완료

사용자가 설계에 만족하면:
1. 최종 `docs/design.md` 저장
2. 다음 단계 안내: `/universe.3-blueprint`로 기술 산출물 생성

---

# feature 모드

기존 프로젝트에 기능을 추가하기 위한 Feature Spec 작성. agent team 없이 1:1 대화.

## 실행 흐름 (feature 모드)

### 1단계: 컨텍스트 로딩

1. `docs/features/{NNN}-{name}/research.md` 읽기
2. `docs/features/{NNN}-{name}/domain-insights.md` 읽기 (있으면)
3. 기존 프로젝트 문서 읽기 (있으면): `docs/design.md`, `docs/architecture.md`
4. 리서치 결과를 3~5줄로 요약하여 사용자에게 공유
   - 특히 영향 분석(Impact Analysis) 결과를 강조

### 2단계: Feature Spec 대화

사용자에게 다음 질문을 순서대로 던진다. 한번에 모든 질문을 나열하지 말고, 한 질문씩 대화하며 진행한다.

**Q1: Motivation**
> "이 기능이 왜 필요한가요? 어떤 문제를 해결하나요?"

**Q2: Current Behavior**
> "현재 이 부분이 어떻게 동작하고 있나요?"
> (리서치의 영향 분석을 참고하여 현재 동작 요약을 먼저 제시하고 확인)

**Q3: Proposed Behavior**
> "변경 후 어떻게 동작하길 원하나요?"

**Q4: Goals / Non-Goals**
> "이 기능이 반드시 해야 하는 것과, 명시적으로 하지 않을 것을 구분해주세요."

**Q5: Impact Scope**
> "영향받는 범위가 맞나요?"
> (리서치의 영향 파일 목록을 보여주며 확인)

**Q6: Rabbit Holes**
> "기술적으로 주의해야 할 함정이 있나요?"
> (리서치의 리스크/회귀 분석 결과를 참고하여 제안)

각 답변을 받을 때마다:
- research.md의 영향 분석과 대조하여 보완 의견 제시
- domain-insights.md의 리스크가 관련되면 경고
- 기존 프로젝트 docs의 관련 내용이 있으면 언급
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

## project 모드: docs/design.md
```markdown
# 설계 문서

## 프로젝트 비전
> 한 문장으로 프로젝트의 목적

## 핵심 기능
1. [기능 1]: 설명
2. [기능 2]: 설명
3. [기능 3]: 설명

## 사용자 및 행위자
| 행위자 | 역할 | 주요 행위 |
|--------|------|-----------|

## 데이터 흐름
### 입력
### 처리
### 저장/출력

## 비기능 요구사항
- 성능:
- 보안:
- 확장성:

## 제약사항

## 범위 (Scope)
### MVP (필수)
### Phase 2 (확장)
### Out of Scope

## 리스크 및 완화 방안
> research.md의 리스크 매트릭스 반영
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
- feature 모드에서는 "Current vs Proposed" 대비를 명확히 유지한다.
- 사용자가 대화 도중 다른 작업을 하더라도, 돌아왔을 때 이전 맥락에서 이어간다.
