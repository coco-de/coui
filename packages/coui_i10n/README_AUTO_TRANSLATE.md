# 🌍 자동 번역 시스템

번역 파일이 변경될 때 자동으로 GPT 번역 및 Dart 클래스를 생성하는 시스템입니다.

## 📦 설치

프로젝트 루트에서 다음 명령을 실행하세요:

```bash
./scripts/install_hooks.sh
```

또는 수동 설치:

```bash
cp scripts/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x scripts/auto_translate.sh
```

## 🚀 사용 방법

### 자동 모드 (권장)

Git Hook이 설치되면 자동으로 작동합니다:

1. 번역 파일 수정 (`packages/coui_i10n/lib/src/json/ko.i18n.json` 또는 `en.i18n.json`)
2. `git add`로 파일 스테이징
3. `git commit` 실행
4. **자동으로 실행됩니다:**
   - GPT로 다른 언어 번역 생성
   - 임시 파일 정리
   - Dart 번역 클래스 생성
   - 생성된 파일 자동 스테이징

### 수동 모드

Hook 없이 수동으로 실행하려면:

```bash
# 전체 번역 프로세스
./scripts/auto_translate.sh

# 또는 개별 단계 실행
melos run translate:slang:full      # GPT 번역 (GDP 10개국)
melos run translate:slang:full:en   # 영어 번역
melos run generate:locale           # Dart 클래스 생성
```

## 🔄 작동 방식

### 감지 대상 파일
- `packages/coui_i10n/lib/src/json/ko.i18n.json` (기본 언어)
- `packages/coui_i10n/lib/src/json/en.i18n.json` (영어)

### 실행 단계

1. **변경 감지**
   - Git staged 파일 중 번역 JSON 확인
   - 기본 언어 변경 시 모든 언어 재생성
   - 영어만 변경 시 영어만 업데이트

2. **GPT 번역**
   - `ko.i18n.json` 기반으로 다음 언어 생성:
     - 🇨🇳 중국어 (zh-Hans)
     - 🇪🇸 스페인어 (es)
     - 🇯🇵 일본어 (ja)
     - 🇩🇪 독일어 (de)
     - 🇫🇷 프랑스어 (fr)
     - 🇵🇹 포르투갈어 (pt)
     - 🇸🇦 아랍어 (ar)
     - 🇮🇹 이탈리아어 (it)
     - 🇷🇺 러시아어 (ru)

3. **파일 정리**
   - `_default_*.i18n.json` → `*.i18n.json` 이름 변경
   - `_gpt_*.txt` 로그 파일 삭제

4. **Dart 클래스 생성**
   - `slang` 실행
   - `lib/src/translations/translations.g.dart` 생성

5. **자동 스테이징**
   - 업데이트된 JSON 파일들
   - 생성된 Dart 파일들

## ⚙️ 설정

### API 키

GPT 번역을 위해 OpenAI API 키가 필요합니다. `pubspec.yaml`에 설정되어 있습니다.

### 번역 제외

특정 커밋에서 자동 번역을 건너뛰려면:

```bash
SKIP_TRANSLATE=1 git commit -m "번역 스킵"
```

또는 환경 변수 설정:

```bash
export SKIP_TRANSLATE=1
git commit -m "번역 스킵"
```

## 🔧 문제 해결

### Hook이 실행되지 않는 경우

```bash
# Hook 실행 권한 확인
ls -la .git/hooks/pre-commit

# 권한이 없다면
chmod +x .git/hooks/pre-commit
chmod +x scripts/auto_translate.sh
```

### GPT 번역 실패

```bash
# API 키 확인
grep "api-key" pubspec.yaml

# 수동으로 번역 실행
melos run translate:slang:full
```

### 임시 파일 정리

```bash
# _default_ 파일 정리
rm -f packages/coui_i10n/lib/src/json/_default_*.i18n.json

# GPT 로그 정리
rm -f packages/coui_i10n/lib/src/json/_gpt_*.txt
```

## 🚫 비활성화

자동 번역을 비활성화하려면:

```bash
# Hook 제거
rm .git/hooks/pre-commit

# 또는 이름 변경
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
```

## 📊 비용 안내

- GPT-4o 사용 (gpt-4o)
- 평균 비용: ~$0.90 per full translation (11개 언어)
- ko.i18n.json 크기에 따라 변동

### 비용 절감 팁

1. 영어만 수정할 경우:
   ```bash
   melos run translate:slang:full:en  # 영어만 업데이트
   ```

2. 수동 번역 후 검증:
   ```bash
   # 번역 후 확인
   git diff packages/coui_i10n/lib/src/json/
   ```

3. 대량 수정 시 한 번에 커밋

## 📝 모범 사례

### 번역 키 추가

```json
{
  "docs": {
    "new_section": {
      "title": "새 섹션",
      "description": "설명"
    }
  }
}
```

### 커밋 메시지

```bash
# 좋은 예
git commit -m "feat: ✨ 검색 기능 번역 추가"
git commit -m "i18n: 🌍 컴포넌트 설명 업데이트"

# 나쁜 예
git commit -m "update"
```

## 🤝 기여

번역 품질 개선이나 새로운 언어 추가는 PR을 통해 기여해주세요!

### 새 언어 추가

1. `slang.yaml`에 언어 추가
2. `pubspec.yaml`의 GPT 타겟에 추가
3. 초기 번역 생성

---

**Created:** 2025-10-24  
**Last Updated:** 2025-10-24

