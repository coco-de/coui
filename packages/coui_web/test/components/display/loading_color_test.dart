import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _CaptureContext extends StatelessComponent {
  const _CaptureContext(this.capture);

  final void Function(BuildContext) capture;

  @override
  Component build(BuildContext context) {
    capture(context);
    return const div([]);
  }
}

BuildContext _context(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _CaptureContext((value) => context = value));
  return context;
}

List<WebElementChrome> _paint(ResolvedLoading resolved) => [
  ?resolved.sweep,
  ?resolved.dot0,
  ?resolved.dot1,
  ?resolved.dot2,
  ?resolved.fill,
  ?resolved.halo,
  ?resolved.dot,
];

void main() {
  const rawColors = {
    'opaque': CoreColor(0xFFB12345),
    'alpha': CoreColor(0x80319AC7),
    'zero alpha with RGB': CoreColor(0x00319AC7),
    'transparent': CoreColor.transparent,
  };

  for (final variant in CoreLoadingVariant.values) {
    final property = variant == .spinner ? 'color' : 'background-color';
    testComponents('$variant preserves existing fractional token opacity', (
      tester,
    ) async {
      final context = _context(tester);
      final prefix = variant == .spinner ? 'text' : 'bg';
      for (final (opacity, percent) in [(0.005, 1), (0.29, 29), (0.625, 63)]) {
        final resolved = resolveLoading(
          context,
          variant: variant,
          loadingStyle: CoreLoadingStyle(
            color: CoreColor.token(CoreColors.warning, opacity: opacity),
          ),
        );
        for (final chrome in _paint(resolved)) {
          expect(
            chrome.className.split(' '),
            contains('$prefix-warning/$percent'),
          );
          expect(chrome.inlineStyles?.properties[property], isNull);
        }
      }
    });
    for (final color in rawColors.entries) {
      testComponents('$variant paints ${color.key} indicator color', (
        tester,
      ) async {
        final resolved = resolveLoading(
          _context(tester),
          variant: variant,
          loadingStyle: CoreLoadingStyle(color: color.value),
        );
        for (final chrome in _paint(resolved)) {
          expect(
            chrome.inlineStyles?.properties[property],
            color.value.toValue(),
          );
          expect(chrome.className, isNot(contains('#')));
        }
        if (variant == .spinner) {
          expect(
            resolved.sweep!.inlineStyles?.properties['stroke'],
            'currentColor',
          );
        }
      });
    }

    testComponents('$variant keeps default and token colors on classes', (
      tester,
    ) async {
      final context = _context(tester);
      final defaults = resolveLoading(context, variant: variant);
      const token = CoreColor.token(CoreColors.warning, opacity: 0.6);
      final override = resolveLoading(
        context,
        variant: variant,
        loadingStyle: const CoreLoadingStyle(color: token),
      );
      final prefix = variant == .spinner ? 'text' : 'bg';
      for (final chrome in _paint(defaults)) {
        expect(chrome.className.split(' '), contains('$prefix-primary'));
        expect(chrome.inlineStyles?.properties[property], isNull);
      }
      for (final chrome in _paint(override)) {
        expect(chrome.className.split(' '), contains('$prefix-warning/60'));
        expect(chrome.inlineStyles?.properties[property], isNull);
      }
      expect(
        override.root.inlineStyles?.properties,
        defaults.root.inlineStyles?.properties,
      );
    });

    testComponents(
      '$variant forwards theme color until the instance overrides',
      (
        tester,
      ) async {
        late BuildContext context;
        tester.pumpComponent(
          Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                loading: CoreLoadingTheme(
                  style: CoreLoadingStyle(color: CoreColor(0xFF123456)),
                ),
              ),
            ),
            child: _CaptureContext((value) => context = value),
          ),
        );
        final themed = resolveLoading(context, variant: variant);
        final instance = resolveLoading(
          context,
          variant: variant,
          loadingStyle: const CoreLoadingStyle(color: CoreColor(0xFFB12345)),
        );
        for (final chrome in _paint(themed)) {
          expect(
            chrome.inlineStyles?.properties[property],
            const CoreColor(0xFF123456).toValue(),
          );
        }
        for (final chrome in _paint(instance)) {
          expect(
            chrome.inlineStyles?.properties[property],
            const CoreColor(0xFFB12345).toValue(),
          );
        }
      },
    );

    testComponents('$variant retains caller root CSS, classes and attributes', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Loading(
          variant: variant,
          classes: 'caller-loading',
          css: const Styles(raw: {'width': '3rem', 'color': 'rgb(1, 2, 3)'}),
          attributes: const {'data-caller': 'kept'},
          loadingStyle: const CoreLoadingStyle(color: CoreColor(0xFFB12345)),
        ),
      );
      final root = find
          .byType(DomComponent)
          .evaluate()
          .map((element) => element.component as DomComponent)
          .singleWhere((element) => element.attributes?['role'] == 'status');
      expect(root.classes?.split(' '), contains('caller-loading'));
      expect(root.styles?.properties['width'], '3rem');
      expect(root.styles?.properties['color'], 'rgb(1, 2, 3)');
      expect(root.attributes?['data-caller'], 'kept');
      expect(root.attributes?['aria-label'], isNotEmpty);
    });
  }
}
