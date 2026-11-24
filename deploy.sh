#!/usr/bin/env bash
set -euo pipefail

SRC="/Users/dongkeunkim/Desktop/유튜브_롱폼_초고속_수익창출_가이드.html"
DIR="/Users/dongkeunkim/youtube-longform-guide"
DST="$DIR/index.html"

if [[ ! -f "$SRC" ]]; then
  echo "❌ 원본 파일을 찾을 수 없습니다: $SRC" >&2
  exit 1
fi

python3 - "$SRC" "$DST" <<'PY'
import re
import sys
from pathlib import Path

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
html = src.read_text(encoding="utf-8")

# 1) 외부 공개 페이지에 로컬 경로/사용자명이 노출되지 않도록 참고 문서 제목 정돈
html = html.replace(
    "<h3>📚 참고한 내 옵시디언 정본 파일 (~/마스터)</h3>",
    "<h3>📚 참고한 핵심 정본 문서</h3>",
)

# 2) 외부 브라우저에서 클릭 시 깨지는 file:///Users/... 링크를 깔끔한 굵은 문서명으로 변환
html = re.sub(
    r'<a\s+href="file:///[^"]+">([^<]+)</a>',
    r'<strong>\1</strong>',
    html,
)

# 3) 안전망: 혹시 남은 /Users/<user>/ 패턴이 있으면 제거
html = re.sub(r'/Users/[^/\s"\'<>]+/', '~/', html)

dst.write_text(html, encoding="utf-8")
print(f"✅ 배포용 index.html 생성 완료 ({dst.stat().st_size:,} bytes)")
PY

cd "$DIR"
touch .nojekyll

if git diff --quiet -- index.html .nojekyll 2>/dev/null && git ls-files --error-unmatch index.html >/dev/null 2>&1; then
  echo "ℹ️ 변경된 내용이 없어 이미 최신 상태입니다."
else
  git add index.html .nojekyll deploy.sh
  git commit -m "update: 유튜브 롱폼 초고속 수익창출 가이드 ($(date '+%Y-%m-%d %H:%M'))"
  git push -u origin main
  echo "🚀 GitHub Pages 배포 푸시 완료: https://1pronano.github.io/youtube-longform-guide/"
fi
