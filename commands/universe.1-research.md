# /universe.1-research - [Step 1] 도메인 리서치 + 영향 분석 (agent 4개 병렬)

## 사용법
```
/universe.1-research <모드> <설명>
```

## 전제 조건
- 없음. universe 워크플로우의 첫 단계.

## 인자
- `$ARGUMENTS`: `[project|feature] <자연어 설명>`
  - 첫 단어가 `project` 또는 `feature`면 해당 모드로 실행
  - 그 외: 자동 감지 — 프로젝트에 실제 코드(`src/`, `lib/`, `app/`, 또는 언어별 소스 디렉토리)가 있으면 `feature`, 없으면 `project`

---

# project 모드

신규 프로젝트를 위한 전체 도메인 + 기술 리서치.

## 실행 흐름 (project 모드)

### 1단계: 팀 편성

`universe-research` 팀을 생성하고, 4개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `domain-explorer` | 탐색 1 | 도메인 지식 + 외부 레퍼런스 (웹 검색) |
| `codebase-analyst` | 탐색 2 | 기존 코드베이스 분석 |
| `lessons-collector` | 탐색 3 | 이전 프로젝트 시행착오/교훈 수집 |
| `devil-advocate` | 검증 | 다른 agent 결과의 반론/리스크 평가 |

### 2단계: 탐색 agent 3개 병렬 실행

**domain-explorer에게 할당할 task:**
- `$ARGUMENTS`를 기반으로 해당 도메인의 핵심 개념, 용어, 업계 표준 조사
- 웹 검색으로 유사 프로젝트, 오픈소스 레퍼런스, 기술 블로그 수집
- 핵심 기술적 제약사항과 일반적인 아키텍처 패턴 정리
- 산출물: `docs/research-domain.md` (나중에 research.md로 병합)

**codebase-analyst에게 할당할 task:**
- 현재 프로젝트의 코드베이스가 있으면 전체 구조 분석
- 사용 중인 기술 스택, 패턴, 의존성 파악
- 재사용 가능한 모듈과 리팩토링 필요한 부분 식별
- 코드베이스가 없으면 "신규 프로젝트"로 기록하고 tech stack 후보 목록 조사
- 산출물: `docs/research-codebase.md` (나중에 research.md로 병합)

**lessons-collector에게 할당할 task:**
- `docs/` 디렉토리에 기존 문서가 있으면 분석
- CLAUDE.md, MEMORY.md 등에서 과거 시행착오 추출
- git log에서 revert, fix, hotfix 패턴 수집하여 반복 실수 식별
- 유사 도메인의 일반적인 함정(pitfall) 정리
- 산출물: `docs/lessons.md`

### 3단계: 검증 agent 실행

**devil-advocate에게 할당할 task:**
탐색 agent 3개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- `docs/research-domain.md`, `docs/research-codebase.md`, `docs/lessons.md`를 읽는다
- 다음 관점에서 비판적 검토:
  1. **가설 반증**: "이 기술/접근법이 실패할 수 있는 시나리오는?"
  2. **실현 가능성**: 팀 규모, 일정, 기술 역량 대비 현실적인가?
  3. **숨겨진 복잡성**: 겉으로 단순해 보이지만 복잡한 부분은?
  4. **대안 누락**: 검토하지 않은 중요한 대안이 있는가?
  5. **리스크 평가**: 각 핵심 결정의 리스크를 상/중/하로 평가
- `docs/domain-insights.md` 작성 (도메인 핵심 인사이트 + 리스크 매트릭스 + 검증 결과)

### 4단계: 산출물 병합 및 보고

모든 agent 완료 후:
1. `docs/research-domain.md`와 `docs/research-codebase.md`를 `docs/research.md`로 병합
   - 도메인 분석 섹션 + 코드베이스 분석 섹션 + domain-insights.md의 검증 결과를 "검증 및 리스크" 섹션으로 통합
2. 병합 후 `docs/research-domain.md`, `docs/research-codebase.md` 삭제
3. `docs/research.md`가 다음 섹션을 포함하는지 확인:
   - 도메인 분석
   - 코드베이스 분석
   - 검증 및 리스크
4. `docs/domain-insights.md`가 존재하는지 확인
5. `docs/lessons.md`가 존재하는지 확인 (교훈이 없으면 "해당 없음" 기록)
6. 팀 종료
7. 사용자에게 요약 보고:
   - 핵심 발견사항 3~5개
   - 주요 리스크 상위 3개
   - 다음 단계: `/universe.2-design`으로 설계 논의 시작 안내

---

# feature 모드

기존 프로젝트에 기능을 추가하기 위한 코드 영향 분석 + 기능 도메인 리서치.

## 실행 흐름 (feature 모드)

### 1단계: Feature 디렉토리 생성

`docs/features/` 디렉토리의 기존 서브디렉토리를 확인하여 다음 번호를 자동 할당한다.
- 첫 번째 feature: `001`
- 이름: `$ARGUMENTS`에서 모드 키워드를 제외한 나머지를 kebab-case로 변환
- 예: `/universe.1-research feature 실시간 알림` → `docs/features/001-realtime-alert/`
- 디렉토리가 없으면 생성

### 2단계: 팀 편성

`universe-research` 팀을 생성하고, 4개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `impact-analyst` | 탐색 1 | 기존 코드에서 feature 관련 파일/모듈 식별, import/dependency 분석 |
| `feature-researcher` | 탐색 2 | feature 도메인의 외부 레퍼런스, 베스트 프랙티스 웹 검색 |
| `regression-analyst` | 탐색 3 | 변경으로 깨질 수 있는 기존 기능, 테스트 영향 분석 |
| `devil-advocate` | 검증 | 다른 agent 결과의 반론/리스크 평가 |

### 3단계: 탐색 agent 3개 병렬 실행

**impact-analyst에게 할당할 task:**
- 프로젝트 전체 디렉토리 구조 파악
- feature 설명과 관련된 파일/모듈 식별
- import/dependency graph 분석으로 영향 범위 추적
- 관련 테스트 파일 식별
- 산출물: `docs/features/{NNN}-{name}/research-impact.md`

**feature-researcher에게 할당할 task:**
- feature 설명을 기반으로 해당 기능의 베스트 프랙티스 웹 검색
- 유사 구현 사례, 오픈소스 레퍼런스 수집
- 기술적 제약사항과 권장 접근법 정리
- 산출물: `docs/features/{NNN}-{name}/research-domain.md`

**regression-analyst에게 할당할 task:**
- 기존 테스트 스위트 분석
- 변경으로 영향받을 수 있는 기존 기능 식별
- 회귀 리스크 등급화 (상/중/하)
- 산출물: `docs/features/{NNN}-{name}/research-regression.md`

### 4단계: 검증 agent 실행

**devil-advocate에게 할당할 task:**
탐색 agent 3개의 작업이 완료된 후 실행한다. (blockedBy 설정)

- 3개의 research 파일을 읽는다
- 다음 관점에서 비판적 검토:
  1. **가설 반증**: "이 접근법이 실패할 수 있는 시나리오는?"
  2. **실현 가능성**: 기존 아키텍처 내에서 현실적인가?
  3. **숨겨진 복잡성**: 겉으로 단순해 보이지만 복잡한 부분은?
  4. **대안 누락**: 검토하지 않은 중요한 대안이 있는가?
  5. **리스크 평가**: 각 핵심 결정의 리스크를 상/중/하로 평가
- 산출물: `docs/features/{NNN}-{name}/domain-insights.md`

### 5단계: 산출물 병합 및 보고

모든 agent 완료 후:
1. `research-impact.md`, `research-domain.md`, `research-regression.md`를 `docs/features/{NNN}-{name}/research.md`로 병합
2. 병합 후 개별 파일 삭제
3. `docs/features/{NNN}-{name}/domain-insights.md` 존재 확인
4. 팀 종료
5. 사용자에게 요약 보고:
   - 영향받는 파일/모듈 상위 5개
   - 회귀 리스크 상위 3개
   - 주요 발견사항 3~5개
   - 다음 단계: `/universe.2-design`으로 feature spec 작성 안내

---

# 산출물 포맷

## project 모드: docs/research.md
```markdown
# 리서치 결과

## 프로젝트 개요
> $ARGUMENTS 기반 요약

## 도메인 분석
### 핵심 개념
### 업계 표준 및 레퍼런스
### 기술적 제약사항

## 코드베이스 분석
### 현재 구조 (또는 "신규 프로젝트")
### 기술 스택
### 재사용 가능 자산

## 검증 및 리스크
### 가설 반증
### 실현 가능성 평가
### 리스크 매트릭스
| 항목 | 리스크 | 영향도 | 완화 방안 |
|------|--------|--------|-----------|
```

## feature 모드: docs/features/{NNN}-{name}/research.md
```markdown
# Feature 리서치: {feature 설명}

## 영향 분석
### 관련 파일/모듈
### dependency graph
### 관련 테스트

## 도메인 분석
### 핵심 개념
### 레퍼런스 및 베스트 프랙티스
### 기술적 제약

## 회귀 리스크
### 영향받는 기존 기능
### 리스크 매트릭스
| 항목 | 리스크 | 영향도 | 완화 방안 |
|------|--------|--------|-----------|

## 검증 및 리스크
### 가설 반증
### 실현 가능성
```

## 공통: docs/domain-insights.md (또는 feature 디렉토리 내)
```markdown
# 도메인 핵심 인사이트

## 반드시 알아야 할 것
## 흔한 실수
## 추천 접근법
## 리스크 매트릭스
```

## project 모드 전용: docs/lessons.md
```markdown
# 시행착오 및 교훈

## 과거 프로젝트 교훈
## 반복된 실수 패턴
## 도메인 일반 함정
```
