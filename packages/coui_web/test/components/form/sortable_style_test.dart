import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveSortable` directly.
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

void main() {
  group('Sortable disabled foreground', () {
    testComponents('a disabled list greys the item text and the remove glyph; '
        'an enabled one does not', (tester) async {
      final context = _themedContext(tester);
      final enabled = resolveSortable(context, enabled: true);
      final disabled = resolveSortable(context, enabled: false);

      expect(
        disabled.removeButtonStyle.foregroundColor,
        CoreSortableStyle.defaultDisabledForegroundColor,
      );
      expect(
        enabled.removeButtonStyle.foregroundColor,
        isNot(CoreSortableStyle.defaultDisabledForegroundColor),
      );
      expect(
        disabled.item.inlineStyles!.properties['color'],
        contains('disabled-content'),
      );
      expect(
        enabled.item.inlineStyles!.properties['color'],
        isNot(contains('disabled-content')),
      );
    });
  });

  group('Sortable remove control — a composed plain square Button', () {
    testComponents('is raw-forwarded to Button as a 32 square, 16 glyph, '
        'onSurfaceVariant', (tester) async {
      final style = resolveSortable(
        _themedContext(tester),
        enabled: true,
      ).removeButtonStyle;

      expect(style.width, CoreControlSize.heightSm);
      expect(style.height, CoreControlSize.heightSm);
      expect(style.padding, CoreEdgeInsets.zero);
      expect(
        style.foregroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(style.leadingIconStyle!.size, CoreIconSize.size16);
    });

    testComponents('a per-instance removeButtonStyle wins over the default '
        'and the flat fields', (tester) async {
      const override = CoreColor(0xFF00FF00);
      final style = resolveSortable(
        _themedContext(tester),
        enabled: true,
        sortableStyle: const CoreSortableStyle(
          removeButtonColor: CoreColor.token(CoreColors.primary),
          removeButtonStyle: CoreButtonStyle(foregroundColor: override),
        ),
      ).removeButtonStyle;

      expect(style.foregroundColor, override);
    });
  });

  group('Sortable row chrome', () {
    testComponents('is 48 high, radius 12, outline-variant 1 px', (
      tester,
    ) async {
      final item = resolveSortable(_themedContext(tester), enabled: true).item;
      final inline = item.inlineStyles!.properties;

      expect(inline['min-height'], pinnedLengthCss(CoreControlSize.heightLg));
      expect(
        inline['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius12).toValue(),
      );
      expect(inline['border-style'], 'solid');
      expect(inline['border-width'], strokeWidthCss(CoreStrokeWidth.stroke1));
      expect(item.className.split(' '), contains('border-outline-variant'));
    });

    testComponents('the padding is directional — 12 before, 8 after, none '
        'above or below', (tester) async {
      final inline = resolveSortable(
        _themedContext(tester),
        enabled: true,
      ).item.inlineStyles!.properties;

      expect(inline['padding-inline-start'], spaceCss(CoreSpace.space12));
      expect(inline['padding-inline-end'], spaceCss(CoreSpace.space8));
      expect(inline['padding-block-start'], spaceCss(0));
      expect(inline['padding-block-end'], spaceCss(0));
      expect(inline.containsKey('padding'), isFalse);
    });

    testComponents('a disabled list takes the disabled tokens and no hover '
        'tint', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveSortable(context, enabled: false);
      final classes = resolved.item.className.split(' ');

      expect(classes, contains('bg-disabled-container'));
      expect(classes, contains('border-disabled-outline'));
      expect(classes.where((c) => c.startsWith('hover:')), isEmpty);
      expect(classes, isNot(contains('bg-surface')));
      expect(
        resolved.handle.className.split(' '),
        contains('text-disabled-content'),
      );
    });

    testComponents('the handle glyph is onSurfaceSubtle with no padding', (
      tester,
    ) async {
      final handle = resolveSortable(
        _themedContext(tester),
        enabled: true,
      ).handle;

      expect(handle.className.split(' '), contains('text-on-surface-subtle'));
      expect(
        handle.inlineStyles!.properties['padding'],
        CoreEdgeInsets.zero.toValue(),
      );
    });

    testComponents('the item label is body-large', (tester) async {
      final inline = resolveSortable(
        _themedContext(tester),
        enabled: true,
      ).item.inlineStyles!.properties;

      expect(inline['font-size'], '${CoreFontSize.s15 / kRemDivisor}rem');
    });
  });

  group('Sortable row hover — default fill', () {
    testComponents(
      'an enabled row hovers to the opaque surfaceContainerHigh tone',
      (tester) async {
        final context = _themedContext(tester);
        final classes = resolveSortable(
          context,
          enabled: true,
        ).item.className.split(' ');

        // A neutral step off the row's `surface` fill, at full strength —
        // the same opaque hover the other option lists use. An opacity
        // modifier (`/50`) would let whatever the list sits on show
        // through, so the hover would read differently on every page.
        expect(classes, contains('hover:bg-surface-container-high'));
        expect(
          classes.where((c) => c.startsWith('hover:bg-')),
          hasLength(1),
          reason: 'the row states a second hover fill',
        );
      },
    );
  });

  group(
    'item width follows axis (Flutter parity — Row/Wrap do not stretch)',
    () {
      testComponents(
        '.vertical items stretch to the list width (w-full)',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveSortable(
            context,
            enabled: true,
          );
          expect(resolved.item.className, contains('w-full'));
        },
      );

      testComponents(
        '.horizontal items size to their own content (no w-full)',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveSortable(
            context,
            enabled: true,
            axis: .horizontal,
          );
          expect(resolved.item.className, isNot(contains('w-full')));
        },
      );

      testComponents(
        '.grid items size to their own content (no w-full)',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveSortable(
            context,
            enabled: true,
            axis: .grid,
          );
          expect(resolved.item.className, isNot(contains('w-full')));
        },
      );
    },
  );

  // One element, one `transition-property`. Tailwind's `transition-*`
  // utilities each write that property outright, so stacking two of them
  // does not add the second group — it replaces the first, and which one
  // survives is decided by the generated stylesheet's order rather than by
  // the class list. The row carried `transition-transform` *and*
  // `transition-colors` and ended up transitioning `transform` alone: the
  // hover tint snapped on Web while the Flutter twin faded it over the same
  // clock through one `AnimatedContainer`.
  //
  // Nothing about that state renders wrong at a glance — it only shows when
  // the colour is asked to move — so the pair is pinned here rather than
  // left to review.
  group('a row animates its shift and its tint on one clock', () {
    testComponents('the row states its transition property list exactly once', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveSortable(
        context,
        enabled: true,
      );

      final className = resolved.item.className;
      final utilities = RegExp(
        r'(^|\s)transition(-[a-z]+)?(\s|$)',
      ).allMatches(className);
      expect(
        utilities,
        isEmpty,
        reason:
            'a `transition-*` utility here would overwrite the inline '
            'property list instead of joining it',
      );

      final property =
          resolved.item.inlineStyles?.properties['transition-property'];
      expect(
        property,
        isNotNull,
        reason: 'the row states no transition at all',
      );
      expect(property, contains('transform'), reason: 'the reorder shift');
      expect(
        property,
        contains('background-color'),
        reason: 'the hover tint — the half that was silently dropped',
      );
    });
  });
}
