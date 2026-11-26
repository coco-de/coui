// Tests for CoreHoverCardStyle defaults (#5967).
//
// The panel box is a composed `Popup`, so the hover card states only what it
// does differently from a bare `Popup` and forwards the rest through the
// nested `panelStyle` slot.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreHoverCardStyle defaults', () {
    test('the card sits 4 off its trigger', () {
      expect(CoreHoverCardStyle.defaultPlacementOffset, CoreSpace.space4);
      expect(CoreHoverCardStyle.defaultPlacementOffset, 4);
    });

    test('the panel states only its content-sized ceiling, nothing else', () {
      // Corner, fill, border, shadow, padding and content colour are
      // `Popup`'s; restating any of them here would be a second copy that
      // stops tracking it.
      expect(
        CoreHoverCardStyle.defaultPanelStyle,
        const CorePopupStyle(minWidth: 0, maxWidth: CoreSpace.space256),
      );
      const stated = CoreHoverCardStyle.defaultPanelStyle;
      expect(stated.borderRadius, isNull);
      expect(stated.backgroundColor, isNull);
      expect(stated.borderColor, isNull);
      expect(stated.padding, isNull);
      expect(stated.boxShadow, isNull);
      expect(stated.contentColor, isNull);
    });

    test('the face the card rests on is the Popup default (issue values)', () {
      // What the redesign states of the card — corner 12, `surface-bright`,
      // inset 16, `lg` cast — are `CorePopupStyle`'s defaults, reached
      // because the hover card does not override them.
      expect(
        CorePopupStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        CorePopupStyle.defaultBorderRadius,
        const CoreBorderRadius.all(12),
      );
      expect(
        CorePopupStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(CorePopupStyle.defaultPadding, const CoreEdgeInsets.all(16));
      expect(CorePopupStyle.defaultBoxShadow, CoreShadow.lg);
    });

    test('a hover card carries no panel chrome field of its own', () {
      expect(const CoreHoverCardStyle().panelStyle, isNull);
    });
  });

  group('CoreHoverCardStyle merge', () {
    test('a stated value still wins on merge', () {
      const base = CoreHoverCardStyle();
      const override = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: CoreColor.token(CoreColors.surface),
          borderRadius: CoreBorderRadius.all(16),
        ),
        placementOffset: 12,
      );
      final merged = base.merge(override);
      expect(
        merged.panelStyle?.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(merged.panelStyle?.borderRadius, const CoreBorderRadius.all(16));
      expect(merged.placementOffset, 12);
    });

    test('the nested panel slot merges field by field', () {
      const base = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
      );
      const override = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(padding: CoreEdgeInsets.all(24)),
      );
      final merged = base.merge(override);
      expect(merged.panelStyle?.borderRadius, const CoreBorderRadius.all(8));
      expect(merged.panelStyle?.padding, const CoreEdgeInsets.all(24));
    });

    test('equality and hashCode cover the panel slot', () {
      const a = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
      );
      const b = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
      );
      const c = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(9)),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('copyWith replaces only what it is given', () {
      const base = CoreHoverCardStyle(
        panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
        placementOffset: 6,
      );
      final copy = base.copyWith(placementOffset: 10);
      expect(copy.panelStyle, base.panelStyle);
      expect(copy.placementOffset, 10);
    });
  });
}
