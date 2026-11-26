import 'dart:io';

import 'package:docs_core/previews/props/flutter_doc_demos.dart';
import 'package:docs_core/previews/props/flutter_prop_previews.dart';
import 'package:docs_core/previews/props/web_doc_demos.dart';
import 'package:docs_core/previews/props/web_prop_previews.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_page_registry.dart';

/// 컴포넌트 페이지 블록의 Web · Flutter 빌더가 같은 이름을 갖는지 본다.
///
/// 사이트는 Web 빌더로, 네이티브 문서 앱은 Flutter 빌더로 같은 마크다운을
/// 그린다. 한쪽에만 있는 컴포넌트 · 장면 · 아이콘 이름은 한 렌더러에서만
/// "미리보기 없음" 으로 조용히 빠진다.
void main() {
  test('속성 빌더 — 두 플랫폼이 같은 컴포넌트를 안다', () {
    expect(kFlutterPropPreviews.keys.toSet(), kWebPropPreviews.keys.toSet());
  });

  test('장면 — 두 플랫폼이 같은 이름을 안다', () {
    expect(kFlutterDocDemos.keys.toSet(), kWebDocDemos.keys.toSet());
  });

  test('플레이그라운드가 있는 컴포넌트는 두 플랫폼 속성 빌더가 있다', () {
    for (final component in kDocsPlaygrounds.keys) {
      expect(kWebPropPreviews, contains(component));
      expect(kFlutterPropPreviews, contains(component));
    }
  });

  test('아이콘 이름 — 두 빌더가 같은 이름을 읽는다', () {
    Set<String> icons(String file) {
      final source = File('lib/pages/$file').readAsStringSync();
      final body = RegExp(
        r'Icon\(String\? name\) => switch \(name\) \{(.*?)\};',
        dotAll: true,
      ).firstMatch(source)!.group(1)!;
      return {for (final m in RegExp(r"'([a-z0-9-]+)' =>").allMatches(body)) m.group(1)!};
    }

    expect(icons('page_kit_flutter.dart'), icons('page_kit_web.dart'));
  });

  test('플래그 컨트롤은 받은 속성을 바꾸지 않는다', () {
    const flag = DocsPlaygroundFlag(label: 'leading', on: {'leading': 'plus'});
    final props = {'leading': 'plus', 'size': 'md'};
    expect(flag.apply(props, value: false), {'size': 'md'});
    expect(props, {'leading': 'plus', 'size': 'md'});
    expect(flag.isOn(flag.apply(props, value: true)), isTrue);
  });

  test('버튼 코드 — 속성이 코드에 그대로 나온다', () {
    final spec = kDocsPlaygrounds['button']!;
    final code = spec.code({...spec.initial, 'trailing': 'arrow-right', 'enabled': 'false'}, spec.label);
    expect(code, contains('size: CoreComponentSize.lg,'));
    expect(code, contains('leading: Icon(LucideIcons.plus),'));
    expect(code, contains('trailing: Icon(LucideIcons.arrowRight),'));
    expect(code, contains('enabled: false,'));
    expect(code, contains("child: Text('저장하기'),"));
  });

  test('페이지 레지스트리가 lib/pages 의 폴더와 같다', () {
    final outputs = renderPageRegistry(Directory('lib/pages'));
    for (final MapEntry(key: path, value: content) in outputs.entries) {
      expect(File(path).readAsStringSync(), content, reason: '$path 가 낡았습니다 — dart run tool/gen_page_registry.dart');
    }
  });

  test('장면 이름은 페이지 슬러그로 시작한다', () {
    final slugs = {for (final folder in findPageFolders(Directory('lib/pages'))) folder.slug};
    for (final name in [...kWebDocDemos.keys, ...kFlutterDocDemos.keys]) {
      expect(slugs, contains(name.split('/').first), reason: name);
    }
  });
}
