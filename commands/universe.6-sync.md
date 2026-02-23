# /universe.6-sync - [Step 6] 코드-문서 동기화 + Feature 통합

## 사용법
```
/universe.6-sync
```

## 전제 조건
- `docs/` 디렉토리에 최소 1개의 문서가 존재해야 한다.
- 프로젝트에 실제 코드가 존재해야 한다. 코드가 없으면 "동기화할 코드가 없습니다"라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 있고, 해당 feature의 모든 task가 `완료` 상태면 → feature 통합 모드
- 그 외 → project 동기화 모드
- feature 통합 대상이 있으면서 project 문서도 갱신이 필요한 경우 → 둘 다 실행

---

# project 동기화 모드

## 실행 흐름 (project 모드)

### 1단계: 팀 편성

`universe-sync` 팀을 생성하고, 3개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `scanner` | 스캔 | 코드베이스 전체 분석 |
| `comparator` | 비교 | 코드 vs 문서 불일치 검출 |
| `updater` | 갱신 | 문서를 코드에 맞게 업데이트 |

### 2단계: 스캔 agent 실행

**scanner에게 할당할 task:**
- 프로젝트 전체 디렉토리 구조 파악
- 주요 파일/모듈 목록 생성
- 각 모듈의 책임, 공개 인터페이스, 의존성 분석
- 데이터 모델/엔티티 추출 (클래스, 스키마, 타입 등)
- 사용 중인 기술 스택 식별 (package.json, requirements.txt, build.gradle 등)
- 분석 결과를 구조화된 형태로 정리
- 산출물: `docs/.sync-scan.md` (임시 파일, 동기화 완료 후 삭제)

### 3단계: 비교 agent 실행

**comparator에게 할당할 task:**
scanner 완료 후 실행한다. (blockedBy 설정)

- `docs/.sync-scan.md`를 읽고 다음 문서들과 비교:
  - `docs/design.md` (있으면)
  - `docs/architecture.md` (있으면)
  - `docs/erd.md` (있으면)
  - `docs/tech-stack.md` (있으면)
- 불일치 유형별 분류:
  1. **추가됨**: 코드에 있지만 문서에 없는 모듈/엔티티/기능
  2. **삭제됨**: 문서에 있지만 코드에서 제거된 항목
  3. **변경됨**: 문서와 코드가 다른 항목 (이름, 구조, 동작)
  4. **불일치**: 문서 간 서로 모순되는 내용
- 각 불일치 항목에 심각도 표시: `[높음]`, `[중간]`, `[낮음]`
- 산출물: `docs/.sync-diff.md` (임시 파일, 동기화 완료 후 삭제)

### 4단계: 갱신 agent 실행

**updater에게 할당할 task:**
comparator 완료 후 실행한다. (blockedBy 설정)

- `docs/.sync-diff.md`를 읽고 불일치 목록을 기반으로 문서 갱신:
  - `docs/design.md`: 범위, 기능 목록 업데이트
  - `docs/architecture.md`: 모듈 구조, 의존성 업데이트
  - `docs/erd.md`: 엔티티, 속성, 관계 업데이트
  - `docs/tech-stack.md`: 실제 사용 기술로 업데이트
- **원칙: 코드가 진실**. 문서를 코드에 맞춘다 (코드를 문서에 맞추지 않는다).
- 갱신 시 기존 문서 구조/포맷을 유지한다.
- `docs/sync-report.md` 작성

### 5단계: 완료 보고

1. 임시 파일 삭제: `docs/.sync-scan.md`, `docs/.sync-diff.md`
2. 팀 종료
3. `docs/sync-report.md` 내용을 사용자에게 요약:
   - 변경된 문서 목록
   - 주요 불일치 항목
   - 갱신 내용 요약
4. 심각도 `[높음]` 불일치가 있었으면 사용자 확인 요청

---

# feature 통합 모드

완료된 feature의 문서를 프로젝트 문서에 병합한다.

## 실행 흐름 (feature 통합 모드)

### 1단계: 완료 확인

1. `docs/features/{NNN}-{name}/tasks/PROGRESS.md`를 읽는다
2. 모든 task가 `완료` 상태인지 확인
3. 완료되지 않은 task가 있으면:
   - "아직 완료되지 않은 task가 있습니다. `/universe.5-execute`로 먼저 완료하세요."
   - 미완료 task 목록 표시 후 중단

### 2단계: 팀 편성

`universe-sync` 팀을 생성하고, 3개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `delta-merger` | 병합 | feature 문서를 project 문서에 통합 |
| `test-verifier` | 검증 | 통합 후 기존 테스트 통과 확인 |
| `archiver` | 정리 | feature 디렉토리 정리, 상태 업데이트 |

### 3단계: delta-merger 실행

**delta-merger에게 할당할 task:**
- feature 문서 읽기:
  - `docs/features/{NNN}-{name}/spec.md`
  - `docs/features/{NNN}-{name}/plan.md`
- project 문서 갱신:
  - `docs/architecture.md`: plan.md의 "아키텍처 변경" 섹션 반영
  - `docs/erd.md`: 새 엔티티/속성 추가 (있으면)
  - `docs/design.md`: 기능 목록 업데이트
- ADR 파일이 있으면 (`docs/adr/`):
  - Status를 `Proposed` → `Accepted`로 변경
- 병합 시 기존 문서 구조를 유지하되, 새 섹션은 적절한 위치에 삽입

### 4단계: test-verifier 실행

**test-verifier에게 할당할 task:**
delta-merger 완료 후 실행한다. (blockedBy 설정)

- 프로젝트 테스트 스위트 실행
- feature 관련 테스트가 통과하는지 확인
- 회귀 테스트 결과 보고
- 실패하는 테스트가 있으면 원인 분석

### 5단계: archiver 실행

**archiver에게 할당할 task:**
test-verifier 완료 후 실행한다. (blockedBy 설정)

- `docs/features/{NNN}-{name}/spec.md`의 Status를 `Done`으로 변경
- feature PROGRESS.md에 최종 완료 기록 추가
- `docs/sync-report.md` 작성 (feature 통합 내역 포함)

### 6단계: 완료 보고

1. 팀 종료
2. 사용자에게 요약:
   - 통합된 feature 이름
   - 갱신된 project 문서 목록
   - 테스트 결과
   - ADR 상태 변경 (있으면)
3. 주의: feature 디렉토리는 삭제하지 않는다 (히스토리 보존)

---

## 산출물 포맷

### docs/sync-report.md
```markdown
# 동기화 보고서

## 동기화 일시
> YYYY-MM-DD

## 동기화 유형
> project 동기화 | feature 통합 (Feature NNN: {기능명})

## 변경 요약
| 문서 | 추가 | 삭제 | 변경 |
|------|------|------|------|

## 상세 변경 내역

### docs/architecture.md
- [변경됨] 모듈 X의 의존성: A -> B로 변경
- [추가됨] 새 모듈 Y 섹션 추가

### docs/erd.md
- [추가됨] 엔티티 Z 추가
- [변경됨] 엔티티 W의 속성 변경

### docs/design.md
- [변경됨] MVP 범위에서 기능 Q 제거

### docs/tech-stack.md
- [변경됨] ORM: TypeORM -> Prisma로 변경

## 특이사항
> 심각도 [높음] 불일치나 판단이 필요한 사항
```
