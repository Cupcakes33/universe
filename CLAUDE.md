# CLAUDE.md - Universe Plugin Project

## 이 프로젝트가 뭔가요?

Claude Code용 multi-agent 워크플로우 플러그인입니다.
복잡한 프로젝트를 79% 성공률의 작은 task로 분해하여 실행합니다.

**UNIVERSE** = **U**ser stories **N**arrated as **I**ntent, **V**alidated and **E**xecuted through **R**equirement-driven **S**pec **E**ngine

## 현재 상태

- **버전**: 1.0.0
- **단계**: 배포 준비 완료 (GitHub push 전)
- **원본 위치**: `~/.claude/commands/universe.*.md` (실제 사용 중)
- **이 디렉토리**: 플러그인 배포용 복사본

## 파일 구조

```
universe/
├── .claude-plugin/
│   ├── plugin.json           # 플러그인 메타데이터 (name, version, author)
│   └── marketplace.json      # 마켓플레이스 등록용
├── commands/                  # 7개 슬래시 명령어
│   ├── universe.1-research.md   # Step 1: 도메인 리서치 + 영향 분석
│   ├── universe.2-design.md     # Step 2: 사용자와 1:1 설계/Spec
│   ├── universe.3-blueprint.md  # Step 3: 아키텍처 + ERD + 기술 스택
│   ├── universe.4-decompose.md  # Step 4: 79% 크기 Task 분해
│   ├── universe.5-execute.md    # Step 5: Task 병렬 실행
│   ├── universe.6-sync.md       # Step 6: 코드-문서 동기화
│   └── universe.7-status.md     # Step 7: 진행 상황 확인
├── README.md                  # 사용자 대면 문서 (존댓말)
└── CLAUDE.md                  # 이 파일
```

## 배포 방법

Claude Code 플러그인 시스템으로 배포합니다.

```bash
# 1. GitHub에 push
git init && git add . && git commit -m "feat: Universe v1.0.0"
git remote add origin https://github.com/{username}/universe.git
git push -u origin main

# 2. 사용자 설치
/plugin marketplace add {username}/universe
/plugin install universe
```

## 핵심 결정사항 (히스토리)

### 파일명 번호 접두사
- `universe.research.md` → `universe.1-research.md` 형식으로 변경
- 이유: Claude Code가 알파벳 순으로 명령어를 정렬하므로, 번호를 붙여 워크플로우 순서대로 표시
- `/universe.1-research` ~ `/universe.7-status`

### README 톤
- 초기: 반말/명령조 ("~한다", "~금지")
- 현재: 존댓말 ("~합니다", "~권장합니다")
- 이유: 오픈소스 README는 사용자를 초대하는 톤이어야 함

### README 위치
- 처음: `~/.claude/commands/universe.README.md` (슬래시 명령어로 노출됨)
- 변경: `~/.claude/README-universe.md` → 이 프로젝트의 `README.md`
- 이유: README는 명령어가 아니라 참고 문서

### Dual Mode (v2)
- 모든 명령어가 project 모드(신규)와 feature 모드(기능 추가) 두 가지를 지원
- project: `docs/`, `tasks/PROGRESS.md`, Task ID `P{Phase}-{XX}`
- feature: `docs/features/{NNN}-{name}/`, Task ID `F{NNN}-{XX}`

### 원본과 이 디렉토리의 관계
- `~/.claude/commands/universe.*.md` = 실제 사용 중인 원본
- 이 디렉토리 = 배포용 복사본
- 원본 수정 시 이 디렉토리에도 동기화 필요

## 배포 전 TODO

- [ ] `plugin.json`의 `author.name` 실제 GitHub 유저명으로 변경
- [ ] GitHub 저장소 생성
- [ ] LICENSE 파일 추가 (MIT)
- [ ] .gitignore 추가 (.idea/ 등)
- [ ] 실제 `/plugin install` 테스트
- [ ] awesome-claude-code-plugins에 PR (선택)
- [ ] claude-plugins.dev 등록 (선택)

## 코드 스타일

- 명령어 파일: 한국어 (기술 용어는 영어 유지)
- README: 존댓말 (~합니다/~입니다)
- 커밋 메시지: 한국어 conventional commits
