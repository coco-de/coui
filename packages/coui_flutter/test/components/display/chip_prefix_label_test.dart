// The key a filter chip draws in front of its value ("필터" before "전체").
//
// Read back where it is consumed: the resolved key style (role per size,
// colour per state) and the drawn row (the key before the value, one gap
// between them, nothing at all when the key is absent). A field that is
// declared, merged and compared but never reaches the drawn `Text` looks
// complete and changes nothing.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Future<
  ({ResolvedChip resolved, CoreColorScheme scheme, CoreTypography typography})
>
_resolve(
  WidgetTester tester, {
  CoreChipSize size = CoreChipSize.md,
  CoreChipColor chipColor = CoreChipColor.neutral,
  CoreChipVariant variant = CoreChipVariant.outlined,
  CoreChipEmphasis emphasis = CoreChipEmphasis.high,
  bool selected = false,
  bool enabled = true,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
}) async {
  late ResolvedChip resolved;
  late CoreColorScheme scheme;
  late CoreTypography typography;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            scheme = theme.colorScheme;
            typography = theme.typography;
            resolved = resolveChip(
              context,
              chipColor: chipColor,
              variant: variant,
              emphasis: emphasis,
              size: size,
              selected: selected,
              enabled: enabled,
              seedColor: seedColor,
              chipStyle: chipStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (resolved: resolved, scheme: scheme, typography: typography);
}

Color _token(CoreColorScheme scheme, CoreColorToken token) =>
    scheme.resolve(CoreColor.token(token)).toValue();

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

void main() {
  group('Chip prefix label — resolved key style', () {
    testWidgets('each size takes its key role — 11 / 12 / 13 at 500', (
      tester,
    ) async {
      final roles = {
        CoreChipSize.sm: (CoreTypography t) => t.labelXs,
        CoreChipSize.md: (CoreTypography t) => t.labelSmall,
        CoreChipSize.lg: (CoreTypography t) => t.labelMedium,
      };
      const sizes = {
        CoreChipSize.sm: 11.0,
        CoreChipSize.md: 12.0,
        CoreChipSize.lg: 13.0,
      };
      for (final size in CoreChipSize.values) {
        final r = await _resolve(tester, size: size);
        final role = roles[size]!(r.typography);
        final key = r.resolved.prefixLabelTextStyle;
        expect(key.fontSize, sizes[size], reason: '${size.name} size');
        expect(key.fontSize, role.fontSize, reason: '${size.name} role size');
        expect(
          key.fontWeight,
          fontWeightFromInt(CoreFontWeight.medium),
          reason: '${size.name} weight',
        );
        expect(key.height, role.lineHeight, reason: '${size.name} height');
        expect(
          key.letterSpacing,
          closeTo(role.letterSpacing! * role.fontSize!, 1e-9),
          reason: '${size.name} tracking',
        );
        // The value beside it is the role's 500 too — the key is the
        // smaller half.
        expect(
          r.resolved.labelTextStyle.fontWeight,
          fontWeightFromInt(CoreFontWeight.medium),
        );
      }
    });

    testWidgets('a resting key reads its own column — outlined and filled, '
        'either emphasis', (tester) async {
      for (final variant in CoreChipVariant.values) {
        for (final emphasis in CoreChipEmphasis.values) {
          final r = await _resolve(
            tester,
            variant: variant,
            emphasis: emphasis,
          );
          expect(
            r.resolved.prefixLabelTextStyle.color,
            _token(r.scheme, CoreColors.onSurfaceVariant),
            reason: '$variant $emphasis',
          );
        }
      }
      // And it is not the value's colour at high emphasis.
      final high = await _resolve(tester);
      expect(
        high.resolved.prefixLabelTextStyle.color,
        isNot(high.resolved.labelTextStyle.color),
      );
    });

    testWidgets('a selected key takes the label colour of its emphasis', (
      tester,
    ) async {
      final high = await _resolve(tester, selected: true);
      expect(
        high.resolved.prefixLabelTextStyle.color,
        _token(high.scheme, CoreColors.inverseOnSurface),
      );
      expect(
        high.resolved.prefixLabelTextStyle.color,
        high.resolved.labelTextStyle.color,
      );

      final low = await _resolve(
        tester,
        selected: true,
        emphasis: CoreChipEmphasis.low,
      );
      expect(
        low.resolved.prefixLabelTextStyle.color,
        low.resolved.labelTextStyle.color,
      );

      final primary = await _resolve(
        tester,
        selected: true,
        chipColor: CoreChipColor.primary,
      );
      expect(
        primary.resolved.prefixLabelTextStyle.color,
        _token(primary.scheme, CoreColors.onPrimary),
      );

      // A custom seed's derived on-colour, the same as its label.
      final custom = await _resolve(
        tester,
        selected: true,
        chipColor: CoreChipColor.custom,
        seedColor: const CoreColor.token(CoreColors.success),
      );
      expect(
        custom.resolved.prefixLabelTextStyle.color,
        custom.resolved.labelTextStyle.color,
      );
    });

    testWidgets('a disabled key takes the disabled content colour', (
      tester,
    ) async {
      for (final selected in [false, true]) {
        final r = await _resolve(tester, enabled: false, selected: selected);
        expect(
          r.resolved.prefixLabelTextStyle.color,
          _token(r.scheme, CoreColors.disabledContent),
          reason: 'selected=$selected',
        );
      }
    });

    testWidgets('foregroundColor wins across states, its own slot wins over '
        'that', (tester) async {
      final forced = await _resolve(
        tester,
        chipStyle: const CoreChipStyle(
          foregroundColor: CoreColor.token(CoreColors.error),
        ),
      );
      expect(
        forced.resolved.prefixLabelTextStyle.color,
        _token(forced.scheme, CoreColors.error),
      );

      final slot = await _resolve(
        tester,
        chipStyle: const CoreChipStyle(
          foregroundColor: CoreColor.token(CoreColors.error),
          prefixLabelStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      expect(
        slot.resolved.prefixLabelTextStyle.color,
        _token(slot.scheme, CoreColors.primary),
      );
      // The label is untouched by the key's slot.
      expect(
        slot.resolved.labelTextStyle.color,
        _token(slot.scheme, CoreColors.error),
      );
    });
  });

  group('Chip prefix label — drawn row', () {
    testWidgets('draws the key before the value, one gap between', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Chip(prefixLabel: '필터', label: '전체')),
      );

      final key = find.text('필터');
      final value = find.text('전체');
      expect(key, findsOneWidget);
      expect(value, findsOneWidget);
      expect(
        tester.getTopLeft(key).dx,
        lessThan(tester.getTopLeft(value).dx),
      );
      expect(find.byType(Gap), findsOneWidget);

      // The drawn key carries the resolved key style, one line.
      final text = tester.widget<Text>(key);
      expect(text.style?.fontSize, 12);
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    });

    testWidgets('sits between the leading icon and the value', (tester) async {
      await tester.pumpWidget(
        _app(
          const Chip(
            prefixLabel: '필터',
            label: '전체',
            leading: Icon(LucideIcons.funnel),
          ),
        ),
      );
      final icon = find.byType(Icon);
      final key = find.text('필터');
      final value = find.text('전체');
      expect(
        tester.getTopLeft(icon).dx,
        lessThan(tester.getTopLeft(key).dx),
      );
      expect(
        tester.getTopLeft(key).dx,
        lessThan(tester.getTopLeft(value).dx),
      );
      expect(find.byType(Gap), findsNWidgets(2));
    });

    testWidgets('draws nothing — not even a gap — when absent', (tester) async {
      await tester.pumpWidget(_app(const Chip(label: '전체')));
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(Gap), findsNothing);
    });

    testWidgets('the remove button names the chip key first', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        CoUIApp(
          home: Center(
            child: Chip(prefixLabel: '필터', label: '전체', onRemove: () {}),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Remove 필터 전체'), findsOneWidget);
      handle.dispose();
    });

    test('copyWith carries the key', () {
      const chip = Chip(prefixLabel: '필터', label: '전체');
      expect(chip.copyWith(label: '진행 중').prefixLabel, '필터');
      expect(chip.copyWith(prefixLabel: '상태').prefixLabel, '상태');
    });
  });
}
