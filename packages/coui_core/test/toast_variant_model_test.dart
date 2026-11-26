// A toast is a dark bubble that contrasts with the page, and the glyph's
// shape (with the copy) says what kind of news it carries — drawn in the
// message colour, not a tone.
//
// It used to be the other way round: `success` (then spelled `default_`)
// filled with `surface` — a
// panel the same colour as the page it floats over — and `destructive`
// filled with `error`, a solid red slab. Neither drew a leading glyph at
// all. The library states the model this file pins: one fill for all three
// variants, and the state on the shape of a 16px mark.
//
// `neutral` is the variant that exists to have no glyph. That absence is
// load-bearing, so it is asserted rather than assumed: a `neutral` that
// picked up a colour would draw a mark, and a `success` that lost one
// would become indistinguishable from it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreToastVariantStyle _row(CoreToastVariant v) =>
    CoreToastStyle.defaultsByVariant[v]!;

void main() {
  group('the panel is the same on every variant', () {
    test('every variant fills with the inverse surface', () {
      for (final v in CoreToastVariant.values) {
        expect(
          _row(v).backgroundColor,
          const CoreColor.token(CoreColors.inverseSurface),
          reason: '${v.name} broke away from the shared fill',
        );
      }
    });

    test('and reads with the inverse-on-surface foreground', () {
      for (final v in CoreToastVariant.values) {
        expect(
          _row(v).foregroundColor,
          const CoreColor.token(CoreColors.inverseOnSurface),
          reason: '${v.name} would read against the wrong ground',
        );
      }
    });

    test('the fill is not the page surface', () {
      // The specific thing that was wrong. A toast filled with `surface`
      // on a `surface` page is a floating rectangle with no edge — which
      // is why the old model needed a border to be visible at all.
      for (final v in CoreToastVariant.values) {
        expect(
          _row(v).backgroundColor,
          isNot(const CoreColor.token(CoreColors.surface)),
        );
      }
    });
  });

  group('the glyph is what tells them apart', () {
    test('success and destructive draw their mark in the message colour', () {
      // The state is carried by the glyph's shape and the copy, not a hue:
      // the page-tuned success / error hues measured under 2:1 on the
      // inverse bubble in Dark.
      for (final v in [
        CoreToastVariant.success,
        CoreToastVariant.destructive,
      ]) {
        expect(
          _row(v).iconColor,
          const CoreColor.token(CoreColors.inverseOnSurface),
          reason: v.name,
        );
        expect(_row(v).iconColor, _row(v).foregroundColor, reason: v.name);
      }
    });

    test('neutral carries none — null, not transparent', () {
      // Not interchangeable. A transparent glyph still takes its width and
      // its gap, so the message would start 24px in from where it should.
      expect(_row(CoreToastVariant.neutral).iconColor, isNull);
    });

    test('exactly one variant is glyphless', () {
      // Pins the count, not just the members. A second glyphless variant
      // would be two variants that render identically — which is what
      // `neutral` looked like before the glyph existed.
      final glyphless = CoreToastVariant.values
          .where((v) => _row(v).iconColor == null)
          .toList();
      expect(glyphless, [CoreToastVariant.neutral]);
    });
  });

  group('the default asserts nothing', () {
    test('the default variant is the glyphless one', () {
      // A bare `Toast('Saved')` draws no glyph — asserting an outcome its
      // caller never stated is what `success` would do here.
      expect(CoreToastVariant.defaultVariant, CoreToastVariant.neutral);
      expect(_row(CoreToastVariant.defaultVariant).iconColor, isNull);
    });

    test('the enum has exactly three members', () {
      // Pinned so a fourth cannot arrive without a variant row and a
      // decision about what it draws.
      expect(CoreToastVariant.values, hasLength(3));
    });
  });

  group('the glyph slot states size without stating colour', () {
    test('the shared style carries a size', () {
      expect(CoreToastStyle.defaultIconStyle.size, CoreIconSize.size16);
    });

    test('and no colour', () {
      // A colour here would sit in front of the variant's own, which is
      // the one thing that distinguishes the three.
      expect(CoreToastStyle.defaultIconStyle.color, isNull);
    });

    test('the glyph has a gap of its own', () {
      // Distinct from `contentActionGapStyle`, which spaces the content
      // from the action — the glyph sits closer than that.
      expect(
        CoreToastStyle.defaultIconContentGapStyle,
        isNot(CoreToastStyle.defaultContentActionGapStyle),
      );
    });
  });

  group('the glyph can be turned off', () {
    test('the contract draws it by default', () {
      // Both widgets take their default from here, so a toast that states
      // nothing draws what it always drew.
      expect(CoreToastContract.defaultShowIcon, isTrue);
    });

    test('the switch needs no row of its own', () {
      // `showIcon` gates the glyph the variant row already picked; it adds
      // no colour and no size. A row that grew a field for it would be a
      // second place to say whether the glyph is there.
      for (final v in CoreToastVariant.values) {
        expect(
          _row(v).iconColor == null,
          v == CoreToastVariant.neutral,
          reason: "${v.name}: whether a glyph exists is the row's call alone",
        );
      }
    });
  });
}
