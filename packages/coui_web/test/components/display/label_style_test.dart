// The Web half of the disabled `Label` colour: the text, the required
// indicator (`*`) and — through the root's inherited colour — the leading
// icon all take the ONE colour the disabled text style carries. The Web
// resolver states it on the root (text, icon) and on the indicator, so both
// are read off the resolved chrome the widget renders from.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// A raw (token-less) colour — the case a class cannot express, so the
/// emit family sends it inline.
const _kRawGreen = CoreColor(0xFF00FF00);
const _kPrimary = CoreColor.token(CoreColors.primary);

BuildContext _context(ComponentTester tester, {ThemeData? data}) {
  late BuildContext context;
  final capture = _ContextCapture((c) => context = c);
  tester.pumpComponent(
    data == null
        ? Theme.defaults(child: capture)
        : Theme(data: data, child: capture),
  );

  return context;
}

ResolvedLabel _resolve(
  BuildContext context, {
  required bool disabled,
  CoreLabelStyle? labelStyle,
}) => resolveLabel(context, disabled: disabled, labelStyle: labelStyle);

void main() {
  group('Label disabled colour (Web)', () {
    testComponents('text and star both take the disabled content colour', (
      tester,
    ) async {
      final resolved = _resolve(_context(tester), disabled: true);

      expect(resolved.root.className, contains('text-disabled-content'));
      expect(resolved.requiredIndicator.className, 'text-disabled-content');
      expect(resolved.requiredIndicator.inlineStyles, isNull);
    });

    testComponents('enabled keeps the live colours', (tester) async {
      final resolved = _resolve(_context(tester), disabled: false);

      expect(resolved.root.className, contains('text-on-surface'));
      expect(resolved.root.className, isNot(contains('disabled-content')));
      expect(resolved.requiredIndicator.className, 'text-error');
    });

    testComponents('disabledTextStyle recolours text and star together', (
      tester,
    ) async {
      final resolved = _resolve(
        _context(tester),
        disabled: true,
        labelStyle: const CoreLabelStyle(
          disabledTextStyle: CoreTextStyle(color: _kPrimary),
        ),
      );

      expect(resolved.root.className, contains('text-primary'));
      expect(resolved.root.className, isNot(contains('disabled-content')));
      expect(resolved.requiredIndicator.className, 'text-primary');
    });

    testComponents('a theme-level disabledTextStyle reaches both too', (
      tester,
    ) async {
      final data = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          label: CoreLabelTheme(
            style: CoreLabelStyle(
              disabledTextStyle: CoreTextStyle(color: _kPrimary),
            ),
          ),
        ),
      );
      final resolved = _resolve(_context(tester, data: data), disabled: true);

      expect(resolved.root.className, contains('text-primary'));
      expect(resolved.requiredIndicator.className, 'text-primary');
    });

    testComponents(
      'a raw disabled colour goes inline on the star, not a class',
      (
        tester,
      ) async {
        final resolved = _resolve(
          _context(tester),
          disabled: true,
          labelStyle: const CoreLabelStyle(
            disabledTextStyle: CoreTextStyle(color: _kRawGreen),
          ),
        );

        expect(resolved.requiredIndicator.className, isEmpty);
        expect(resolved.requiredIndicator.inlineStyles, isNotNull);
        expect(
          resolved.requiredIndicator.inlineStyles!.properties,
          contains('color'),
        );
      },
    );

    testComponents('requiredColor speaks for the enabled state only', (
      tester,
    ) async {
      const labelStyle = CoreLabelStyle(requiredColor: _kPrimary);
      final context = _context(tester);

      expect(
        _resolve(
          context,
          disabled: false,
          labelStyle: labelStyle,
        ).requiredIndicator.className,
        'text-primary',
      );
      expect(
        _resolve(
          context,
          disabled: true,
          labelStyle: labelStyle,
        ).requiredIndicator.className,
        'text-disabled-content',
        reason: 'a disabled label keeps no live-looking required mark',
      );
    });
  });
}
