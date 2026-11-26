@TestOn('vm')
library;

import 'package:docs_core/shared/component_deprecation.dart';
import 'package:test/test.dart';

void main() {
  test('대체 이름이 있는 메시지를 파싱한다', () {
    const source = '''
/// 문서 주석.
@Deprecated('Use NewWidget instead (since 0.130).')
class OldWidget extends StatelessWidget {}
''';
    final status = parseClassDeprecation(source, 'OldWidget');
    expect(status, isNotNull);
    expect(status!.since, '0.130');
    expect(status.replacementName, 'NewWidget');
    expect(status.message, contains('Use NewWidget instead'));
  });

  test('여러 줄 문자열 연결 메시지를 이어붙이고, 사이의 다른 어노테이션을 건넌다', () {
    const source = '''
@Deprecated(
  'Unread (since 0.128). No renderer consumes these layers on either '
  'platform — the glass surface draws from opacity and blurRadius.',
)
@immutable
class CoreGlassMaterial {}
''';
    final status = parseClassDeprecation(source, 'CoreGlassMaterial');
    expect(status, isNotNull);
    expect(status!.since, '0.128');
    expect(status.replacementName, isNull);
    expect(status.message, contains('opacity and blurRadius'));
  });

  test('클래스가 deprecated 아니면 null', () {
    const source = '''
class ActiveWidget extends StatelessWidget {}
''';
    expect(parseClassDeprecation(source, 'ActiveWidget'), isNull);
  });

  test('다른 클래스의 @Deprecated 는 매칭되지 않는다', () {
    const source = '''
@Deprecated('Use Bar (since 0.100).')
class Foo {}

class Baz extends StatelessWidget {}
''';
    expect(parseClassDeprecation(source, 'Baz'), isNull);
  });

  test('메시지 안의 중첩 괄호를 건너 정확히 since 를 뽑는다', () {
    const source = '''
@Deprecated('Use NewWidget(arg: 1) instead (since 0.140).')
class OldWidget {}
''';
    final status = parseClassDeprecation(source, 'OldWidget');
    expect(status, isNotNull);
    expect(status!.since, '0.140');
    expect(status.replacementName, 'NewWidget');
  });

  test('since 가 없는 메시지는 null (형식 미준수)', () {
    const source = '''
@Deprecated('Just do not use this.')
class OldWidget {}
''';
    expect(parseClassDeprecation(source, 'OldWidget'), isNull);
  });

  test('필드 레벨 @Deprecated 는 클래스 상태로 잡히지 않는다', () {
    const source = '''
class Switcher extends StatelessWidget {
  const Switcher({this.curve});

  @Deprecated('Use switcherStyle: CoreSwitcherStyle(curve: CoreEasing.x) (since 0.128).')
  final Curve? curve;
}
''';
    expect(parseClassDeprecation(source, 'Switcher'), isNull);
  });
}
