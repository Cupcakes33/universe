# /universe.7-status - [Step 7] 진행 상황 확인 (토큰 0)

## 사용법
```
/universe.7-status
```

## 전제 조건
- `tasks/PROGRESS.md` 또는 `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 최소 1개 존재해야 한다.
- 없으면 `/universe.4-decompose`를 먼저 실행하라고 안내하고 중단.

---

## 실행 방법

이 명령은 agent team을 사용하지 않는다. Bash 도구로 PROGRESS.md를 파싱하여 시각적 요약만 출력한다. 토큰을 최소한으로 사용한다.

### 모드 감지 및 출력 범위

1. `tasks/PROGRESS.md`가 있으면 → project 진행 상황 출력
2. `docs/features/*/tasks/PROGRESS.md`가 있으면 → 각 feature 진행 상황 출력
3. 둘 다 있으면 → project + 활성 feature 모두 출력

### 파싱 및 출력

PROGRESS.md 파일을 읽고 다음 정보를 추출한다:

1. 전체 task 수와 완료 task 수
2. Phase별 (project) 또는 전체 (feature) task 수와 완료 수
3. 상태별 task 수 (대기, 진행중, 완료, 차단됨)
4. 착수 가능한 task 목록 (상태=대기 이고 의존성이 모두 완료된 것)

### 출력 포맷

**project 모드:**
```
=== Universe 진행 상황 ===

진행률: {완료}/{전체} ({백분율}%)
[{'#' * 완료비율칸}{'.' * 나머지칸}]

Phase 1 ({Phase 1 설명}): {완료}/{전체}
  [{'█' * 비율}{'░' * 나머지}]
Phase 2 ({Phase 2 설명}): {완료}/{전체}
  [{'█' * 비율}{'░' * 나머지}]
...

상태 분포:
  완료: {N}  진행중: {N}  대기: {N}  차단됨: {N}

착수 가능한 task:
  - {Task ID}: {Task 이름}
  ...

{차단됨이 있으면}
차단된 task:
  - {Task ID}: {원인}
```

**feature 모드:**
```
=== Feature 진행 상황 ===

--- Feature {NNN}: {기능명} ---
진행률: {완료}/{전체} ({백분율}%)
[{'#' * 완료비율칸}{'.' * 나머지칸}]

상태 분포:
  완료: {N}  진행중: {N}  대기: {N}  차단됨: {N}

착수 가능한 task:
  - {Task ID}: {Task 이름}
  ...
```

**복합 모드 (project + feature):**
```
=== Universe 진행 상황 ===

[Project]
진행률: {완료}/{전체} ({백분율}%)
[{'#' * 완료비율칸}{'.' * 나머지칸}]
(Phase별 상세는 project 모드와 동일)

[Feature {NNN}: {기능명}] {상태}
진행률: {완료}/{전체} ({백분율}%)
[{'#' * 완료비율칸}{'.' * 나머지칸}]

[Feature {NNN}: {기능명}] {상태}
진행률: {완료}/{전체} ({백분율}%)
[{'#' * 완료비율칸}{'.' * 나머지칸}]
...
```

### 구현 방법

Bash를 사용하여 PROGRESS.md의 상세 테이블을 파싱한다.

**project PROGRESS.md 포맷:**
```
| Task ID | 이름 | Phase | 상태 | 검증 | 비고 |
```

**feature PROGRESS.md 포맷:**
```
| ID | Task | 상태 | 검증 | 비고 |
```

파싱 로직:
1. project: `tasks/PROGRESS.md` 파싱
2. feature: `docs/features/*/tasks/PROGRESS.md` 파싱 (glob으로 탐색)
3. feature spec.md의 Status가 `Done`인 것은 출력하지 않음 (완료된 feature 제외)
4. Phase별 그룹핑하여 완료/전체 카운트
5. 착수 가능 판별: 상태=대기 이고, 의존성 열의 모든 task가 완료 상태
6. 프로그레스 바는 10칸 기준으로 비율 계산

AI의 분석이나 판단은 필요 없다. 파싱 결과만 포맷에 맞춰 출력하면 된다.
