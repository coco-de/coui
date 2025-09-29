#!/bin/bash
# 파일명: fix_slang_gpt.sh

# i18n 디렉토리로 이동
cd lib/src/json

# $default$_ 접두사가 붙은 파일을 원래 파일에 덮어쓰기
for file in \$default\$_*.i18n.json; do
  if [ -f "$file" ]; then
    dest_file="${file/\$default\$_/}"
    echo "Overwriting $dest_file with content from $file"
    cp "$file" "$dest_file"
  fi
done

# 처리 완료 후 $default$_ 파일 삭제
rm -f \$default\$_*.i18n.json

echo "Translation files have been successfully updated!"