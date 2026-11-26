// A retiring size is announced, not enforced. During the notice the step is
// still correct — the app renders it — so the announcement may not cost the
// caller anything but a line in the log: no error screen wherever asserts
// are on, nothing at all where they are stripped, and not the same line on
// every build.
//
// The stripped half (an `assert` body compiled out) cannot be observed from
// a test that runs with asserts on; what can be pinned here is that the
// asserts-on half only ever writes, never throws.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const retiring = [
    CoreRetiringSize(
      size: CoreComponentSize.xs,
      fallback: CoreComponentSize.sm,
      removedIn: '0.999',
    ),
  ];

  late List<String> said;

  setUp(() {
    said = [];
    debugRetiringSizeNoticeSink = (message) => said = [...said, message];
    debugResetRetiringSizeNotices();
  });

  tearDown(() {
    debugRetiringSizeNoticeSink = null;
    debugResetRetiringSizeNotices();
  });

  test('a retiring size is announced with its replacement and release', () {
    noticeRetiringSize(
      component: 'TextField',
      size: CoreComponentSize.xs,
      retiring: retiring,
    );

    expect(said, hasLength(1));
    expect(said.single, contains('TextField'));
    expect(said.single, contains('`xs`'));
    expect(said.single, contains('`sm`'));
    expect(said.single, contains('coui_core 0.999'));
  });

  test('it never throws — the caller renders as before', () {
    expect(
      () => noticeRetiringSize(
        component: 'TextField',
        size: CoreComponentSize.xs,
        retiring: retiring,
      ),
      returnsNormally,
    );
  });

  test('the same component and size are announced once', () {
    for (var i = 0; i < 3; i++) {
      noticeRetiringSize(
        component: 'TextField',
        size: CoreComponentSize.xs,
        retiring: retiring,
      );
    }

    expect(said, hasLength(1));
  });

  test('another component asking for the same size is its own notice', () {
    for (final component in ['TextField', 'TextArea', 'TextField']) {
      noticeRetiringSize(
        component: component,
        size: CoreComponentSize.xs,
        retiring: retiring,
      );
    }

    expect(said, hasLength(2));
    expect(said.first, contains('TextField'));
    expect(said.last, contains('TextArea'));
  });

  test('a size that is not retiring says nothing', () {
    for (final size in CoreComponentSize.values) {
      if (size == CoreComponentSize.xs) continue;
      noticeRetiringSize(
        component: 'TextField',
        size: size,
        retiring: retiring,
      );
    }

    expect(said, isEmpty);
  });

  test('a component with nothing retiring says nothing', () {
    noticeRetiringSize(
      component: 'Button',
      size: CoreComponentSize.xs,
      retiring: const [],
    );

    expect(said, isEmpty);
  });
}
