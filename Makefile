# CoUI 프로젝트 개발 도구

.PHONY: lint lint-web lint-flutter lint-fix analyze help

# 기본 타겟
help:
	@echo "CoUI 프로젝트 개발 도구"
	@echo ""
	@echo "사용 가능한 명령어:"
	@echo "  make lint        - 모든 패키지의 린트 검사 (dart analyze + dcm analyze)"
	@echo "  make lint-web    - coui_web 패키지만 린트 검사"
	@echo "  make lint-flutter- coui_flutter 패키지만 린트 검사"
	@echo "  make lint-fix    - 자동으로 수정 가능한 린트 이슈 수정"
	@echo "  make analyze     - dart analyze만 실행"
	@echo "  make dcm         - dcm analyze만 실행"
	@echo "  make help        - 이 도움말 표시"

# 전체 린트 검사
lint:
	@./scripts/lint_all.sh

# dart만 린트 검사
lint-web:
	@echo "🔍 Analyzing coui_web package..."
	@echo "Dart analyze:"
	@cd packages/coui_web && dart analyze --fatal-infos .
	@echo ""
	@echo "DCM analyze:"
	@dcm analyze packages/coui_web --reporter=console

# flutter만 린트 검사  
lint-flutter:
	@echo "🔍 Analyzing coui_flutter package..."
	@echo "Dart analyze:"
	@cd packages/coui_flutter && dart analyze --fatal-infos .
	@cd packages/flutter_coui && dart analyze --fatal-infos .
	@echo ""
	@echo "DCM analyze:"
	@dcm analyze packages/coui_flutter --reporter=console
	@dcm analyze packages/flutter_coui --reporter=console

# 자동 수정
lint-fix:
	@echo "🔧 Auto-fixing lint issues..."
	@cd packages/coui_web && dart fix --apply
	@cd packages/coui_flutter && dart fix --apply
	@cd packages/flutter_coui && dart fix --apply
	@echo "✅ Auto-fix complete!"

# Dart analyze만
analyze:
	@echo "🔧 Running dart analyze..."
	@cd packages/coui_web && dart analyze --fatal-infos .
	@cd packages/coui_flutter && dart analyze --fatal-infos .
	@cd packages/flutter_coui && dart analyze --fatal-infos .

# DCM analyze만
dcm:
	@echo "🎯 Running dcm analyze..."
	@dcm analyze packages/coui_web --reporter=console
	@dcm analyze packages/coui_flutter --reporter=console
	@dcm analyze packages/flutter_coui --reporter=console