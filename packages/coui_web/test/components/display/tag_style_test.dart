import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveTag` directly.
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

BuildContext _contextUnder(ComponentTester tester, CoreTagTheme tag) {
  late BuildContext context;
  tester.pumpComponent(
    Theme(
      data: ThemeData.coui.copyWith(
        coreComponentTheme: CoreComponentTheme(tag: tag),
      ),
      child: _ContextCapture((c) => context = c),
    ),
  );
  return context;
}

ResolvedTag _resolve(
  BuildContext context, {
  CoreCategoryColor color = CoreTagContract.defaultColor,
  CoreTagEmphasis emphasis = CoreTagEmphasis.defaultEmphasis,
  CoreTagSize size = CoreTagSize.defaultSize,
  CoreTagStyle? tagStyle,
}) => resolveTag(
  context,
  color: color,
  emphasis: emphasis,
  size: size,
  tagStyle: tagStyle,
);

/// A corner on the radius ladder goes out as its variable on all four
/// corners, so a style preset reaches it.
String _radius(int step) =>
    List.filled(4, 'var(--coui-radius-$step)').join(' ');

List<String> _classes(ResolvedTag tag) => tag.root.className.split(' ');

Map<String, String> _inline(ResolvedTag tag) =>
    tag.root.inlineStyles?.properties ?? const {};

void main() {
  group('size rows', () {
    testComponents('md — 24 tall on the size scale, 8 sides, corner 6, '
        'labelSmall', (tester) async {
      final tag = _resolve(_themedContext(tester));
      expect(_classes(tag), contains('min-h-size24'));
      expect(_classes(tag), contains('text-label-small'));
      expect(_inline(tag)['border-radius'], _radius(6));
      // Sides only — the height is the step and the label centres in it.
      expect(
        _inline(tag)['padding'],
        '${spaceCss(0)} ${spaceCss(8)} ${spaceCss(0)} ${spaceCss(8)}',
      );
      expect(_classes(tag), containsAll(['inline-flex', 'items-center']));
    });

    testComponents('sm — 20 tall, 6 sides, corner 4, labelXs', (tester) async {
      final tag = _resolve(_themedContext(tester), size: CoreTagSize.sm);
      expect(_classes(tag), contains('min-h-size20'));
      expect(_classes(tag), contains('text-label-xs'));
      expect(_inline(tag)['border-radius'], _radius(4));
      expect(
        _inline(tag)['padding'],
        '${spaceCss(0)} ${spaceCss(6)} ${spaceCss(0)} ${spaceCss(6)}',
      );
    });

    testComponents('an overridden height goes inline instead of the class', (
      tester,
    ) async {
      final tag = _resolve(
        _themedContext(tester),
        tagStyle: const CoreTagStyle(minHeight: 32),
      );
      expect(_classes(tag).where((c) => c.startsWith('min-h-')), isEmpty);
      expect(_inline(tag)['min-height'], '2.0rem');
    });
  });

  group('colours — every hue × emphasis', () {
    for (final hue in CoreCategoryColor.values) {
      testComponents('${hue.name} subtle — container, text, inner outline', (
        tester,
      ) async {
        final tag = _resolve(_themedContext(tester), color: hue);
        expect(
          _classes(tag),
          containsAll([
            'bg-category-${hue.name}-container',
            'text-on-category-${hue.name}-container',
            'border-category-${hue.name}-outline',
          ]),
        );
        expect(
          _inline(tag)['border-width'],
          strokeWidthCss(CoreTagStyle.defaultBorderWidth),
        );
        // The role's own weight — no overlay.
        expect(_inline(tag).containsKey('font-weight'), isFalse);
      });

      testComponents('${hue.name} bold — fill, on-fill, no line, 600', (
        tester,
      ) async {
        final tag = _resolve(
          _themedContext(tester),
          color: hue,
          emphasis: CoreTagEmphasis.bold,
        );
        expect(
          _classes(tag),
          containsAll([
            'bg-category-${hue.name}',
            'text-on-category-${hue.name}',
          ]),
        );
        expect(_classes(tag).where((c) => c.startsWith('border')), isEmpty);
        expect(_inline(tag).containsKey('border-width'), isFalse);
        expect(_inline(tag)['font-weight'], '600');
      });
    }
  });

  group('surface material', () {
    testComponents('a filled tag carries the content marker and its fill', (
      tester,
    ) async {
      final tag = _resolve(_themedContext(tester));
      expect(
        _classes(tag),
        containsAll([
          ...webSurfaceMarkerFor(CoreSurfaceRole.content),
          kControlShadowRestMarker,
        ]),
      );
      expect(_inline(tag).keys, contains(kWebSurfaceFillVar));
    });

    testComponents('a caller-made transparent fill drops the marker', (
      tester,
    ) async {
      final tag = _resolve(
        _themedContext(tester),
        tagStyle: const CoreTagStyle(backgroundColor: CoreColor.transparent),
      );
      expect(_classes(tag), isNot(contains(kWebSurfaceMarker)));
      expect(_inline(tag).keys, isNot(contains(kWebSurfaceFillVar)));
    });
  });

  group('overrides', () {
    testComponents('a raw colour goes inline and drops its class', (
      tester,
    ) async {
      final tag = _resolve(
        _themedContext(tester),
        tagStyle: const CoreTagStyle(backgroundColor: CoreColor(0xFF112233)),
      );
      expect(_classes(tag).where((c) => c.startsWith('bg-')), isEmpty);
      expect(_inline(tag)['background-color'], isNotNull);
    });

    testComponents('theme rows are read in order, instance last', (
      tester,
    ) async {
      final context = _contextUnder(
        tester,
        const CoreTagTheme(
          style: CoreTagStyle(minHeight: 28),
          colorStyles: {CoreCategoryColor.red: CoreTagStyle(minHeight: 29)},
          emphasisStyles: {
            CoreTagEmphasis.subtle: CoreTagStyle(
              borderRadius: CoreBorderRadius.all(2),
            ),
          },
        ),
      );
      final tag = _resolve(
        context,
        color: CoreCategoryColor.red,
        tagStyle: const CoreTagStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      expect(_inline(tag)['min-height'], '${29 / 16}rem');
      expect(_inline(tag)['border-radius'], _radius(8));

      final blue = _resolve(context, color: CoreCategoryColor.blue);
      expect(_inline(blue)['min-height'], '${28 / 16}rem');
      expect(_inline(blue)['border-radius'], _radius(2));
    });
  });
}
