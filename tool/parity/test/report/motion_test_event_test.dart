import 'package:test/test.dart';

import '../../src/report/motion_test_event.dart';

void main() {
  group('parseMotionTestFailures', () {
    test('extracts failing test name + error, skips passing tests', () {
      const log = '''
{"type":"start","time":0}
{"type":"testStart","time":1,"test":{"id":1,"name":"Dialog enter animates opacity"}}
{"type":"testDone","time":5,"testID":1,"result":"success","hidden":false,"skipped":false}
{"type":"testStart","time":6,"test":{"id":2,"name":"Dialog exit transition declared"}}
{"type":"error","time":10,"testID":2,"error":"Element: no transition declared for \\"opacity\\" — computed contract is X.","isFailure":true}
{"type":"testDone","time":11,"testID":2,"result":"failure","hidden":false,"skipped":false}
{"type":"done","success":false}
''';

      final failures = parseMotionTestFailures(
        log,
        isMotionProbe: (name) => true,
      );

      expect(failures, hasLength(1));
      expect(failures.single.testName, 'Dialog exit transition declared');
      expect(
        failures.single.errorMessage,
        contains('no transition declared for'),
      );
    });

    test('respects isMotionProbe filter', () {
      const log = '''
{"type":"testStart","time":1,"test":{"id":1,"name":"unrelated widget test"}}
{"type":"error","time":2,"testID":1,"error":"boom"}
{"type":"testDone","time":3,"testID":1,"result":"failure"}
''';

      final failures = parseMotionTestFailures(
        log,
        isMotionProbe: (name) => name.contains('parity_probe'),
      );

      expect(failures, isEmpty);
    });

    test('tolerates non-JSON noise lines', () {
      const log = '''
00:01 +0: loading test...
{"type":"testStart","time":1,"test":{"id":1,"name":"probe"}}
{"type":"error","time":2,"testID":1,"error":"boom"}
{"type":"testDone","time":3,"testID":1,"result":"failure"}
00:02 +0 -1: Some tests failed.
''';

      final failures = parseMotionTestFailures(
        log,
        isMotionProbe: (name) => true,
      );

      expect(failures, hasLength(1));
      expect(failures.single.errorMessage, 'boom');
    });

    test(
      'missing error event still surfaces the failure with a placeholder',
      () {
        const log = '''
{"type":"testStart","time":1,"test":{"id":1,"name":"probe"}}
{"type":"testDone","time":3,"testID":1,"result":"error"}
''';

        final failures = parseMotionTestFailures(
          log,
          isMotionProbe: (name) => true,
        );

        expect(failures, hasLength(1));
        expect(
          failures.single.errorMessage,
          contains('no error message captured'),
        );
      },
    );
  });
}
