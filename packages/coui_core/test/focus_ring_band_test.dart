// The focus ring's gap band: transparent by default, opaque only where the
// background behind the control is unknown.
//
// The band is the 2px gap between a control's edge and its ring. Painted
// `surface` everywhere, it reads as a second outline glued to the control on
// every container that is not `surface` — the ring stops looking like a ring
// with a gap. So the shared default is transparent and the gap shows what is
// behind the control.
//
// Where nothing promises what is behind the control — floating over scrolling
// content or a photo, or sitting on an inverse-surface or saturated fill — the
// ring alone cannot promise contrast, so those components state the opaque
// band and the indicator becomes two colours. Those statements are Core
// defaults (platform resolvers may not name tokens), and this file pins every
// one of them, plus the rows that must NOT turn the band on.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreColor _band = CoreFocusRing.opaqueOffsetColor;

void main() {
  group('the shared default band is transparent', () {
    test('the token and the FocusOutline default agree on transparent', () {
      expect(CoreFocusRing.ringOffsetColor, CoreColor.transparent);
      expect(CoreFocusOutlineStyle.defaultOffsetColor, CoreColor.transparent);
    });

    test('the opaque band is the surface token', () {
      expect(_band, const CoreColor.token(CoreColors.surface));
    });

    test('slots that restate the default carry the transparent band', () {
      // These slots copy the whole recipe so a caller can retune any field
      // from one place; the copy must follow the shared default.
      final slots = <String, CoreFocusOutlineStyle>{
        'Button': CoreButtonStyle.defaultFocusOutlineStyle,
        'Clickable': CoreClickableStyle.defaultFocusOutlineStyle,
        'Badge': CoreBadgeStyle.defaultFocusOutlineStyle,
        'Checkbox': CoreCheckboxStyle.defaultFocusOutlineStyle,
        'ScrollableClient': CoreScrollableClientStyle.defaultFocusOutlineStyle,
        'TextField': CoreTextFieldStyle.defaultFocusOutlineStyle,
      };
      for (final MapEntry(key: name, value: slot) in slots.entries) {
        expect(
          slot.offsetColor,
          CoreColor.transparent,
          reason: '$name sits on a known background',
        );
      }
    });
  });

  group('components whose background is unknown state the opaque band', () {
    test('Fab main button — floats over scrolling content', () {
      expect(
        CoreFabStyle.defaultButtonStyle.focusOutlineStyle?.offsetColor,
        _band,
      );
    });

    test('Fab extended button inherits it through the shared base', () {
      for (final MapEntry(key: size, value: row)
          in CoreFabStyle.defaultsBySize.entries) {
        final extended = CoreFabStyle.defaultButtonStyle.merge(
          row.extendedButtonStyle,
        );
        expect(
          extended.focusOutlineStyle?.offsetColor,
          _band,
          reason: 'extended ${size.name}',
        );
      }
    });

    test('Carousel prev/next buttons — over the slides', () {
      expect(
        CoreCarouselStyle
            .defaultPrevNextButtonStyle
            .focusOutlineStyle
            ?.offsetColor,
        _band,
      );
    });

    test('Carousel overlay dots — the slide is behind them', () {
      expect(
        CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle.offsetColor,
        _band,
      );
    });

    test('Carousel overlay dots — the band is an overridable slot', () {
      // The resolvers read `default.merge(merged.<slot>)`, so a caller that
      // states only a ring colour keeps the band, and one that states a band
      // replaces it. The slot merges recursively and joins equality, or a
      // theme change to it would not rebuild.
      const ringOnly = CoreCarouselStyle(
        overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
          borderColor: CoreColor.token(CoreColors.error),
        ),
      );
      const bandOnly = CoreCarouselStyle(
        overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreColor.transparent,
        ),
      );
      final merged = ringOnly.merge(bandOnly);
      expect(
        merged.overlayIndicatorFocusOutlineStyle,
        const CoreFocusOutlineStyle(
          borderColor: CoreColor.token(CoreColors.error),
          offsetColor: CoreColor.transparent,
        ),
      );
      expect(ringOnly == bandOnly, isFalse);
      expect(
        CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle
            .merge(ringOnly.overlayIndicatorFocusOutlineStyle)
            .offsetColor,
        _band,
      );
      expect(
        const CoreCarouselStyle()
            .copyWith(
              overlayIndicatorFocusOutlineStyle:
                  bandOnly.overlayIndicatorFocusOutlineStyle,
            )
            .overlayIndicatorFocusOutlineStyle,
        bandOnly.overlayIndicatorFocusOutlineStyle,
      );
    });

    test('Toast close button — on the inverse-surface slab', () {
      final ring = CoreToastStyle.defaultCloseButtonStyle.focusOutlineStyle;
      expect(ring?.offsetColor, _band);
      // The band joins the width the slot already stated; it does not
      // replace it.
      expect(ring?.borderWidth, CoreFocusRing.ringWidth);
    });

    test('Toast Button action — the same slab, the same band', () {
      expect(
        CoreToastStyle.defaultActionButtonStyle.focusOutlineStyle?.offsetColor,
        _band,
      );
    });

    test('Chip close button — on the chip fill, at every size', () {
      expect(
        CoreChipStyle.defaultCloseButtonStyle.focusOutlineStyle?.offsetColor,
        _band,
      );
      for (final MapEntry(key: size, value: row)
          in CoreChipStyle.defaultsBySize.entries) {
        final close = CoreChipStyle.defaultCloseButtonStyle.merge(
          row.closeButtonStyle,
        );
        expect(
          close.focusOutlineStyle?.offsetColor,
          _band,
          reason: 'the size row must not drop the band (${size.name})',
        );
      }
    });

    test('ChipInput chips inherit the Chip band', () {
      // ChipInput's partial close-button slot merges over Chip's own
      // default; stating nothing about the ring keeps Chip's band.
      final close = CoreChipStyle.defaultCloseButtonStyle.merge(
        CoreChipInputStyle.defaultChipStyle.closeButtonStyle,
      );
      expect(close.focusOutlineStyle?.offsetColor, _band);
    });
  });

  group('components on a known face take the standard ring', () {
    test('CodeSnippet copy button — on a container tone, no band', () {
      // The block sits on `surfaceContainerLow`, a tone the ring already reads
      // on, so the copy button states no ring of its own and Button's
      // transparent-band default applies.
      const stated = CoreCodeSnippetStyle.defaultCopyButtonStyle;
      expect(stated.focusOutlineStyle, isNull);
      expect(
        CoreButtonStyle.defaultFocusOutlineStyle
            .merge(stated.focusOutlineStyle)
            .offsetColor,
        CoreColor.transparent,
      );
    });
  });

  group('Banner turns the band on for solid rows only', () {
    for (final MapEntry(key: variant, value: rows)
        in CoreBannerStyle.defaultsByVariant.entries) {
      test('${variant.name}: solid has the band, weak does not', () {
        // A solid row fills with the tone's own saturated colour; a weak row
        // is a light container the ring already reads on.
        expect(
          rows[CoreBannerEmphasis.solid]!.focusOutlineStyle?.offsetColor,
          _band,
        );
        expect(rows[CoreBannerEmphasis.weak]!.focusOutlineStyle, isNull);
      });
    }
  });
}
