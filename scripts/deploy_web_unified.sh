#!/bin/bash
set -e  # 오류 발생시 스크립트 중단

ENV=$1
TARGET_FILE="lib/main.dart"

# 사용법 출력
if [ -z "$ENV" ]; then
  echo "Usage: $0 <environment>"
  echo "  environment: dev, stg, prod"
  exit 1
fi

# 현재 디렉토리 확인
echo "Current directory: $(pwd)"

# 환경에 따라 적절한 firebase 설정 파일 선택 및 index.html 경로 설정
if [ "$ENV" = "prod" ] || [ "$ENV" = "production" ]; then
  FIREBASE_CONFIG="firebase-prod.json"
  PROJECT_ALIAS="prod"
  PROJECT_ID="im-laputa-kobic"
  INDEX_HTML_SRC="web/index_prod.html"
  echo "Using production Firebase configuration"
elif [ "$ENV" = "stg" ] || [ "$ENV" = "staging" ]; then
  FIREBASE_CONFIG="firebase-stg.json"
  PROJECT_ALIAS="stg"
  PROJECT_ID="im-laputa-kobic-stg"
  INDEX_HTML_SRC="web/index_stg.html"
  echo "Using staging Firebase configuration"
elif [ "$ENV" = "dev" ] || [ "$ENV" = "development" ]; then
  FIREBASE_CONFIG="firebase-dev.json"
  PROJECT_ALIAS="dev"
  PROJECT_ID="im-laputa-kobic-dev"
  INDEX_HTML_SRC="web/index_dev.html"
  echo "Using development Firebase configuration"
else
  FIREBASE_CONFIG="firebase.json"
  PROJECT_ALIAS="dev"  # 기본값으로 개발 환경 설정
  PROJECT_ID="im-laputa-kobic-dev"
  INDEX_HTML_SRC="web/index_dev.html"
  echo "Using default Firebase configuration (development)"
fi

# flavor별 index.html 파일 교체
echo "Checking for flavor-specific index.html file..."
if [ -f "$INDEX_HTML_SRC" ]; then
  echo "Found $INDEX_HTML_SRC, replacing web/index.html..."
  # 원본 파일 백업 (필요한 경우)
  if [ ! -f "web/index.html.original" ]; then
    cp "web/index.html" "web/index.html.original"
    echo "Created backup of original index.html at web/index.html.original"
  fi
  cp "$INDEX_HTML_SRC" "web/index.html"
  echo "Successfully replaced web/index.html with $INDEX_HTML_SRC"
else
  echo "Warning: $INDEX_HTML_SRC not found. Using existing web/index.html"
fi

# Firebase 설정 파일 교체
if [ -f "$FIREBASE_CONFIG" ]; then
  if [ ! -f "firebase.json.original" ]; then
    cp "firebase.json" "firebase.json.original" 2>/dev/null || true
    echo "Created backup of original firebase.json at firebase.json.original"
  fi
  
  if [ "$FIREBASE_CONFIG" != "firebase.json" ]; then
    echo "Copying $FIREBASE_CONFIG to firebase.json..."
    cp "$FIREBASE_CONFIG" "firebase.json"
    echo "Successfully copied $FIREBASE_CONFIG to firebase.json"
  fi
else
  echo "Warning: $FIREBASE_CONFIG file not found"
fi

# firebase.json 파일 유효성 확인 및 호스팅 설정 체크
if [ ! -f "firebase.json" ] || ! grep -q "\"hosting\"" firebase.json; then
  echo "Error: firebase.json file not found or doesn't contain hosting configuration."
  echo "Running Firebase hosting initialization..."
  
  # 호스팅 초기화 스크립트 실행
  if [ -f "scripts/initialize_firebase_hosting.sh" ]; then
    bash scripts/initialize_firebase_hosting.sh $ENV
  else
    echo "Warning: initialize_firebase_hosting.sh not found"
  fi
  
  if [ ! -f "firebase.json" ] || ! grep -q "\"hosting\"" firebase.json; then
    echo "Failed to initialize Firebase hosting. Please run 'firebase init hosting' manually."
    exit 1
  fi
  
  echo "Firebase hosting initialization completed."
fi

# 환경에 따라 타겟 파일 결정
if [ "$ENV" = "prod" ] || [ "$ENV" = "production" ]; then
  TARGET_FILE="lib/main_production.dart"
  echo "Building for production using $TARGET_FILE"
elif [ "$ENV" = "stg" ] || [ "$ENV" = "staging" ]; then
  TARGET_FILE="lib/main_staging.dart"
  echo "Building for staging using $TARGET_FILE"
elif [ "$ENV" = "dev" ] || [ "$ENV" = "development" ]; then
  TARGET_FILE="lib/main_development.dart"
  echo "Building for development using $TARGET_FILE"
else
  echo "Using default main.dart"
fi

# 타겟 파일 존재 여부 확인 및 자동 생성
if [ ! -f "$TARGET_FILE" ]; then
  if [ "$TARGET_FILE" != "lib/main.dart" ] && [ -f "lib/main.dart" ]; then
    echo "📁 Auto-creating $TARGET_FILE from main.dart..."
    cp "lib/main.dart" "$TARGET_FILE"
    echo "✅ Successfully created $TARGET_FILE"
  else
    echo "Error: Target file $TARGET_FILE not found!"
    exit 1
  fi
fi

# 타겟 파일이 main.dart가 아닌 경우, main.dart로 복사하여 덮어씌우기
if [ "$TARGET_FILE" != "lib/main.dart" ]; then
  echo "Copying $TARGET_FILE to lib/main.dart..."
  cp "$TARGET_FILE" "lib/main.dart"
  echo "Successfully copied $TARGET_FILE to lib/main.dart"
fi

# Firebase 로그인 확인
echo "Checking Firebase authentication..."
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "Using service account authentication from: $GOOGLE_APPLICATION_CREDENTIALS"
  
  # FIREBASE_TOKEN 환경변수가 있으면 제거 (deprecated 방식 방지)
  if [ -n "$FIREBASE_TOKEN" ]; then
    echo "Removing deprecated FIREBASE_TOKEN environment variable..."
    unset FIREBASE_TOKEN
  fi
  
  # 기존 Firebase 로그인 상태 초기화
  firebase logout --project="$PROJECT_ID" 2>/dev/null || true
  
  # 서비스 계정으로 gcloud 인증 (Firebase CLI가 이를 사용)
  gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet
  echo "Activated service account credentials for: [$(gcloud config get-value account)]"
  echo "Service account authentication completed"
  
  # Firebase CLI가 서비스 계정을 사용하도록 강제 설정
  export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"
  
  # Firebase CLI 토큰 캐시 제거 (Service Account 사용 강제)
  rm -rf ~/.config/firebase 2>/dev/null || true
  
else
  echo "No service account found. Checking Firebase token authentication..."
  firebase projects:list > /dev/null 2>&1 || {
    echo "Firebase authentication required. Please log in:"
    firebase login
  }
fi

# 실제 프로젝트 존재 여부 확인
echo "Verifying Firebase project $PROJECT_ID exists..."
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  # 서비스 계정을 사용하는 경우 - 권한 문제로 직접 검증 생략
  echo "Using service account to set project: $PROJECT_ID"
  
  # Firebase CLI 테스트 (권한 오류 시 무시하고 계속 진행)
  if firebase projects:list --account="$(gcloud config get-value account)" 2>/dev/null | grep -q "$PROJECT_ID"; then
    echo "✅ Service account has access to project $PROJECT_ID"
  else
    echo "⚠️  Cannot verify project access with service account, but proceeding with deployment..."
    echo "Firebase will validate project access during deployment."
  fi
  
else
  # Firebase token을 사용하는 경우 firebase CLI로 확인
  if ! firebase projects:list | grep -q "$PROJECT_ID"; then
    echo "Error: Project ID '$PROJECT_ID' not found in your Firebase projects."
    echo "Available Firebase projects:"
    firebase projects:list
    echo ""
    echo "Please update the script with the correct project ID."
    exit 1
  fi
fi

# Firebase 프로젝트 설정
echo "Setting Firebase project to $PROJECT_ALIAS ($PROJECT_ID)..."
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  # Service Account 사용 시 토큰 방식으로 설정
  firebase use "$PROJECT_ID" --token "$(gcloud auth print-access-token)"
else
  firebase use "$PROJECT_ID"
fi

# .firebaserc 파일 업데이트
if [ -f ".firebaserc" ] && grep -q "\"$PROJECT_ALIAS\"" .firebaserc; then
  echo "Updating default project in .firebaserc to $PROJECT_ID..."
  sed -i.bak "s/\"default\": \".*\"/\"default\": \"$PROJECT_ID\"/" .firebaserc
  rm -f .firebaserc.bak
else
  echo "Warning: .firebaserc not found or doesn't contain alias '$PROJECT_ALIAS'"
fi

echo "Active Firebase project: $PROJECT_ID (alias: $PROJECT_ALIAS)"

# Flutter 웹 빌드
echo "Building Flutter web app..."
flutter clean
flutter pub get

# 환경별 빌드 명령어 설정
if [ "$ENV" = "prod" ] || [ "$ENV" = "production" ]; then
  flutter build web --release
elif [ "$ENV" = "stg" ] || [ "$ENV" = "staging" ]; then
  flutter build web --release
else
  flutter build web --release
fi

# firebase.json 파일 검증
echo "Validating firebase.json file..."
if [ ! -f "firebase.json" ] || ! grep -q "\"hosting\"" firebase.json; then
  echo "Error: firebase.json file validation failed."
  exit 1
fi

# hosting의 public 디렉토리 설정 확인
echo "Checking public directory setting in firebase.json..."
PUBLIC_DIR=$(grep -A 5 '"hosting"' firebase.json | grep '"public"' | sed 's/.*"public": *"\([^"]*\)".*/\1/' | head -1)
if [ "$PUBLIC_DIR" != "build/web" ]; then
  echo "Warning: public directory is set to '$PUBLIC_DIR', expected 'build/web'"
fi

# Firebase 호스팅에 배포
echo "Deploying to Firebase hosting..."
echo ""
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  # Service Account 사용 시 토큰 방식으로 배포
  firebase deploy --only hosting --project "$PROJECT_ID" --token "$(gcloud auth print-access-token)" || {
    echo "Deployment failed. Checking common issues..."
    echo "1. Verify that build/web directory exists and contains files"
    echo "2. Check firebase.json hosting configuration"
    echo "3. Ensure proper authentication"
    exit 1
  }
else
  firebase deploy --only hosting --project "$PROJECT_ID" || {
    echo "Deployment failed. Checking common issues..."
    echo "1. Verify that build/web directory exists and contains files"
    echo "2. Check firebase.json hosting configuration"
    echo "3. Ensure proper authentication"
    exit 1
  }
fi

echo ""
echo "Deployment completed successfully!"

# Firebase 설정 파일 백업 업데이트
if [ -f "$FIREBASE_CONFIG" ] && [ "$FIREBASE_CONFIG" != "firebase.json" ]; then
  echo "Updating $FIREBASE_CONFIG with current configuration..."
  cp "firebase.json" "$FIREBASE_CONFIG"
  echo "Successfully updated $FIREBASE_CONFIG"
fi

# 원본 index.html 복원
if [ -f "web/index.html.original" ]; then
  echo "Restoring original index.html..."
  cp "web/index.html.original" "web/index.html"
  echo "Original index.html restored"
fi

echo "$ENV web deployment complete." 