<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

### 번역 키를 추가한 뒤

JSON 에 키를 추가해도 Dart 번역 클래스를 다시 만들지 않으면 그 키를 찾을 수
없다는 에러가 난다. 재생성:

```bash
melos run generate:locale
```

`lib/src/translations/translations.g.dart` 와 언어별 `translations_*.g.dart`
가 갱신된다. 로컬의 `melos run translate:validate` 도 번역 키가 모자라면 이 명령을 안내한다.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
