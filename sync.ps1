# sync.ps1 — Obsidian vault -> Quartz content 동기화 후 배포
# 사용법: 프로젝트 폴더에서  .\sync.ps1   (또는  .\sync.ps1 "커밋 메시지")
param(
  [string]$Message = "Update content"
)

$ErrorActionPreference = "Stop"
$vaultRoot = "C:\Users\lee\Documents\obsidian\평"
$vault   = "$vaultRoot\평"
$content = "C:\dev\pyeong-quartz\content"
$repo    = "C:\dev\pyeong-quartz"

# 사이트 비공개 대상: vault에는 그대로 두고 사이트에만 올리지 않는 폴더
$excluded = @("성과", "성과사진")

Write-Host "[1/4] vault -> content 동기화 (robocopy)..." -ForegroundColor Cyan
$xd = @(".obsidian", ".space", ".makemd", ".trash") + ($excluded | ForEach-Object { Join-Path $vault $_ })
robocopy $vault $content /E /XD $xd | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy 실패 (exit $LASTEXITCODE)" }

Write-Host "[2/4] 구조 정규화..." -ForegroundColor Cyan
# 비공개 대상이 content에 남아 있으면 제거(과거 동기화 잔재 대비)
foreach ($name in $excluded) {
  $stale = Join-Path $content $name
  if (Test-Path $stale) {
    Remove-Item $stale -Recurse -Force
    Write-Host "    $name/ (비공개 대상) 제거" -ForegroundColor DarkGray
  }
}
# vault의 평.md는 옛 홈페이지(중복). 사이트 홈은 content/index.md 사용 -> stray 제거
$pyeongStray = Join-Path $content "평.md"
if (Test-Path $pyeongStray) {
  Remove-Item $pyeongStray -Force
  Write-Host "    평.md (stray) 제거" -ForegroundColor DarkGray
}

Write-Host "[3/4] git add/commit..." -ForegroundColor Cyan
Set-Location $repo
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host "    커밋할 변경 없음" -ForegroundColor Yellow; return }

Write-Host "[4/4] git push (GitHub Actions가 자동 배포)..." -ForegroundColor Cyan
git push origin main
Write-Host "완료. 1~2분 후 https://pyeongdan.github.io/pyeong/ 반영." -ForegroundColor Green
