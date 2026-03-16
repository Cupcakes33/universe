# /universe.6-sync - [Step 6] 코드-Spec 동기화 + Feature 통합

## 사용법
```
/universe.6-sync
```

## 전제 조건
- `spec/` 디렉토리에 최소 `spec/spec.md`가 존재해야 한다.
- 프로젝트에 실제 코드가 존재해야 한다. 코드가 없으면 "동기화할 코드가 없습니다"라고 안내하고 중단.

## 모드 감지
- `docs/features/{NNN}-{name}/tasks/PROGRESS.md`가 있고, 해당 feature의 모든 task가 `완료` 상태면 → feature 통합 모드
- 그 외 → project 동기화 모드
- feature 통합 대상이 있으면서 project spec도 갱신이 필요한 경우 → 둘 다 실행

---

# project 동기화 모드

코드와 spec/의 불일치를 검출하고 동기화한다.

## 원칙
- **spec/이 진실의 원천**이지만, 구현 과정에서 합리적으로 변경된 부분은 spec을 업데이트한다
- 단순 오류(spec을 잘못 구현)는 코드를 수정하도록 task를 생성한다
- 모든 변경은 `spec/spec.md`의 Changelog에 기록한다

## 실행 흐름 (project 모드)

### 1단계: 팀 편성

`universe-sync` 팀을 생성하고, 3개의 agent를 편성한다.

| Agent 이름 | 역할 | 담당 |
|-----------|------|------|
| `scanner` | 스캔 | 코드베이스 전체 분석 |
| `comparator` | 비교 | 코드 vs spec/ 불일치 검출 |
| `updater` | 갱신 | spec/ 업데이트 또는 수정 task 생성 |

### 2단계: 스캔 agent 실행

**scanner에게 할당할 task:**
- 프로젝트 전체 디렉토리 구조 파악
- 주요 파일/모듈 목록 생성
- 각 모듈의 책임, 공개 인터페이스, 의존성 분석
- 데이터 모델/엔티티 추출 (클래스, 스키마, 타입 등)
- 실제 API 엔드포인트 추출 (라우터, 컨트롤러 등)
- 사용 중인 기술 스택 식별 (package.json, requirements.txt, build.gradle 등)
- 산출물: `docs/.sync-scan.md` (임시 파일, 동기화 완료 후 삭제)

### 3단계: 비교 agent 실행

**comparator에게 할당할 task:**
scanner 완료 후 실행한다. (blockedBy 설정)

- `docs/.sync-scan.md`를 읽고 다음 spec 문서들과 비교:
  - `spec/spec.md`: 유저 시나리오, 아키텍처, MVP 범위
  - `spec/erd.md`: 데이터 모델
  - `spec/tech-stack.md`: 기술 스택
  - `spec/contracts/*.md`: API 엔드포인트, 요청/응답, 비즈니스 규칙
- 불일치 유형별 분류:
  1. **Spec에만 있음**: spec에 정의되었지만 구현되지 않은 항목 (미구현)
  2. **코드에만 있음**: 구현되었지만 spec에 없는 항목 (spec 누락 또는 미승인 추가)
  3. **불일치**: spec과 코드가 다른 항목 (이름, 구조, 동작, 타입 등)
- 각 불일치 항목에:
  - 심각도 표시: `[높음]`, `[중간]`, `[낮음]`
  - 판단: `[spec 업데이트]` (코드가 합리적) 또는 `[코드 수정 필요]` (spec이 맞음) 또는 `[확인 필요]` (판단 불가)
- 산출물: `docs/.sync-diff.md` (임시 파일, 동기화 완료 후 삭제)

### 4단계: 갱신 agent 실행

**updater에게 할당할 task:**
comparator 완료 후 실행한다. (blockedBy 설정)

- `docs/.sync-diff.md`를 읽고 불일치 유형별 처리:

**`[spec 업데이트]` 항목:**
- `spec/spec.md`: 유저 시나리오, 아키텍처, MVP 범위 업데이트
- `spec/erd.md`: 엔티티, 속성, 관계 업데이트
- `spec/tech-stack.md`: 실제 사용 기술로 업데이트
- `spec/contracts/{domain}.md`: API 엔드포인트, 요청/응답, 비즈니스 규칙 업데이트
- 모든 변경을 `spec/spec.md`의 Changelog에 기록

**`[코드 수정 필요]` 항목:**
- 수정 task를 `tasks/` 디렉토리에 생성 (ID: `SYNC-{번호}`)
- `tasks/PROGRESS.md`에 추가

**`[확인 필요]` 항목:**
- 사용자에게 결정을 요청할 목록으로 정리

- `docs/sync-report.md` 작성

### 5단계: 완료 보고

1. 임시 파일 삭제: `docs/.sync-scan.md`, `docs/.sync-diff.md`
2. 팀 종료
3. `docs/sync-report.md` 내용을 사용자에게 요약:
   - spec/ 변경된 파일 목록과 변경 내용
   - 생성된 수정 task 목록 (있으면)
   - 사용자 확인이 필요한 항목 (있으면)
4. `[확인 필요]` 항목이 있으면 사용자에게 결정을 요청하고, 결정에 따라 spec/ 또는 코드를 업데이트

---

# feature 통합 모드

완료된 feature의 spec 변경을 검증하고, 프로젝트에 통합한다.

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
| `spec-verifier` | 검증 | feature로 인한 spec/ 변경이 코드와 일치하는지 최종 검증 |
| `test-verifier` | 테스트 | 통합 후 기존 테스트 통과 확인 |
| `archiver` | 정리 | feature 디렉토리 정리, 상태 업데이트 |

### 3단계: spec-verifier 실행

**spec-verifier에게 할당할 task:**
- blueprint 단계(Step 3)에서 이미 spec/에 반영된 변경사항을 검증
- 실제 구현된 코드와 spec/의 최종 일치 여부 확인:
  - `spec/erd.md`의 feature 관련 엔티티 ↔ 실제 DB 스키마/모델
  - `spec/contracts/{domain}.md`의 feature 관련 API ↔ 실제 엔드포인트
  - `spec/spec.md`의 feature 관련 유저 시나리오 ↔ 실제 동작
- 불일치 발견 시:
  - spec/을 코드에 맞게 업데이트 (구현 중 합리적으로 변경된 경우)
  - `spec/spec.md`의 Changelog에 기록

### 4단계: test-verifier 실행

**test-verifier에게 할당할 task:**
spec-verifier 완료 후 실행한다. (blockedBy 설정)

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
   - spec/ 최종 변경 내역
   - 테스트 결과
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

## Spec 변경 요약
| spec 파일 | 변경 유형 | 변경 내용 |
|-----------|----------|----------|

## 코드 수정 필요 항목
| 항목 | 심각도 | task ID |
|------|--------|---------|

## 사용자 확인 필요 항목
| 항목 | spec 내용 | 코드 내용 | 판단 |
|------|----------|----------|------|

## 특이사항
> 심각도 [높음] 불일치나 판단이 필요한 사항
```
