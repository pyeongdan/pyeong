# sync.ps1 — Obsidian vault -> Quartz content 동기화 후 배포
# 사용법: 프로젝트 폴더에서  .\sync.ps1   (또는  .\sync.ps1 "커밋 메시지")
#         .\sync.ps1 -NoCommit  : content 동기화까지만 (커밋/푸시 안 함, 미리보기 확인용)
param(
  [string]$Message = "Update content",
  [switch]$NoCommit
)

$ErrorActionPreference = "Stop"
$vaultRoot = "C:\Users\lee\Documents\obsidian\평"
$vault   = "$vaultRoot\평"
$content = "C:\dev\pyeong-quartz\content"
$repo    = "C:\dev\pyeong-quartz"

# 사이트 비공개 대상: vault에는 그대로 두고 사이트에만 올리지 않는 폴더
$excluded = @("성과", "성과사진")
# vault에 없는 사이트 전용 파일 (content 기준 상대경로). 여기 없으면 [2/5]에서 삭제됨
$siteOnly = @("index.md", "logo.png")
$skipDirs = @(".obsidian", ".space", ".makemd", ".trash")
$imageExt = @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp")

Write-Host "[1/5] vault -> content 동기화 (robocopy)..." -ForegroundColor Cyan
$xd = $skipDirs + ($excluded | ForEach-Object { Join-Path $vault $_ })
robocopy $vault $content /E /XD $xd | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy 실패 (exit $LASTEXITCODE)" }

Write-Host "[2/5] vault에서 삭제/이동된 파일 정리..." -ForegroundColor Cyan
# robocopy /E는 삭제를 반영하지 않으므로, vault에 없는 content 파일을 직접 지운다(사이트 전용 파일 제외)
$vaultFiles = @{}
Get-ChildItem -LiteralPath $vault -Recurse -File -Force | ForEach-Object {
  $vaultFiles[$_.FullName.Substring($vault.Length + 1)] = $true
}
Get-ChildItem -LiteralPath $content -Recurse -File -Force | ForEach-Object {
  $rel = $_.FullName.Substring($content.Length + 1)
  if (-not $vaultFiles.ContainsKey($rel) -and $siteOnly -notcontains $rel) {
    Remove-Item -LiteralPath $_.FullName -Force
    Write-Host "    $rel (vault에 없음) 제거" -ForegroundColor DarkGray
  }
}

Write-Host "[3/5] 구조 정규화..." -ForegroundColor Cyan
# 비공개 대상이 content에 남아 있으면 제거(과거 동기화 잔재 대비)
foreach ($name in $excluded) {
  $stale = Join-Path $content $name
  if (Test-Path -LiteralPath $stale) {
    Remove-Item -LiteralPath $stale -Recurse -Force
    Write-Host "    $name/ (비공개 대상) 제거" -ForegroundColor DarkGray
  }
}
# vault의 평.md는 옛 홈페이지(중복). 사이트 홈은 content/index.md 사용 -> stray 제거
$pyeongStray = Join-Path $content "평.md"
if (Test-Path -LiteralPath $pyeongStray) {
  Remove-Item -LiteralPath $pyeongStray -Force
  Write-Host "    평.md (stray) 제거" -ForegroundColor DarkGray
}
# Make.md가 만드는 빈 폴더 노트(폴더명.md, 0바이트) 제거: 폴더와 슬러그가 충돌해 그래프/링크가 끊김
Get-ChildItem -LiteralPath $content -Recurse -File -Filter *.md |
  Where-Object { $_.Length -eq 0 -and $_.BaseName -eq $_.Directory.Name } |
  ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force
    Write-Host "    $($_.FullName.Substring($content.Length + 1)) (빈 폴더 노트) 제거" -ForegroundColor DarkGray
  }
# 어떤 노트에서도 쓰지 않는 이미지 제거 (![[x.png]], [[x.png]], ![](path/x.png) 기준, 파일명으로 매칭)
$refs = @{}
Get-ChildItem -LiteralPath $content -Recurse -File -Filter *.md | ForEach-Object {
  $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
  foreach ($m in [regex]::Matches($text, '\[\[([^\]|#]+)')) {
    $refs[($m.Groups[1].Value.Trim() -split '[\\/]')[-1]] = $true
  }
  foreach ($m in [regex]::Matches($text, '\]\(([^)]+)\)')) {
    $target = $m.Groups[1].Value.Trim()
    try { $target = [uri]::UnescapeDataString($target) } catch {}
    $refs[($target -split '[\\/]')[-1]] = $true
  }
}
$unused = @(Get-ChildItem -LiteralPath $content -Recurse -File | Where-Object {
  $imageExt -contains $_.Extension.ToLower() -and
  -not $refs.ContainsKey($_.Name) -and
  $siteOnly -notcontains $_.FullName.Substring($content.Length + 1)
})
foreach ($img in $unused) { Remove-Item -LiteralPath $img.FullName -Force }
if ($unused.Count -gt 0) { Write-Host "    본문에 쓰이지 않는 이미지 $($unused.Count)개 제외" -ForegroundColor DarkGray }
# 비어 버린 폴더 제거 (깊은 폴더부터)
Get-ChildItem -LiteralPath $content -Recurse -Directory -Force |
  Sort-Object { $_.FullName.Length } -Descending |
  Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
  ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

if ($NoCommit) {
  Write-Host "완료(-NoCommit). content만 갱신함. 확인 후 .\sync.ps1 로 커밋/푸시." -ForegroundColor Green
  $global:LASTEXITCODE = 0  # robocopy 종료 코드(1~7 = 정상)가 남지 않게
  return
}

Write-Host "[4/5] git add/commit..." -ForegroundColor Cyan
Set-Location $repo
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host "    커밋할 변경 없음" -ForegroundColor Yellow; return }

Write-Host "[5/5] git push (GitHub Actions가 자동 배포)..." -ForegroundColor Cyan
git push origin main
Write-Host "완료. 1~2분 후 https://pyeongdan.github.io/pyeong/ 반영." -ForegroundColor Green
