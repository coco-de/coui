// CoreCommandSearchStyle — the command palette trigger's own contract.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('size ladder', () {
    test('three rungs on the control ladder — 32 / 40 / 48', () {
      expect(
        CoreCommandSearchStyle.defaultsBySize[CoreCommandSize.sm]!.height,
        CoreControlSize.heightSm,
      );
      expect(
        CoreCommandSearchStyle.defaultsBySize[CoreCommandSize.md]!.height,
        CoreControlSize.heightMd,
      );
      expect(
        CoreCommandSearchStyle.defaultsBySize[CoreCommandSize.lg]!.height,
        CoreControlSize.heightLg,
      );
      expect(CoreCommandSize.defaultSize, CoreCommandSize.md);
    });

    test('every row covers every size', () {
      expect(
        CoreCommandSearchStyle.defaultsBySize.keys.toSet(),
        CoreCommandSize.values.toSet(),
      );
    });

    test('the corner is the height × 0.25 on every rung', () {
      for (final MapEntry(key: size, value: row)
          in CoreCommandSearchStyle.defaultsBySize.entries) {
        final corner = row.borderRadius!;
        expect(
          corner.topLeft,
          row.height! * CoreControlSize.cornerRatio,
          reason: size.name,
        );
        expect(
          corner,
          CoreBorderRadius.all(corner.topLeft),
          reason: '${size.name}: four equal corners',
        );
      }
    });

    test('insets are directional — the end inset is the smaller one', () {
      final expected = {
        CoreCommandSize.sm: (CoreSpace.space12, CoreSpace.space8),
        CoreCommandSize.md: (CoreSpace.space12, CoreSpace.space10),
        CoreCommandSize.lg: (CoreSpace.space16, CoreSpace.space12),
      };
      for (final MapEntry(key: size, value: (start, end)) in expected.entries) {
        final padding = CoreCommandSearchStyle.defaultsBySize[size]!.padding!;
        expect(padding.isDirectional, isTrue, reason: size.name);
        expect(padding.start, start, reason: size.name);
        expect(padding.end, end, reason: size.name);
        expect(padding.top, 0, reason: '${size.name}: the height centres');
        expect(padding.bottom, 0, reason: '${size.name}: the height centres');
      }
    });

    test('gap 8 / 8 / 12 · glyph 16 / 18 / 20 · hint body S / M / L', () {
      final expected = {
        CoreCommandSize.sm: (
          CoreSpace.space8,
          CoreIconSize.size16,
          CoreTextStyles.bodySmall,
        ),
        CoreCommandSize.md: (
          CoreSpace.space8,
          CoreIconSize.size18,
          CoreTextStyles.bodyMedium,
        ),
        CoreCommandSize.lg: (
          CoreSpace.space12,
          CoreIconSize.size20,
          CoreTextStyles.bodyLarge,
        ),
      };
      for (final MapEntry(key: size, value: (gap, glyph, role))
          in expected.entries) {
        final row = CoreCommandSearchStyle.defaultsBySize[size]!;
        expect(row.contentGapStyle!.size, gap, reason: size.name);
        expect(row.leadingIconStyle!.size, glyph, reason: size.name);
        expect(row.hintTextStyle!.token, role, reason: size.name);
        // The ladder states the role only — never a size over it, which
        // would keep the default role's letter spacing on a new size.
        expect(row.hintTextStyle!.fontSize, isNull, reason: size.name);
      }
    });
  });

  group('face and ink', () {
    test('a card-level face with no stroke field at all', () {
      expect(
        CoreCommandSearchStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
    });

    test('glyph and hint read the secondary-text step', () {
      expect(
        CoreCommandSearchStyle.defaultForegroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('disabled drops to the disabled pair', () {
      expect(
        CoreCommandSearchStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreCommandSearchStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the state layer is onSurface at hover 8 · focus 8 · pressed 12', () {
      expect(
        CoreCommandSearchStyle.defaultStateLayerColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      const ramp = CoreCommandSearchStyle.defaultStateLayer;
      expect(ramp.hover, CoreOpacity.opacity8);
      expect(ramp.focus, CoreOpacity.opacity8);
      expect(ramp.pressed, CoreOpacity.pressed);
      // The same ramp a menu row presses with.
      expect(ramp, CoreMenuItemStyle.defaultStateLayer);
    });

    test('the composed Clickable does not dim the disabled pair', () {
      expect(
        CoreCommandSearchStyle.defaultClickableStyle.disabledOpacity,
        CoreOpacity.opacity100,
      );
    });
  });

  group('value semantics', () {
    const a = CoreCommandSearchStyle(
      height: CoreControlSize.heightMd,
      padding: CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        end: CoreSpace.space8,
      ),
      contentGapStyle: CoreGapStyle(size: CoreSpace.space8),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      hintTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      stateLayerColor: CoreColor.token(CoreColors.onSurface),
      stateLayer: CoreStateLayer(hover: 0.08, focus: 0.08, pressed: 0.12),
      clickableStyle: CoreClickableStyle(disabledOpacity: 1),
    );

    test('== and hashCode cover every field', () {
      const same = CoreCommandSearchStyle(
        height: CoreControlSize.heightMd,
        padding: CoreEdgeInsets.directional(
          start: CoreSpace.space12,
          end: CoreSpace.space8,
        ),
        contentGapStyle: CoreGapStyle(size: CoreSpace.space8),
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
        hintTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
        disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
        disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
        stateLayerColor: CoreColor.token(CoreColors.onSurface),
        stateLayer: CoreStateLayer(hover: 0.08, focus: 0.08, pressed: 0.12),
        clickableStyle: CoreClickableStyle(disabledOpacity: 1),
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);

      final variants = <CoreCommandSearchStyle>[
        a.copyWith(height: CoreControlSize.heightLg),
        a.copyWith(padding: CoreEdgeInsets.zero),
        a.copyWith(contentGapStyle: const CoreGapStyle(size: 12)),
        a.copyWith(borderRadius: CoreBorderRadius.zero),
        a.copyWith(leadingIconStyle: const CoreIconStyle(size: 20)),
        a.copyWith(
          hintTextStyle: const CoreTextStyle.token(CoreTextStyles.bodyLarge),
        ),
        a.copyWith(
          backgroundColor: const CoreColor.token(CoreColors.surface),
        ),
        a.copyWith(
          foregroundColor: const CoreColor.token(CoreColors.onSurface),
        ),
        a.copyWith(
          disabledBackgroundColor: const CoreColor.token(CoreColors.surface),
        ),
        a.copyWith(
          disabledForegroundColor: const CoreColor.token(CoreColors.outline),
        ),
        a.copyWith(
          stateLayerColor: const CoreColor.token(CoreColors.primary),
        ),
        a.copyWith(
          stateLayer: const CoreStateLayer(
            hover: 0.04,
            focus: 0.04,
            pressed: 0.04,
          ),
        ),
        a.copyWith(
          clickableStyle: const CoreClickableStyle(disabledOpacity: 0.5),
        ),
      ];
      for (final (i, other) in variants.indexed) {
        expect(other, isNot(a), reason: 'field #$i is not compared');
      }
    });

    test('merge — the other side wins per field, nested slots recurse', () {
      const base = CoreCommandSearchStyle(
        leadingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      );
      const patch = CoreCommandSearchStyle(
        leadingIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
        height: CoreControlSize.heightLg,
      );
      final merged = base.merge(patch);
      expect(merged.height, CoreControlSize.heightLg);
      expect(
        merged.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
      // The caller's colour lands without dropping the base glyph size.
      expect(merged.leadingIconStyle!.size, CoreIconSize.size18);
      expect(
        merged.leadingIconStyle!.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(base.merge(null), base);
    });
  });

  test('the component theme carries the slot', () {
    const style = CoreCommandSearchStyle(height: CoreControlSize.heightLg);
    const theme = CoreComponentTheme(
      commandSearch: CoreCommandSearchTheme(style: style),
    );
    expect(theme.commandSearch!.style, style);
    expect(
      theme,
      isNot(const CoreComponentTheme()),
      reason: 'the slot takes part in ==',
    );
    expect(
      theme.copyWith().commandSearch,
      const CoreCommandSearchTheme(style: style),
    );
  });
}
