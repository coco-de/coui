import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// `Clickable`'s focus ring is an outline with a transparent gap by
// default. The default path must never name the transparent band in a
// class (it has no token — `.tailwindColor` would throw), and a stated
// band must leave the class path for the scoped rule, which is the only
// place a band can paint.

late ResolvedClickable _seenDefault;
late ResolvedClickableRules _seenRules;

class _Capture extends StatelessComponent {
  const _Capture({required this.style});

  final CoreClickableStyle? style;

  @override
  Component build(BuildContext context) {
    _seenDefault = resolveClickable(
      context,
      enabled: true,
      focusOutline: true,
      enableFeedback: true,
      clickableStyle: style,
    );
    _seenRules = resolveClickableRules(
      context,
      scopeId: 'co-clickable-ring',
      enabled: true,
      focusOutline: true,
      enableFeedback: true,
      clickableStyle: style,
    );
    return const Component.text('x');
  }
}

void main() {
  testComponents(
    'the default ring rides outline classes, with no band class and no '
    'scoped rule',
    (tester) async {
      pumpWithTheme(tester, const _Capture(style: null));
      await tester.pump();

      final classes = _seenDefault.root.className.split(' ');
      expect(classes, contains('outline-none'));
      expect(classes, contains('focus-visible:outline-2'));
      expect(classes, contains('focus-visible:outline-offset-2'));
      expect(classes, contains('focus-visible:outline-focus-ring'));
      expect(classes.where((c) => c.contains('ring-offset')), isEmpty);
      expect(_seenRules.css, isEmpty);
    },
  );

  testComponents(
    'a stated band leaves the class path and paints through the scoped '
    'rule as one box-shadow layer',
    (tester) async {
      pumpWithTheme(
        tester,
        const _Capture(
          style: CoreClickableStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              offsetColor: CoreFocusRing.opaqueOffsetColor,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        _seenDefault.root.className,
        isNot(contains('focus-visible:outline-')),
      );
      final css = _seenRules.css;
      expect(
        css,
        contains('#co-clickable-ring:focus-visible{outline-color:'),
      );
      expect(
        css,
        contains(
          'box-shadow:0 0 0 calc(4.0px - var(--coui-stroke-width-2)) rgb(var(--coui-surface))',
        ),
      );
    },
  );
}
