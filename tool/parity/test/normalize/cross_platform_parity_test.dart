// #3606 completion definition AC2 — "같은 디자인 의도가 양 플랫폼에서 같은
// 정규화 값으로 나옴을 대표 케이스로 확인": one design intent, expressed as
// what each platform's raw capture would actually contain for it, must
// normalize to the same values.
//
// There is no single `normalizeFlutterSnapshot(...)` entry point yet —
// that's Component ②/FlutterCaptureBackend's job (#3376), which runs the
// actual widget-tree extraction inside `flutter test` and isn't built yet.
// This test instead calls the Flutter-side conversion functions directly
// with the primitives that extraction *would* hand them (documented at
// each call site), and compares against `normalizeWebSnapshot`'s output
// for the Web-side capture of the same design intent.
import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';
import '../../src/normalize/flutter_property_normalizer.dart';
import '../../src/normalize/web_property_normalizer.dart';

void main() {
  test(
    'design intent "16px, weight 600, 0.5px tracking, 1.5x line height, '
    'onSurface color" normalizes identically from both platforms\' raw '
    'shapes',
    () {
      // --- Web half: the getComputedStyle() strings a browser would
      // report for an element carrying this design intent. Chrome already
      // resolves lineHeight/letterSpacing to absolute px by the time
      // getComputedStyle() returns them (see
      // web_property_normalizer.dart's own doc comment on this), so the
      // raw fixture states the *already-resolved* px values directly.
      final webRaw = {
        'fontFamily': 'Pretendard, system-ui, sans-serif',
        'fontWeight': '600',
        'fontSize': '16px',
        'lineHeight': '24px', // 1.5 * 16px, pre-resolved by the browser
        'letterSpacing': '0.5px',
        'color': 'rgb(29, 29, 31)',
        'backgroundColor': 'rgb(255, 255, 255)',
        'borderTopColor': 'rgb(0, 0, 0)',
        'borderRightColor': 'rgb(0, 0, 0)',
        'borderBottomColor': 'rgb(0, 0, 0)',
        'borderLeftColor': 'rgb(0, 0, 0)',
        'borderTopWidth': '0px',
        'borderRightWidth': '0px',
        'borderBottomWidth': '0px',
        'borderLeftWidth': '0px',
        'borderTopLeftRadius': '0px',
        'borderTopRightRadius': '0px',
        'borderBottomRightRadius': '0px',
        'borderBottomLeftRadius': '0px',
        'paddingTop': '0px',
        'paddingRight': '0px',
        'paddingBottom': '0px',
        'paddingLeft': '0px',
        'outlineWidth': '0px',
        'outlineOffset': '0px',
        'boxShadow': 'none',
        'opacity': '1',
      };
      final webSnapshot = normalizeWebSnapshot(
        webRaw,
        key: 'k',
        probeRole: 'root',
      );

      // --- Flutter half: the primitives `probeEffectiveTextStyle`
      // (Epic A's widget_tree_probe.dart) would hand a future
      // FlutterCaptureBackend for a `TextStyle` carrying the same intent —
      // `Color.toARGB32()` for 0xFF1D1D1F (rgb(29, 29, 31) fully opaque),
      // `FontWeight.w600.value`, an unitless `TextStyle.height` of 1.5 at
      // a 16px font size, and an absolute-px `TextStyle.letterSpacing` of
      // 0.5 (already past the CoreTextStyle em→px conversion — see
      // flutter_property_normalizer.dart's own doc comment on why this
      // function's input is post-conversion).
      const flutterArgbColor = 0xFF1D1D1F;
      const flutterFontWeightValue = 600;
      const flutterFontSizePx = 16.0;
      const flutterHeightMultiplier = 1.5;
      const flutterLetterSpacingPx = 0.5;

      expect(
        normalizeFlutterArgbColor(flutterArgbColor),
        webSnapshot.color,
        reason: 'color must normalize the same regardless of source format',
      );
      expect(
        normalizeFlutterFontWeight(flutterFontWeightValue),
        webSnapshot.fontWeight,
      );
      expect(flutterFontSizePx, webSnapshot.fontSizePx);
      expect(
        normalizeFlutterLineHeightPx(
          flutterHeightMultiplier,
          flutterFontSizePx,
        ),
        webSnapshot.lineHeightPx,
        reason:
            "Flutter's unitless multiplier × fontSize must land on the "
            "same absolute px the browser already resolved 1.5x line "
            'height to.',
      );
      expect(
        normalizeFlutterLetterSpacingPx(flutterLetterSpacingPx),
        webSnapshot.letterSpacingPx,
      );
    },
  );
}
