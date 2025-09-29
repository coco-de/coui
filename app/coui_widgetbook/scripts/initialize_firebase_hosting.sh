#!/bin/bash
set -e  # 오류 발생시 스크립트 중단

ENV=$1
DEFAULT_ENV="dev"

# 환경 인자가 없으면 개발 환경으로 기본 설정
if [ -z "$ENV" ]; then
  echo "No environment specified, defaulting to development environment"
  ENV=$DEFAULT_ENV
fi

# 프로젝트 및 웹앱 관련 정보 설정
if [ "$ENV" = "prod" ] || [ "$ENV" = "production" ]; then
  PROJECT_ID="im-cocode-coui"
  PROJECT_ALIAS="prod"
  CONFIG_FILE="firebase-prod.json"
elif [ "$ENV" = "stg" ] || [ "$ENV" = "staging" ]; then
  PROJECT_ID="im-cocode-coui-stg"
  PROJECT_ALIAS="stg"
  CONFIG_FILE="firebase-stg.json"
elif [ "$ENV" = "dev" ] || [ "$ENV" = "development" ]; then
  PROJECT_ID="im-cocode-coui-dev"
  PROJECT_ALIAS="dev"
  CONFIG_FILE="firebase-dev.json"
else
  echo "Invalid environment: $ENV. Using development as default."
  PROJECT_ID="im-cocode-coui-dev"
  PROJECT_ALIAS="dev"
  CONFIG_FILE="firebase-dev.json"
fi

echo "Initializing Firebase Hosting for project: $PROJECT_ID (alias: $PROJECT_ALIAS)"

# Firebase CLI 설치 확인
if ! command -v firebase &> /dev/null; then
  echo "Firebase CLI not found, installing..."
  npm install -g firebase-tools
  echo "Firebase CLI installed successfully"
fi

# Firebase 로그인 상태 확인
firebase projects:list &> /dev/null || {
  echo "You need to login to Firebase first"
  firebase login
}

# 실제 프로젝트 정보 검증
echo "Verifying Firebase project existence..."
if ! firebase projects:list | grep -q "$PROJECT_ID"; then
  echo "Warning: Project ID '$PROJECT_ID' not found in your Firebase projects."
  echo "Available Firebase projects:"
  firebase projects:list
  echo ""
  echo "Please confirm this is the correct project ID (y/n)?"
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Operation cancelled. Please update the script with the correct project ID."
    exit 1
  fi
fi

# 기존 firebase.json 백업
if [ -f "firebase.json" ]; then
  echo "Backing up existing firebase.json to firebase.json.bak"
  cp firebase.json firebase.json.bak
fi

# 기존 .firebaserc 백업
if [ -f ".firebaserc" ]; then
  echo "Backing up existing .firebaserc to .firebaserc.bak"
  cp .firebaserc .firebaserc.bak
fi

# Firebase 프로젝트 선택
echo "Selecting Firebase project: $PROJECT_ID"
firebase use --add "$PROJECT_ID" "$PROJECT_ALIAS" || {
  echo "Failed to add project alias. Checking if it already exists..."
  firebase use "$PROJECT_ALIAS" || {
    echo "Error: Failed to use project $PROJECT_ALIAS. Please check if the project exists and you have access to it."
    exit 1
  }
}

# Firebase 호스팅 초기화
echo "Initializing Firebase Hosting..."
cat > firebase.init.json << EOL
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
EOL

# firebase.json 파일 생성
echo "Creating firebase.json..."
cat firebase.init.json > firebase.json
rm firebase.init.json

# 환경별 설정 파일 저장
if [ "$CONFIG_FILE" != "firebase.json" ]; then
  echo "Saving a copy as $CONFIG_FILE..."
  cp firebase.json "$CONFIG_FILE"
fi

echo "Firebase Hosting initialization completed successfully."
echo "You can now deploy using: make deploy_web_$PROJECT_ALIAS" 