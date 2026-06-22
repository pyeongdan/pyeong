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


## 노트를 수정하려면
- content/는 vault(`...\obsidian\평\평`)의 복사본이며 **폴더 구조까지 그대로 미러링**함. Explorer 트리 = 이 폴더 구조.
- vault를 고쳐도 사이트는 자동으로 안 바뀜.
- 갱신 방법 두 가지:
  - (A) vault에서 고친 뒤 robocopy로 content/에 동기화 후 commit + push:
    `robocopy "C:\Users\lee\Documents\obsidian\평\평" "C:\dev\pyeong-quartz\content" /E /XD .obsidian`
    주의: robocopy는 추가/수정만 반영. vault에서 **삭제**한 파일은 content/에서 수동으로 지워야 함.
  - (B) content/의 .md를 직접 고친 후 commit + push.
- push하면 GitHub Actions가 자동으로 다시 빌드/배포함.
- ONGEKI(`방송글/콜라보/ONGEKI COLLABORATION LIVE(미완).md`)는 **공개**로 전환됨(과거 비공개 방침 폐기).

## 기타
- 저장소는 public. 즉 원본 마크다운 노트도 누구나 볼 수 있음.
- 한글 파일명은 URL에서 퍼센트 인코딩되지만 정상 동작함.
- 로컬 미리보기: 프로젝트 폴더에서 `npx quartz build --serve` → http://localhost:8080
