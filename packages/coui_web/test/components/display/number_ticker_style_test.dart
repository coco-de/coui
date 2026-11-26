// The value glyph of a Web NumberTicker: the `titleLarge` role class, read
// both off the resolver and off the `<span>` the widget actually renders.
//
// The role carries size, weight, line-height and tracking together, so the
// default names the role and nothing rides inline. The class on the span
// comes from the chrome, never from the digits on screen, so the box a
// counting value is drawn in is the same on every frame.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

Set<String> _classes(String? classes) =>
    (classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

/// The `<span>` the ticker rendered — found by its numeric font feature.
DomComponent _tickerSpan() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere(
      (c) => c.tag == 'span' && _classes(c.classes).contains('tabular-nums'),
    );

void main() {
  group('NumberTicker value typography (Web)', () {
    testComponents('resolves the titleLarge role class, nothing inline', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final root = resolveNumberTicker(context).root;
      final classes = _classes(root.className);
      expect(classes, contains('text-title-large'));
      expect(classes, isNot(contains('text-body-large')));
      expect(classes, containsAll(['inline-block', 'tabular-nums']));
      // The role carries size, weight, line-height and tracking, so a
      // scalar overlay is exactly what must not appear.
      expect(
        root.inlineStyles?.properties ?? const <String, String>{},
        isEmpty,
      );
    });

    testComponents('the role is the one the Core default names', (
      tester,
    ) async {
      final context = _themedContext(tester);

      // Flutter materialises this same default; Web emits its class.
      final role = CoreNumberTickerStyle.defaultTextStyle.token!;
      expect(role, CoreTextStyles.titleLarge);
      expect(
        _classes(resolveNumberTicker(context).root.className),
        contains('text-${role.name}'),
      );
    });

    testComponents('a size overlay rides inline and the role class stays', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final root = resolveNumberTicker(
        context,
        numberTickerStyle: const CoreNumberTickerStyle(
          textStyle: CoreTextStyle(fontSize: 32),
        ),
      ).root;
      expect(_classes(root.className), contains('text-title-large'));
      expect(root.inlineStyles?.properties['font-size'], isNotNull);
      // Only the stated field is inline — weight and tracking stay the role's.
      expect(root.inlineStyles?.properties['font-weight'], isNull);
      expect(root.inlineStyles?.properties['letter-spacing'], isNull);
    });

    testComponents('a per-instance role replaces the default role class', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final classes = _classes(
        resolveNumberTicker(
          context,
          numberTickerStyle: const CoreNumberTickerStyle(
            textStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
          ),
        ).root.className,
      );
      expect(classes, contains('text-headline-small'));
      expect(classes, isNot(contains('text-title-large')));
    });
  });

  group('NumberTicker rendered span (Web)', () {
    testComponents('the span wears the titleLarge role class', (
      tester,
    ) async {
      pumpWithTheme(tester, const NumberTicker(value: 2048));

      final classes = _classes(_tickerSpan().classes);
      expect(classes, contains('text-title-large'));
      expect(classes, isNot(contains('text-body-large')));
    });

    testComponents('the line box does not depend on the digits shown', (
      tester,
    ) async {
      // The role class (and with it the line-height) comes from the chrome,
      // so a one-digit and a four-digit value are drawn in the same box.
      pumpWithTheme(tester, const NumberTicker(value: 7));
      final one = _classes(_tickerSpan().classes);
      final oneInline = _tickerSpan().styles?.properties;

      pumpWithTheme(tester, const NumberTicker(value: 2048));
      final four = _classes(_tickerSpan().classes);
      final fourInline = _tickerSpan().styles?.properties;

      expect(four, one);
      expect(fourInline, oneInline);
      expect(four, contains('text-title-large'));
    });
  });
}
