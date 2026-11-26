# CoUI 프로젝트 개발 도구
#
# 린트 스택은 `dart analyze` 하나다 — 규칙 구성은 루트
# `analysis_options.yaml`(very_good_analysis + lint/strict + coui_lints
# 플러그인)이 소유한다. 아래 타겟은 그 애널라이저를 좁은 범위로 부르는
# 단축키일 뿐 별도 판정을 내리지 않는다.

.PHONY: lint lint-web lint-flutter lint-fix analyze format format-check help

help:
	@echo "CoUI 프로젝트 개발 도구"
	@echo ""
	@echo "사용 가능한 명령어:"
	@echo "  make lint         - 레포 전체 린트 검사 (CI 와 같은 판정)"
	@echo "  make lint-web     - coui_web 패키지만 린트 검사"
	@echo "  make lint-flutter - coui_flutter 패키지만 린트 검사"
	@echo "  make lint-fix     - 자동으로 수정 가능한 린트 이슈 수정"
	@echo "  make analyze      - 레포 전체 dart analyze (info 까지)"
	@echo "  make format       - 레포 전체 포맷 적용"
	@echo "  make format-check - 포맷 드리프트 검사 (CI 와 같은 판정)"
	@echo "  make help         - 이 도움말 표시"

# CI 게이트와 같은 판정 — warning 부터 차단한다.
lint:
	@echo "🔍 Analyzing the whole repo (CI gate semantics)..."
	@dart analyze . --fatal-warnings

lint-web:
	@echo "🔍 Analyzing coui_web package..."
	@dart analyze --fatal-infos packages/coui_web

lint-flutter:
	@echo "🔍 Analyzing coui_flutter package..."
	@dart analyze --fatal-infos packages/coui_flutter

lint-fix:
	@echo "🔧 Auto-fixing lint issues..."
	@dart fix --apply
	@echo "✅ Auto-fix complete!"

# CI 보다 엄격하다 — info 까지 본다.
analyze:
	@echo "🔧 Running dart analyze (info 포함)..."
	@dart analyze . --fatal-infos

format:
	@dart format .

format-check:
	@dart format --set-exit-if-changed --output=none .
