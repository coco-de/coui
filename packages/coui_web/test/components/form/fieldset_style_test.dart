// Fieldset — the size-keyed legend typography ladder (md=titleSmall/16px,
// lg=titleMedium/18px), the disabled legend colour (disabled-content), the
// `variant` axis (filled / outlined / plain), the `description` slot and the
// spacing that sets the header apart from the fields.

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

ResolvedFieldset _resolve(
  BuildContext context, {
  bool enabled = true,
  CoreComponentSize size = CoreFieldsetStyle.defaultSize,
  CoreFieldsetVariant variant = CoreFieldsetVariant.defaultVariant,
  CoreFieldsetStyle? style,
}) => resolveFieldset(
  context,
  enabled: enabled,
  size: size,
  variant: variant,
  fieldsetStyle: style,
);

/// What the transparent sentinel emits inline — read from the emit family,
/// not restated, so the test follows the colour spelling.
String _transparentInline(String property, ColorTarget target) => emitColor(
  null,
  CoreColor.transparent,
  target,
).inline![property]!;

void main() {
  group('Fieldset legend size ladder', () {
    testComponents(
      'md/xs/sm read the 16px (titleSmall) role class — the default rung',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in [
          CoreComponentSize.xs,
          CoreComponentSize.sm,
          CoreComponentSize.md,
        ]) {
          final resolved = _resolve(context, size: size);
          expect(
            resolved.legend.className,
            contains('text-title-small'),
            reason: size.name,
          );
        }
      },
    );

    testComponents(
      'lg/xl/xl2 read the 18px (titleMedium) role class',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in [
          CoreComponentSize.lg,
          CoreComponentSize.xl,
          CoreComponentSize.xl2,
        ]) {
          final resolved = _resolve(context, size: size);
          expect(
            resolved.legend.className,
            contains('text-title-medium'),
            reason: size.name,
          );
        }
      },
    );
  });

  group('Fieldset disabled legend colour (#3269-style)', () {
    testComponents(
      'a disabled fieldset tones the legend with disabled-content — not '
      'the onSurfaceVariant convention other form components use',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context, enabled: false);
        expect(resolved.legend.className, contains('text-disabled-content'));
      },
    );

    testComponents(
      'an enabled fieldset legend stays on-surface, not disabled-content',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context);
        expect(resolved.legend.className, contains('text-on-surface'));
        expect(
          resolved.legend.className,
          isNot(contains('text-disabled-content')),
        );
      },
    );

    testComponents(
      'a disabled fieldset forces the disabled tone even over an explicit '
      'legendTextStyle.color override — mirrors the Flutter resolver',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreFieldsetStyle(
          legendTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        );
        final resolved = _resolve(context, enabled: false, style: style);
        expect(resolved.legend.className, contains('text-disabled-content'));
        expect(resolved.legend.className, isNot(contains('text-primary')));
      },
    );

    testComponents(
      'an explicit legendTextStyle.color override wins when enabled',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreFieldsetStyle(
          legendTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        );
        final resolved = _resolve(context, style: style);
        expect(resolved.legend.className, contains('text-primary'));
      },
    );
  });

  group('Fieldset spacing', () {
    testComponents('fields sit space16 apart, on the fields wrapper', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context);
      expect(
        resolved.fields.inlineStyles?.properties['gap'],
        'var(--coui-space-16)',
      );
      // The header is set apart by its own gap, so the root carries none.
      expect(resolved.root.inlineStyles?.properties['gap'], isNull);
    });

    testComponents('legend → description 4, header → first field 12', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context);
      expect(resolved.legendDescriptionGapStyle.size, CoreSpace.space4);
      expect(resolved.headerFieldsGapStyle.size, CoreSpace.space12);
    });

    testComponents('a fieldsetStyle gap override reaches the nested slot', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        style: const CoreFieldsetStyle(
          headerFieldsGapStyle: CoreGapStyle(size: CoreSpace.space24),
        ),
      );
      expect(resolved.headerFieldsGapStyle.size, CoreSpace.space24);
      // The untouched slot keeps its default.
      expect(resolved.legendDescriptionGapStyle.size, CoreSpace.space4);
    });

    testComponents('the legend wrapper adds no inset', (tester) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context);
      expect(
        resolved.legendWrapper.inlineStyles?.properties['padding'],
        CoreEdgeInsets.zero.toValue(),
      );
    });
  });

  group('Fieldset variants', () {
    testComponents('defaults to filled: panel fill, subtle edge, 16 corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context);
      final root = resolved.root;
      expect(root.className, contains('bg-surface-container-low'));
      expect(root.className, contains('border-outline-subtle'));
      expect(root.inlineStyles?.properties['border-radius'], isNotNull);
      expect(
        root.inlineStyles?.properties['border-radius'],
        CoreFieldsetStyle.defaultBorderRadius.toValue(),
      );
      expect(
        root.inlineStyles?.properties['padding'],
        CoreFieldsetStyle.defaultPadding.toValue(),
      );
    });

    testComponents('outlined keeps the edge but states no fill class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final root = _resolve(
        context,
        variant: CoreFieldsetVariant.outlined,
      ).root;
      expect(root.className, isNot(contains('bg-surface-container-low')));
      expect(root.className, contains('border-outline-subtle'));
      expect(
        root.inlineStyles?.properties['background-color'],
        _transparentInline('background-color', .background),
      );
      expect(
        root.inlineStyles?.properties['padding'],
        CoreFieldsetStyle.defaultPadding.toValue(),
      );
    });

    testComponents('plain draws no box: no padding, edge, corner or material', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final root = _resolve(context, variant: CoreFieldsetVariant.plain).root;
      final props = root.inlineStyles!.properties;
      expect(props['padding'], CoreEdgeInsets.zero.toValue());
      expect(props['border-radius'], CoreBorderRadius.zero.toValue());
      expect(props['border-width'], strokeWidthCss(CoreStrokeWidth.stroke0));
      expect(
        props['border-color'],
        _transparentInline('border-color', .border),
      );
      expect(
        props['background-color'],
        _transparentInline('background-color', .background),
      );
      // No fill → no surface material; no box → no cast.
      expect(root.className, isNot(contains('coui-surface')));
      expect(root.className, isNot(contains(kControlShadowRestMarker)));
    });

    testComponents('a boxed variant takes the style cast, plain does not', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final variant in [
        CoreFieldsetVariant.filled,
        CoreFieldsetVariant.outlined,
      ]) {
        expect(
          _resolve(context, variant: variant).root.className,
          contains(kControlShadowRestMarker),
          reason: variant.name,
        );
      }
    });

    testComponents('a theme variantStyles row overrides one variant only', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              fieldset: CoreFieldsetTheme(
                variantStyles: {
                  CoreFieldsetVariant.outlined: CoreFieldsetStyle(
                    padding: CoreEdgeInsets.all(CoreSpace.space8),
                  ),
                },
              ),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );
      expect(
        _resolve(
          context,
          variant: CoreFieldsetVariant.outlined,
        ).root.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.all(CoreSpace.space8).toValue(),
      );
      expect(
        _resolve(context).root.inlineStyles?.properties['padding'],
        CoreFieldsetStyle.defaultPadding.toValue(),
      );
    });
  });

  group('Fieldset description', () {
    testComponents('reads bodySmall in on-surface-variant', (tester) async {
      final context = _themedContext(tester);
      final description = _resolve(context).description;
      expect(description.className, contains('text-body-small'));
      expect(description.className, contains('text-on-surface-variant'));
    });

    testComponents('a disabled fieldset does not recolour the description', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final description = _resolve(context, enabled: false).description;
      expect(description.className, contains('text-on-surface-variant'));
      expect(description.className, isNot(contains('disabled-content')));
    });
  });
}
