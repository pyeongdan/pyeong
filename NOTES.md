# NOTES (구조적 주의사항)

## 이 프로젝트는 무엇인가
- Obsidian 노트를 Quartz 5로 변환해 GitHub Pages로 무료 공개하는 사이트.
- 원본 vault: `C:\Users\lee\Documents\obsidian\평` (이 폴더는 절대 직접 수정/배포하지 않음).
- 공개 대상: 방송글(`V LIBERTY 5 LIVE 정리글`, `V LIBERTY 5 LIVE 스크립트` 등) + 스크린샷. 파일이 변경됨에 따라 유동적으로 바뀔 수 있음. 성과 계열은 비공개(아래 5번).

## 반드시 지킬 것
1. baseUrl = 저장소 이름과 일치해야 함.
   - 현재: `pyeongdan.github.io/pyeong` (quartz.config.yaml). 실제 라이브 사이트 = 이 repo(`pyeongdan/pyeong`).
   - `pyeongdan/djmax-notes` repo는 이제 리다이렉트 전용(옛 URL → 새 URL). DJMAX 글 경로 바뀌면 그쪽 index.html도 같이 수정.
   - 저장소 이름을 바꾸면 baseUrl도 같이 바꿔야 링크/이미지가 안 깨짐.
2. CI 배포는 빌드 전에 `npx quartz plugin install` 필수.
   - Quartz 5는 커뮤니티 플러그인을 github에서 받아옴.
   - 이미 `.github/workflows/deploy.yml`에 반영됨.
3. `enableSPA: false` 유지(quartz.config.yaml).
   - GitHub Pages 서브경로(/pyeong) + 폴더 페이지 + 상대링크 조합에서 SPA가 클릭 이동 시 `/pyeong/` 프리픽스를 떨어뜨려 404가 났음(직접 로드는 GitHub의 trailing-slash 301로 우회돼 "가끔"만 발생).
   - SPA를 끄면 매 이동이 풀 로드 → GitHub가 슬래시를 붙여줘 상대링크가 항상 정상. 트레이드오프: 이동이 살짝 느림(작은 사이트라 체감 거의 없음).
4. 폴더 대표(허브) 노트는 `폴더/index.md`로 둘 것.
   - 폴더명과 같은 이름의 파일(예: `방송글/방송글.md`)을 두면 슬러그 충돌로 빈 폴더페이지와 실제 내용이 **다른 노드로 갈라져** 그래프/링크가 끊김.
   - 그래프 매칭: 폴더노트 슬러그는 simplifySlug에서 `폴더명/`(끝 슬래시)이 됨. 그래서 홈에서 `[[폴더명]]`으로 걸면 그래프 엣지가 안 생김. **`content/index.md`에서는 `[[폴더명/index|표시이름]]`으로 걸어야** 폴더 노드에 매칭돼 연결됨.
5. `성과`, `성과사진`은 사이트 비공개(2026-09-07부터).
   - 갱신을 못 따라가서 사이트에서 내림. 2026-09-11 기준 vault에서도 휴지통(`평\.trash\`)으로 옮겨진 상태.
   - `sync.ps1`의 `$excluded`가 robocopy 제외 + content에 남은 잔재 삭제까지 처리하므로, vault에 폴더를 되살려도 다시 올라가지 않음.
   - 다시 공개하려면 `$excluded = @()`로 비우고 `content/index.md`에 `[[성과/index|성과]]` 줄을 되살린 뒤 sync. 이때 허브는 `성과/index.md`여야 함(위 4번).


## 노트를 수정하려면
- content/는 vault(`...\obsidian\평\평`)의 복사본이며 **폴더 구조까지 그대로 미러링**함. Explorer 트리 = 이 폴더 구조.
- vault를 고쳐도 사이트는 자동으로 안 바뀜.
- 갱신 방법:
  - (A) **권장**: Obsidian에서 글 수정/추가 후 프로젝트 폴더에서 `.\sync.ps1` 실행.
    sync.ps1 = robocopy(vault→content, 비공개 폴더 제외) + vault에서 삭제/이동된 파일 정리 + 구조 정규화 + git add/commit/push 한 방.
    커밋 메시지 지정: `.\sync.ps1 "메시지"`. 커밋 전에 확인만 하려면 `.\sync.ps1 -NoCommit`(content만 갱신).
  - (B) content/의 .md를 직접 고친 후 git add/commit/push.
- 삭제/이동 반영(2026-09-11~): robocopy /E는 삭제를 반영하지 않으므로 sync.ps1 [2/5]가 **vault에 없는 content 파일을 직접 지움**. 폴더를 옮기거나 파일을 지워도 수동 정리 불필요.
  - 예외는 `$siteOnly`에 적힌 content 루트의 사이트 전용 파일(`index.md`, `logo.png`)뿐. **content에 사이트 전용 파일을 새로 두면 `$siteOnly`에 추가**할 것. 안 하면 다음 sync에서 지워짐.
  - robocopy /MIR는 쓰지 말 것(사이트 전용 파일까지 지움).
- sync.ps1이 올리지 않는 것(구조 정규화 [3/5]):
  - **빈 폴더 노트**: 0바이트이면서 파일명이 폴더명과 같은 `.md`(예: `DNF/DNF.md`). Make.md 플러그인이 폴더를 만들 때마다 생성함. 올라가면 위 4번의 슬러그 충돌. 내용을 채우면(0바이트가 아니면) 그대로 올라감.
  - **본문에 쓰이지 않는 이미지**: 어떤 노트에서도 `![[x.png]]`/`[[x.png]]`/`![](…/x.png)`로 참조하지 않는 이미지. 파일명으로만 매칭. 노트에 넣으면 다음 sync에서 올라감.
- push하면 GitHub Actions가 자동으로 다시 빌드/배포함.
- ONGEKI(`방송글/콜라보/ONGEKI COLLABORATION LIVE(미완).md`)는 **공개**로 전환됨(과거 비공개 방침 폐기).

## 홈페이지(메인) 수정
- 메인 페이지 = `content/index.md` (vault에 없는 사이트 전용 파일). **Obsidian이 아니라 이 파일을 직접 고친 뒤 push.**
- 구조: `## 글` 리스트(위키링크) + `## SNS` 리스트(마크다운 링크). 디자인 군더더기 없이 단순 유지.
- robocopy는 index.md를 덮어쓰지 않음(vault에 없으므로). 단 vault의 `평.md`가 동기화로 content에 딸려와 stray 노드가 될 수 있으니, 필요시 content에서 삭제.

## 그래프(노드뷰)
- 간격/힘은 quartz.config.yaml의 graph 플러그인 `options.localGraph`/`globalGraph`에서 조정(repelForce 클수록 멀어짐, linkDistance 링크 길이).
- 화살표(방향선)는 기본 미지원 — 추가하려면 graph 렌더링(PIXI moveTo/lineTo) 패치 필요(미니파이 dist까지 sed 패치, 취약). 현재 미적용.

## 동기화 캐비엇 (2026-07-08 추가)
- robocopy 제외 목록은 `.obsidian .space .makemd .trash` 전부 필요. `.space`(Make.md 플러그인 메타)가 한 번 공개 repo에 올라간 적 있음(히스토리에 잔존).
- **수동 robocopy + git push는 sync.ps1의 제외/정규화를 건너뜀** → 비공개 폴더(성과·성과사진)가 다시 올라가고 stray 평.md도 재발. 반드시 sync.ps1 사용.
- vault에서 이미지 폴더 구조를 바꿔도(예: 2026-09-11 `DNF 사진`, `LIBERTY 5 사진` → `사진 폴더/` 아래로 이동) sync.ps1 [2/5]가 옛 사본을 지우므로 중복이 쌓이지 않음. 위키링크는 파일명 기준(`markdownLinkResolution: shortest`)이라 폴더를 옮겨도 안 깨짐.
- `sync.ps1`은 **UTF-8 BOM으로 저장**할 것. BOM이 없으면 Windows PowerShell 5.1이 ANSI(CP949)로 읽어 스크립트 안의 한글 경로 문자열(`$excluded` 등)이 깨지고, 제외/삭제가 오류 없이 조용히 실패함.
- CI의 graph 플러그인 재빌드는 `npm ci`(devDependency tsup 설치) 후 `npm run build` — npm ci를 빼면 `tsup: not found`로 전체 배포 실패.

## 기타
- 저장소는 public. 즉 원본 마크다운 노트도 누구나 볼 수 있음.
- 한글 파일명은 URL에서 퍼센트 인코딩되지만 정상 동작함.
- 로컬 미리보기: 프로젝트 폴더에서 `npx quartz build --serve` → http://localhost:8080
