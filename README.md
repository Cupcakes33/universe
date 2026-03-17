# UNIVERSE 🌌

**U**ser stories **N**arrated as **I**ntent, **V**alidated and **E**xecuted through **R**equirement-driven **S**pec **E**ngine

> 사용자의 이야기(U)가 자연어 서술(N)로 표현되고, 의도(I)로 압축되어, 검증(V)을 거쳐 실행(E)되는 요구사항(R) 기반의 Spec(S) 엔진(E)

AI Agent Orchestration Skill Set for Claude Code

## Overview

AI agent에게 대규모 기능을 한번에 맡기면 성공률이 약 29% 수준으로 나타났습니다. Universe는 이 문제를 구조적으로 해결하기 위해 만들어졌습니다. 복잡한 프로젝트를 79% 성공률의 작은 task로 분해하여 실행하는 multi-agent 워크플로우를 제공합니다.

| 원칙 | 설명 |
|------|------|
| **79% Rule** | 모든 task를 agent가 30분~1시간 내 완료할 수 있는 크기로 분해합니다 |
| **Dual Agent Pattern** | 매 단계마다 "만드는 agent"와 "검증하는 agent"를 분리합니다 |
| **File-based State** | 대화 기억이 아닌 파일 시스템(`PROGRESS.md`)이 상태를 관리합니다. 컨텍스트 압축이 발생해도 상태를 잃지 않습니다 |
| **Human-in-the-Loop** | 설계 단계(`/universe.2-design`)에서는 반드시 사람과 대화합니다. 설계는 사용자의 도메인 지식과 판단이 필수적인 영역입니다 |
| **Token Efficiency** | `/universe.7-status`는 bash만 사용하여 AI 토큰을 소비하지 않습니다 |
| **Dual Mode** | 모든 명령어가 신규 프로젝트(project)와 기능 추가(feature) 두 가지 모드를 지원합니다 |
| **Spec-Driven** | `spec/` 디렉토리가 "무엇을 만들 것인가"의 단일 정본(Single Source of Truth)입니다. 모든 단계가 spec을 먼저 읽고, 변경 시 spec을 먼저 업데이트합니다 |

## 워크플로우

### Project 모드 (신규 프로젝트)

```
/universe.1-research project <설명>
    → /universe.2-design
    → /universe.3-blueprint
    → /universe.4-decompose
    → ./execute.sh                   (자동 루프 실행 — 권장)
    → /universe.5-execute <task-id>  (단일 task 직접 실행)
        ↕
    /universe.6-sync    (문서 동기화)
    /universe.7-status  (진행 확인)
```

### Feature 모드 (기존 프로젝트에 기능 추가)

```
/universe.1-research feature <설명>
    → /universe.2-design       (Feature Spec 작성)
    → /universe.3-blueprint    (Impact Analysis + 구현 계획)
    → /universe.4-decompose    (Feature task 분해)
    → ./execute.sh                   (자동 루프 실행 — 권장)
    → /universe.5-execute <task-id>  (단일 task 직접 실행)
        ↕
    /universe.6-sync    (Feature 문서를 프로젝트에 통합)
    /universe.7-status  (Feature 진행 확인)
```

각 단계는 이전 단계의 산출물을 필요로 합니다. 순서대로 진행하는 것을 권장합니다.

## 모드 비교

| 관점 | Project 모드 | Feature 모드 |
|------|-------------|-------------|
| **목적** | 신규 프로젝트 전체 구축 | 기존 프로젝트에 기능 추가 |
| **시작점** | 아이디어/요구사항 | 기존 코드 + 변경 요청 |
| **Spec 위치** | `spec/` | `spec/` (기존) + `docs/features/{NNN}-{name}/spec.md` |
| **과정 문서** | `docs/` (아카이브) | `docs/features/{NNN}-{name}/` |
| **Task ID** | `P{Phase}-{XX}` | `F{NNN}-{XX}` |
| **PROGRESS.md** | `tasks/PROGRESS.md` | `docs/features/{NNN}-{name}/tasks/PROGRESS.md` |
| **설계 결과물** | `spec/spec.md` (유저 시나리오 + 아키텍처) | Feature spec.md (Current vs Proposed) |
| **기술 결과물** | `spec/erd.md`, `spec/tech-stack.md`, `spec/contracts/*.md` | `plan.md` + spec/ 업데이트 |
| **완료 후** | `/universe.6-sync`로 코드-Spec 동기화 | `/universe.6-sync`로 spec/ 검증 + 통합 |

---

## 명령어 상세

### `/universe.1-research [project|feature] <설명>`

워크플로우의 첫 단계입니다. 도메인을 병렬로 조사하고, 검증 agent가 반론을 제시합니다.

**사용법:**
```
# Project 모드
/universe.1-research project 15분봉 코인 퀀트 트레이딩 봇 (중위험), Python asyncio 기반

# Feature 모드
/universe.1-research feature 실시간 알림 기능
```

**모드 자동 감지:** 첫 단어가 `project`/`feature`가 아니면, 프로젝트에 실제 코드가 있으면 `feature`, 없으면 `project`로 자동 결정됩니다.

**Agent 구성:**

| | Project 모드 (4개) | Feature 모드 (4개) |
|--|-------------------|-------------------|
| 탐색 1 | `domain-explorer` — 도메인 지식 + 웹 검색 | `impact-analyst` — 기존 코드 영향 분석 |
| 탐색 2 | `codebase-analyst` — 코드베이스 분석 | `feature-researcher` — 기능 도메인 웹 검색 |
| 탐색 3 | `lessons-collector` — 시행착오 추출 | `regression-analyst` — 회귀 리스크 분석 |
| 검증 | `devil-advocate` — 반론/리스크 | `devil-advocate` — 반론/리스크 |

**생성되는 파일:**
- Project: `docs/research.md`, `docs/domain-insights.md`, `docs/lessons.md`
- Feature: `docs/features/{NNN}-{name}/research.md`, `docs/features/{NNN}-{name}/domain-insights.md`

**시작하기 전에:** 별도의 사전 조건이 없습니다. 워크플로우의 첫 단계입니다.

---

### `/universe.2-design`

사용자와 1:1 대화로 설계를 다듬는 단계입니다. Agent team을 사용하지 않습니다.

**사용법:**
```
/universe.2-design
```

**모드별 질문:**

| Project 모드 | Feature 모드 |
|-------------|-------------|
| Q1: 핵심 기능 3가지 | Q1: Motivation (왜 필요한가) |
| Q2: 사용자/행위자 | Q2: Current Behavior (현재 동작) |
| Q3: 유저 시나리오 | Q3: Proposed Behavior (원하는 동작) |
| Q4: 데이터 흐름 | Q4: Goals / Non-Goals |
| Q5: 비기능 요구사항 | Q5: Spec 영향 범위 |
| Q6: 제약사항 | Q6: Rabbit Holes (기술적 함정) |
| Q7: 우선순위 (MVP) | |

**생성되는 파일:**
- Project: `spec/spec.md` (정본 — 유저 시나리오 + Clarifications + Changelog), `docs/design.md` (과정 문서)
- Feature: `docs/features/{NNN}-{name}/spec.md` (Current vs Proposed 패턴)

**시작하기 전에:** `research.md`가 존재해야 합니다.

---

### `/universe.3-blueprint`

확정된 설계를 기술 결과물로 변환하는 단계입니다.

**사용법:**
```
/universe.3-blueprint
```

**Agent 구성:**

| | Project 모드 (5개) | Feature 모드 (4개) |
|--|-------------------|-------------------|
| 생성 1 | `architect` → `spec/spec.md` 아키텍처 섹션 | `delta-designer` → `plan.md` |
| 생성 2 | `data-modeler` → `spec/erd.md` | `impact-mapper` → plan.md "변경 파일 상세" |
| 생성 3 | `tech-selector` → `spec/tech-stack.md` | `spec-updater` → spec/ 변경 초안 |
| 생성 4 | `contract-designer` → `spec/contracts/*.md` | - |
| 검증 | `consistency-checker` | `consistency-checker` |

**생성되는 파일:**
- Project: `spec/spec.md` (아키텍처 섹션 추가), `spec/erd.md`, `spec/tech-stack.md`, `spec/contracts/*.md`
- Feature: `docs/features/{NNN}-{name}/plan.md`, spec/ 업데이트

**시작하기 전에:**
- Project: `spec/spec.md`가 존재해야 합니다
- Feature: `docs/features/{NNN}-{name}/spec.md`가 존재해야 합니다

---

### `/universe.4-decompose`

기술 결과물을 79% 크기의 task로 분해하는 단계입니다.

**사용법:**
```
/universe.4-decompose
```

**Agent 구성:**

| | Project 모드 (5개) | Feature 모드 (3개) |
|--|-------------------|-------------------|
| 분해 1 | `decomposer-infra` — 인프라/설정 | `feature-decomposer` — plan.md 기반 분해 |
| 분해 2 | `decomposer-core` — 핵심 로직 | `test-planner` — 테스트 task 생성 |
| 분해 3 | `decomposer-api` — API/통합 | - |
| 분해 4 | `decomposer-quality` — 테스트/품질 | - |
| 리뷰 | `decompose-reviewer` | `decompose-reviewer` |

**Task ID 규칙:**
- Project: `P{Phase}-{XX}` (예: P1-01, P2-03)
- Feature: `F{NNN}-{XX}` (예: F001-01, F001-02)

**생성되는 파일:**
- Project: `tasks/00-index.md`, `tasks/PROGRESS.md`, `tasks/P{N}-{XX}-*.md`
- Feature: `docs/features/{NNN}-{name}/tasks/00-index.md`, `tasks/PROGRESS.md`, `F{NNN}-{XX}-*.md`

**시작하기 전에:**
- Project: `spec/spec.md`가 존재해야 합니다 (`spec/erd.md`, `spec/tech-stack.md`, `spec/contracts/`도 권장)
- Feature: `docs/features/{NNN}-{name}/spec.md`, `docs/features/{NNN}-{name}/plan.md`가 존재해야 합니다

---

### `/universe.5-execute`

task를 실행하는 단계입니다. **bash 루프 방식(`execute.sh`)** 이 기본입니다. 각 task마다 fresh Claude 세션을 사용하므로 context 오염이 없습니다. Phase가 완료될 때마다 `phase-reviewer` (devil's advocate)가 실제 코드를 읽고 설계 문서와 대조 검증합니다.

**방법 1 — execute.sh (권장):**
```bash
# 프로젝트 루트에 execute.sh 복사 후
chmod +x execute.sh

./execute.sh 20 2 sonnet      # 최대 20회, 2초 대기, sonnet 모델
./execute.sh 30 1 haiku       # 최대 30회, 1초 대기, haiku 모델
./execute.sh --help           # 도움말
```

**방법 2 — 단일 task 직접 실행:**
```
/universe.5-execute <task-id>    # 특정 task 1개만 실행 (예: P1-03, F001-02)
```

**execute.sh 동작:**
- 루프마다 `claude --dangerously-skip-permissions` fresh 세션으로 task 1개 실행
- `tasks/learnings.md`에 발견사항 누적 (세션 간 지식 공유)
- 3회 연속 진행 없으면 stale 감지로 자동 중단
- `<universe-complete/>` 감지 시 루프 종료

**Phase 완료 검증 (Devil's Advocate):**

Phase에 속하는 모든 task가 완료되면 `phase-reviewer` 세션이 자동 실행됩니다:
1. 해당 Phase에서 생성/수정된 **모든 파일을 직접 읽습니다** (요약에 의존하지 않습니다)
2. Spec 문서(`spec/spec.md`, `spec/erd.md`, `spec/contracts/*.md`)와 실제 코드를 대조합니다
3. 코드 품질을 검증합니다 (컨벤션, 설계 원칙, 성능, 보안, 에러 처리, 중복)
4. 문제 발견 시 심각도별 수정 task를 생성합니다 (`P{Phase}-R{번호}` / `F{NNN}-R{번호}`)
5. 심각도 상 문제가 해결되기 전까지 다음 Phase로 진행하지 않습니다

**시작하기 전에:** PROGRESS.md와 00-index.md가 존재해야 합니다.

---

### `/universe.6-sync`

코드와 문서의 불일치를 검출하고 동기화하는 단계입니다.

**사용법:**
```
/universe.6-sync
```

**모드별 동작:**

| Project 동기화 | Feature 통합 |
|---------------|-------------|
| 코드 vs spec/ 불일치 검출 | 완료된 feature의 spec/ 변경 검증 |
| `scanner` → `comparator` → `updater` | `spec-verifier` → `test-verifier` → `archiver` |
| 원칙: spec이 정본, 합리적 변경은 spec 업데이트 | spec/와 코드의 최종 일치 검증 |
| 생성되는 파일: `docs/sync-report.md` | spec Status를 Done으로 변경 |

**시작하기 전에:** `spec/` 디렉토리에 `spec/spec.md`가 존재하고, 실제 코드가 있어야 합니다.

---

### `/universe.7-status`

AI 토큰을 소비하지 않고 진행 상황을 확인할 수 있는 명령어입니다.

**사용법:**
```
/universe.7-status
```

**동작:** Bash로 PROGRESS.md를 파싱하여 시각적 요약만 출력합니다.
- project PROGRESS.md가 있으면 → project 진행률을 표시합니다
- feature PROGRESS.md가 있으면 → feature별 진행률을 표시합니다
- 둘 다 있으면 → 통합하여 표시합니다

**시작하기 전에:** PROGRESS.md가 최소 1개 존재해야 합니다.

---

## 생성물 구조

### Project 모드
```
project/
├── spec/                          # 정본 (Single Source of Truth)
│   ├── spec.md                    # 프로젝트 정의 + 유저 시나리오 + 아키텍처 + Changelog
│   ├── erd.md                     # 데이터 모델
│   ├── tech-stack.md              # 기술 스택
│   └── contracts/                 # 도메인별 API contract
│       ├── README.md              # API 설계 원칙, 공통 규칙
│       └── {domain}.md            # 도메인별 엔드포인트 + 요청/응답
├── docs/                          # 과정 문서 (아카이브)
│   ├── research.md                # 도메인 + 코드베이스 분석 통합
│   ├── domain-insights.md         # 핵심 인사이트 + 리스크 매트릭스
│   ├── lessons.md                 # 시행착오 및 교훈
│   ├── design.md                  # 설계 대화 기록
│   └── sync-report.md             # 동기화 보고서 (sync 실행 시)
├── tasks/                         # 실행 추적 (PROGRESS.md가 진실의 원천)
│   ├── 00-index.md                # 전체 의존성 맵 + 병렬 Wave
│   ├── PROGRESS.md                # 실행 상태의 유일한 진실의 원천 (SSOT)
│   ├── P1-01-project-init.md      # Phase 1 task 예시
│   ├── P2-01-user-service.md      # Phase 2 task 예시
│   └── ...
└── src/                           # 실제 구현 코드
```

### Feature 모드
```
project/
├── spec/                              # 정본 (Feature로 인해 업데이트됨)
│   ├── spec.md                        # 유저 시나리오 추가/변경
│   ├── erd.md                         # 엔티티 추가/변경
│   ├── tech-stack.md
│   └── contracts/                     # API 추가/변경
│       └── {domain}.md
├── docs/
│   ├── features/
│   │   └── 001-realtime-alert/        # Feature 001
│   │       ├── research.md            # Feature 도메인 리서치
│   │       ├── domain-insights.md     # Feature 리스크/인사이트
│   │       ├── spec.md               # Feature Spec (Current vs Proposed)
│   │       ├── plan.md               # 구현 계획 + 변경 파일 상세
│   │       └── tasks/
│   │           ├── 00-index.md       # 의존성 맵 + Wave
│   │           ├── PROGRESS.md       # Feature 진실의 원천
│   │           ├── F001-01-base.md   # Feature task
│   │           └── ...
│   └── design.md                      # (과정 문서)
└── src/
```

## Feature Spec 템플릿

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

## Feature 라이프사이클

```
[기능 요청]
    │
    ▼
research (영향 분석 + 도메인 리서치)
    │
    ▼
design (Feature Spec: Current vs Proposed)
    │
    ▼
blueprint (plan.md + ADR)
    │
    ▼
decompose (F{NNN}-XX task 분해)
    │
    ▼
execute (task 실행, PROGRESS.md 기반)
    │
    ▼
sync (feature 문서를 프로젝트 문서에 통합)
    │
    ▼
[기능 완료, spec.md Status = Done]
```

## 프롬프팅 가이드

### 좋은 프롬프트

```
/universe.1-research project 15분봉 코인 퀀트 트레이딩 봇 (중위험), Python asyncio 기반, ccxt 사용
```
구체적인 도메인 + 기술 스택 + 리스크 제약조건이 포함되어 있어서 agent가 범위를 명확히 잡을 수 있습니다.

```
/universe.1-research feature 실시간 가격 알림 (텔레그램 봇, 가격 임계값 도달 시 알림)
```
기능 이름 + 구현 방향 + 동작 조건이 명확하여 영향 분석이 정확해집니다.

### 나쁜 프롬프트

```
/universe.1-research 트레이딩 봇
```
너무 모호합니다. 어떤 시장, 어떤 주기, 어떤 리스크 수준인지 agent가 범위를 좁히지 못합니다.

```
/universe.1-research feature 알림
```
어떤 알림인지, 어떤 채널인지, 어떤 조건인지 불명확합니다.

### 실전 팁

| 상황 | 팁 |
|------|-----|
| 이전 프로젝트가 있을 때 | research 프롬프트에 경로를 언급하면 교훈을 이식할 수 있습니다 |
| 설계가 불확실할 때 | `/universe.2-design`은 여러 번 반복하셔도 됩니다 |
| 기능 추가 시 | `feature` 모드를 명시하면 영향 분석이 자동으로 수행됩니다 |
| 실행 중 설계 변경이 필요할 때 | `spec/` 파일을 먼저 수정하고, 영향받는 task를 업데이트한 후 계속 진행하시면 됩니다 |
| 진행 상황을 빠르게 확인하고 싶을 때 | `/universe.7-status`는 토큰을 소비하지 않으므로 자주 사용하셔도 부담이 없습니다 |
| feature 완료 후 | `/universe.6-sync`가 feature 문서를 프로젝트 문서에 자동으로 통합합니다 |
| 대규모 프로젝트일 때 | 한 Phase가 끝날 때마다 `/universe.6-sync`로 코드-Spec 정합성을 유지하는 것을 권장합니다 |
| execute.sh 실행 중 특정 task만 수정하고 싶을 때 | execute.sh를 중단하고 `/universe.5-execute <task-id>`로 직접 실행하시면 됩니다 |

## 설계 원칙

### 1. 79% Rule
Anthropic 내부 데이터에 따르면, AI agent의 고도 작업 성공률은 29%이지만 작은 단위 작업 성공률은 79%입니다. 모든 task를 agent가 30분~1시간 내 완료할 수 있는 크기로 분해하여 성공률을 끌어올립니다.

### 2. Dual Agent Pattern (Maker-Checker)
매 단계에서 생성 agent와 검증 agent를 분리합니다. research에서는 `devil-advocate`, blueprint에서는 `consistency-checker`, decompose에서는 `decompose-reviewer`, execute에서는 `phase-reviewer`가 검증을 담당합니다. 특히 execute의 `phase-reviewer`는 요약이 아닌 실제 코드를 직접 읽고 설계 문서와 대조하여 검증합니다. 단일 agent의 편향을 구조적으로 방지합니다.

### 3. File-based State Management
LLM의 컨텍스트 윈도우는 유한하고, 긴 대화에서 압축이 발생합니다. Universe는 `PROGRESS.md`를 유일한 진실의 원천으로 사용하여, 컨텍스트가 압축되어도 상태를 잃지 않습니다.

### 4. Human-in-the-Loop
`/universe.2-design`은 의도적으로 agent team을 사용하지 않습니다. 설계는 사용자의 도메인 지식과 판단이 필수적인 영역입니다. 사람이 개입해야 하는 지점을 명확히 구분합니다.

### 5. Current vs Proposed (Feature 모드)
Feature Spec은 "현재 동작"과 "원하는 동작"을 명확히 대비합니다. Copilot Workspace의 검증된 패턴을 채택하여 변경의 의도와 범위를 구조적으로 관리합니다.

### 6. Impact-First (Feature 모드)
기능 추가 시 코드부터 작성하지 않습니다. research 단계에서 영향 분석을 먼저 수행하고, 회귀 리스크를 파악한 후 구현에 착수합니다.

## Agent 구성 요약

| 명령어 | Project Agent | Feature Agent | 패턴 |
|--------|--------------|---------------|------|
| `/universe.1-research` | 4 (탐색 3+검증 1) | 4 (영향+도메인+회귀+검증) | 병렬→순차 |
| `/universe.2-design` | 0 (1:1 대화) | 0 (1:1 대화) | 대화형 |
| `/universe.3-blueprint` | 5 (생성 4+검증 1) | 4 (delta+impact+spec-updater+검증) | 병렬→순차 |
| `/universe.4-decompose` | 5 (분해 4+리뷰 1) | 3 (분해+테스트+리뷰) | 병렬→순차 |
| `/universe.5-execute` | phase-reviewer | phase-reviewer | Ralph Loop (순차)→Phase 검증 |
| `/universe.6-sync` | 3 (순차 파이프) | 3 (병합+검증+정리) | 순차 |
| `/universe.7-status` | 0 (bash) | 0 (bash) | 파싱 |

## 설치

### npx (권장)

```bash
npx @cupcakes33/create-universe
```

인터랙티브 프롬프트로 설치 경로를 선택할 수 있습니다:
- **글로벌** (`~/.claude/commands/`) — 모든 프로젝트에서 사용
- **프로젝트** (`./.claude/commands/`) — 현재 프로젝트에서만 사용
- **둘 다**

플래그로 바로 설치할 수도 있습니다:

```bash
npx @cupcakes33/create-universe --global     # 글로벌 설치
npx @cupcakes33/create-universe --project    # 프로젝트 설치
npx @cupcakes33/create-universe --both       # 둘 다
```

### 수동 설치

```bash
# 슬래시 명령어 설치
cp commands/universe.*.md ~/.claude/commands/

# execute.sh를 사용할 각 프로젝트 루트에 복사
cp execute.sh /path/to/your/project/
chmod +x /path/to/your/project/execute.sh

# 확인
ls ~/.claude/commands/universe.*.md
```

7개 명령어 파일이 존재하면 설치가 완료된 것입니다:
- `universe.1-research.md`
- `universe.2-design.md`
- `universe.3-blueprint.md`
- `universe.4-decompose.md`
- `universe.5-execute.md`
- `universe.6-sync.md`
- `universe.7-status.md`

`execute.sh`는 각 프로젝트 루트에서 실행하는 bash 스크립트입니다. 필요한 프로젝트마다 복사해서 사용하세요.

README는 `~/.claude/README-universe.md`에 별도로 배치합니다 (명령어가 아닌 참고 문서입니다).

### 호환성

- **Claude Code** (Anthropic CLI) 전용입니다
- 어떤 프로젝트, 어떤 프로그래밍 언어에서든 사용할 수 있습니다
- 기존 slash command/skill과 독립적으로 동작합니다
- `~/.claude/commands/`에 배치하면 모든 프로젝트에서 사용할 수 있습니다
- 프로젝트별로 `.claude/commands/`에 배치하면 해당 프로젝트에서만 사용할 수 있습니다

## FAQ

**Q: 중간 단계를 건너뛸 수 있나요?** <br>
A: 각 단계는 이전 단계의 산출물을 필요로 합니다. 다만, 해당 산출물이 이미 존재하면 그 단계부터 시작할 수 있습니다.

**Q: project 모드와 feature 모드를 동시에 진행할 수 있나요?** <br>
A: 가능합니다. project의 `tasks/PROGRESS.md`와 feature의 `docs/features/{NNN}/tasks/PROGRESS.md`는 독립적입니다. `/universe.7-status`로 둘 다 확인할 수 있습니다.

**Q: feature가 여러 개이면 어떻게 되나요?** <br>
A: 각 feature는 `docs/features/{NNN}-{name}/` 아래에 독립적으로 관리됩니다. NNN은 자동으로 증가합니다 (001, 002, 003...).

**Q: feature 완료 후 프로젝트 문서는 어떻게 되나요?** <br>
A: `/universe.6-sync`의 feature 통합 모드가 spec/plan의 변경사항을 `architecture.md`, `design.md` 등에 자동으로 병합합니다. Feature 디렉토리는 히스토리 보존을 위해 삭제하지 않으며, spec.md의 Status를 `Done`으로 변경합니다.

**Q: execute.sh는 언제 사용하나요?** <br>
A: task가 많고 중간에 개입할 필요가 없을 때 사용합니다. 각 task마다 fresh Claude 세션을 실행하므로 context 오염이 없고, 실행 중에도 터미널 출력으로 진행 상황을 모니터링할 수 있습니다. 3회 연속 진행이 없으면 자동으로 중단됩니다.

**Q: execute 도중 설계를 변경하고 싶으면 어떻게 하나요?** <br>
A: `spec/` 파일을 먼저 수정한 후 코드를 변경하세요. Spec-First 원칙에 따라 spec이 코드보다 먼저 업데이트되어야 합니다. 완료 후 `/universe.6-sync`로 정합성을 확인하시면 됩니다.

**Q: task 하나가 예상보다 커서 완료되지 않았다면 어떻게 하나요?** <br>
A: execute 중 task 크기가 79%를 초과하면 자동으로 분할됩니다. 분할된 새 task는 PROGRESS.md에 즉시 반영됩니다.

**Q: PROGRESS.md를 수동으로 편집해도 되나요?** <br>
A: 가능합니다. 다만 상태 값(`대기`, `진행중`, `완료`, `차단됨`)과 테이블 포맷을 유지해야 `/universe.7-status`가 정상적으로 파싱할 수 있습니다.

## 라이선스

MIT
