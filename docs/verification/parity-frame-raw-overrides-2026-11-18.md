# Frame raw override 계약 복구 (#6428)

Web Frame이 명시한 비기본 `clipBehavior`를 style보다 우선하고, `CoreAlignment`의 소수 좌표를 정수 퍼센트로 바꾸지 않도록 수정했다. CoreFrameContract의 flat slot 우선순위와 기존 Native 구현을 따른다. 기본 `hardEdge`는 기존 Native처럼 style 위임의 sentinel로 유지한다.

`clipBehavior: .none`과 style의 `.hardEdge`가 함께 있으면 기존 Web은 자식을 잘랐지만, 수정 후에는 Native처럼 바깥으로 그린다. 정렬 좌표 `(.17, .23)`은 origin과 image position 모두 기존 `59% 62%` 대신 `58.5% 61.5%`로 전달된다. 공개 API·const 생성자·Core/Native·디자인 기본값·토큰·caller CSS의 최종 우선순위는 변경하지 않았다.

제품/테스트 커밋 `8d9757637`을 최신 main `3a85986a93e563c7b7ce033fc2c745f370de7453`과 ordinary merge한 `49ea0ff2c449c504f022152e8694139e2e18b2bb`에서 검증했다. 독립 동결한 수정 전 Web과 실제 브라우저로 비교했고, 원래 Native Frame을 대조군으로 사용했다. 등록된 Frame 기본·column·dashed·elevated의 라이트/다크 **8개 PNG와 RGBA가 전후 모두 동일**했다. 기존 잔여174칸을 줄였다는 주장은 하지 않는다.

새 회귀 테스트18개 및 독립 Root의 Web Frame 전체38개 테스트가 통과했다. 변경 파일 fatal-infos 진단0, format 변경0, 전체 계약 guard exit0(기존 WARN7)이다. 최종 소스의 문서 O2 빌드가 성공했고 추적 파일 변경은 없었다. 소유한 실제 SSR Dart VM의 hot reload도 성공했다.

지원 범위 밖 좌표의 기존 clamp와 기존 RTL physical/directional 차이는 유지했다. image와 fill을 함께 줄 때 Web이 fill을 생략하는 별개 기존 문제도 이번 범위에 포함하지 않았다. 해당 실제 캡처와 임시 Native/Web RTL 부모 배치 차이를 원본 보고서에 기록했으며, 전체 raw 값이나 모든 RTL 픽셀의 Native 일치를 주장하지 않는다.

원본 증거·재현 fixture·명령·동결 소스·정리 증빙: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6428-frame-proof-20261118.nul4o_xg/README.md`. 기계 요약은 같은 디렉터리의 `validation-summary.json`, 원본 이미지8장 선정은 `selected-evidence8.json`이다.
