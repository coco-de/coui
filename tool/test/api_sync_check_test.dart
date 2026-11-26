import 'dart:io';

import 'package:test/test.dart';

import '../api_sync_check.dart';

Implementation _impl(String contract, String className, {String path = 'p'}) =>
    Implementation(contract: contract, className: className, path: path);

void main() {
  group('isDeprecatedBefore', () {
    test('reads a single-line annotation directly above the declaration', () {
      const source = '''
/// Doc.
@Deprecated('Use Stacks.')
abstract interface class CoreGroupContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 2), isTrue);
    });

    test('reads a multi-line annotation across its argument lines', () {
      const source = '''
/// Doc.
@Deprecated(
  'Use Stacks with Position for each positioned child instead '
  '(since 0.129).',
)
abstract interface class CoreGroupContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 5), isTrue);
    });

    test('steps over doc comments and other annotations', () {
      const source = '''
@Deprecated('Gone.')
@immutable
/// Doc between annotations.
abstract interface class CoreGroupContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 3), isTrue);
    });

    test('undecorated declaration is not deprecated', () {
      const source = '''
/// Doc.
abstract interface class CoreCardContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 1), isFalse);
    });

    // The failure this guards: a deprecated *member* further up the file must
    // not read as deprecating a later contract. Without the statement-boundary
    // stop, the backward walk would run past it and retire a live obligation.
    test('a deprecated member above does not deprecate a later contract', () {
      const source = '''
/// Old surface.
abstract interface class CoreLegacyContract<W> {
  @Deprecated('Use child.')
  W? get body;
}

/// Live surface.
abstract interface class CoreCardContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 7), isFalse);
    });

    test('a preceding deprecated class does not leak downward', () {
      const source = '''
@Deprecated('Gone.')
abstract interface class CoreGroupContract<W> {}

abstract interface class CoreCardContract<W> {}
''';
      final lines = source.split('\n');
      expect(isDeprecatedBefore(lines, 3), isFalse);
    });
  });

  group('scanDeprecatedContracts', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('contracts'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('collects only the deprecated contract declarations', () {
      File('${dir.path}/group_contract.dart').writeAsStringSync('''
/// Doc.
@Deprecated(
  'Use Stacks with Position instead (since 0.129).',
)
abstract interface class CoreGroupContract<W> {
  /// Children.
  List<W> get children;
}
''');
      File('${dir.path}/card_contract.dart').writeAsStringSync('''
/// Doc.
abstract interface class CoreCardContract<W> {
  /// Child.
  W? get child;
}
''');

      expect(scanDeprecatedContracts(dir), {'CoreGroupContract'});
    });

    test('a missing directory yields no exclusions', () {
      final absent = Directory('${dir.path}/nope');
      expect(scanDeprecatedContracts(absent), isEmpty);
    });
  });

  group('analyzeSync', () {
    test('a live single-platform contract stays a parity gap', () {
      final report = analyzeSync(
        {
          'CoreCardContract': _impl('CoreCardContract', 'Card'),
          'CoreGroupContract': _impl('CoreGroupContract', 'Group'),
        },
        {'CoreCardContract': _impl('CoreCardContract', 'Card')},
      );

      expect(report.flutterOnly, ['CoreGroupContract']);
      expect(report.retired, isEmpty);
      expect(report.matchRate, lessThan(kCiThreshold));
    });

    test('a deprecated single-platform contract retires the obligation', () {
      final report = analyzeSync(
        {
          'CoreCardContract': _impl('CoreCardContract', 'Card'),
          'CoreGroupContract': _impl('CoreGroupContract', 'Group'),
        },
        {'CoreCardContract': _impl('CoreCardContract', 'Card')},
        deprecatedContracts: {'CoreGroupContract'},
      );

      expect(report.flutterOnly, isEmpty);
      expect(report.retired, ['CoreGroupContract']);
      expect(report.matchRate, kCiThreshold);
    });

    test('retirement applies to a Web-only leftover too', () {
      final report = analyzeSync(
        {'CoreCardContract': _impl('CoreCardContract', 'Card')},
        {
          'CoreCardContract': _impl('CoreCardContract', 'Card'),
          'CoreGroupContract': _impl('CoreGroupContract', 'Group'),
        },
        deprecatedContracts: {'CoreGroupContract'},
      );

      expect(report.webOnly, isEmpty);
      expect(report.retired, ['CoreGroupContract']);
      expect(report.matchRate, kCiThreshold);
    });

    // Retiring the obligation must not retire the *naming* rule: while both
    // platforms still ship the contract, their class names have to agree.
    test('a deprecated contract present on both sides still checks names', () {
      final report = analyzeSync(
        {'CoreGroupContract': _impl('CoreGroupContract', 'Group')},
        {'CoreGroupContract': _impl('CoreGroupContract', 'GroupBox')},
        deprecatedContracts: {'CoreGroupContract'},
      );

      expect(report.shared, ['CoreGroupContract']);
      expect(report.retired, isEmpty);
      expect(report.classNameMismatches, hasLength(1));
    });

    test('the retired contract is reported, not silently dropped', () {
      final report = analyzeSync(
        {
          'CoreCardContract': _impl('CoreCardContract', 'Card'),
          'CoreGroupContract': _impl(
            'CoreGroupContract',
            'Group',
            path: 'packages/coui_flutter/lib/src/x/group.dart',
          ),
        },
        {'CoreCardContract': _impl('CoreCardContract', 'Card')},
        deprecatedContracts: {'CoreGroupContract'},
      );

      final json = report.toJson();
      final summary = json['summary'] as Map<String, dynamic>;
      expect(summary['retired_deprecated'], 1);
      expect(
        (json['retired_deprecated'] as List).single,
        containsPair('class', 'Group'),
      );
    });
  });
}
