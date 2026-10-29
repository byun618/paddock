# paddock — 공통 지침

paddock 은 AI 작업 흐름(규칙·역할·스킬·게이트·harness 매핑·출고)을 프로젝트에 깔아 주는 Claude Code 플러그인이다.
`adopt` 스킬이 대상 코드베이스를 분석해 프로젝트별 설계를 쓰고, 고정 뼈대는 `assets/` 에서 그대로 복사한다.
지금은 adopt 와 L0·L1·L2 자산이 있다 — sync(고정 자산 갱신)·L3(출고)·specs-inrepo 는 아직 없다.

## 산출물

- **작업 문서(분석·기준·판정·회고)는 별도 private 레포 paddock-specs 에 둔다** — 이 레포 checkout 옆 `../paddock-specs`.
  작업 하나 = `<일감 ID>-<슬러그>/` 폴더, 단계 산출물은 번호 파일(00-analysis.md, …). 방향은 그 레포의 00-project.md
- **이 레포는 공개될 수 있다.** 일감 번호·홈 경로·사용자 이름·작업 원자료를 커밋하지 않는다. `docs/` 는 사용자용 문서만
  (아직 없음). `scripts/check.sh` 의 「공개」 검사가 이것을 본다

## 레이아웃

- `.claude-plugin/` — `plugin.json`(버전 원본) · `marketplace.json`(이 레포 자체가 마켓플레이스, `paddock@paddock`)
- `skills/` — 플러그인 스킬: `adopt` (예정: sync)
- `bin/` — 결정적 도구 `paddock-render`(render·apply·sync) · `paddock-check`. 플러그인 bin 이라 세션 PATH 에 들어간다
- `evals/` — `claude plugin eval` 트리거 케이스 (결과 `evals/results/` 는 커밋하지 않음)
- `assets/l<층>/` — 대상 레포 루트를 비추는 자산 트리. **층·표기 규약·변수·복사 규칙의 원본은 `assets/README.md` 한 곳**
- `templates/` — 역할마다 찍어내는 틀
- `scripts/check.sh` — 자산 계약·공개 안전 검사. 자산을 고친 커밋 전에 돌린다
- `scripts/render-test.sh` · `scripts/sync-test.sh` · `scripts/l1-tests/` — 렌더·sync 도구, task 스크립트 시험
  (`SY_MUTANT=<가드>` · `TF_MUTANT=<가드>` 로 변이 대조)

## 자산 수정

- 자산의 표기(`{{VAR}}`·`paddock:fixed`·`seed`·`design`·`module`)를 쓰거나 바꾸면 `assets/README.md` 를 같은 커밋에서 고친다
- 대상 레포의 다른 파일이 이름·번호로 가리키는 것(절 제목·절 번호·변수 이름·마커 형식)을 바꾸는 것은 깨는 변경이다
- 자산은 특정 프로젝트의 사례·일감 번호·경로를 담지 않는다 — 규칙 문장만 남긴다

## 버전

- 원본은 `.claude-plugin/plugin.json` 의 `version` 한 곳 — `marketplace.json` 에 적지 않는다(적으면 무시되고 validate 가 경고)
- SemVer, 태그 `vX.Y.Z`, 변경 내역은 `CHANGELOG.md`. 0.x 동안은 minor 가 깨는 변경을 포함할 수 있다
- 1.0 이후: major = 대상 레포에서 손으로 이전해야 하는 변경 · minor = 자산·모듈 추가 · patch = 문구
- 버전을 올리지 않으면 설치한 쪽에 갱신이 가지 않는다(캐시가 버전 이름으로 잡힌다)

## 작업 흐름

- v0(adopt 동작) 전까지는 `main` 에 직접 커밋한다. v0 뒤 paddock 에 adopt 를 스스로 적용하고 PR 흐름으로 바꾼다
- 검증: `claude plugin validate . --strict` · `scripts/check.sh` · `scripts/render-test.sh` · `scripts/sync-test.sh` 가 통과해야 커밋한다. task 스크립트를 고치면 `scripts/l1-tests/task-finish-test.sh` 도
- 시크릿 점검: gitleaks pre-commit 훅(`.githooks/`). 클론마다 한 번 `git config core.hooksPath .githooks`
