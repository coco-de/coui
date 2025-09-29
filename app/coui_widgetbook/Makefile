## 설정 명령 ----------------------------------------

## 참고: Windows의 경우 권장 터미널은 cmd입니다.

direnv_allow: ## direnv 허용
	direnv allow

clean: ## build/ 및 .dart_tool/ 디렉터리를 삭제합니다.
	fvm flutter clean
	
pub_clean: ## 디스크 공간을 확보하거나 문제가 있는 패키지를 제거하기 위해 전체 시스템 캐시를 비웁니다.
	fvm flutter pub cache clean	

pub_get: ## 펍을 가져옵니다.
	fvm flutter pub get

pub_outdated: ## 오래된 패키지를 확인합니다.
	fvm flutter pub outdated

pub_repair: ## 시스템 캐시에 있는 모든 패키지를 새로 재설치합니다.
	fvm flutter pub cache repair

build_runner: ## 이 명령은 코드에서 생성된 의존성 파일을 생성합니다.
	fvm dart run build_runner build --delete-conflicting-outputs

build_runner_watch: ## 이 명령은 '개발 중 자동으로' 코드 생성 종속성 파일을 생성합니다. 
	fvm dart run build_runner watch --delete-conflicting-outputs

format: ## 이 명령은 코드베이스의 형식을 지정하고 임포트 소터를 실행합니다.
	fvm dart format lib test

clean_rebuild: clean pub_clean pub_global pub_get build_runner format

rebuild: pub_get build_runner format

pub_global: ## 기본 글로벌 패키지를 설치 합니다
	fvm dart pub global activate coverage
	dart pub global activate melos
	fvm dart pub global activate mason_cli
	fvm dart pub global activate flutter_gen
	fvm dart pub global activate jaspr_cli
	fvm dart pub global activate serverpod_cli 2.4.0
	fvm dart pub global activate flutterfire_cli

lint: ## 코드베이스에서 이슈를 분석합니다.
	fvm flutter analyze lib test
	fvm dart analyze lib test

lcov_gen: ## lcov를 생성합니다.
	fvm flutter test --coverage

lcov_gen_ci: ## CI 환경에서 lcov를 생성합니다.
	fvm flutter test --dart-define=CI=true --coverage

lcov_gen_unit: ## 단위 테스트에 대해서만 lcov를 생성합니다.
	fvm flutter test test/unit --coverage

lcov_gen_widget: ## 위젯 테스트에 대해서만 lcov를 생성합니다.
	fvm flutter test test/widget --coverage

lcov_report_mac: ## macOS용 lcov 보고서를 생성합니다.
	lcov --ignore-errors unused --remove  coverage/lcov.info  'lib/app/*' 'lib/bootstrap.dart' '*.g.dart'  '*.freezed.dart' '*.dto.dart' '*.config.dart' '*.chopper.dart' '*_webview.dart' '**/service/*' '**/model/*' -o coverage/lcov.info
	genhtml coverage/lcov.info -o coverage/
	open coverage/index.html

lcov_report_win:  ## 윈도우용 lcov 보고서를 생성합니다.
	perl ${LCOV} --remove coverage/lcov.info 'lib/app/*' 'lib/bootstrap.dart' '*.g.dart'  '*.freezed.dart' '*.dto.dart' '*.config.dart' '*.chopper.dart' '*_webview.dart' '**/service/*' '**/model/*' -o coverage/lcov.info
	perl ${GENHTML} -o coverage/html coverage/lcov.info
	CMD /C start coverage/html/index.html	

lcov_win: lcov_gen lcov_report_win ## lcov 보고서를 생성하고 Windows용 커버리지 보고서를 자동으로 엽니다.

lcov_mac: lcov_gen lcov_report_mac  ## lcov 보고서를 생성하고 macOS용 커버리지 보고서를 자동으로 엽니다.

update_goldens: ## 골든 파일을 업데이트합니다.
	fvm flutter test --update-goldens

delete_goldens_win: ## Windows에서 모든 골든 파일을 삭제합니다.
	CMD /C FOR /d /r "test/widget" %d IN ("goldens") DO @IF EXIST "%d" rd /s /q "%d"

delete_failures_win: ## Windows에서 실패한 모든 골든 파일을 삭제합니다.
	CMD /C FOR /d /r "test/widget" %d IN ("failures") DO @IF EXIST "%d" rd /s /q "%d"

delete_failures_mac:  ## macOS에서 모든 골든 파일을 삭제합니다.
	find ./test/widget -type d -name "failures" -exec rm -rf {} \;

delete_goldens_mac:  ## macOS에서 실패한 모든 황금 파일을 삭제합니다.
	find ./test/widget -type d -name "goldens" -exec rm -rf {} \;

goldens_win: delete_goldens_win delete_failures_win update_goldens ## 기존 황금과 실패를 삭제하고 Windows용 황금 파일을 업데이트합니다.

goldens_mac: delete_goldens_mac delete_failures_mac update_goldens ## 기존 골든 및 실패 파일을 삭제하고 macOS용 골든 파일을 업데이트합니다.

dependency_validator: ## 이 명령은 의존성 검사기를 실행합니다.
	fvm dart run dependency_validator

# Firebase App ID를 .envrc에 추가하는 함수
# 사용법: add_to_envrc "변수명" "값" "설명"
define add_to_envrc
	@if [ -n "$(2)" ]; then \
		if grep -q "$(1)" .envrc; then \
			sed -i.bak "s|^export $(1)=.*|export $(1)='$(2)'|" .envrc; \
		else \
			echo "export $(1)='$(2)'" >> .envrc; \
		fi; \
		echo "✓ $(3) added to .envrc"; \
	fi
endef

update_app_icons_and_splash_screens:
	@echo "Updating icons and splash screens..."
	@fvm dart run flutter_native_splash:create --flavor development
	@fvm dart run flutter_native_splash:create --flavor staging
	@fvm dart run flutter_native_splash:create
	@fvm dart run icons_launcher:create --flavor development
	@fvm dart run icons_launcher:create --flavor staging
	@fvm dart run icons_launcher:create
	@echo "Update complete."

### 파이어베이스 콘솔 프로젝트 생성
create_new_firebase_project:
	@echo "Creating new Firebase project..."
	@firebase projects:create im-cocode-coui-ymnc-dev --display-name "coui DEV"
	@firebase projects:create im-cocode-coui-ymnc-stg --display-name "coui STG"
	@firebase projects:create im-cocode-coui-ymnc --display-name "coui"
	@echo "Create complete."

### 파이어베이스 프로젝트 설정 초기화
init_firebase_project:
	@echo "Initializing Firebase project..."
	@flutterfire configure --project=im-cocode-coui-ymnc-dev \
		-i im.cocode.coui.ymnc.dev \
		--ios-target="Runner" \
		--ios-out=ios/Runner/development/GoogleService-Info.plist \
		-m im.cocode.mac.coui.dev \
		-a im.cocode.coui.ymnc.dev \
		--android-out=android/app/src/development/google-services.json \
		-o lib/app/config/firebase/development_firebase_options.dart \
		-y
	@cp "firebase.json" "firebase-dev.json"

	$(call add_to_envrc,FIREBASE_DEV_ANDROID_ID,$$(firebase apps:list android --project im-cocode-coui-ymnc-dev | grep -o "1:[0-9]*:android:[a-f0-9]*" | head -n 1),Development Android App ID)
	$(call add_to_envrc,FIREBASE_DEV_IOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc-dev | grep "coui (ios)" | awk -F'│' '{print $$3}' | tr -d ' '),Development iOS App ID)
	$(call add_to_envrc,FIREBASE_DEV_MACOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc-dev | grep "coui (macos)" | awk -F'│' '{print $$3}' | tr -d ' '),Development macOS App ID)
	$(call add_to_envrc,FIREBASE_DEV_WEB_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc-dev | grep "coui (web)" | awk -F'│' '{print $$3}' | tr -d ' '),Development Web App ID)
	$(call add_to_envrc,FIREBASE_DEV_WINDOWS_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc-dev | grep "coui (windows)" | awk -F'│' '{print $$3}' | tr -d ' '),Development Windows App ID)

	@flutterfire configure --project=im-cocode-coui-ymnc-stg \
		-i im.cocode.coui.ymnc.stg \
		--ios-target="Runner" \
		--ios-out=ios/Runner/staging/GoogleService-Info.plist \
		-m im.cocode.mac.coui.stg \
		-a im.cocode.coui.ymnc.stg \
		--android-out=android/app/src/staging/google-services.json \
		-o lib/app/config/firebase/staging_firebase_options.dart \
		-y
	@cp "firebase.json" "firebase-stg.json"

	$(call add_to_envrc,FIREBASE_STG_ANDROID_ID,$$(firebase apps:list android --project im-cocode-coui-ymnc-stg | grep -o "1:[0-9]*:android:[a-f0-9]*" | head -n 1),Staging Android App ID)
	$(call add_to_envrc,FIREBASE_STG_IOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc-stg | grep "coui (ios)" | awk -F'│' '{print $$3}' | tr -d ' '),Staging iOS App ID)
	$(call add_to_envrc,FIREBASE_STG_MACOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc-stg | grep "coui (macos)" | awk -F'│' '{print $$3}' | tr -d ' '),Staging macOS App ID)
	$(call add_to_envrc,FIREBASE_STG_WEB_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc-stg | grep "coui (web)" | awk -F'│' '{print $$3}' | tr -d ' '),Staging Web App ID)
	$(call add_to_envrc,FIREBASE_STG_WINDOWS_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc-stg | grep "coui (windows)" | awk -F'│' '{print $$3}' | tr -d ' '),Staging Windows App ID)

	@flutterfire configure --project=im-cocode-coui-ymnc \
		-i im.cocode.coui.ymnc \
		--ios-target="Runner" \
		--ios-out=ios/Runner/production/GoogleService-Info.plist \
		-m im.cocode.mac.coui \
		-a im.cocode.coui.ymnc \
		--android-out=android/app/src/production/google-services.json \
		-o lib/app/config/firebase/production_firebase_options.dart \
		-y

	$(call add_to_envrc,FIREBASE_PROD_ANDROID_ID,$$(firebase apps:list android --project im-cocode-coui-ymnc | grep -o "1:[0-9]*:android:[a-f0-9]*" | head -n 1),Production Android App ID)
	$(call add_to_envrc,FIREBASE_PROD_IOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc | grep "coui (ios)" | awk -F'│' '{print $$3}' | tr -d ' '),Production iOS App ID)
	$(call add_to_envrc,FIREBASE_PROD_MACOS_ID,$$(firebase apps:list ios --project im-cocode-coui-ymnc | grep "coui (macos)" | awk -F'│' '{print $$3}' | tr -d ' '),Production macOS App ID)
	$(call add_to_envrc,FIREBASE_PROD_WEB_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc | grep "coui (web)" | awk -F'│' '{print $$3}' | tr -d ' '),Production Web App ID)
	$(call add_to_envrc,FIREBASE_PROD_WINDOWS_ID,$$(firebase apps:list web --project im-cocode-coui-ymnc | grep "coui (windows)" | awk -F'│' '{print $$3}' | tr -d ' '),Production Windows App ID)

	@rm -f .envrc.bak
	@direnv allow .
	@echo "Initialize complete."

### GCP 서비스 계정 키 생성
create_service_account_keys:
	@echo "Setting up GCP authentication and service account keys..."
	@echo "1. Authenticating with Google Cloud..."
	# @gcloud auth login
	
	@echo "\n2. Setting up projects..."
	@gcloud projects list --format="value(projectId)" | grep -q "^im-cocode-coui-ymnc-dev$$" || \
		gcloud projects create im-cocode-coui-ymnc-dev --name="coui DEV" --set-as-default || \
		echo "Project im-cocode-coui-ymnc-dev already exists"
	
	@gcloud projects list --format="value(projectId)" | grep -q "^im-cocode-coui-ymnc-stg$$" || \
		gcloud projects create im-cocode-coui-ymnc-stg --name="coui STG" || \
		echo "Project im-cocode-coui-ymnc-stg already exists"
	
	@gcloud projects list --format="value(projectId)" | grep -q "^im-cocode-coui-ymnc$$" || \
		gcloud projects create im-cocode-coui-ymnc --name="coui" || \
		echo "Project im-cocode-coui-ymnc already exists"
	
	@echo "\n3. Creating service account keys for all environments..."
	@mkdir -p android/keystore
	@$(MAKE) create_dev_service_account_key
	@$(MAKE) create_stg_service_account_key
	@$(MAKE) create_prod_service_account_key
	@$(MAKE) enable_play_api_and_roles
	@echo "\nService account keys created successfully for all environments."

# 개별 환경별 키 생성 명령어
create_dev_service_account_key:
	@echo "\n[Development] Creating service account key..."
	@if ! gcloud iam service-accounts describe coui-dev-fastlane@im-cocode-coui-ymnc-dev.iam.gserviceaccount.com --project=im-cocode-coui-ymnc-dev > /dev/null 2>&1; then \
		gcloud iam service-accounts create coui-dev-fastlane \
			--display-name="coui Dev Fastlane Service Account" \
			--project=im-cocode-coui-ymnc-dev; \
	else \
		echo "Development service account already exists, skipping creation..."; \
	fi
	@gcloud services enable firebaseappdistribution.googleapis.com --project=im-cocode-coui-ymnc-dev
	@gcloud services enable androidpublisher.googleapis.com --project=im-cocode-coui-ymnc-dev
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc-dev \
		--member="serviceAccount:coui-dev-fastlane@im-cocode-coui-ymnc-dev.iam.gserviceaccount.com" \
		--role="roles/iam.serviceAccountAdmin"
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc-dev \
		--member="serviceAccount:coui-dev-fastlane@im-cocode-coui-ymnc-dev.iam.gserviceaccount.com" \
		--role="roles/firebaseappdistro.admin"
	@gcloud iam service-accounts keys create \
		android/keystore/im-cocode-coui-ymnc-development.json \
		--iam-account=coui-dev-fastlane@im-cocode-coui-ymnc-dev.iam.gserviceaccount.com \
		--project=im-cocode-coui-ymnc-dev

create_stg_service_account_key:
	@echo "\n[Staging] Creating service account key..."
	@if ! gcloud iam service-accounts describe coui-stg-fastlane@im-cocode-coui-ymnc-stg.iam.gserviceaccount.com --project=im-cocode-coui-ymnc-stg > /dev/null 2>&1; then \
		gcloud iam service-accounts create coui-stg-fastlane \
			--display-name="coui Staging Fastlane Service Account" \
			--project=im-cocode-coui-ymnc-stg; \
	else \
		echo "Staging service account already exists, skipping creation..."; \
	fi
	@gcloud services enable firebaseappdistribution.googleapis.com --project=im-cocode-coui-ymnc-stg
	@gcloud services enable androidpublisher.googleapis.com --project=im-cocode-coui-ymnc-stg
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc-stg \
		--member="serviceAccount:coui-stg-fastlane@im-cocode-coui-ymnc-stg.iam.gserviceaccount.com" \
		--role="roles/iam.serviceAccountAdmin"
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc-stg \
		--member="serviceAccount:coui-stg-fastlane@im-cocode-coui-ymnc-stg.iam.gserviceaccount.com" \
		--role="roles/firebaseappdistro.admin"
	@gcloud iam service-accounts keys create \
		android/keystore/im-cocode-coui-ymnc-staging.json \
		--iam-account=coui-stg-fastlane@im-cocode-coui-ymnc-stg.iam.gserviceaccount.com \
		--project=im-cocode-coui-ymnc-stg

create_prod_service_account_key:
	@echo "\n[Production] Creating service account key..."
	@if ! gcloud iam service-accounts describe coui-prod-fastlane@im-cocode-coui-ymnc.iam.gserviceaccount.com --project=im-cocode-coui-ymnc > /dev/null 2>&1; then \
		gcloud iam service-accounts create coui-prod-fastlane \
			--display-name="coui Production Fastlane Service Account" \
			--project=im-cocode-coui-ymnc; \
	else \
		echo "Production service account already exists, skipping creation..."; \
	fi
	@gcloud services enable firebaseappdistribution.googleapis.com --project=im-cocode-coui-ymnc
	@gcloud services enable androidpublisher.googleapis.com --project=im-cocode-coui-ymnc
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc \
		--member="serviceAccount:coui-prod-fastlane@im-cocode-coui-ymnc.iam.gserviceaccount.com" \
		--role="roles/iam.serviceAccountAdmin"
	@gcloud projects add-iam-policy-binding im-cocode-coui-ymnc \
		--member="serviceAccount:coui-prod-fastlane@im-cocode-coui-ymnc.iam.gserviceaccount.com" \
		--role="roles/firebaseappdistro.admin"
	@gcloud iam service-accounts keys create \
		android/keystore/im-cocode-coui-ymnc-production.json \
		--iam-account=coui-prod-fastlane@im-cocode-coui-ymnc.iam.gserviceaccount.com \
		--project=im-cocode-coui-ymnc

enable_play_api_and_roles:
	@echo "Enabling Google Play Android Developer API..."	
	@echo "\nSetup complete. Please follow these additional steps:"
	@echo "1. Go to Google Play Console (https://play.google.com/console/)"
	@echo "2. Navigate to Setup > API access"
	@echo "3. Link your project"
	@echo "4. Grant the necessary permissions to your service account"


### 파이어베이스 프로젝트 SHA-1 추가
add_firebase_sha:
	@echo "Adding SHA-1 certificates to Firebase projects..."
	@$(MAKE) add_dev_firebase_sha
	@$(MAKE) add_stg_firebase_sha
	@$(MAKE) add_prod_firebase_sha
	@echo "SHA-1 certificates added successfully to all environments."

add_dev_firebase_sha:
	@echo "\n[Development] Adding SHA-1 certificates..."
	@echo "Setting Firebase project to im-cocode-coui-ymnc-dev..."
	@firebase use im-cocode-coui-ymnc-dev
	@echo "1. Adding debug keystore SHA-1..."
	@echo "- Reading debug keystore from ~/.android/debug.keystore"
	@keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Debug SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc-dev..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc-dev | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc-dev; \
	}
	@echo "2. Adding release keystore SHA-1..."
	@echo "- Reading release keystore from android/keystore/release.keystore"
	@keytool -list -v -keystore android/keystore/release.keystore -alias coui -storepass "laputa1477!" -keypass "laputa1477!" | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Release SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc-dev..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc-dev | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc-dev; \
	}
	@echo "✓ Development SHA-1 certificates added successfully"

add_stg_firebase_sha:
	@echo "\n[Staging] Adding SHA-1 certificates..."
	@echo "Setting Firebase project to im-cocode-coui-ymnc-stg..."
	@firebase use im-cocode-coui-ymnc-stg
	@echo "1. Adding debug keystore SHA-1..."
	@echo "- Reading debug keystore from ~/.android/debug.keystore"
	@keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Debug SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc-stg..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc-stg | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc-stg; \
	}
	@echo "2. Adding release keystore SHA-1..."
	@echo "- Reading release keystore from android/keystore/release.keystore"
	@keytool -list -v -keystore android/keystore/release.keystore -alias coui -storepass "laputa1477!" -keypass "laputa1477!" | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Release SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc-stg..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc-stg | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc-stg; \
	}
	@echo "✓ Staging SHA-1 certificates added successfully"

add_prod_firebase_sha:
	@echo "\n[Production] Adding SHA-1 certificates..."
	@echo "Setting Firebase project to im-cocode-coui-ymnc..."
	@firebase use im-cocode-coui-ymnc
	@echo "1. Adding debug keystore SHA-1..."
	@echo "- Reading debug keystore from ~/.android/debug.keystore"
	@keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Debug SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc; \
	}
	@echo "2. Adding release keystore SHA-1..."
	@echo "- Reading release keystore from android/keystore/release.keystore"
	@keytool -list -v -keystore android/keystore/release.keystore -alias coui -storepass "laputa1477!" -keypass "laputa1477!" | grep "SHA1:" | sed 's/^[[:space:]]*SHA1:[[:space:]]*//' | { \
		read -r sha1; \
		echo "- Release SHA-1: $$sha1"; \
		echo "- Adding to Firebase project im-cocode-coui-ymnc..."; \
		app_id=$$(firebase apps:list android --project im-cocode-coui-ymnc | grep -o "1:[0-9]*:android:[a-f0-9]*"); \
		echo "- App ID: $$app_id"; \
		firebase apps:android:sha:create "$$app_id" "$$sha1" --project im-cocode-coui-ymnc; \
	}
	@echo "✓ Production SHA-1 certificates added successfully"

build_apk:
	fvm flutter build apk --release  --no-tree-shake-icons --target-platform=android-arm64 --flavor production --target lib/main_production.dart

encode_keystore: ## 안드로이드 키스토어 파일을 base64로 인코딩하여 .envrc에 추가
	@echo "Encoding Android keystore files to base64..."
	@if [ -f "android/keystore/release.keystore" ]; then \
		RELEASE_KEY_BASE64=$$(base64 -i android/keystore/release.keystore); \
		if grep -q "ANDROID_RELEASE_KEY_BASE64" .envrc; then \
			sed -i.bak "s|^export ANDROID_RELEASE_KEY_BASE64=.*|export ANDROID_RELEASE_KEY_BASE64='$$RELEASE_KEY_BASE64'|" .envrc; \
		else \
			echo "export ANDROID_RELEASE_KEY_BASE64='$$RELEASE_KEY_BASE64'" >> .envrc; \
		fi; \
		echo "✓ Release keystore encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: android/keystore/release.keystore file not found"; \
	fi
	@if [ -f "android/key.properties" ]; then \
		KEY_PROPERTIES_BASE64=$$(base64 -i android/key.properties); \
		if grep -q "ANDROID_KEY_PROPERTIES_BASE64" .envrc; then \
			sed -i.bak "s|^export ANDROID_KEY_PROPERTIES_BASE64=.*|export ANDROID_KEY_PROPERTIES_BASE64='$$KEY_PROPERTIES_BASE64'|" .envrc; \
		else \
			echo "export ANDROID_KEY_PROPERTIES_BASE64='$$KEY_PROPERTIES_BASE64'" >> .envrc; \
		fi; \
		echo "✓ Android key.properties encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: android/key.properties file not found"; \
	fi
	@if [ -f "ios/fastlane/appstore_connect_api_key.json" ]; then \
		APPSTORE_KEY_BASE64=$$(base64 -i ios/fastlane/appstore_connect_api_key.json); \
		if grep -q "APPSTORE_CONNECT_API_KEY_BASE64" .envrc; then \
			sed -i.bak "s|^export APPSTORE_CONNECT_API_KEY_BASE64=.*|export APPSTORE_CONNECT_API_KEY_BASE64='$$APPSTORE_KEY_BASE64'|" .envrc; \
		else \
			echo "export APPSTORE_CONNECT_API_KEY_BASE64='$$APPSTORE_KEY_BASE64'" >> .envrc; \
		fi; \
		echo "✓ App Store Connect API key encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: ios/fastlane/appstore_connect_api_key.json file not found"; \
	fi
	@if [ -f "android/keystore/im-cocode-coui-ymnc-development.json" ]; then \
		DEV_KEY_BASE64=$$(base64 -i android/keystore/im-cocode-coui-ymnc-development.json); \
		if grep -q "FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64" .envrc; then \
			sed -i.bak "s|^export FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64=.*|export FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$DEV_KEY_BASE64'|" .envrc; \
		else \
			echo "export FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$DEV_KEY_BASE64'" >> .envrc; \
		fi; \
		echo "✓ Development service account key encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: android/keystore/im-cocode-coui-ymnc-development.json file not found"; \
	fi
	@if [ -f "android/keystore/im-cocode-coui-ymnc-staging.json" ]; then \
		STG_KEY_BASE64=$$(base64 -i android/keystore/im-cocode-coui-ymnc-staging.json); \
		if grep -q "FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64" .envrc; then \
			sed -i.bak "s|^export FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64=.*|export FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$STG_KEY_BASE64'|" .envrc; \
		else \
			echo "export FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$STG_KEY_BASE64'" >> .envrc; \
		fi; \
		echo "✓ Staging service account key encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: android/keystore/im-cocode-coui-ymnc-staging.json file not found"; \
	fi
	@if [ -f "android/keystore/im-cocode-coui-ymnc-production.json" ]; then \
		PROD_KEY_BASE64=$$(base64 -i android/keystore/im-cocode-coui-ymnc-production.json); \
		if grep -q "FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64" .envrc; then \
			sed -i.bak "s|^export FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64=.*|export FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$PROD_KEY_BASE64'|" .envrc; \
		else \
			echo "export FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64='$$PROD_KEY_BASE64'" >> .envrc; \
		fi; \
		echo "✓ Production service account key encoded and added to .envrc"; \
	else \
		echo "⚠️  Warning: android/keystore/im-cocode-coui-ymnc-production.json file not found"; \
	fi
	@rm -f .envrc.bak
	@echo "direnv 설정을 적용합니다..."
	@direnv allow
	@echo "✓ All keystore files have been processed"

github_secrets: ## GitHub Actions secrets 추가
	gh secret set MATCH_KEYCHAIN_NAME --body "$(MATCH_KEYCHAIN_NAME)"
	gh secret set MATCH_KEYCHAIN_PASSWORD --body "$(MATCH_KEYCHAIN_PASSWORD)"
	gh secret set RELEASE_STORE_PASSWORD --body "$(RELEASE_STORE_PASSWORD)"
	gh secret set MATCH_GIT_BASIC_AUTHORIZATION_BASE64 --body "$(MATCH_GIT_BASIC_AUTHORIZATION_BASE64)"
	gh secret set FIREBASE_DEV_ANDROID_ID --body "$(FIREBASE_DEV_ANDROID_ID)"
	gh secret set FIREBASE_DEV_IOS_ID --body "$(FIREBASE_DEV_IOS_ID)" 
	gh secret set FIREBASE_DEV_WEB_ID --body "$(FIREBASE_DEV_WEB_ID)"
	gh secret set FIREBASE_DEV_MACOS_ID --body "$(FIREBASE_DEV_MACOS_ID)"
	gh secret set FIREBASE_DEV_WINDOWS_ID --body "$(FIREBASE_DEV_WINDOWS_ID)"
	gh secret set FIREBASE_STG_ANDROID_ID --body "$(FIREBASE_STG_ANDROID_ID)"
	gh secret set FIREBASE_STG_IOS_ID --body "$(FIREBASE_STG_IOS_ID)"
	gh secret set FIREBASE_STG_WEB_ID --body "$(FIREBASE_STG_WEB_ID)" 
	gh secret set FIREBASE_STG_MACOS_ID --body "$(FIREBASE_STG_MACOS_ID)"
	gh secret set FIREBASE_STG_WINDOWS_ID --body "$(FIREBASE_STG_WINDOWS_ID)"
	gh secret set FIREBASE_PROD_ANDROID_ID --body "$(FIREBASE_PROD_ANDROID_ID)"
	gh secret set FIREBASE_PROD_IOS_ID --body "$(FIREBASE_PROD_IOS_ID)"
	gh secret set FIREBASE_PROD_WEB_ID --body "$(FIREBASE_PROD_WEB_ID)"
	gh secret set FIREBASE_PROD_MACOS_ID --body "$(FIREBASE_PROD_MACOS_ID)" 
	gh secret set FIREBASE_PROD_WINDOWS_ID --body "$(FIREBASE_PROD_WINDOWS_ID)"
	gh secret set FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64 --body "$(FIREBASE_DEV_APP_DISTRIBUTION_CREDENTIALS_BASE64)"
	gh secret set FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64 --body "$(FIREBASE_STG_APP_DISTRIBUTION_CREDENTIALS_BASE64)"
	gh secret set FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64 --body "$(FIREBASE_PROD_APP_DISTRIBUTION_CREDENTIALS_BASE64)"
	gh secret set ANDROID_KEY_PROPERTIES_BASE64 --body "$(ANDROID_KEY_PROPERTIES_BASE64)"
	gh secret set ANDROID_RELEASE_KEY_BASE64 --body "$(ANDROID_RELEASE_KEY_BASE64)"
	gh variable set LAST_BUILD_NUMBER --body "$(LAST_BUILD_NUMBER)

# iOS 앱 생성
create_ios_app:
	@echo "Creating iOS app..."
	@cd ios && fastlane create_app flavor:dev
	@cd ios && fastlane create_app flavor:stg
	@cd ios && fastlane create_app flavor:prod
	@cd ios && fastlane certificates force:true readonly:false generate_certs:true
	@echo "iOS app creation complete."

# Firebase 초기화 명령어
firebase_init_dev: ## Firebase 개발 환경 초기화
	@echo "Initializing Firebase for development environment..."
	@bash scripts/firebase_init.sh dev
	@echo "Firebase dev initialization complete."

firebase_init_stg: ## Firebase 스테이징 환경 초기화
	@echo "Initializing Firebase for staging environment..."
	@bash scripts/firebase_init.sh stg
	@echo "Firebase staging initialization complete."

firebase_init_prod: ## Firebase 프로덕션 환경 초기화
	@echo "Initializing Firebase for production environment..."
	@bash scripts/firebase_init.sh prod
	@echo "Firebase production initialization complete."

firebase_init: ## Firebase 모든 환경 초기화
	@echo "Initializing Firebase for all environments..."
	@$(MAKE) firebase_init_dev
	@$(MAKE) firebase_init_stg
	@$(MAKE) firebase_init_prod
	@echo "All Firebase environments initialization complete."

# Firebase 환경 확인 및 초기화
ensure_firebase:
	@command -v firebase >/dev/null 2>&1 || { echo "Firebase CLI is not installed. Installing..."; npm install -g firebase-tools; }
	@if [ ! -f "firebase.json" ]; then \
		echo "Firebase.json not found. Running Firebase initialization..."; \
		$(MAKE) firebase_init_$(subst deploy_web_,,$(MAKECMDGOALS)); \
	fi

# Firebase 웹 배포 명령어
deploy_web_dev: ensure_firebase ## 개발 환경 웹 배포
	@echo "Deploying web app to development environment..."
	@bash scripts/deploy_web.sh dev
	@echo "Development web deployment complete."

deploy_web_stg: ensure_firebase ## 스테이징 환경 웹 배포
	@echo "Deploying web app to staging environment..."
	@bash scripts/deploy_web.sh stg
	@echo "Staging web deployment complete."

deploy_web_prod: ensure_firebase ## 프로덕션 환경 웹 배포
	@echo "Deploying web app to production environment..."
	@bash scripts/deploy_web.sh prod
	@echo "Production web deployment complete."

deploy_web: ensure_firebase ## 모든 환경 웹 배포
	@echo "Deploying web app to all environments..."
	@$(MAKE) deploy_web_dev
	@$(MAKE) deploy_web_stg
	@$(MAKE) deploy_web_prod
	@echo "All web deployments complete."

init_project: ## 프로젝트 초기화
	@echo "Initializing project..."
	@$(MAKE) create_new_firebase_project
	@$(MAKE) init_firebase_project
	@$(MAKE) create_service_account_keys
	@$(MAKE) encode_keystore
	@$(MAKE) github_secrets
	@echo "Project initialization complete."

.PHONY: \
	direnv_allow \
	clean \
	pub_clean \
	pub_get \
	pub_outdated \
	pub_repair \
	build_runner \
	build_runner_watch \
	format \
	lint \
	lcov_gen \
	lcov_gen_ci \
	lcov_gen_unit \
	lcov_gen_widget \
	lcov_report_mac \
	update_goldens \
	delete_goldens_win \
	delete_failures_win \
	dependency_validator \
	create_service_account_keys \
	create_dev_service_account_key \
	create_stg_service_account_key \
	create_prod_service_account_key \
	add_firebase_sha \
	github_secrets \
	github_variables \
	add_dev_firebase_sha \
	add_stg_firebase_sha \
	add_prod_firebase_sha \
	enable_play_api_and_roles \
	firebase_init_dev \
	firebase_init_stg \
	firebase_init_prod \
	firebase_init \
	deploy_web_dev \
	deploy_web_stg \
	deploy_web_prod \
	deploy_web \
	encode_keystore