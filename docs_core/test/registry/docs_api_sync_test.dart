@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:test/test.dart';

/// 컴포넌트 문서가 실제 컴포넌트 API 와 갈라지지 않도록 게이트한다.
///
/// 왜 테스트인가: 문서는 규율로만 지켜지고 있었고, 그래서 조용히 썩었다.
/// Style 슬롯 마이그레이션이 코드에서 끝난 뒤에도 `divider.md` 는 사라진
/// `color` / `thickness` / `indent` / `endIndent` / `padding` 를 위젯
/// 파라미터라고 광고했고, 실제 단일 진입점인 `dividerStyle` 은 Props 표에
/// 없었다. 13개 문서는 phantom generic 이 제거된 뒤에도
/// `CoreXxxStyle<Color, List<BoxShadow>>` 를 가르쳤다 — 복붙하면 컴파일이
/// 안 되는 코드다.
///
/// 문서가 틀리면 소비자는 컴파일 에러를 만나고, 그 에러의 원인이 문서라는
/// 걸 알 방법이 없다. 그게 이 게이트가 존재하는 이유다.
///
/// 이 게이트가 **보지 못하는 것**: 설명 문장이 참인지, 예제가 의도한 화면을
/// 만드는지. 그건 사람 리뷰와 프리뷰의 몫이다. 여기서 막는 것은 "문서가
/// 존재하지 않는 API 를 가르치는" 상태뿐이고, 실제로 반복된 건 그쪽이다.
void main() {
  final flutterComponents = Directory('../packages/coui_flutter/lib/src/components');
  final webComponents = Directory('../packages/coui_web/lib/src/components');
  final slugs = [
    ...kDocsComponentEntries.map((e) => e.slug),
    ...kDocsBlocks.map((e) => e.slug),
  ]..sort();

  /// 블록으로 옮긴 페이지는 `content/blocks`, 나머지는 `content/components`.
  File docsMarkdown(String slug) {
    for (final root in const ['content/blocks', 'content/components']) {
      final file = File('$root/$slug.md');
      if (file.existsSync()) return file;
    }
    return File('content/components/$slug.md');
  }

  /// 슬러그에 해당하는 위젯 파일. 없으면 null.
  File? widgetFile(Directory base, String slug) {
    final component = slug.replaceAll('-', '_');
    if (!base.existsSync()) return null;
    for (final category in base.listSync().whereType<Directory>()) {
      final candidate = File('${category.path}/$component/$component.dart');
      if (candidate.existsSync()) return candidate;
    }
    return null;
  }

  /// 주 생성자의 named 파라미터 이름들.
  ///
  /// `this.x` / `super.x` / `required Type x` / `Type x = default` 를 모두
  /// 읽는다. 코드 생성 없이 정규식으로 읽으므로 완벽하지 않고, 그래서 파싱에
  /// 실패한 컴포넌트는 아래 커버리지 테스트가 별도로 센다 — 조용히 검사에서
  /// 빠지는 것이 이 게이트의 유일한 실패 방식이기 때문이다.
  Set<String>? ctorParams(File file, String className) {
    final source = file
        .readAsStringSync()
        .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
        .replaceAll(RegExp('//.*'), '');

    final open = RegExp('(?:const\\s+)?\\b$className\\s*\\(').firstMatch(source);
    if (open == null) return null;

    var depth = 0;
    var end = -1;
    for (var i = open.end - 1; i < source.length; i++) {
      final char = source[i];
      if (char == '(' || char == '[' || char == '{') depth++;
      if (char == ')' || char == ']' || char == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    if (end < 0) return null;

    final body = source.substring(open.end, end);
    final braced = RegExp(r'\{(.*)\}', dotAll: true).firstMatch(body);
    if (braced == null) return const <String>{};

    final names = <String>{};
    var depthInner = 0;
    final chunk = StringBuffer();
    void flush() {
      final text = chunk
          .toString()
          .replaceAll(RegExp(r'@\w+(\([^)]*\))?'), '')
          .split('=')
          .first
          .replaceAll(RegExp(r'^\s*required\s+'), '')
          .trim();
      chunk.clear();
      if (text.isEmpty) return;
      final direct = RegExp(r'^(?:this|super)\.(\w+)$').firstMatch(text);
      if (direct != null) {
        names.add(direct.group(1)!);
        return;
      }
      final typed = RegExp(r'(\w+)$').firstMatch(text);
      if (typed != null) names.add(typed.group(1)!);
    }

    for (final char in braced.group(1)!.split('')) {
      if ('(<[{'.contains(char)) depthInner++;
      if (')>]}'.contains(char)) depthInner--;
      if (char == ',' && depthInner == 0) {
        flush();
      } else {
        chunk.write(char);
      }
    }
    flush();
    return names;
  }

  /// `Props` / `Parameters` 표의 첫 칸에 백틱으로 적힌 이름들.
  ///
  /// Blocks 페이지는 같은 표를 `## 속성` 아래 둔다(`docs_template.dart` 의
  /// 블록 템플릿). `CoreXxxStyle 필드` 표는 위젯 파라미터가 아니므로 세지
  /// 않는다 — 그 구분이 이 검사의 핵심이다. v2 페이지는 `## API` 아래의
  /// 표 전부를 센다(`docsDocumentedNames` 가 함수 표를 따로 나눈다).
  Set<String> documentedProps(String markdown) => docsDocumentedNames(markdown).widget;

  // Web 전용 배관 — HTML 정체성/이벤트 표면이라 문서 Props 표의 대상이 아니다.
  const plumbing = {
    'id',
    'classes',
    'css',
    'styles',
    'attributes',
    'events',
    'eventHandlers',
    'tag',
    'role',
    'key',
    'onChange',
    'onClick',
    'onInput',
    'onKeyDown',
    'onKeyUp',
    'onMouseEnter',
    'onMouseLeave',
    'onFocus',
    'onBlur',
    'onSubmit',
  };

  group('v2 API 표 읽기', () {
    test('## API 아래의 표를 세고, 함수 절의 표는 그 함수로 나눈다', () {
      const markdown = '''
## 테마와 스타일

| `notAParam` | 표 밖 |

## API

### 위젯

| 이름 | 타입 |
| --- | --- |
| `title` | `W?` |

### 여는 함수 — `showThing` (Flutter)

| `builder` | `WidgetBuilder` |

```dart
| `insideFence` | 코드 |
```

### `CoreThingStyle` 필드

| `padding` | `CoreEdgeInsets?` |

## 관련 컴포넌트

| `elsewhere` | 표 밖 |
''';
      final names = docsDocumentedNames(markdown);
      expect(names.widget, {'title', 'padding'});
      expect(names.functions, {
        'showThing': {'builder'},
      });
    });

    test('함수 선언의 위치 · 이름 있는 파라미터를 모두 읽고, 호출은 선언으로 보지 않는다', () {
      const source = '''
void use() => showThing(context, builder: (_) => null);

Future<T?> showThing<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Map<String, int> options = const {},
}) async => null;
''';
      expect(docsFunctionParams(source, 'showThing'), {'context', 'builder', 'barrierDismissible', 'options'});
      expect(docsFunctionParams(source, 'missing'), isNull);
    });
  });

  test('문서가 존재하지 않는 위젯 파라미터를 광고하지 않는다', () {
    final offenders = <String>[];
    for (final slug in slugs) {
      final markdown = docsMarkdown(slug);
      if (!markdown.existsSync()) continue;
      final names = docsDocumentedNames(markdown.readAsStringSync());
      final documented = names.widget;

      // 함수 표(`### 여는 함수 — `showDialog``) 는 위젯이 아니라 그 함수의
      // 파라미터와 대조한다 — 위젯 생성자와 섞으면 실재하는 함수 파라미터가
      // 없는 이름으로 잡힌다.
      for (final MapEntry(key: function, value: listed) in names.functions.entries) {
        final real = <String>{};
        for (final base in [flutterComponents, webComponents]) {
          final directory = widgetFile(base, slug)?.parent;
          if (directory == null) continue;
          for (final file in directory.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
            real.addAll(docsFunctionParams(file.readAsStringSync(), function) ?? const <String>{});
          }
        }
        if (real.isEmpty) {
          offenders.add('$slug: 함수 `$function` 의 선언을 찾지 못했다');
          continue;
        }
        final ghosts = listed.difference(real)..removeWhere((n) => n.contains('.') || n.contains(' '));
        if (ghosts.isNotEmpty) offenders.add('$slug `$function`: ${(ghosts.toList()..sort()).join(", ")}');
      }
      if (documented.isEmpty) continue;

      final className = slug.split('-').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
      final real = <String>{};
      for (final base in [flutterComponents, webComponents]) {
        final file = widgetFile(base, slug);
        if (file == null) continue;
        real.addAll(ctorParams(file, className) ?? const <String>{});
      }
      if (real.isEmpty) continue;

      // 한 문서는 위젯 하나만 설명하지 않는다 — Style 필드 표와 하위
      // 컴포넌트/데이터 타입 표(`Radio` 아이템, `CoreDockItemData`, `ListCol`
      // 류)가 같은 Props 섹션 아래 산다. 그래서 실재 이름 집합은 그 컴포넌트
      // contract 디렉터리 전체에서 모은다. 검사 대상은 "아무 데도 없는
      // 이름"이고, 하위 타입 필드를 ghost 로 부르면 게이트가 노이즈가 된다.
      final contractDir = Directory(
        '../packages/coui_core/lib/src/component/contracts/'
        '${slug.replaceAll('-', '_')}',
      );
      // 위젯 파일 안의 하위 위젯(Web 의 `Radio` 처럼 그 플랫폼에만 있는 것)의
      // 필드도 같은 이유로 실재 이름이다.
      final widgetDirs = [
        for (final base in [flutterComponents, webComponents])
          if (widgetFile(base, slug)?.parent case final directory?) directory,
      ];
      {
        for (final file in [
          if (contractDir.existsSync()) ...contractDir.listSync().whereType<File>(),
          for (final directory in widgetDirs)
            ...directory.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
        ]) {
          final source = file.readAsStringSync();
          for (final match in RegExp(
            r'^\s*final\s+[\w<>,?\s]+?\s+(\w+);',
            multiLine: true,
          ).allMatches(source)) {
            real.add(match.group(1)!);
          }
          for (final match in RegExp(
            r'\bget\s+(\w+)\s*;',
          ).allMatches(source)) {
            real.add(match.group(1)!);
          }
        }
      }

      final ghosts = documented.difference(real)..removeWhere((n) => n.contains('.') || n.contains(' '));
      if (ghosts.isNotEmpty) {
        offenders.add('$slug: ${(ghosts.toList()..sort()).join(", ")}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '문서가 실재하지 않는 파라미터를 Props 표에 적었다 — 복붙하면 '
          '컴파일 에러가 난다:\n  ${offenders.join("\n  ")}',
    );
  });

  test('chrome 단일 진입점(xxxStyle)이 문서에 있다', () {
    // Style 슬롯은 그 컴포넌트의 모든 시각 override 가 지나는 단 하나의 문이다.
    // 문서에서 빠지면 소비자는 커스터마이즈할 방법 자체를 알 수 없다.
    final missing = <String>[];
    for (final slug in slugs) {
      final markdown = docsMarkdown(slug);
      final file = widgetFile(flutterComponents, slug);
      if (!markdown.existsSync() || file == null) continue;

      final className = slug.split('-').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
      final params = ctorParams(file, className);
      if (params == null) continue;

      final slot = params.firstWhere(
        (p) => p.endsWith('Style') && !plumbing.contains(p),
        orElse: () => '',
      );
      if (slot.isEmpty) continue;
      if (!markdown.readAsStringSync().contains(slot)) missing.add('$slug ($slot)');
    }

    expect(
      missing,
      isEmpty,
      reason: 'Style 슬롯이 문서에 언급되지 않았다: ${missing.join(" · ")}',
    );
  });

  test('문서가 팬텀 generic 을 가르치지 않는다', () {
    // `CoreXxxStyle` / `CoreXxxTheme` 구상 클래스는 타입 파라미터를 갖지
    // 않는다(coui_core 에 generic Style/Theme 은 0개). 문서에 남은 `<...>` 는
    // 제거된 시절의 잔재이고, 그대로 쓰면 컴파일되지 않는다.
    final offenders = <String>[];
    for (final slug in slugs) {
      final markdown = docsMarkdown(slug);
      if (!markdown.existsSync()) continue;
      final hits = RegExp(
        r'Core[A-Za-z]+(?:Style|Theme)\s*<',
      ).allMatches(markdown.readAsStringSync());
      if (hits.isNotEmpty) offenders.add('$slug (${hits.length})');
    }

    expect(offenders, isEmpty, reason: '팬텀 generic: ${offenders.join(" · ")}');
  });

  test('문서 예제가 통일 컴포넌트를 쓴다', () {
    // 예제는 소비자가 가장 먼저 복사하는 코드다. 거기에 legacy/raw API 가
    // 남아 있으면 그 패턴이 소비자 코드베이스로 복제된다.
    const banned = <String, String>{
      r'\bIcons\.\w+': 'Material Icons → LucideIcons',
      r'Component\.text\(': 'Component.text → Text 체인',
      // 간격용 SizedBox 만 잡는다 — `SizedBox(height: 320, child: …)` 는
      // 뷰포트 크기 지정이라 `Gap` 으로 바꿀 수 없다. 자식 없이 단일 축만
      // 주는 형태가 스페이서다.
      r'SizedBox\(\s*(?:height|width):\s*[\d.]+\s*,?\s*\)': '간격용 SizedBox → Gap',
      r'(?<![A-Za-z])Stack\(': 'Stack → Stacks',
      r'(?<![A-Za-z])Positioned[.(]': 'Positioned → Position',
      r'(?<![A-Za-z])Separator\(': 'Separator → Divider',
      'CoreSeparatorStyle': 'CoreSeparatorStyle → CoreDividerStyle',
      r'\bIconButton\s*[.(]': 'IconButton → Button(variant: .plain)',
    };

    final offenders = <String>[];
    for (final slug in slugs) {
      final markdown = docsMarkdown(slug);
      if (!markdown.existsSync()) continue;
      final source = markdown.readAsStringSync();
      final hits = banned.entries.where((e) => RegExp(e.key).hasMatch(source)).map((e) => e.value).toList();
      if (hits.isNotEmpty) offenders.add('$slug: ${hits.join(", ")}');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'legacy/raw API 가 예제에 남아 있다:\n  ${offenders.join("\n  ")}',
    );
  });

  test('문서에 tracker 메타가 남아 있지 않다', () {
    // 이슈 번호는 닫히면 의미를 잃고, 소비자에게는 처음부터 의미가 없다.
    // 그리고 tracker 참조가 붙은 문장은 대개 "무엇이 바뀌었는지"를 말하는
    // 전이 서술이라, 현재 API 를 알고 싶은 독자에게 노이즈다.
    final offenders = <String>[];
    for (final slug in slugs) {
      final markdown = docsMarkdown(slug);
      if (!markdown.existsSync()) continue;
      final hits = RegExp(
        r'(?:Epic|Story|Issue|PR|RFC)\s*#\s*\d+|Phase\s+\d+[a-z]?',
      ).allMatches(markdown.readAsStringSync()).map((m) => m.group(0)!).toSet();
      if (hits.isNotEmpty) offenders.add('$slug: ${hits.join(", ")}');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'tracker 메타: ${offenders.join(" · ")}',
    );
  });

  test('온보딩 문서가 양 플랫폼 앱 루트를 함께 보여준다', () {
    // 왜 별도 검사인가: 위 검사들은 전부 "문서에 적힌 것이 실재하는가" 를
    // 본다. 이 검사만 반대 방향 — "적혀야 할 것이 안 적혔는가" 다.
    //
    // 실제 사고: `getting-started.md` 의 "기본 설정" 절이 Flutter 는
    // `CoUIApp` 으로 앱 루트와 테마 배선을 보여주면서 Web 은 곧바로
    // 컴포넌트만 보여줬다. 적힌 API 는 전부 실재했으므로 심볼 검사도
    // banned 목록도 통과했고, 그대로 따라한 Web 독자는 테마를 읽는 첫
    // 컴포넌트에서 `No Theme found in context` 로 죽었다. 이름 대조로는
    // 구조적으로 검출할 수 없는 종류다.
    //
    // 양방향인 이유: 결손이 Web 쪽에만 나지 않았다. `theming.md` 는 Flutter
    // 루트만, `cross-platform.md` 는 Web 루트만 갖고 있었다. 단방향 규칙은
    // "Web 은 나중 문제" 라는 편향을 규칙에 새겨 넣는다.
    //
    // 이 검사가 보지 못하는 것: 앱 루트가 **올바르게** 배선됐는지, 그리고
    // Web 설정의 나머지 절반(`ThemeConfig` 의 `--coui-*` 주입)이 있는지.
    // 후자를 같은 불변식에 넣으면 그것을 다루지 않는 페이지가 오탐으로
    // 걸린다. 이 검사가 막는 것은 "아예 없음" 뿐이고, 반복된 것이 그쪽이다.
    const flutterRoot = 'CoUIApp';
    const webRoot = 'CoUIWeb';

    // 앵커 자기검증 — 심볼 이름이 바뀌면 아래 정규식이 아무것도 매칭하지
    // 않아 이 게이트가 조용히 공허참이 된다. 이 저장소에서 이미 일어난
    // 실패 유형이라(회귀를 주입해도 통과하던 가드) 먼저 존재를 확인한다.
    for (final entry in <String, String>{
      flutterRoot: '../packages/coui_flutter/lib',
      webRoot: '../packages/coui_web/lib',
    }.entries) {
      final declared = Directory(entry.value)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .any(
            (f) => RegExp(
              r'class\s+' + entry.key + r'\b',
            ).hasMatch(f.readAsStringSync()),
          );
      expect(
        declared,
        isTrue,
        reason:
            '게이트 앵커 소실 — `${entry.key}` 선언을 찾지 못했다. '
            '이름이 바뀌었으면 이 테스트도 같이 옮겨라 (안 옮기면 이 검사는 '
            '아무것도 막지 않으면서 초록으로 남는다).',
      );
    }

    final fence = RegExp(r'```dart\n(.*?)```', dotAll: true);
    final lineComment = RegExp(r'//.*');

    bool establishesRoot(String source, String symbol) {
      // dart 펜스 안의 **생성자 호출**만 센다. 산문이나 주석의 언급은 설정
      // 지시가 아니다 — `cross-platform.md` 는 주석으로 `CoUIWeb` 을
      // 설명하면서 정작 Flutter 쪽 루트는 안 보여주고 있었다.
      final code = fence.allMatches(source).map((m) => m.group(1)!.replaceAll(lineComment, '')).join('\n');
      return RegExp('\\b$symbol\\s*\\(').hasMatch(code);
    }

    final offenders = <String>[];
    for (final page
        in Directory('content')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            // 컴포넌트 레퍼런스 페이지는 대상이 아니다 — 온보딩을 139번
            // 복제하라는 요구가 된다.
            .where((f) => !f.path.contains('/components/'))
            .where((f) => !f.path.contains('_templates'))) {
      final source = page.readAsStringSync();
      final hasFlutter = establishesRoot(source, flutterRoot);
      final hasWeb = establishesRoot(source, webRoot);
      if (hasFlutter == hasWeb) continue;
      offenders.add(
        '${page.uri.pathSegments.last}: '
        '${hasFlutter ? "Flutter 앱 루트($flutterRoot)만 있고 "
                  "Web 앱 루트($webRoot)가 없다" : "Web 앱 루트($webRoot)만 있고 "
                  "Flutter 앱 루트($flutterRoot)가 없다"}',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '한 플랫폼의 앱 루트만 보여주는 문서 — 반대편 독자는 그대로 '
          '따라하면 앱이 죽는다:\n  ${offenders.join("\n  ")}',
    );
  });

  test('컴포넌트 페이지 밖의 문서도 같은 규율을 따른다', () {
    // 왜 별도 테스트인가: 위 검사들은 카탈로그(= 컴포넌트 페이지)만 돈다.
    // 가이드와 개요 페이지는 아무도 보지 않았고, 그래서 `크로스 플랫폼`
    // 가이드는 "Web 과 Flutter 는 동일한 named properties API 를 씁니다" 라고
    // 쓴 바로 다음에 서로 다른 코드를, 그것도 존재하지 않는 파라미터
    // (`Card(title:)`, `TimelineItem`)로 보여주고 있었다. 그 페이지가 틀리면
    // 읽는 사람은 통일이라는 주장 자체를 의심하게 된다.
    final root = Directory('content');
    final pages = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .where((f) => !f.path.contains('/components/'))
        // 템플릿은 실제 API 가 아니라 자리표시자를 담는다.
        .where((f) => !f.path.contains('_templates'));

    const banned = <String, String>{
      r'Core[A-Za-z]+(?:Style|Theme)\s*<': '팬텀 generic',
      r'(?:Epic|Story|Issue|PR|RFC)\s*#\s*\d+': 'tracker 메타',
      r'\bIcons\.\w+': 'Material Icons',
      r'Component\.text\(': 'raw Component.text',
      'CoreSeparatorStyle': 'deprecated CoreSeparatorStyle',
      // 온보딩 API 드리프트 감사(docs-benchmark-2026-08-01.md 3장)로 발견된
      // 구체 오탈자들 — Core 접두가 없어서 아래 "Core 심볼 존재" 검사가 못
      // 잡는다. 재발 방지를 위해 리터럴로 막는다.
      r'\bAnimationConstants\b': 'AnimationConstants(존재하지 않음) → Duration(milliseconds: CoreDuration.*)',
      r'\bComponentThemeData\b': 'ComponentThemeData(존재하지 않음) → CoreComponentTheme + ThemeData.fromCore',
      r'\bButtonVariant\b': 'bare ButtonVariant(존재하지 않음) → CoreButtonVariant',
      r'\bButtonSize\b': 'bare ButtonSize(존재하지 않음) → CoreComponentSize',
      r'pub\.dev/packages/coui_': 'pub.dev 링크(존재하지 않는 패키지 페이지, publish_to: none)',
      r'35\+\s*(?:내장\s*)?테마': '"35+ 테마" 주장(실제 CoreThemePresets 는 4개뿐)',
    };

    final offenders = <String>[];
    for (final page in pages) {
      final source = page.readAsStringSync();
      final hits = banned.entries.where((e) => RegExp(e.key).hasMatch(source)).map((e) => e.value).toList();
      if (hits.isNotEmpty) {
        offenders.add('${page.uri.pathSegments.last}: ${hits.join(", ")}');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });

  test('가이드·최상위 문서가 참조하는 Core 심볼이 실제로 존재한다', () {
    // 왜 별도 검사인가: 위 banned 목록은 "이미 한 번 일어난 실수"만 막는
    // 리터럴 블록리스트다. 이 검사는 반대 방향 — 컴포넌트 페이지 밖(시작하기·
    // 가이드·기여 가이드)의 ```dart 블록이 참조하는 모든 `Core*` 심볼이
    // coui_core/coui_flutter/coui_web 어딘가에 실제로 선언돼 있는지 본다.
    // `AnimationConstants`/`ComponentThemeData`처럼 Core 접두가 없는 과거
    // 오탈자는 여기서 못 잡으므로 위 banned 목록이 계속 책임진다 — 이 둘은
    // 서로 대체가 아니라 상호 보완이다.
    final pages = Directory('content')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .where((f) => !f.path.contains('/components/'))
        .where((f) => !f.path.contains('_templates'));

    final libDirs = [
      Directory('../packages/coui_core/lib'),
      Directory('../packages/coui_flutter/lib'),
      Directory('../packages/coui_web/lib'),
    ];
    final declared = <String>{};
    final declPattern = RegExp(
      r'\b(?:class|enum|mixin|typedef|extension)\s+(?:type\s+)?(Core\w*)',
    );
    for (final dir in libDirs) {
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final match in declPattern.allMatches(file.readAsStringSync())) {
          declared.add(match.group(1)!);
        }
      }
    }

    final symbolPattern = RegExp(r'\bCore[A-Za-z0-9]*\b');
    final fencePattern = RegExp(r'```dart\n(.*?)```', dotAll: true);
    final offenders = <String>[];
    for (final page in pages) {
      final source = page.readAsStringSync();
      final ghosts = <String>{};
      for (final block in fencePattern.allMatches(source)) {
        for (final match in symbolPattern.allMatches(block.group(1)!)) {
          final symbol = match.group(0)!;
          if (!declared.contains(symbol)) ghosts.add(symbol);
        }
      }
      if (ghosts.isNotEmpty) {
        offenders.add(
          '${page.uri.pathSegments.last}: ${(ghosts.toList()..sort()).join(", ")}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '문서가 존재하지 않는 Core 심볼을 참조한다 — 복붙하면 컴파일 '
          '에러가 난다:\n  ${offenders.join("\n  ")}',
    );
  });

  test('라이브 프리뷰 예제 코드가 통일 컴포넌트를 쓴다', () {
    // 왜 .md 와 별도인가: 위 검사는 문서 본문의 코드 블록만 본다. 실제로
    // 렌더되는 라이브 프리뷰와 "복사" 버튼이 주는 스니펫은
    // `lib/previews/examples/**` 의 `.dart` 파일이고, 그쪽은 아무도 보지
    // 않았다 — Web 예제 79개가 `Component.text(...)` 로 텍스트를 그리고
    // 있었다. 문서 본문보다 이쪽이 더 많이 복사된다.
    final examples = Directory('lib/previews/examples');
    if (!examples.existsSync()) return;

    const banned = <String, String>{
      r'Component\.text\(': 'Component.text → Text 체인',
      r'(?<![A-Za-z._$])text\(': 'raw jaspr text() → Text 체인',
      r'\bIcons\.\w+': 'Material Icons → LucideIcons',
      r'\bIconButton\s*[.(]': 'IconButton → Button(variant: .plain)',
      r'SizedBox\(\s*(?:height|width):\s*[\d.]+\s*,?\s*\)': '간격용 SizedBox → Gap',
      r'(?<![A-Za-z])Positioned[.(]': 'Positioned → Position',
      r'(?<![A-Za-z])Separator\(': 'Separator → Divider',
      'CoreSeparatorStyle': 'CoreSeparatorStyle → CoreDividerStyle',
      r'\b(?:Ghost|Primary|Secondary|Outline)Button\b': 'legacy Button → Button(variant:)',
    };

    final offenders = <String>[];
    for (final file in examples.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      var source = file.readAsStringSync();
      // 코드 예시를 담은 문자열 리터럴은 그 컴포넌트의 *콘텐츠*다 (code_diff
      // 가 diff 대상 코드를 보여주는 식) — 라이브러리 사용이 아니다.
      source = source.replaceAll(RegExp('"[^"\n]*"'), '""');
      final hits = banned.entries.where((e) => RegExp(e.key).hasMatch(source)).map((e) => e.value).toList();
      if (hits.isNotEmpty) {
        offenders.add('${file.uri.pathSegments.last}: ${hits.join(", ")}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '프리뷰 예제에 legacy/raw API 가 남아 있다:\n  '
          '${offenders.join("\n  ")}',
    );
  });

  test('접근성 다섯 축 이행이 뒷걸음질치지 않는다', () {
    // `accessibility.md` 는 "각 컴포넌트가 따로 말하는 것" 으로 다섯 축을
    // 약속하고, 템플릿은 해당 없는 축도 지우지 말고 "없음" 이라고 적으라고
    // 한다 — 지우면 독자는 "아직 안 썼나" 와 "정말 없나" 를 구분할 수 없다.
    //
    // 왜 게이트인가: 이 축들의 이행률은 **두 번 잘못 세어졌다.** 한 번은
    // 키워드로 세서(`포커스` 라는 단어가 키보드 표의 `Tab` 행에 나온다)
    // 66개 문서가 이행한 것으로 과대 계상됐고, 한 번은 정확한 라벨로 세서
    // (`### 포커스` 라는 동의 라벨을 놓쳐) 50개가 과소 계상됐다. 사람이
    // 세면 매번 다른 답이 나온다.
    //
    // 그래서 라벨을 하나로 고정하고 그 라벨을 센다. 라벨이 갈리면 이
    // 게이트가 즉시 결손으로 잡는다 — 그게 의도다.
    const axes = ['역할', '키보드', '스크린 리더', '포커스 관리', '알려진 제약'];

    /// `## 접근성` 섹션 안의 `###` 헤딩들. 다른 섹션의 동명 헤딩
    /// (`## 동작 스펙` 아래 `### 포커스 관리`)은 이 축의 이행이 아니다.
    List<String> accessibilityHeadings(String markdown) {
      final headings = <String>[];
      var inside = false;
      for (final line in markdown.split('\n')) {
        if (line.startsWith('## ')) {
          inside = line.contains('접근성');
          continue;
        }
        if (inside && line.startsWith('### ')) {
          headings.add(line.substring(4).trim());
        }
      }
      return headings;
    }

    final missing = {for (final axis in axes) axis: <String>[]};
    for (final slug in slugs) {
      final markdown = File('content/components/$slug.md');
      if (!markdown.existsSync()) continue;
      final headings = accessibilityHeadings(markdown.readAsStringSync());
      for (final axis in axes) {
        if (!headings.contains(axis)) missing[axis]!.add(slug);
      }
    }

    final regressed = <String>[];
    for (final axis in axes) {
      final baseline = kDocsAccessibilityAxisBaseline[axis]!;
      final count = missing[axis]!.length;
      if (count > baseline) {
        regressed.add('$axis: 결손 $count > 기준 $baseline');
      }
    }

    expect(
      regressed,
      isEmpty,
      reason:
          '접근성 축 결손이 늘었다. 축을 지웠거나, 라벨을 템플릿과 다르게 '
          '썼거나(`### 포커스` ✗ / `### 포커스 관리` ✓), 새 컴포넌트가 축 '
          '없이 들어왔다:\n  ${regressed.join("\n  ")}\n\n'
          '이 PR 이 건드린 문서를 봐라 — 아래는 그 축이 빠진 문서 **전체**라 '
          '대부분은 이번 회귀와 무관하다:\n'
          '${regressed.map((r) => "  ${r.split(":").first}: "
              "${missing[r.split(":").first]!.join(", ")}").join("\n")}',
    );
  });

  test('Props 검사 커버리지가 줄지 않는다', () {
    // 위 검사들은 생성자를 정규식으로 읽는다. 파싱이 실패하면 그 컴포넌트는
    // 조용히 검사에서 빠지고, 그게 이 게이트의 유일한 실패 방식이다 —
    // 커버리지를 세서 그 침묵을 깨뜨린다.
    final unparsed = <String>[];
    for (final slug in slugs) {
      final file = widgetFile(flutterComponents, slug);
      if (file == null) {
        unparsed.add('$slug (파일 없음)');
        continue;
      }
      final className = slug.split('-').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
      if (ctorParams(file, className) == null) unparsed.add('$slug (파싱 실패)');
    }

    // 베이스라인: 위젯이 슬러그와 다른 이름/구조로 사는 문서들. 늘어나면
    // 새 컴포넌트가 검사 밖으로 빠졌다는 뜻이다.
    expect(
      unparsed.length,
      lessThanOrEqualTo(kDocsPropsCheckUnparsedBaseline),
      reason:
          'Props 검사에서 빠진 컴포넌트가 늘었다 (${unparsed.length} > '
          '$kDocsPropsCheckUnparsedBaseline):\n  ${unparsed.join("\n  ")}',
    );
  });
}

/// Props 검사가 생성자를 읽지 못하는 문서 수의 상한.
///
/// 대부분은 위젯 클래스가 슬러그와 다른 이름으로 사는 문서(`drag`,
/// `formatter`, `mockup` 처럼 한 페이지가 여러 위젯을 설명하는 경우)다.
/// 줄이는 건 언제나 환영이고, 늘리려면 왜 늘어야 하는지 적어야 한다.
const int kDocsPropsCheckUnparsedBaseline = 40;

/// 접근성 다섯 축이 아직 빠져 있는 컴포넌트 문서 수의 상한.
///
/// **전부 0 이다** — 카탈로그의 모든 문서가 다섯 축을 모두 답한다. 이 지점부터 이 게이트는
/// ratchet 이 아니라 **불변식**이다: 축을 지우거나, 라벨을 템플릿과 다르게 쓰거나,
/// 새 컴포넌트를 축 없이 추가하면 즉시 실패한다.
///
/// 올리지 마라. 새 컴포넌트를 추가하면서 이 값을 올리고 싶다면, 올릴 게 아니라
/// 그 문서의 축을 채워야 한다 — 해당 없는 축은 지우지 말고 "없음" 이라고 적는 것이
/// 이행이다(`_templates/component.md`).
const Map<String, int> kDocsAccessibilityAxisBaseline = {
  '역할': 0,
  '키보드': 0,
  '스크린 리더': 0,
  '포커스 관리': 0,
  '알려진 제약': 0,
};

/// 문서의 파라미터 표가 적은 이름 — 위젯 파라미터와, 함수 표마다의 이름.
///
/// 읽는 표: 제목이 Props · Parameters · 파라미터 · 속성인 절(옛 구성과 블록
/// 템플릿), 그리고 v2 의 `## API` 아래 전부. `## API` 안에서 제목이 백틱으로
/// 함수 이름을 적은 절(`### 여는 함수 — `showDialog``)의 표는 그 함수의
/// 파라미터라 [functions] 로 따로 모은다.
({Set<String> widget, Map<String, Set<String>> functions}) docsDocumentedNames(String markdown) {
  final widget = <String>{};
  final functions = <String, Set<String>>{};
  var inTable = false;
  var inApi = false;
  String? function;
  var fenced = false;
  for (final line in markdown.split('\n')) {
    if (line.startsWith('```')) fenced = !fenced;
    if (fenced) continue;
    if (line.startsWith('#')) {
      if (line.startsWith('## ')) {
        inApi = line.trim() == '## API';
        function = null;
      } else if (line.startsWith('### ')) {
        function = inApi ? _functionNamedIn(line) : null;
      }
      inTable = inApi || RegExp(r'Props|Parameters|파라미터').hasMatch(line) || RegExp(r'^#+ 속성\s*$').hasMatch(line);
      continue;
    }
    if (!inTable) continue;
    final cell = RegExp(r'^\|\s*`([^`]+)`').firstMatch(line);
    if (cell == null) continue;
    if (function == null) {
      widget.add(cell.group(1)!);
    } else {
      (functions[function] ??= <String>{}).add(cell.group(1)!);
    }
  }
  return (widget: widget, functions: functions);
}

/// 제목이 백틱으로 적은 함수 이름(소문자로 시작하는 식별자) — 없으면 `null`.
String? _functionNamedIn(String heading) {
  for (final match in RegExp('`([^`]+)`').allMatches(heading)) {
    final name = match.group(1)!;
    if (RegExp(r'^[a-z]\w*$').hasMatch(name)) return name;
  }
  return null;
}

/// [source] 에 맨 바깥에서 선언된 함수 [name] 의 파라미터 이름(위치 · 이름
/// 있는 것 모두) — 선언이 없으면 `null`.
Set<String>? docsFunctionParams(String source, String name) {
  final code = source.replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '').replaceAll(RegExp('//.*'), '');
  final open = RegExp('^[\\w<>?, ]+\\s+$name\\s*(?:<[^>()]*>)?\\s*\\(', multiLine: true).firstMatch(code);
  if (open == null) return null;
  var depth = 0;
  var end = -1;
  for (var i = open.end - 1; i < code.length; i++) {
    final char = code[i];
    if ('([{'.contains(char)) depth++;
    if (')]}'.contains(char)) {
      depth--;
      if (depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return null;
  final body = code.substring(open.end, end);
  final names = <String>{};
  var nesting = 0;
  final chunk = StringBuffer();
  void flush() {
    final text = chunk
        .toString()
        .replaceAll(RegExp(r'@\w+(\([^)]*\))?'), '')
        .split('=')
        .first
        .replaceAll(RegExp(r'^\s*required\s+'), '')
        .trim();
    chunk.clear();
    final last = RegExp(r'(\w+)$').firstMatch(text);
    if (last != null) names.add(last.group(1)!);
  }

  for (final char in body.split('')) {
    // 맨 바깥의 `{` `[` 는 이름 있는 · 선택 파라미터를 묶을 뿐이다 — 깊이로 세지 않는다.
    if (nesting == 0 && '{[]}'.contains(char)) continue;
    if ('(<[{'.contains(char)) nesting++;
    if (')>]}'.contains(char)) nesting--;
    if (char == ',' && nesting == 0) {
      flush();
    } else {
      chunk.write(char);
    }
  }
  flush();
  return names;
}
