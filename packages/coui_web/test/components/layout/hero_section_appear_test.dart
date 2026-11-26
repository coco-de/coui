import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every inline-style map in the rendered tree.
Iterable<Map<String, String>> _styleMaps(ComponentTester tester) sync* {
  for (final element in find.byType(DomComponent).evaluate()) {
    final styles = (element.component as DomComponent).styles?.properties;
    if (styles != null) yield styles;
  }
}

Map<String, String>? _motionStyle(ComponentTester tester) {
  for (final styles in _styleMaps(tester)) {
    if (styles.containsKey('opacity')) return styles;
  }
  return null;
}

void main() {
  group('HeroSection appear', () {
    test('copyWith keeps the opt-in flag', () {
      const section = HeroSection(
        appear: true,
        child: Text('x'),
      );

      expect(section.copyWith().appear, isTrue);
      expect(section.copyWith(appear: false).appear, isFalse);
      expect(const HeroSection(child: Text('x')).appear, isFalse);
    });

    testComponents('the default hero has no entrance styles', (tester) async {
      pumpWithTheme(
        tester,
        const HeroSection(child: Text('Static hero')),
      );

      expect(find.text('Static hero'), findsOneComponent);
      expect(_motionStyle(tester), isNull);
      expect(find.tag('noscript'), findsNothing);
    });

    testComponents('appear publishes the hidden pose and the motion tokens', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const HeroSection(
          appear: true,
          semanticLabel: 'CoUI 소개',
          child: Text('In view'),
        ),
      );

      final motion = _motionStyle(tester);
      expect(motion, isNotNull);
      expect(motion!['opacity'], '0');
      expect(motion['pointer-events'], 'none');
      expect(motion['transform'], 'translateY(1.0rem)');
      expect(
        motion['transition'],
        contains('var(--coui-duration-${CoreDuration.moderate})'),
      );
      expect(
        motion['transition'],
        contains(CoreEasing.enter.toVarCss()),
      );
      expect(find.text('In view'), findsOneComponent);
      expect(find.tag('noscript'), findsOneComponent);

      final noscript =
          find.tag('noscript').evaluate().single.component as DomComponent;
      final styleTag = noscript.children!.single as DomComponent;
      final css = (styleTag.children!.single as RawText).text;
      expect(css, contains('opacity:1'));
      expect(css, contains('transform:none'));
      expect(css, contains('pointer-events:auto'));
    });

    testComponents('a style override retimes and rescales the entrance', (
      tester,
    ) async {
      BuildContext? captured;
      pumpWithTheme(
        tester,
        _ContextCapture((context) => captured = context),
      );
      final context = captured!;
      final resolved = resolveHero(
        context,
        appear: true,
        heroSectionStyle: const CoreHeroStyle(
          appearDuration: Duration(milliseconds: CoreDuration.slow),
          appearOffset: CoreSpace.space24,
          appearCurve: CoreEasing.exit,
        ),
      );

      final hidden = resolved.appearHidden!.inlineStyles!.properties;
      final shown = resolved.appearShown!.inlineStyles!.properties;
      expect(
        hidden['transition'],
        contains('var(--coui-duration-${CoreDuration.slow})'),
      );
      expect(hidden['transition'], contains(CoreEasing.exit.toVarCss()));
      expect(hidden['transform'], 'translateY(1.5rem)');
      expect(hidden['opacity'], '0');
      expect(shown['opacity'], '1');
      expect(shown['transform'], 'none');
      expect(shown['pointer-events'], 'auto');
      expect(
        shown['transition'],
        contains('var(--coui-duration-${CoreDuration.slow})'),
      );
    });

    testComponents('appear false leaves the entrance bundles null', (
      tester,
    ) async {
      BuildContext? captured;
      pumpWithTheme(
        tester,
        _ContextCapture((context) => captured = context),
      );

      final resolved = resolveHero(captured!);
      expect(resolved.appearHidden, isNull);
      expect(resolved.appearShown, isNull);
    });
  });
}

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Text('');
  }
}
