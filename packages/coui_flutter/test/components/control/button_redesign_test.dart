import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the redesigned `Button` paints, read back from the resolver's
/// output rather than from the style it was given.
///
/// A token can be wired into the table, the merge and `==` and still never
/// reach a pixel; and a state can be "implemented" by being left out. So
/// every claim here is a resolved `Color` for a named widget-state set.
class _Capture extends StatelessWidget {
  const _Capture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);

    return const SizedBox.shrink();
  }
}

/// A variant of every kind the table states, in the table's own order.
const Set<WidgetState> _kRest = {};
const Set<WidgetState> _kHover = {WidgetState.hovered};
const Set<WidgetState> _kPressed = {WidgetState.pressed};
const Set<WidgetState> _kFocus = {WidgetState.focused};
const Set<WidgetState> _kDisabled = {WidgetState.disabled};

/// The two rows that fold focus into hover on purpose (`useFocusedAsHover`).
const Set<CoreButtonVariant> _kFocusIsHover = {
  CoreButtonVariant.menu,
  CoreButtonVariant.menubar,
};

void main() {
  late BuildContext context;
  late ColorScheme scheme;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: _Capture((c) => context = c),
      ),
    );
    scheme = Theme.of(context).colorScheme;
  }

  Color resolve(CoreColorToken token) =>
      scheme.resolve(CoreColor.token(token)).toValue();

  ResolvedButton resolved(
    CoreButtonVariant variant, {
    CoreComponentSize size = .md,
  }) => resolveButton(
    context,
    variant: variant,
    size: size,
    shape: .rectangle,
  );

  BoxDecoration decoration(
    ResolvedButton r,
    Set<WidgetState> states,
  ) => r.decoration.resolve(states) as BoxDecoration;

  group('the variant set', () {
    test('link is not a Button variant', () {
      expect(
        CoreButtonVariant.values.map((v) => v.name),
        [
          'primary',
          'secondary',
          'tonal',
          'outline',
          'ghost',
          'plain',
          'destructive',
          'menu',
          'menubar',
          'fixed',
        ],
      );
    });
  });

  group('tonal is secondary with the brand container pair', () {
    testWidgets('rests on primaryContainer with onPrimaryContainer ink', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.tonal);

      expect(
        decoration(r, _kRest).color,
        resolve(CoreColors.primaryContainer),
      );
      expect(decoration(r, _kRest).border, isNull);
      expect(
        r.textStyle.resolve(_kRest).color,
        resolve(CoreColors.onPrimaryContainer),
      );
    });

    testWidgets('hover and pressed wash the ink over the resting fill', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.tonal);
      final fill = resolve(CoreColors.primaryContainer);
      final ink = resolve(CoreColors.onPrimaryContainer);

      expect(
        decoration(r, _kHover).color,
        Color.alphaBlend(ink.withValues(alpha: CoreOpacity.hover), fill),
      );
      expect(
        decoration(r, _kPressed).color,
        Color.alphaBlend(ink.withValues(alpha: CoreOpacity.pressed), fill),
      );
      expect(decoration(r, _kFocus).color, fill);
      expect(
        r.textStyle.resolve(_kHover).color,
        resolve(CoreColors.onPrimaryContainer),
      );
    });

    testWidgets('disabled is the shared disabled pair', (tester) async {
      await pump(tester);
      final r = resolved(.tonal);

      expect(
        decoration(r, _kDisabled).color,
        resolve(CoreColors.disabledContainer),
      );
      expect(
        r.textStyle.resolve(_kDisabled).color,
        resolve(CoreColors.disabledContent),
      );
    });
  });

  group('outline draws the pale boundary', () {
    testWidgets('outlineVariant at rest, hover, focus and pressed', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.outline);

      for (final states in [_kRest, _kHover, _kFocus, _kPressed]) {
        final border = decoration(r, states).border! as Border;
        expect(
          border.top.color,
          resolve(CoreColors.outlineVariant),
          reason: '$states',
        );
      }
      final disabled = decoration(r, _kDisabled).border! as Border;
      expect(disabled.top.color, resolve(CoreColors.disabledOutline));
    });
  });

  group('secondary is a tonal fill', () {
    testWidgets('rests on secondaryContainer with onSecondaryContainer ink', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.secondary);

      expect(
        decoration(r, _kRest).color,
        resolve(CoreColors.secondaryContainer),
      );
      expect(
        r.textStyle.resolve(_kRest).color,
        resolve(CoreColors.onSecondaryContainer),
      );
    });

    testWidgets('hover and pressed wash the ink over the resting fill', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.secondary);
      final fill = resolve(CoreColors.secondaryContainer);
      final ink = resolve(CoreColors.onSecondaryContainer);

      expect(
        decoration(r, _kHover).color,
        Color.alphaBlend(ink.withValues(alpha: CoreOpacity.hover), fill),
      );
      expect(
        decoration(r, _kPressed).color,
        Color.alphaBlend(ink.withValues(alpha: CoreOpacity.pressed), fill),
      );
      // A wash, not a swap: the label keeps its colour in every state.
      expect(
        r.textStyle.resolve(_kHover).color,
        resolve(CoreColors.onSecondaryContainer),
      );
    });

    testWidgets('the retired hover and pressed scheme slots are not read', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.secondary);

      for (final states in [_kHover, _kPressed]) {
        expect(
          decoration(r, states).color,
          isNot(resolve(CoreColors.secondaryHover)),
        );
        expect(
          decoration(r, states).color,
          isNot(resolve(CoreColors.secondaryPressed)),
        );
      }
    });
  });

  group('destructive is tinted at rest and filled under the pointer', () {
    testWidgets('errorContainer at rest, onErrorContainer ink, no stroke', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.destructive);
      final rest = decoration(r, _kRest);

      expect(rest.color, resolve(CoreColors.errorContainer));
      expect(rest.border, isNull);
      expect(
        r.textStyle.resolve(_kRest).color,
        resolve(CoreColors.onErrorContainer),
      );
    });

    testWidgets('hover is error and pressed is errorPressed — apart', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.destructive);
      final hover = decoration(r, _kHover).color;
      final pressed = decoration(r, _kPressed).color;

      expect(hover, resolve(CoreColors.error));
      expect(pressed, resolve(CoreColors.errorPressed));
      // A press that cannot be told from a hover is a state nothing shows.
      expect(pressed, isNot(hover));
    });

    testWidgets('the label is onErrorContainer at rest and focused, onError '
        'once filled', (tester) async {
      await pump(tester);
      final r = resolved(.destructive);

      for (final states in [_kRest, _kFocus]) {
        expect(
          r.textStyle.resolve(states).color,
          resolve(CoreColors.onErrorContainer),
          reason: '$states',
        );
      }
      for (final states in [_kHover, _kPressed]) {
        expect(
          r.textStyle.resolve(states).color,
          resolve(CoreColors.onError),
          reason: '$states',
        );
      }
    });

    testWidgets('disabled is the disabled container with no stroke', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(.destructive);
      final disabled = decoration(r, _kDisabled);

      expect(disabled.color, resolve(CoreColors.disabledContainer));
      expect(disabled.border, isNull);
      expect(
        r.textStyle.resolve(_kDisabled).color,
        resolve(CoreColors.disabledContent),
      );
    });
  });

  group('focus is the resting look plus the ring', () {
    for (final variant in CoreButtonVariant.values) {
      if (_kFocusIsHover.contains(variant)) continue;

      testWidgets('${variant.name} paints the same focused as at rest', (
        tester,
      ) async {
        await pump(tester);
        final r = resolved(variant);

        expect(decoration(r, _kFocus), decoration(r, _kRest));
        expect(r.textStyle.resolve(_kFocus), r.textStyle.resolve(_kRest));
        expect(
          r.leadingIconTheme.resolve(_kFocus),
          r.leadingIconTheme.resolve(_kRest),
        );
      });
    }

    for (final variant in _kFocusIsHover) {
      testWidgets('${variant.name} folds focus into hover, on purpose', (
        tester,
      ) async {
        await pump(tester);
        final r = resolved(variant);

        expect(decoration(r, _kFocus), decoration(r, _kHover));
        expect(
          decoration(r, _kFocus).color,
          isNot(decoration(r, _kRest).color),
        );
      });
    }
  });

  group('a disabled label is one ink on every variant', () {
    for (final variant in CoreButtonVariant.values) {
      testWidgets('${variant.name} is disabledContent', (tester) async {
        await pump(tester);
        final r = resolved(variant);

        expect(
          r.textStyle.resolve(_kDisabled).color,
          resolve(CoreColors.disabledContent),
        );
        expect(
          r.leadingIconTheme.resolve(_kDisabled).color,
          resolve(CoreColors.disabledContent),
        );
      });
    }
  });

  group('the xs label', () {
    testWidgets('is 12px, and the 24 row still holds it', (tester) async {
      await pump(tester);
      final xs = resolved(.primary, size: .xs);
      final sm = resolved(.primary, size: .sm);

      expect(xs.textStyle.resolve(_kRest).fontSize, 12);
      // Not the 10px role it replaced, and not borrowed from the next row.
      expect(
        xs.textStyle.resolve(_kRest).fontSize,
        lessThan(
          sm.textStyle.resolve(_kRest).fontSize!,
        ),
      );
      expect(xs.height, CoreControlSize.heightXs);
    });
  });
}
