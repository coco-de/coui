import 'package:test/test.dart';

import '../../src/cli/flags.dart';

void main() {
  group('parseFlags', () {
    test('parses --key=value pairs', () {
      expect(parseFlags(['--tier=t1', '--out=/tmp/x.json']), {
        'tier': 't1',
        'out': '/tmp/x.json',
      });
    });

    test('parses bare --flag as true', () {
      expect(parseFlags(['--keep-harness']), {'keep-harness': 'true'});
    });

    test('ignores positional args', () {
      expect(parseFlags(['positional', '--a=b']), {'a': 'b'});
    });
  });

  group('parseListFlag', () {
    test('returns null for an absent flag', () {
      expect(parseListFlag({}, 'components'), isNull);
    });

    test('splits and trims a comma-separated value', () {
      expect(
        parseListFlag({'components': 'dialog, command ,card'}, 'components'),
        ['dialog', 'command', 'card'],
      );
    });

    test('throws for a present-but-empty value', () {
      expect(
        () => parseListFlag({'components': ''}, 'components'),
        throwsArgumentError,
      );
    });
  });
}
