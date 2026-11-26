// Tests for CoreToggleStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../tool/check_contrast.dart' show auditedSchemes;

const double _kTrackWidthSm = 32;
const double _kTrackWidthMd = 40;
const double _kTrackHeight = 20;
const _kTrackRadiusSm = CoreBorderRadius.all(10);
const _kTrackRadiusLg = CoreBorderRadius.all(12);
const double _kThumbSizeSm = 14;
const double _kThumbSizeMd = 18;
const _kThumbRadius = CoreBorderRadius.all(9);
const _kGapSm = CoreGapStyle(size: 4);
const _kGapLg = CoreGapStyle(size: 8);

const _kTrackActivePrimary = CoreColor.token(CoreColors.primary);
const _kTrackActiveSuccess = CoreColor.token(CoreColors.success);
const _kTrackInactiveOutline = CoreColor.token(CoreColors.outline);
const _kThumbActiveOnPrimary = CoreColor.token(CoreColors.onPrimary);
const _kThumbInactiveOnSurface = CoreColor.token(CoreColors.onSurface);
const _kTrackInactiveOutlineClr = CoreColor.token(CoreColors.outline);
const _kInkTertiary = CoreColor.token(CoreColors.tertiary);
const _kRingError = CoreColor.token(CoreColors.error);

const double _kFontBody = 14;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

// The designer's ladder: a track as wide as its height plus one shared
// travel, a 2px band on every side.
const double _kTrackTravel = 16;
const double _kFormulaTolerance = 1e-9;
const _kCustomRamp = CoreStateLayer(hover: 0.2, focus: 0.3, pressed: 0.4);

void main() {
  test('thumb shadow merges, clears explicitly, and has value equality', () {
    const base = CoreToggleStyle(thumbShadow: CoreShadow.sm);
    final copied = CoreToggleStyle(thumbShadow: List.of(CoreShadow.sm));
    expect(base, copied);
    expect(base.hashCode, copied.hashCode);
    expect(base.copyWith(thumbShadow: CoreShadow.none).thumbShadow, isEmpty);
    expect(
      base
          .merge(const CoreToggleStyle(thumbShadow: CoreShadow.none))
          .thumbShadow,
      isEmpty,
    );
    expect(base.merge(const CoreToggleStyle()).thumbShadow, CoreShadow.sm);
    // The default cast is the faint drop + contact ring that carries the
    // white off thumb's outline on the light off track.
    expect(CoreToggleStyle.defaultThumbShadow, const [
      (
        offsetX: 0.0,
        offsetY: 1.0,
        blurRadius: 2.0,
        spreadRadius: 0.0,
        opacity: 0.08,
        inset: false,
      ),
      (
        offsetX: 0.0,
        offsetY: 0.0,
        blurRadius: 1.0,
        spreadRadius: 0.0,
        opacity: 0.06,
        inset: false,
      ),
    ]);
    const tinted = CoreToggleStyle(
      thumbShadowBaseColor: CoreColor.token(CoreColors.primary),
    );
    expect(
      base.merge(tinted).thumbShadowBaseColor,
      tinted.thumbShadowBaseColor,
    );
    expect(
      base.copyWith(thumbShadowBaseColor: tinted.thumbShadowBaseColor),
      base.merge(tinted),
    );
  });

  group('CoreToggleStyle.merge', () {
    test('null other returns this', () {
      const a = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
        thumbActiveColor: _kThumbActiveOnPrimary,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → variantStyles → widget', () {
      const designSystem = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
        trackInactiveColor: _kTrackInactiveOutline,
        trackBorderRadius: _kTrackRadiusSm,
        trackWidth: _kTrackWidthMd,
        trackHeight: _kTrackHeight,
        thumbSize: _kThumbSizeMd,
        iconLabelGapStyle: _kGapLg,
      );
      const themeStyle = CoreToggleStyle(
        trackBorderRadius: _kTrackRadiusLg,
      );
      const variantStyle = CoreToggleStyle(
        trackActiveColor: _kTrackActiveSuccess,
      );
      const widgetStyle = CoreToggleStyle(
        iconLabelGapStyle: _kGapSm,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(variantStyle)
          .merge(widgetStyle);

      expect(effective.trackActiveColor, _kTrackActiveSuccess); // variant
      expect(effective.trackInactiveColor, _kTrackInactiveOutline);
      expect(effective.trackBorderRadius, _kTrackRadiusLg); // theme
      expect(effective.trackWidth, _kTrackWidthMd);
      expect(effective.trackHeight, _kTrackHeight);
      expect(effective.thumbSize, _kThumbSizeMd);
      expect(effective.iconLabelGapStyle, _kGapSm); // widget
    });

    test('right-most non-null wins on each field', () {
      const a = CoreToggleStyle(
        trackWidth: _kTrackWidthSm,
        thumbSize: _kThumbSizeSm,
      );
      const b = CoreToggleStyle(trackWidth: _kTrackWidthMd);
      const c = CoreToggleStyle(thumbSize: _kThumbSizeMd);

      final result = a.merge(b).merge(c);

      expect(result.trackWidth, _kTrackWidthMd);
      expect(result.thumbSize, _kThumbSizeMd);
    });

    test('thumb chrome merge', () {
      const base = CoreToggleStyle(
        thumbActiveColor: _kThumbActiveOnPrimary,
        thumbInactiveColor: _kThumbInactiveOnSurface,
        thumbSize: _kThumbSizeMd,
        thumbBorderRadius: _kThumbRadius,
      );
      const override = CoreToggleStyle(
        thumbSize: _kThumbSizeSm,
      );
      final merged = base.merge(override);
      expect(merged.thumbActiveColor, _kThumbActiveOnPrimary);
      expect(merged.thumbInactiveColor, _kThumbInactiveOnSurface);
      expect(merged.thumbSize, _kThumbSizeSm);
      expect(merged.thumbBorderRadius, _kThumbRadius);
    });

    test('state layer fields merge — ramp, both inks', () {
      const base = CoreToggleStyle(
        stateLayer: CoreStateLayer.subtle,
        stateLayerActiveColor: _kInkTertiary,
      );
      const override = CoreToggleStyle(
        stateLayer: _kCustomRamp,
        stateLayerInactiveColor: _kInkTertiary,
      );
      final merged = base.merge(override);
      expect(merged.stateLayer, _kCustomRamp);
      expect(merged.stateLayerActiveColor, _kInkTertiary);
      expect(merged.stateLayerInactiveColor, _kInkTertiary);
    });

    test('focusOutlineStyle merges recursively (subset override)', () {
      const base = CoreToggleStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(
          borderRadius: _kTrackRadiusSm,
        ),
      );
      const override = CoreToggleStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRingError),
      );
      final merged = base.merge(override);
      expect(merged.focusOutlineStyle?.borderRadius, _kTrackRadiusSm);
      expect(merged.focusOutlineStyle?.borderColor, _kRingError);
    });

    test('labelStyle merges recursively (subset override)', () {
      const base = CoreToggleStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kTrackInactiveOutlineClr,
        ),
      );
      const override = CoreToggleStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.labelStyle?.color, _kTrackInactiveOutlineClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreToggleStyle();
      const override = CoreToggleStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
    });
  });

  group('CoreToggleStyle equality', () {
    test('same fields → equal', () {
      const a = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
        thumbSize: _kThumbSizeMd,
        iconLabelGapStyle: _kGapSm,
        stateLayer: _kCustomRamp,
      );
      const b = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
        thumbSize: _kThumbSizeMd,
        iconLabelGapStyle: _kGapSm,
        stateLayer: _kCustomRamp,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different trackActiveColor → not equal', () {
      const a = CoreToggleStyle(trackActiveColor: _kTrackActivePrimary);
      const b = CoreToggleStyle(trackActiveColor: _kTrackActiveSuccess);
      expect(a, isNot(equals(b)));
    });

    test('different stateLayer / focusOutlineStyle → not equal', () {
      const a = CoreToggleStyle(stateLayer: CoreStateLayer.subtle);
      const b = CoreToggleStyle(stateLayer: CoreStateLayer.strong);
      expect(a, isNot(equals(b)));
      const c = CoreToggleStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRingError),
      );
      expect(c, isNot(equals(const CoreToggleStyle())));
    });
  });

  group('CoreToggleStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
        thumbSize: _kThumbSizeMd,
        iconLabelGapStyle: _kGapLg,
      );
      final copy = base.copyWith(thumbSize: _kThumbSizeSm);
      expect(copy.trackActiveColor, _kTrackActivePrimary);
      expect(copy.thumbSize, _kThumbSizeSm);
      expect(copy.iconLabelGapStyle, _kGapLg);
    });

    test('preserves nested labelStyle when not specified', () {
      const base = CoreToggleStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final copy = base.copyWith(trackActiveColor: _kTrackActiveSuccess);
      expect(copy.trackActiveColor, _kTrackActiveSuccess);
      expect(copy.labelStyle?.fontSize, _kFontBody);
    });
  });

  group('CoreToggleTheme', () {
    test('style + variantStyles pass through', () {
      const style = CoreToggleStyle(iconLabelGapStyle: _kGapLg);
      const variantStyle = CoreToggleStyle(
        trackActiveColor: _kTrackActivePrimary,
      );
      const theme = CoreToggleTheme(
        style: style,
        variantStyles: {
          .defaultVariant: variantStyle,
        },
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles![CoreToggleVariant.defaultVariant],
        variantStyle,
      );
    });

    test('null fields', () {
      const theme = CoreToggleTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality', () {
      const a = CoreToggleTheme(
        style: CoreToggleStyle(iconLabelGapStyle: _kGapLg),
        variantStyles: {
          .defaultVariant: CoreToggleStyle(
            trackActiveColor: _kTrackActivePrimary,
          ),
        },
      );
      const b = CoreToggleTheme(
        style: CoreToggleStyle(iconLabelGapStyle: _kGapLg),
        variantStyles: {
          .defaultVariant: CoreToggleStyle(
            trackActiveColor: _kTrackActivePrimary,
          ),
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  // `sizeDefaults` is the resolvers' only door into the ladder. `xs` has
  // no row (a 24×12 switch cannot show its own travel), so the door has to
  // clamp rather than throw — pinned here so the map can lose a row again
  // without either platform learning about it at runtime.
  group('CoreToggleStyle.sizeDefaults', () {
    test('every size resolves to a row', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreToggleStyle.sizeDefaults(size).trackHeight,
          isNotNull,
          reason: 'CoreComponentSize.${size.name} has no toggle row',
        );
      }
    });

    test('xs has no row of its own and clamps to sm', () {
      expect(CoreToggleStyle.defaultsBySize[CoreComponentSize.xs], isNull);
      expect(
        CoreToggleStyle.sizeDefaults(CoreComponentSize.xs),
        same(CoreToggleStyle.defaultsBySize[CoreToggleStyle.smallestSize]),
      );
    });

    test('the ladder is sm..xl2 — 16 / 20 / 24 / 28 / 32', () {
      const expectedHeights = {
        CoreComponentSize.sm: 16.0,
        CoreComponentSize.md: 20.0,
        CoreComponentSize.lg: 24.0,
        CoreComponentSize.xl: 28.0,
        CoreComponentSize.xl2: 32.0,
      };
      expect(
        CoreToggleStyle.defaultsBySize.keys,
        orderedEquals(expectedHeights.keys),
      );
      for (final entry in expectedHeights.entries) {
        expect(
          CoreToggleStyle.defaultsBySize[entry.key]!.trackHeight,
          entry.value,
          reason: 'CoreComponentSize.${entry.key.name} trackHeight',
        );
      }
    });

    test('trackWidth / thumbSize / thumbOffset stay derived from '
        'trackHeight with a 2px band', () {
      expect(CoreToggleStyle.defaultThumbInset, CoreSpace.space2);
      for (final chrome in CoreToggleStyle.defaultsBySize.values) {
        final trackHeight = chrome.trackHeight!;
        final trackWidth = chrome.trackWidth!;
        final thumbSize = chrome.thumbSize!;
        final thumbOffset = chrome.thumbOffset!;
        final padding = chrome.padding!;

        expect(
          trackWidth,
          closeTo(trackHeight + _kTrackTravel, _kFormulaTolerance),
          reason: 'trackWidth = trackHeight + 16',
        );
        expect(
          thumbSize,
          closeTo(
            trackHeight - 2 * CoreToggleStyle.defaultThumbInset,
            _kFormulaTolerance,
          ),
          reason: 'thumbSize = trackHeight − 2 × 2',
        );
        expect(
          padding,
          const CoreEdgeInsets.all(CoreToggleStyle.defaultThumbInset),
          reason: 'padding is the thumb inset on every side',
        );
        expect(
          thumbOffset,
          closeTo(
            trackWidth - padding.left - padding.right - thumbSize,
            _kFormulaTolerance,
          ),
          reason: 'thumbOffset flush with the trailing padded edge',
        );
        expect(
          thumbOffset,
          _kTrackTravel,
          reason: 'the thumb travels the same 16 on every row',
        );
      }
    });

    test('the track widths are 32 / 36 / 40 / 44 / 48', () {
      const expectedWidths = {
        CoreComponentSize.sm: 32.0,
        CoreComponentSize.md: 36.0,
        CoreComponentSize.lg: 40.0,
        CoreComponentSize.xl: 44.0,
        CoreComponentSize.xl2: 48.0,
      };
      for (final entry in expectedWidths.entries) {
        expect(
          CoreToggleStyle.defaultsBySize[entry.key]!.trackWidth,
          entry.value,
          reason: 'CoreComponentSize.${entry.key.name} trackWidth',
        );
      }
    });

    // The size ladder for the label — 13 / 14 / 15 / 15 / 15 at body
    // weight and the body role's 150% line height. Read back through the
    // same merge the resolvers run (`defaultLabelStyle → size row`), so a
    // row that states the wrong role fails here rather than on a
    // screenshot.
    test('label follows the size ladder at body weight / 150%', () {
      const expectedSizes = {
        CoreComponentSize.sm: 13.0,
        CoreComponentSize.md: 14.0,
        CoreComponentSize.lg: 15.0,
        CoreComponentSize.xl: 15.0,
        CoreComponentSize.xl2: 15.0,
      };
      for (final entry in expectedSizes.entries) {
        final row = CoreToggleStyle.defaultsBySize[entry.key]!;
        final merged = CoreToggleStyle.defaultLabelStyle.merge(row.labelStyle);
        final role = merged.token!.read(CoreTypography.coui);
        expect(
          role.fontSize,
          entry.value,
          reason: 'CoreComponentSize.${entry.key.name} label fontSize',
        );
        expect(role.fontWeight, CoreFontWeight.regular);
        expect(role.lineHeight, CoreLineHeight.h150);
        expect(
          merged.color,
          const CoreColor.token(CoreColors.onSurface),
          reason: 'colour comes from defaultLabelStyle, not the row',
        );
      }
    });
  });

  group('CoreToggleStyle defaults — what the canvas draws', () {
    final vs =
        CoreToggleStyle.defaultsByVariant[CoreToggleVariant.defaultVariant]!;

    // The on thumb is the mark chosen to be read on its own track:
    // `onPrimary` on the primary on track. The off thumb is white in both
    // modes on the highest container step the off track is, and so is the
    // disabled off thumb. The disabled on thumb stays `surface` (the
    // disabled-content on track carries it).
    test(
      'the off track is the highest step; the off thumb is fixed white',
      () {
        expect(
          vs.inactiveTrack,
          const CoreColor.token(CoreColors.surfaceContainerHighest),
        );
        expect(vs.activeThumb, const CoreColor.token(CoreColors.onPrimary));
        expect(vs.inactiveThumb, const CoreColor(0xFFFFFFFF));
        expect(vs.inactiveThumb.token, isNull);
        expect(vs.disabledThumb, const CoreColor.token(CoreColors.surface));
        expect(vs.disabledInactiveThumb, const CoreColor(0xFFFFFFFF));
        // The negative controls: the neighbouring tones (`surfaceContainer`
        // for the track, `surface` for the on and off thumbs) must not be
        // what matched, or the expectations above prove nothing.
        expect(
          vs.inactiveTrack,
          isNot(const CoreColor.token(CoreColors.surfaceContainer)),
        );
        expect(
          vs.activeThumb,
          isNot(const CoreColor.token(CoreColors.surface)),
        );
        expect(
          vs.inactiveThumb,
          isNot(const CoreColor.token(CoreColors.surface)),
        );
      },
    );

    // The enabled twin of the disabled floor below: the position mark of an
    // enabled switch has to stand off the track it sits on, in every scheme
    // the contrast gate audits — CoUI's own source, the standard mapping a
    // brand inherits, each in all four modes, and each audited preset.
    //
    // One pose is exempt by design decision: the white off thumb on a light
    // off track (~1.25:1 on CoUI's palette, ~1.75:1 on the standard
    // mapping). Its outline is carried by the default thumb cast instead, so
    // that pose asserts the cast exists and pins a lower floor that a
    // further drift of the off track still fails.
    group('every enabled thumb stands off its own track (≥ 3:1)', () {
      const lightOffFloor = 1.2;
      const graphicsFloor = 3.0;
      final poses = <String, (CoreColor thumb, CoreColor track)>{
        'on': (vs.activeThumb, vs.activeTrack),
        'off': (vs.inactiveThumb, vs.inactiveTrack),
      };

      for (final audited in auditedSchemes()) {
        final scheme = audited.scheme;
        for (final MapEntry(key: pose, value: (thumb, track))
            in poses.entries) {
          test('${audited.key} · $pose', () {
            CoreColor opaque(CoreColor c) =>
                CoreColor(scheme.resolve(c).argb | 0xFF000000);
            final ratio = CoreContrast.ratio(opaque(thumb), opaque(track));
            final castCarriesOutline =
                pose == 'off' && audited.brightness == CoreBrightness.light;
            if (castCarriesOutline) {
              expect(CoreToggleStyle.defaultThumbShadow, isNotEmpty);
            }
            expect(
              ratio,
              greaterThanOrEqualTo(
                castCarriesOutline ? lightOffFloor : graphicsFloor,
              ),
              reason:
                  '$pose thumb on its track is '
                  '${ratio.toStringAsFixed(2)}:1 in ${audited.key}',
            );
          });
        }
      }
    });

    // The thumb is the one mark that says where a switch sits. WCAG exempts
    // disabled controls from the contrast floor, but the graphics floor is
    // still what makes the position readable, so every disabled pose's
    // thumb has to clear it against the track it sits on — measured on every
    // scheme the contrast gate audits (CoUI's own source and the standard
    // mapping, each in all four modes, plus each audited preset).
    //
    // Two light poses sit lower by design decision. The disabled on pose
    // (`surface` thumb) on CoUI's light schemes draws `disabledContent` at
    // neutral 400, which stands off the white thumb at about 2.05:1 —
    // disabled reads lighter
    // than placeholder. The disabled off pose is white on the disabled
    // container (~1.09:1 on CoUI's palette, ~1.26:1 on the standard
    // mapping); its outline is carried by the default thumb cast, as the
    // enabled off thumb's is. The lower floors pin both so a further drift
    // still fails.
    group('every disabled thumb stands off its own track (≥ 3:1)', () {
      const graphicsFloor = 3.0;
      const couiLightFloor = 1.85;
      const lightOffFloor = 1.05;
      final poses = <String, (CoreColor thumb, CoreColor track)>{
        'on': (vs.disabledThumb, vs.disabledActiveTrack),
        'off': (vs.disabledInactiveThumb, vs.disabledInactiveTrack),
      };

      for (final audited in auditedSchemes()) {
        final scheme = audited.scheme;
        for (final MapEntry(key: pose, value: (thumb, track))
            in poses.entries) {
          test('${audited.key} · disabled $pose', () {
            CoreColor opaque(CoreColor c) =>
                CoreColor(scheme.resolve(c).argb | 0xFF000000);
            final ratio = CoreContrast.ratio(opaque(thumb), opaque(track));
            final castCarriesOutline =
                pose == 'off' && audited.brightness == CoreBrightness.light;
            if (castCarriesOutline) {
              expect(CoreToggleStyle.defaultThumbShadow, isNotEmpty);
            }
            final floor = castCarriesOutline
                ? lightOffFloor
                : _isCouiLight(audited.key)
                ? couiLightFloor
                : graphicsFloor;
            expect(
              ratio,
              greaterThanOrEqualTo(floor),
              reason:
                  'disabled $pose thumb on its track is '
                  '${ratio.toStringAsFixed(2)}:1 in ${audited.key}',
            );
          });
        }
      }
    });

    test('disabled is said by the track — on and off differ', () {
      expect(
        vs.disabledActiveTrack,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        vs.disabledInactiveTrack,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(vs.disabledActiveTrack, isNot(vs.disabledInactiveTrack));
      expect(
        vs.disabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test("state layer — standard ramp (8 / 16), ink is the track's own", () {
      expect(CoreToggleStyle.defaultStateLayer, CoreStateLayer.standard);
      expect(CoreToggleStyle.defaultStateLayer.hover, CoreOpacity.opacity8);
      expect(
        CoreToggleStyle.defaultStateLayer.pressed,
        CoreOpacity.opacity16,
      );
      expect(vs.activeStateLayer, const CoreColor.token(CoreColors.surface));
      expect(
        vs.inactiveStateLayer,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('focus outline is a pill around the track; the row ring is off '
        'and the press shrink is left to the Clickable default', () {
      expect(
        CoreToggleStyle.defaultFocusOutlineStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      // The canvas draws the pressed pose as the wash alone, but the code
      // keeps the gesture-time shrink — so the slot must NOT pin it.
      expect(CoreToggleStyle.defaultClickableStyle.pressedScale, isNull);
      expect(
        CoreToggleStyle.defaultClickableStyle.disabledOpacity,
        CoreOpacity.opacity100,
      );
    });
  });
  group('CoreToggleStyle transient lens', () {
    const outset = CoreEdgeInsets.symmetric(horizontal: 8, vertical: 6);
    const chrome = CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    );

    test('lens fields merge, copy and compare like every other field', () {
      const base = CoreToggleStyle(lensOutset: CoreEdgeInsets.zero);
      final merged = base.merge(
        const CoreToggleStyle(
          lensOutset: outset,
          lensContainerStyle: chrome,
          lensFadeFraction: 0.1,
        ),
      );
      expect(merged.lensOutset, outset);
      expect(merged.lensContainerStyle, chrome);
      expect(merged.lensFadeFraction, 0.1);
      // An unset override leaves the base in place.
      expect(base.merge(const CoreToggleStyle()).lensOutset, base.lensOutset);

      final copied = const CoreToggleStyle().copyWith(
        lensOutset: outset,
        lensContainerStyle: chrome,
        lensFadeFraction: 0.1,
      );
      expect(copied, merged);
      expect(copied.hashCode, merged.hashCode);
      expect(
        copied,
        isNot(copied.copyWith(lensOutset: CoreEdgeInsets.zero)),
      );
      expect(
        copied,
        isNot(
          copied.copyWith(
            lensContainerStyle: const CoreOutlinedContainerStyle(
              borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            ),
          ),
        ),
      );
      expect(copied, isNot(copied.copyWith(lensFadeFraction: 0.2)));
    });

    test('the lens chrome slot merges field by field, not wholesale', () {
      // A caller who restates one field keeps the rest of the slot — a
      // tinted lens is still a pill with no cast, not a fresh box.
      const tint = CoreColor.token(CoreColors.primary);
      final merged =
          const CoreToggleStyle(
            lensContainerStyle: CoreOutlinedContainerStyle(
              boxShadow: CoreShadow.none,
            ),
          ).merge(
            const CoreToggleStyle(
              lensContainerStyle: CoreOutlinedContainerStyle(
                backgroundColor: tint,
              ),
            ),
          );
      expect(merged.lensContainerStyle?.backgroundColor, tint);
      expect(merged.lensContainerStyle?.boxShadow, CoreShadow.none);
    });

    test('the default lens is a clear pill that casts nothing', () {
      const lens = CoreToggleStyle.defaultLensContainerStyle;
      expect(lens.backgroundColor, CoreColor.transparent);
      expect(lens.borderColor, CoreColor.transparent);
      expect(lens.borderWidth, CoreStrokeWidth.stroke0);
      expect(lens.borderStyle, CoreOutlinedContainerBorderStyle.none);
      expect(lens.boxShadow, isEmpty);
      expect(lens.padding, CoreEdgeInsets.zero);
      expect(
        lens.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      // The size is the outset's to state — the slot leaves it to the
      // resolvers, which lay the computed size over it.
      expect(lens.width, isNull);
      expect(lens.height, isNull);
    });

    test('the fade fraction leaves room for a hold', () {
      expect(CoreToggleStyle.defaultLensFadeFraction, greaterThan(0));
      expect(
        CoreToggleStyle.defaultLensFadeFraction,
        lessThan(CoreToggleStyle.maxLensFadeFraction),
      );
      // In and out together take the whole travel at the bound.
      expect(CoreToggleStyle.maxLensFadeFraction * 2, 1);
    });

    test('the lens spills past the track on every size', () {
      const lens = CoreToggleStyle.defaultLensOutset;
      // Symmetric — the switch is not a statement about reading direction.
      expect(lens.left, lens.right);
      expect(lens.top, lens.bottom);
      // Wider than tall: a capsule lying along the travel.
      expect(lens.left, greaterThan(lens.top));
      for (final size in CoreToggleStyle.defaultsBySize.keys) {
        final row = CoreToggleStyle.sizeDefaults(size);
        final thumbTop = (row.trackHeight! - row.thumbSize!) / 2;
        expect(
          lens.top,
          greaterThan(thumbTop),
          reason: '$size — the lens reaches past the track edge',
        );
      }
    });
  });
}

/// CoUI's light schemes (plain and preset) — the ones whose disabled
/// content sits at neutral 400 (#5748). High contrast keeps its own step.
// CoUI's light disabled tones (#5748), and those of a brand registered by
// colour — it reads CoUI's mapping for every disabled slot.
bool _isCouiLight(String key) {
  final prefix = key.split(' ').first;
  final couiMapping = prefix == 'coui' || prefix == 'brand';

  return couiMapping &&
      !key.contains('high-contrast') &&
      (key == '$prefix light' || key.endsWith('(light)'));
}
