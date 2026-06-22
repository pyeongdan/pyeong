# NOTES (구조적 주의사항)

## 이 프로젝트는 무엇인가
- Obsidian 노트를 Quartz 5로 변환해 GitHub Pages로 무료 공개하는 사이트.
- 원본 vault: `C:\Users\lee\Documents\obsidian\평` (이 폴더는 절대 직접 수정/배포하지 않음).
- 공개 대상: `V LIBERTY 5 LIVE 정리글`, `V LIBERTY 5 LIVE 스크립트` 2개 + 스크린샷 33장. 이나 파일이변경됨에따라 유동적으로 바뀔수있음.

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
   - 폴더명과 같은 이름의 파일(예: `성과/성과.md`)을 두면 슬러그 충돌로 빈 폴더페이지와 실제 내용이 **다른 노드로 갈라져** 그래프/링크가 끊김.
   - `성과` 허브는 `성과/index.md`로 둠. vault는 `성과/성과.md` 그대로 둬도 됨 — **`sync.ps1`이 동기화 후 자동으로 `성과/성과.md`→`성과/index.md`로 정규화**함.
   - 그래프 매칭: 폴더노트 슬러그는 simplifySlug에서 `성과/`(끝 슬래시)가 됨. 그래서 홈에서 `[[성과]]`(→`성과`)로 걸면 그래프 엣지가 안 생김. **`content/index.md`에서는 `[[성과/index|성과]]`로 걸어야** `성과/`에 매칭돼 평→성과 연결됨.


## 노트를 수정하려면
- content/는 vault(`...\obsidian\평\평`)의 복사본이며 **폴더 구조까지 그대로 미러링**함. Explorer 트리 = 이 폴더 구조.
- vault를 고쳐도 사이트는 자동으로 안 바뀜.
- 갱신 방법:
  - (A) **권장**: Obsidian에서 글 수정/추가 후 프로젝트 폴더에서 `.\sync.ps1` 실행.
    sync.ps1 = robocopy(vault→content) + 구조 정규화(성과/성과.md→index.md, stray 평.md 제거) + git add/commit/push 한 방.
    커밋 메시지 지정: `.\sync.ps1 "메시지"`.
  - (B) content/의 .md를 직접 고친 후 git add/commit/push.
- 주의: robocopy는 추가/수정만 반영. vault에서 **삭제**한 파일은 content/에서 수동으로 지워야 함(/MIR는 index.md·sync.ps1까지 지우므로 쓰지 말 것).
- push하면 GitHub Actions가 자동으로 다시 빌드/배포함.
- ONGEKI(`방송글/콜라보/ONGEKI COLLABORATION LIVE(미완).md`)는 **공개**로 전환됨(과거 비공개 방침 폐기).

## 홈페이지(메인) 수정
- 메인 페이지 = `content/index.md` (vault에 없는 사이트 전용 파일). **Obsidian이 아니라 이 파일을 직접 고친 뒤 push.**
- 구조: `## 글` 리스트(위키링크) + `## SNS` 리스트(마크다운 링크). 디자인 군더더기 없이 단순 유지.
- robocopy는 index.md를 덮어쓰지 않음(vault에 없으므로). 단 vault의 `평.md`가 동기화로 content에 딸려와 stray 노드가 될 수 있으니, 필요시 content에서 삭제.

## 그래프(노드뷰)
- 간격/힘은 quartz.config.yaml의 graph 플러그인 `options.localGraph`/`globalGraph`에서 조정(repelForce 클수록 멀어짐, linkDistance 링크 길이).
- 화살표(방향선)는 기본 미지원 — 추가하려면 graph 렌더링(PIXI moveTo/lineTo) 패치 필요(미니파이 dist까지 sed 패치, 취약). 현재 미적용.

## 기타
- 저장소는 public. 즉 원본 마크다운 노트도 누구나 볼 수 있음.
- 한글 파일명은 URL에서 퍼센트 인코딩되지만 정상 동작함.
- 로컬 미리보기: 프로젝트 폴더에서 `npx quartz build --serve` → http://localhost:8080
