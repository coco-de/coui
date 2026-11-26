import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// The widths the canvas members were measured at.
const _kPhonePortraitWidth = 160.0;
const _kPhoneLandscapeWidth = 328.0;
const _kTabletPortraitWidth = 321.0;
const _kTabletLandscapeWidth = 455.0;

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

ResolvedMockupDevice _resolve(
  ComponentTester tester, {
  required CoreMockupDevice device,
  required CoreMockupOrientation orientation,
  required double width,
  CoreMockupDeviceFinish finish = .realistic,
  bool? showCamera = true,
  bool? showStatusBar = true,
  bool? showGestureBar = true,
  CoreMockupDeviceStyle? style,
}) => resolveMockupDevice(
  _themedContext(tester),
  device: device,
  orientation: orientation,
  widgetWidth: width,
  finish: finish,
  showCamera: showCamera,
  showStatusBar: showStatusBar,
  showGestureBar: showGestureBar,
  mockupDeviceStyle: style,
);

/// Resolves a `MockupDevice` under a theme that carries [componentTheme].
ResolvedMockupDevice _resolveUnder(
  ComponentTester tester,
  CoreComponentTheme componentTheme, {
  required CoreMockupDeviceFinish finish,
  double width = 256,
}) {
  late BuildContext context;
  tester.pumpComponent(
    Theme(
      data: ThemeData.coui.copyWith(coreComponentTheme: componentTheme),
      child: _ContextCapture((c) => context = c),
    ),
  );
  return resolveMockupDevice(
    context,
    device: .phone,
    orientation: .portrait,
    widgetWidth: width,
    finish: finish,
  );
}

/// `16px` in the root-font-relative unit every inline dimension emits in.
String _rem(double px) => '${px / 16}rem';

/// Reads an inline `rem` (or `px`) value back as logical px — fractions of the
/// body height land on binary-inexact doubles, so those are compared with a
/// tolerance rather than as strings.
double _px(String? value) {
  final text = value!;
  if (text.endsWith('rem')) {
    return double.parse(text.replaceAll('rem', '')) * 16;
  }
  return double.parse(text.replaceAll('px', ''));
}

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles!.properties;

/// Pins an absolute rectangle to the canvas numbers.
void _expectRect(
  WebElementChrome chrome,
  double left,
  double top,
  double width,
  double height, {
  double tolerance = 1e-6,
}) {
  final p = _props(chrome);
  expect(_px(p['left']), closeTo(left, tolerance), reason: 'left');
  expect(_px(p['top']), closeTo(top, tolerance), reason: 'top');
  expect(_px(p['width']), closeTo(width, tolerance), reason: 'width');
  expect(_px(p['height']), closeTo(height, tolerance), reason: 'height');
}

/// Every chrome slot the resolver produced, for the properties that must hold
/// of all of them.
List<WebElementChrome> _everyChrome(ResolvedMockupDevice r) {
  Iterable<WebElementChrome> item(ResolvedMockupDeviceStatusItem i) => [
    i.root,
    for (final part in i.parts) ...item(part),
  ];

  final bar = r.statusBar;

  return [
    r.root,
    r.frame,
    ?r.rimHighlight,
    ?r.rimGlow,
    ?r.rimGlowRing,
    ...r.antennaBands,
    r.bezel,
    r.screen,
    r.content,
    if (bar != null) ...[
      bar.root,
      bar.leading,
      bar.trailing,
      for (final i in bar.leadingItems) ...item(i),
      for (final i in bar.trailingItems) ...item(i),
    ],
    ...r.screenCameraParts,
    ...r.bezelCameraParts,
    r.gestureBar!,
    ?r.powerButton,
    ?r.volumeUpButton,
    ?r.volumeDownButton,
  ];
}

void main() {
  testComponents('resizing preserves Figma camera and system chrome', (
    tester,
  ) async {
    for (final width in [160.0, 240.0, 320.0]) {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: width,
      );
      expect(_px(_props(r.screenCameraParts.first)['top']), 4);
      final bar = r.statusBar!;
      expect(_px(_props(bar.root)['height']), closeTo(21.13432884, 1e-6));
      final leading = _props(bar.leading);
      expect(
        _px(leading['top']) + _px(leading['height']) / 2,
        closeTo(11.64179104, 1e-6),
      );
      expect(
        _px(leading['left']) + _px(leading['width']) / 2,
        closeTo(26.68656716, 1e-6),
      );
      expect(_px(_props(r.gestureBar!)['width']), closeTo(51.58208955, 1e-6));
      expect(_px(_props(r.content)['padding-top']), closeTo(21.13432884, 1e-6));
    }
  });

  group('resolveMockupDevice — phone upright (160 wide)', () {
    testComponents('root is the positioning context, at the body box', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      expect(r.root.className, contains('relative'));
      expect(r.root.className, contains('inline-flex'));
      expect(_props(r.root)['width'], _rem(160));
      expect(_props(r.root)['height'], _rem(328));
      // The body fills the root; it is a sibling of the rim and the bezel.
      expect(r.frame.className, 'absolute inset-0');
    });

    testComponents('the body is the rail gradient in the composed primitive', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      // The body radius reaches the composed primitive as the token step.
      expect(
        r.frameStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius24),
      );
      expect(
        r.frameStyle.backgroundGradient,
        CoreMockupDeviceStyle.defaultRailGradient,
      );
      expect(
        r.frameStyle.borderColor,
        CoreMockupDeviceStyle.defaultBorderColor,
      );
      expect(
        r.frameStyle.borderWidth,
        CoreMockupDeviceStyle.defaultBorderWidth,
      );
      expect(
        r.frameStyle.boxShadow,
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
      // The cast is black in every mode, not the palette's `shadow` slot,
      // and the dark scope does not strengthen it.
      expect(r.frameStyle.shadowBaseColor, const CoreColor(0xFF000000));
      expect(r.frameStyle.shadowStrengthens, isFalse);
      // The bezel is a sibling of the body, not the primitive's child: no
      // inset.
      expect(r.frameStyle.padding, isNull);
    });

    testComponents('bezel and screen: rail 3 + bezel 5, radii 24 → 21 → 16', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      _expectRect(r.bezel, 3, 3, 154, 322);
      // The screen sits one bezel in from the bezel box (8 from the body).
      _expectRect(r.screen, 5, 5, 144, 312);
      expect(
        _props(r.bezel)['border-radius'],
        const CoreBorderRadius.all(21).toValue(),
      );
      expect(
        _props(r.screen)['border-radius'],
        const CoreBorderRadius.all(16).toValue(),
      );
      expect(r.screen.className, contains('absolute'));
      expect(r.screen.className, contains('overflow-hidden'));
    });

    testComponents('the bezel draws its outline outside and its glow inside', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      final shadow = _props(r.bezel)['box-shadow']!;
      // OUTSIDE ring: a spread shadow, so a half-pixel line is not snapped to
      // a whole device pixel the way a CSS border would be.
      // The outline is the designer copy's literal, inline.
      expect(shadow, startsWith('0 0 0 0.5px rgb(39, 40, 43), '));
      // INNER shadow: no offset, blur 0.5, spread 0.3, the stated alpha.
      expect(shadow, contains('inset 0.0rem 0.0rem 0.03125rem 0.01875rem '));
      expect(
        shadow,
        endsWith(
          CoreMockupDeviceStyle.defaultBezelInnerShadowColor.toValue(),
        ),
      );
      // The fill is the designer copy's black, inline — not a class.
      expect(_props(r.bezel)['background-color'], 'rgb(0, 0, 0)');
      expect(r.bezel.className, isNot(contains('bg-')));
    });

    testComponents('the camera is cut out of the screen, upright', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      expect(r.bezelCameraParts, isEmpty);
      // camera, lens ring, core, glint — back to front.
      expect(r.screenCameraParts, hasLength(4));
      final [camera, lens, core, glint] = r.screenCameraParts;
      _expectRect(camera, 49.5, 4, 45, 13);
      expect(_props(camera)['border-radius'], _rem(6.5));
      _expectRect(lens, 84.75, 7.25, 6.5, 6.5);
      _expectRect(core, 86.05, 8.55, 3.9, 3.9);
      _expectRect(glint, 86.57, 8.81, 1.04, 1.04);
      for (final part in [camera, lens, core, glint]) {
        expect(part.className, contains('absolute'));
      }
      // The pill holds a ring, so it is the cut-out colour; the pill and the
      // ring are both black, the glint white — the designer copy's literals,
      // inline, no class.
      expect(_props(camera)['background-color'], 'rgb(0, 0, 0)');
      expect(_props(lens)['background-color'], 'rgb(0, 0, 0)');
      expect(_props(glint)['background-color'], 'rgb(255, 255, 255)');
      for (final part in [camera, lens, glint]) {
        expect(part.className, isNot(contains('bg-')));
      }
    });

    testComponents('the core is a radial gradient reaching its own edge', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      final core = _props(r.screenCameraParts[2]);
      // `closest-side`: the radius is half the box, the way Flutter's
      // `RadialGradient` draws at its default radius — CSS's own default
      // (`farthest-corner`) would leave the last stops unseen.
      expect(
        core['background-image'],
        startsWith('radial-gradient(circle closest-side at 50% 50%, '),
      );
      // The designer copy's six stops: black at the middle and the rim, a
      // blue glass sheen between them.
      expect(
        core['background-image'],
        'radial-gradient(circle closest-side at 50% 50%, '
        'rgb(0, 0, 0) 20%, '
        'rgb(10, 51, 72) 35%, '
        'rgb(12, 59, 82) 50%, '
        'rgb(16, 81, 113) 62%, '
        'rgb(12, 59, 82) 80%, '
        'rgb(0, 0, 0) 100%)',
      );
      expect(core['background-color'], isNull);
      expect(core['border-radius'], _rem(3.9 / 2));
    });

    testComponents('the home indicator is the opaque bar of the canvas', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      _expectRect(
        r.gestureBar!,
        46.209,
        307.343,
        51.582,
        1.791,
        tolerance: 2e-3,
      );
      // A little under half its height — not a pill.
      expect(_px(_props(r.gestureBar!)['border-radius']), closeTo(0.716, 1e-3));
      expect(r.gestureBar!.className, contains('bg-on-surface'));
      expect(r.gestureBar!.className, isNot(contains('bg-on-surface/')));
    });

    testComponents('buttons: three background layers, shaded toward the body', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      _expectRect(r.volumeUpButton!, -1.5, 65.6, 2, 26);
      _expectRect(r.volumeDownButton!, -1.5, 99.6, 2, 26);
      _expectRect(r.powerButton!, 159.5, 98.4, 2, 40);
      expect(_props(r.volumeUpButton!)['border-radius'], _rem(1));

      for (final button in [r.volumeUpButton!, r.powerButton!]) {
        final p = _props(button);
        // The solid is the bottom layer — the designer copy's grey, inline;
        // the two gradients over it are one property.
        expect(p['background-color'], 'rgb(174, 175, 178)');
        expect(button.className, isNot(contains('bg-')));
        final layers = p['background-image']!;
        // Top layer: the shade across the thickness; then the gloss along the
        // length (top to bottom for a button on a vertical edge).
        expect(layers, matches(RegExp(r'^linear-gradient\(-?90deg, ')));
        expect(layers, contains(', linear-gradient(180deg, '));
      }
      // The body lies to the right of a left-edge button and to the left of a
      // right-edge one: the shade starts on that side.
      expect(
        _props(r.volumeUpButton!)['background-image'],
        startsWith('linear-gradient(-90deg, rgba(0, 0, 0, 0.35) 0%, '),
      );
      expect(
        _props(r.powerButton!)['background-image'],
        startsWith('linear-gradient(90deg, rgba(0, 0, 0, 0.35) 0%, '),
      );
      // The gloss and the shade are optical layers: literals, no variable.
      for (final button in [r.volumeUpButton!, r.powerButton!]) {
        expect(_props(button)['background-image'], isNot(contains('--coui-')));
      }
    });

    testComponents('six antenna bands, rail-thick, pale and translucent', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      expect(r.antennaBands, hasLength(6));
      final expected = [
        (122.441, 0.0, 1.9, 3.0),
        (0.0, 35.782, 3.0, 1.9),
        (157.0, 35.782, 3.0, 1.9),
        (0.0, 290.355, 3.0, 1.9),
        (157.0, 290.355, 3.0, 1.9),
        (31.549, 325.0, 1.9, 3.0),
      ];
      for (final (i, e) in expected.indexed) {
        _expectRect(r.antennaBands[i], e.$1, e.$2, e.$3, e.$4);
        final p = _props(r.antennaBands[i]);
        // A band is a plain rectangle, drawn top to bottom in its own frame
        // whichever way it lies, at the layer opacity.
        expect(p['border-radius'], isNull);
        // The designer copy's pale ramp, top to bottom.
        expect(
          p['background-image'],
          'linear-gradient(180deg, rgb(252, 252, 253) 0%, '
          'rgb(228, 229, 231) 100%)',
        );
        expect(p['opacity'], '0.7');
      }
    });

    testComponents('rim highlight and glow follow the body, not the bezel', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      final body = const CoreBorderRadius.all(CoreRadius.radius24).toValue();

      _expectRect(r.rimHighlight!, 0, 0.4, 160, 327.2);
      expect(_props(r.rimHighlight!)['border-radius'], body);
      // An inset ring, 0.5 wide, white.
      expect(
        _props(r.rimHighlight!)['box-shadow'],
        'inset 0 0 0 0.5px rgb(255, 255, 255)',
      );

      // The glow: a wrapper that blurs and fades what is inside it …
      _expectRect(r.rimGlow!, 0, 0.8, 160, 326.8);
      final wrapper = _props(r.rimGlow!);
      expect(wrapper['opacity'], '0.5');
      // Figma radius 0.8 is a CSS blur of half that: 0.4px.
      expect(wrapper['filter'], 'blur(${0.4 / 16}rem)');
      // … around a ring cut by a mask, so the blur softens the ring itself.
      final ring = _props(r.rimGlowRing!);
      expect(ring['padding'], '0.6px');
      expect(ring['border-radius'], body);
      expect(
        ring['background-image'],
        'linear-gradient(180deg, rgb(255, 255, 255) 0%, '
        'rgba(255, 255, 255, 0.00) 51%)',
      );
      const mask =
          'linear-gradient(#000 0 0) content-box, '
          'linear-gradient(#000 0 0)';
      expect(ring['mask'], mask);
      expect(ring['-webkit-mask'], mask);
      expect(ring['mask-composite'], 'exclude');
      expect(ring['-webkit-mask-composite'], 'xor');
      expect(r.rimGlowRing!.className, 'absolute inset-0');
    });

    testComponents('every stroke of the picture is a literal px width', (
      tester,
    ) async {
      // A width that equals a stroke step would otherwise be emitted as a
      // `--coui-stroke-width-N` reference, which a surface style's stroke
      // floor moves; the Flutter twin never floors these strokes.
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(
          bezelBorderWidth: CoreStrokeWidth.stroke2,
          rimHighlightWidth: CoreStrokeWidth.stroke2,
          rimGlowWidth: CoreStrokeWidth.stroke2,
        ),
      );
      expect(_props(r.bezel)['box-shadow'], startsWith('0 0 0 2px '));
      expect(
        _props(r.rimHighlight!)['box-shadow'],
        startsWith('inset 0 0 0 2px '),
      );
      expect(_props(r.rimGlowRing!)['padding'], '2px');

      // The battery outline remains one point at the fixed authored scale.
      // A caller may explicitly ask for unscaled iOS chrome.
      final unscaled = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: 418,
        style: const CoreMockupDeviceStyle(systemBarReferenceScale: 1),
      );
      final battery = unscaled.statusBar!.trailingItems.last;
      expect(
        _props(battery.parts.first.root)['box-shadow'],
        startsWith('inset 0 0 0 1px '),
      );
    });

    testComponents('the status bar is the clock and three glyphs', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      final bar = r.statusBar!;
      _expectRect(bar.root, 0, 0, 144, 21.134, tolerance: 1e-3);
      // The bar's own fill is the screen's, a class (dark-mode reactive).
      expect(bar.root.className, contains('bg-surface'));
      // A device does not mirror when the text does: the groups lay out left
      // to right under an RTL root too.
      expect(_props(bar.root)['direction'], 'ltr');

      // The clock sits in its wing; the glyphs in theirs, both centred.
      _expectRect(bar.leading, 8.597, 2.149, 36.179, 18.985, tolerance: 1e-3);
      _expectRect(bar.trailing, 99.224, 2.149, 35.463, 18.985, tolerance: 1e-3);
      expect(bar.leading.className, contains('justify-center'));
      expect(bar.trailing.className, contains('justify-center'));
      for (final group in [bar.leading, bar.trailing]) {
        expect(group.className, contains('absolute'));
        expect(group.className, contains('items-center'));
      }

      expect(bar.leadingItems, hasLength(1));
      final clock = bar.leadingItems.single;
      expect(clock.content.text, '9:41');
      // The role's own class and colour, at the bar's scale: the role size
      // read from its variable, times points → px.
      expect(clock.root.className, contains('text-title-small'));
      expect(clock.root.className, contains('text-on-surface'));
      expect(clock.root.className, contains('whitespace-nowrap'));
      expect(
        _props(clock.root)['font-size'],
        'calc(var(--coui-text-title-small-size) * ${144 / 402})',
      );

      expect(bar.trailingItems, hasLength(3));
      final [cellular, wifi, battery] = bar.trailingItems;
      expect(
        cellular.content.path,
        CoreMockupDeviceStyle.phoneCellularGlyph.path,
      );
      expect(cellular.content.viewBox, '0 0 19.2 12.2264');
      expect(cellular.content.fillRule, 'evenodd');
      expect(_px(_props(cellular.root)['width']), closeTo(6.878, 1e-3));
      expect(_px(_props(cellular.root)['height']), closeTo(4.380, 1e-3));
      expect(_px(_props(cellular.root)['margin-right']), closeTo(2.149, 1e-3));
      expect(cellular.root.className, contains('text-on-surface'));
      expect(wifi.content.path, CoreMockupDeviceStyle.phoneWifiGlyph.path);
      expect(_px(_props(wifi.root)['width']), closeTo(6.140, 1e-3));
      expect(_px(_props(wifi.root)['height']), closeTo(4.416, 1e-3));

      // The battery: one box, three parts — outline, level, nub.
      expect(_px(_props(battery.root)['width']), closeTo(9.789, 1e-3));
      expect(_px(_props(battery.root)['height']), closeTo(4.657, 1e-3));
      expect(_props(battery.root)['margin-right'], isNull);
      final [outline, level, nub] = battery.parts;
      _expectRect(outline.root, 0, 0, 8.955, 4.657, tolerance: 1e-3);
      expect(
        _props(outline.root)['box-shadow'],
        startsWith('inset 0 0 0 0.358'),
      );
      expect(
        _props(outline.root)['box-shadow'],
        endsWith(
          CoreMockupDeviceStyle.defaultStatusBarBatteryBorderColor.toValue(),
        ),
      );
      expect(_px(_props(outline.root)['border-radius']), closeTo(1.433, 1e-3));
      _expectRect(level.root, 0.716, 0.716, 7.522, 3.224, tolerance: 1e-3);
      expect(level.root.className, contains('bg-on-surface'));
      expect(_px(_props(level.root)['border-radius']), closeTo(0.716, 1e-3));
      _expectRect(nub.root, 9.313, 1.612, 0.476, 1.460, tolerance: 1e-3);
      expect(nub.root.className, contains('text-on-surface/40'));
      expect(
        nub.content.path,
        CoreMockupDeviceStyle.phoneBatteryCapGlyph.path,
      );
      expect(nub.content.fillRule, 'nonzero');
    });
  });

  group('resolveMockupDevice — phone on its side (328 wide)', () {
    testComponents('draws no status bar', (tester) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      expect(r.statusBar, isNull);
      expect(_props(r.root)['width'], _rem(328));
      expect(_props(r.root)['height'], _rem(160));
    });

    testComponents("the camera stands on the screen's left edge", (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      _expectRect(r.screen, 5, 5, 312, 144);
      expect(r.bezelCameraParts, isEmpty);
      final [camera, lens, core, glint] = r.screenCameraParts;
      _expectRect(camera, 4, 49.5, 13, 45);
      _expectRect(lens, 7.25, 52.75, 6.5, 6.5);
      _expectRect(core, 8.55, 54.05, 3.9, 3.9);
      // The glint stays up and to the left of the core in every pose.
      _expectRect(glint, 9.07, 54.31, 1.04, 1.04);
    });

    testComponents('buttons and antenna bands are carried one edge round', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      _expectRect(r.volumeUpButton!, 65.6, -1.5, 26, 2);
      _expectRect(r.volumeDownButton!, 99.6, -1.5, 26, 2);
      _expectRect(r.powerButton!, 189.6, 159.5, 40, 2);

      // A button on a horizontal edge is shaded across its thickness toward
      // the body (below a top-edge button, above a bottom-edge one) and
      // glossed along its length, left to right.
      expect(
        _props(r.volumeUpButton!)['background-image'],
        startsWith('linear-gradient(0deg, rgba(0, 0, 0, 0.35) 0%, '),
      );
      expect(
        _props(r.volumeUpButton!)['background-image'],
        contains(', linear-gradient(90deg, '),
      );
      expect(
        _props(r.powerButton!)['background-image'],
        startsWith('linear-gradient(180deg, rgba(0, 0, 0, 0.35) 0%, '),
      );

      final expected = [
        (325.0, 122.441, 3.0, 1.9),
        (35.782, 0.0, 1.9, 3.0),
        (35.782, 157.0, 1.9, 3.0),
        (290.355, 0.0, 1.9, 3.0),
        (290.355, 157.0, 1.9, 3.0),
        (0.0, 31.549, 3.0, 1.9),
      ];
      expect(r.antennaBands, hasLength(6));
      for (final (i, e) in expected.indexed) {
        _expectRect(r.antennaBands[i], e.$1, e.$2, e.$3, e.$4);
      }
    });

    testComponents('the rim keeps the body width and insets top and bottom', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      _expectRect(r.rimHighlight!, 0, 0.4, 328, 159.2);
      _expectRect(r.rimGlow!, 0, 0.8, 328, 158.8);
      // The glow still fades top to bottom.
      expect(
        _props(r.rimGlowRing!)['background-image'],
        startsWith('linear-gradient(180deg, '),
      );
    });

    testComponents('the home indicator is the wider bar of a turned phone', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      _expectRect(
        r.gestureBar!,
        118.696,
        139.359,
        74.609,
        1.785,
        tolerance: 2e-3,
      );
    });
  });

  group('resolveMockupDevice — tablet (321 × 455 / 455 × 321)', () {
    testComponents('rail 3 + bezel 8, radii 16 → 13 → 5', (tester) async {
      final r = _resolve(
        tester,
        device: .tablet,
        orientation: .portrait,
        width: _kTabletPortraitWidth,
      );
      expect(
        r.frameStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(_props(r.root)['height'], _rem(455));
      _expectRect(r.bezel, 3, 3, 315, 449);
      _expectRect(r.screen, 8, 8, 299, 433);
      expect(
        _props(r.bezel)['border-radius'],
        const CoreBorderRadius.all(13).toValue(),
      );
      expect(
        _props(r.screen)['border-radius'],
        const CoreBorderRadius.all(5).toValue(),
      );
    });

    testComponents('the camera is in the bezel strip, with no lens ring', (
      tester,
    ) async {
      final portrait = _resolve(
        tester,
        device: .tablet,
        orientation: .portrait,
        width: _kTabletPortraitWidth,
      );
      expect(portrait.screenCameraParts, isEmpty);
      // camera, core, glint — the round cut-out is the lens.
      expect(portrait.bezelCameraParts, hasLength(3));
      final [camera, core, glint] = portrait.bezelCameraParts;
      _expectRect(camera, 155.5, 2, 4, 4);
      _expectRect(core, 156.3, 2.8, 2.4, 2.4);
      _expectRect(glint, 156.62, 2.96, 0.64, 0.64);
      expect(_props(camera)['background-color'], 'rgb(0, 0, 0)');
      expect(camera.className, isNot(contains('bg-')));
      expect(_props(glint)['background-color'], 'rgb(255, 255, 255)');

      // The strip stays on top when the tablet is turned; it re-centres.
      final landscape = _resolve(
        tester,
        device: .tablet,
        orientation: .landscape,
        width: _kTabletLandscapeWidth,
      );
      expect(landscape.screenCameraParts, isEmpty);
      _expectRect(landscape.bezelCameraParts[0], 222.5, 2, 4, 4);
    });

    testComponents('no antenna bands, one rocker, per-orientation buttons', (
      tester,
    ) async {
      final portrait = _resolve(
        tester,
        device: .tablet,
        orientation: .portrait,
        width: _kTabletPortraitWidth,
      );
      expect(portrait.antennaBands, isEmpty);
      expect(portrait.volumeDownButton, isNull);
      _expectRect(
        portrait.powerButton!,
        238.096,
        -1.5,
        45.433,
        2,
        tolerance: 1e-3,
      );
      _expectRect(
        portrait.volumeUpButton!,
        -1.5,
        83.642,
        2,
        33.317,
        tolerance: 1e-3,
      );

      final landscape = _resolve(
        tester,
        device: .tablet,
        orientation: .landscape,
        width: _kTabletLandscapeWidth,
      );
      expect(landscape.antennaBands, isEmpty);
      _expectRect(
        landscape.powerButton!,
        454.5,
        49.748,
        2,
        49.522,
        tolerance: 1e-3,
      );
      _expectRect(
        landscape.volumeUpButton!,
        282.343,
        -1.5,
        36.316,
        2,
        tolerance: 1e-3,
      );
    });

    testComponents('the status bar hugs both edges, in both poses', (
      tester,
    ) async {
      for (final (orientation, width, screenWidth) in [
        (CoreMockupOrientation.portrait, _kTabletPortraitWidth, 299.0),
        (CoreMockupOrientation.landscape, _kTabletLandscapeWidth, 433.0),
      ]) {
        final r = _resolve(
          tester,
          device: .tablet,
          orientation: orientation,
          width: width,
        );
        final bar = r.statusBar!;
        _expectRect(bar.root, 0, 0, screenWidth, 11.463, tolerance: 1e-3);
        // No wings: one box between the two insets, the groups pushed to its
        // ends.
        _expectRect(
          bar.leading,
          5.731,
          0,
          screenWidth - 2 * 5.731,
          11.463,
          tolerance: 1e-3,
        );
        expect(bar.leading.className, contains('justify-start'));
        expect(bar.trailing.className, contains('justify-end'));

        expect(
          [for (final i in bar.leadingItems) i.content.text],
          ['9:41', '오전', '4월 1일 수요일'],
        );
        // The gaps: clock → meridiem 0.716, meridiem → date 2.866.
        expect(
          _px(_props(bar.leadingItems[0].root)['margin-right']),
          closeTo(0.716, 1e-3),
        );
        expect(
          _px(_props(bar.leadingItems[1].root)['margin-right']),
          closeTo(2.866, 1e-3),
        );
        expect(
          bar.leadingItems.last.root.className,
          contains('text-label-large'),
        );
        // The tablet is authored at the phone's scale, so each pose has its
        // own reference width.
        final reference = screenWidth == 299.0
            ? 834.7083333333334
            : 1208.7916666666667;
        expect(
          _props(bar.leadingItems.first.root)['font-size'],
          'calc(var(--coui-text-label-large-size) * '
          '${screenWidth / reference})',
        );

        // Wifi, "100%", battery — the battery is one drawing here.
        final [wifi, level, battery] = bar.trailingItems;
        expect(wifi.content.path, CoreMockupDeviceStyle.tabletWifiGlyph.path);
        expect(level.content.text, '100%');
        expect(
          battery.content.path,
          CoreMockupDeviceStyle.tabletBatteryGlyph.path,
        );
        expect(battery.parts, isEmpty);
        expect(_px(_props(battery.root)['width']), closeTo(9.791, 1e-3));
        expect(_px(_props(wifi.root)['margin-right']), closeTo(1.433, 1e-3));
      }
    });

    testComponents('the home indicator is 314 points wide in both poses', (
      tester,
    ) async {
      final portrait = _resolve(
        tester,
        device: .tablet,
        orientation: .portrait,
        width: _kTabletPortraitWidth,
      );
      _expectRect(
        portrait.gestureBar!,
        93.261,
        428.343,
        112.478,
        1.791,
        tolerance: 2e-3,
      );
      final landscape = _resolve(
        tester,
        device: .tablet,
        orientation: .landscape,
        width: _kTabletLandscapeWidth,
      );
      _expectRect(
        landscape.gestureBar!,
        160.261,
        294.343,
        112.478,
        1.791,
        tolerance: 2e-3,
      );
    });
  });

  group('resolveMockupDevice — the safe area reserves four sides', () {
    // Each Show flag releases exactly its own inset.
    Map<String, double> insets(ResolvedMockupDevice r) {
      final p = _props(r.content);
      return {
        for (final side in ['top', 'right', 'bottom', 'left'])
          side: _px(p['padding-$side']),
      };
    }

    testComponents('phone upright: status bar, camera and bar', (tester) async {
      ResolvedMockupDevice phone({
        bool camera = true,
        bool status = true,
        bool bar = true,
      }) => _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        showCamera: camera,
        showStatusBar: status,
        showGestureBar: bar,
      );

      expect(insets(phone())['top'], closeTo(21.134, 1e-3));
      expect(insets(phone())['bottom'], closeTo(12.179, 1e-3));
      expect(insets(phone())['left'], 0);
      expect(insets(phone())['right'], 0);
      // The camera alone: its reach + the same gap on the content side.
      expect(insets(phone(status: false))['top'], closeTo(21, 1e-6));
      // The status bar alone.
      expect(insets(phone(camera: false))['top'], closeTo(21.134, 1e-3));
      expect(insets(phone(camera: false, status: false))['top'], 0);
      expect(insets(phone(bar: false))['bottom'], 0);
      expect(insets(phone(bar: false))['top'], closeTo(21.134, 1e-3));
    });

    testComponents('phone on its side: the camera takes the left', (
      tester,
    ) async {
      ResolvedMockupDevice phone({bool camera = true, bool status = true}) =>
          _resolve(
            tester,
            device: .phone,
            orientation: .landscape,
            width: _kPhoneLandscapeWidth,
            showCamera: camera,
            showStatusBar: status,
          );

      final all = insets(phone());
      expect(all['left'], closeTo(21, 1e-6));
      expect(all['top'], 0);
      expect(all['right'], 0);
      expect(all['bottom'], closeTo(7.497, 1e-3));
      expect(insets(phone(camera: false))['left'], 0);
      // There is no bar to release on its side.
      expect(insets(phone(status: false)), all);
    });

    testComponents('tablet: the bar reserves the top, the bezel camera not', (
      tester,
    ) async {
      for (final (orientation, width) in [
        (CoreMockupOrientation.portrait, _kTabletPortraitWidth),
        (CoreMockupOrientation.landscape, _kTabletLandscapeWidth),
      ]) {
        ResolvedMockupDevice tablet({bool status = true, bool camera = true}) =>
            _resolve(
              tester,
              device: .tablet,
              orientation: orientation,
              width: width,
              showStatusBar: status,
              showCamera: camera,
            );

        expect(insets(tablet())['top'], closeTo(11.463, 1e-3));
        expect(insets(tablet())['bottom'], closeTo(7.164, 1e-3));
        expect(insets(tablet(status: false))['top'], 0);
        expect(insets(tablet(camera: false))['top'], closeTo(11.463, 1e-3));
      }
    });
  });

  group('resolveMockupDevice — colour (theme-free emit)', () {
    testComponents('hardware colours are inline literals, no token class', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      // A raw fill goes inline, so the colour is the designer copy's whatever
      // the mode or the palette — no class for the browser to re-resolve.
      expect(_props(r.bezel)['background-color'], 'rgb(0, 0, 0)');
      expect(r.bezel.className, isNot(contains('bg-')));
      for (final button in [
        r.powerButton!,
        r.volumeUpButton!,
        r.volumeDownButton!,
      ]) {
        expect(_props(button)['background-color'], 'rgb(174, 175, 178)');
        expect(button.className, isNot(contains('bg-')));
      }
      // The side button has a colour of its own — it does not follow the
      // rail.
      expect(
        _props(r.powerButton!)['background-color'],
        isNot(CoreMockupDeviceStyle.defaultRailColor.toValue()),
      );
    });

    testComponents("the body is the copy's literals too", (tester) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      // The body is the composed OutlinedContainer's: the rail gradient and
      // the rim reach it as raw Core values (it emits them), and they are the
      // designer copy's literals.
      final gradient = r.frameStyle.backgroundGradient!;
      expect([for (final c in gradient.colors) c.token], List.filled(4, null));
      expect(
        [for (final c in gradient.colors) c.argb],
        [
          0xFFC3C4C6,
          0xFF7D7F82,
          0xFF7D7F82,
          0xFFAEAFB2,
        ],
      );
      expect(gradient.stops, [0, 0.1, 0.9, 1]);
      expect(r.frameStyle.borderColor, const CoreColor(0xFF646568));
    });

    testComponents('the hardware names no colour variable, in every pose', (
      tester,
    ) async {
      // The hardware is the device: frame, rim, antenna, buttons, bezel,
      // camera. Its colours are the designer copy's literals, so none of it
      // names a token — neither a slot that follows the mode nor a fixed one,
      // which a brand palette would still tint. The screen, the status bar
      // and the home indicator are not hardware; they follow the mode and are
      // not read here.
      final reference = RegExp(r'rgb\(var\(--coui-([a-z0-9-]+)\)');
      final colourClass = RegExp(
        r'(?:^|\s)(?:bg|border|text)-([a-z0-9-]+)(?:/\d+)?(?=\s|$)',
      );
      const layout = {'transparent', 'inherit', 'current'};

      for (final (device, orientation, width) in [
        (CoreMockupDevice.phone, CoreMockupOrientation.portrait, 160.0),
        (CoreMockupDevice.phone, CoreMockupOrientation.landscape, 328.0),
        (CoreMockupDevice.tablet, CoreMockupOrientation.portrait, 321.0),
        (CoreMockupDevice.tablet, CoreMockupOrientation.landscape, 455.0),
      ]) {
        final r = _resolve(
          tester,
          device: device,
          orientation: orientation,
          width: width,
        );
        final named = <String>{};
        var inline = 0;
        for (final chrome in [
          r.rimHighlight!,
          r.rimGlow!,
          r.rimGlowRing!,
          ...r.antennaBands,
          r.bezel,
          ...r.screenCameraParts,
          ...r.bezelCameraParts,
          r.powerButton!,
          r.volumeUpButton!,
          ?r.volumeDownButton,
        ]) {
          named.addAll(
            colourClass
                .allMatches(chrome.className)
                .map((m) => m.group(1)!)
                .where((name) => !layout.contains(name)),
          );
          for (final value in _props(chrome).values) {
            named.addAll(reference.allMatches(value).map((m) => m.group(1)!));
            if (value.contains('rgb(') && !value.contains('var(')) inline++;
          }
        }
        final frame = r.frameStyle;
        named.addAll([
          for (final c in frame.backgroundGradient!.colors) ?c.token?.name,
          ?frame.borderColor!.token?.name,
        ]);

        // Not vacuous: the hardware does paint colours, inline.
        expect(inline, greaterThan(0), reason: '$device $orientation');
        expect(
          named,
          isEmpty,
          reason: '$device $orientation names a colour token',
        );
      }
    });

    testComponents('the optical layers are literals, never a slot', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      // White fading to clear, the gloss and shade over a button, and the
      // faint light along the bezel's inside are partial-alpha white or black
      // laid over the hardware: the same in every mode, so no variable.
      expect(
        _props(r.rimGlowRing!)['background-image'],
        isNot(contains('--coui-')),
      );
      expect(
        _props(r.powerButton!)['background-image'],
        isNot(contains('--coui-')),
      );
      expect(
        _props(r.bezel)['box-shadow'],
        endsWith(CoreMockupDeviceStyle.defaultBezelInnerShadowColor.toValue()),
      );
      expect(
        CoreMockupDeviceStyle.defaultBezelInnerShadowColor.toValue(),
        isNot(contains('--coui-')),
      );
    });

    testComponents('the cast under the body names no variable of the mode', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      final body = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: r.frameStyle,
      );
      final cast = body.root.inlineStyles!.properties['box-shadow']!;
      final ink = CoreMockupDeviceStyle.defaultContainerStyle.shadowBaseColor!;

      // The palette's `--coui-shadow` colour is the brand's to state and
      // `--shadow-*` is built from it; either one in the value would tint
      // the device's black by the brand. The dark scope's strength does not
      // reach it either: the device draws v1's two layers at their own
      // alpha in every mode (#5485).
      expect(cast, isNot(contains('var(--coui-shadow)')));
      expect(cast, isNot(contains('--shadow-')));
      expect(cast, isNot(contains('--coui-shadow-strength')));
      expect(
        cast,
        startsWith(
          '0.0rem 0.875rem 1.75rem -0.3125rem '
          'color-mix(in srgb, ${ink.toValue()} 8%, transparent), '
          '0.0rem 0.375rem 0.625rem -0.1875rem '
          'color-mix(in srgb, ${ink.toValue()} 5%, transparent)',
        ),
      );
    });

    testComponents('a stated token still rides a class, a raw one is inline', (
      tester,
    ) async {
      final token = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(
          bezelColor: CoreColor.token(CoreColors.primary),
          lensHighlightColor: CoreColor.token(CoreColors.primary),
          buttonColor: CoreColor.token(CoreColors.secondary),
        ),
      );
      expect(token.bezel.className, contains('bg-primary'));
      expect(_props(token.bezel)['background-color'], isNull);
      // A stated glint colour replaces the default literal.
      expect(token.screenCameraParts.last.className, contains('bg-primary'));
      expect(
        _props(token.screenCameraParts.last)['background-color'],
        isNull,
      );
      expect(token.powerButton!.className, contains('bg-secondary'));

      final raw = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(
          lensHighlightColor: CoreColor(0x80FFFFFF),
        ),
      );
      final glint = raw.screenCameraParts.last;
      expect(glint.className, 'absolute');
      expect(_props(glint)['background-color'], 'rgba(255, 255, 255, 0.50)');
    });

    testComponents('a stated solid beats the default gradient', (tester) async {
      const solid = CoreColor(0xFF112233);
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(railColor: solid),
      );
      // The frame colour a theme folds into `railColor` still wins.
      expect(r.frameStyle.backgroundColor, solid);
      expect(r.frameStyle.backgroundGradient, isNull);

      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFF000000), CoreColor(0xFFFFFFFF)],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      );
      final stated = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(
          railColor: solid,
          railGradient: gradient,
        ),
      );
      expect(stated.frameStyle.backgroundGradient, gradient);
    });

    testComponents('a stated cut-out colour makes the core a solid', (
      tester,
    ) async {
      const style = CoreMockupDeviceStyle(
        cutoutColor: CoreColor(0xFF010203),
        lensColor: CoreColor(0xFF405060),
      );
      final phone = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: style,
      );
      final [camera, lens, core, _] = phone.screenCameraParts;
      // The pill holds a ring — `cutoutColor` reaches the whole pill and,
      // stated, the core too.
      expect(
        _props(camera)['background-color'],
        const CoreColor(0xFF010203).toValue(),
      );
      expect(
        _props(lens)['background-color'],
        const CoreColor(0xFF405060).toValue(),
      );
      expect(
        _props(core)['background-color'],
        const CoreColor(0xFF010203).toValue(),
      );
      expect(_props(core)['background-image'], isNull);

      final tablet = _resolve(
        tester,
        device: .tablet,
        orientation: .portrait,
        width: _kTabletPortraitWidth,
        style: style,
      );
      // No ring — the round cut-out is the lens.
      expect(
        _props(tablet.bezelCameraParts[0])['background-color'],
        const CoreColor(0xFF405060).toValue(),
      );
      expect(
        _props(tablet.bezelCameraParts[1])['background-color'],
        const CoreColor(0xFF010203).toValue(),
      );
    });

    testComponents('the screen and the bars follow the scheme via classes', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      expect(r.screen.className, contains('bg-surface'));
      expect(_props(r.screen)['background-color'], isNull);
      expect(r.gestureBar!.className, contains('bg-on-surface'));
      expect(r.statusBar!.root.className, contains('bg-surface'));
    });

    testComponents('style overrides flow through', (tester) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        style: const CoreMockupDeviceStyle(
          bezelColor: CoreColor(0xFF112233),
          backgroundColor: CoreColor.token(CoreColors.primary),
          statusBarIconColor: CoreColor.token(CoreColors.primary),
          antennaOpacity: 0.25,
          rimGlowBlur: 0,
          statusBarTextStyle: CoreTextStyle(fontSize: 20),
        ),
      );
      expect(
        _props(r.bezel)['background-color'],
        const CoreColor(0xFF112233).toValue(),
      );
      expect(r.screen.className, contains('bg-primary'));
      expect(r.statusBar!.root.className, contains('bg-primary'));
      expect(
        r.statusBar!.trailingItems.first.root.className,
        contains('text-primary'),
      );
      expect(_props(r.antennaBands.first)['opacity'], '0.25');
      // No blur stated, no filter emitted.
      expect(_props(r.rimGlow!)['filter'], isNull);
      // A stated size is shrunk to the bar's scale instead of the role's.
      expect(
        _props(r.statusBar!.leadingItems.single.root)['font-size'],
        _rem(20 * (144 / 402)),
      );
    });
  });

  group('resolveMockupDevice — nothing is chrome a caller could inject', () {
    testComponents('geometry is rem, classes are layout or a token', (
      tester,
    ) async {
      // A class is allowed to be layout, or a colour/typography token the emit
      // family chose; anything else (shadow, radius, opacity …) would be
      // chrome a caller could also have put through `classes`.
      final allowed = RegExp(
        '^(absolute|relative|inline-flex|flex|items-center|inset-0|'
        'overflow-hidden|whitespace-nowrap|shrink-0|justify-(start|end|center)|'
        'bg-(surface|on-surface)|'
        r'text-(on-surface(/\d+)?|title-small|label-large))$',
      );
      for (final (device, orientation, width) in [
        (CoreMockupDevice.phone, CoreMockupOrientation.portrait, 160.0),
        (CoreMockupDevice.phone, CoreMockupOrientation.landscape, 328.0),
        (CoreMockupDevice.tablet, CoreMockupOrientation.portrait, 321.0),
        (CoreMockupDevice.tablet, CoreMockupOrientation.landscape, 455.0),
      ]) {
        final r = _resolve(
          tester,
          device: device,
          orientation: orientation,
          width: width,
        );
        for (final chrome in _everyChrome(r)) {
          for (final name in chrome.className.split(' ')) {
            if (name.isEmpty) continue;
            expect(name, matches(allowed), reason: '$device $orientation');
          }
          final p = chrome.inlineStyles?.properties ?? const {};
          for (final key in [
            'left',
            'top',
            'width',
            'height',
            'margin-right',
            'padding-top',
            'padding-right',
            'padding-bottom',
            'padding-left',
          ]) {
            final value = p[key];
            if (value == null) continue;
            expect(value, endsWith('rem'), reason: '$key of $device');
          }
        }
      }
    });
  });

  group('MockupDevice widget', () {
    for (final device in CoreMockupDevice.values) {
      testComponents('$device backgroundColor is shared with the safe area', (
        tester,
      ) async {
        const background = CoreColor(0xFFFFE0B2);
        pumpWithTheme(
          tester,
          MockupDevice(
            device: device,
            width: _kPhonePortraitWidth,
            mockupDeviceStyle: const CoreMockupDeviceStyle(
              backgroundColor: background,
            ),
            child: div(
              const [Component.text('content')],
              styles: Styles(
                raw: {
                  'background-color': background.toValue(),
                },
              ),
            ),
          ),
        );
        final backgrounds = find
            .ancestor(of: find.text('content'), matching: find.tag('div'))
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where(
              (c) =>
                  c.styles?.properties['background-color'] ==
                  background.toValue(),
            )
            .toList();
        expect(backgrounds, hasLength(2)); // child and full screen
        expect(backgrounds.last.styles!.properties['height'], isNotNull);
        final safeArea =
            find
                    .byComponentPredicate(
                      (c) =>
                          c is DomComponent &&
                          (c.styles?.properties.containsKey('padding-top') ??
                              false),
                    )
                    .evaluate()
                    .single
                    .component
                as DomComponent;
        expect(safeArea.styles!.properties['background-color'], isNull);
      });
    }

    for (final device in CoreMockupDevice.values) {
      for (final showCamera in [true, false]) {
        for (final showStatusBar in [true, false]) {
          for (final showGestureBar in [true, false]) {
            testComponents(
              '$device camera=$showCamera statusBar=$showStatusBar '
              'gestureBar=$showGestureBar draws only what is shown',
              (tester) async {
                final mockup = MockupDevice(
                  device: device,
                  width: _kPhonePortraitWidth,
                  mockupDeviceStyle: const CoreMockupDeviceStyle(
                    cutoutColor: CoreColor(0xFF010203),
                    lensColor: CoreColor(0xFF405060),
                    gestureBarColor: CoreColor(0xFF123456),
                    buttonColor: CoreColor(0xFF708090),
                  ),
                  child: const Component.text('screen'),
                );
                pumpWithTheme(
                  tester,
                  mockup.copyWith(
                    showCamera: showCamera,
                    showStatusBar: showStatusBar,
                    showGestureBar: showGestureBar,
                  ),
                );
                Finder painted(CoreColor color) => find.byComponentPredicate(
                  (component) =>
                      component is DomComponent &&
                      component.styles?.properties['background-color'] ==
                          color.toValue(),
                );
                // The pill (phone) and the core hold the cut-out colour; the
                // tablet's camera is the lens, so only its core does.
                expect(
                  painted(const CoreColor(0xFF010203)),
                  findsNComponents(showCamera ? (device == .phone ? 2 : 1) : 0),
                );
                expect(
                  painted(const CoreColor(0xFF405060)),
                  findsNComponents(showCamera ? 1 : 0),
                );
                expect(
                  painted(const CoreColor(0xFF123456)),
                  findsNComponents(showGestureBar ? 1 : 0),
                );
                // Hardware buttons are never hidden by a flag.
                expect(
                  painted(const CoreColor(0xFF708090)),
                  findsNComponents(device == .phone ? 3 : 2),
                );
                expect(find.text('screen'), findsOneComponent);
                expect(
                  find.text('9:41'),
                  findsNComponents(showStatusBar ? 1 : 0),
                );
              },
            );
          }
        }
      }
    }

    testComponents('a phone on its side ignores showStatusBar', (tester) async {
      pumpWithTheme(
        tester,
        const MockupDevice(
          orientation: .landscape,
          width: _kPhoneLandscapeWidth,
          child: Component.text('screen'),
        ),
      );
      expect(find.text('9:41'), findsNothing);
    });

    testComponents('the tablet status bar says its three texts', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MockupDevice(
          device: .tablet,
          width: _kTabletPortraitWidth,
          child: Component.text('screen'),
        ),
      );
      for (final text in ['9:41', '오전', '4월 1일 수요일', '100%']) {
        expect(find.text(text), findsOneComponent);
      }
    });

    testComponents('the safe-area wrapper pads all four sides', (tester) async {
      pumpWithTheme(
        tester,
        const MockupDevice(
          orientation: .landscape,
          width: _kPhoneLandscapeWidth,
          child: Component.text('screen'),
        ),
      );
      final wrapper =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent &&
                        (c.styles?.properties.containsKey('padding-left') ??
                            false),
                  )
                  .evaluate()
                  .single
                  .component
              as DomComponent;
      final p = wrapper.styles!.properties;
      expect(wrapper.classes, 'absolute inset-0');
      expect(_px(p['padding-left']), closeTo(21, 1e-6));
      expect(p['padding-top'], _rem(0));
      expect(p['padding-right'], _rem(0));
      expect(_px(p['padding-bottom']), closeTo(7.497, 1e-3));
      expect(p['box-sizing'], 'border-box');
    });

    testComponents('safe insets follow oversized lens overrides', (
      tester,
    ) async {
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        showStatusBar: false,
        style: const CoreMockupDeviceStyle(
          cameraOffset: 12,
          cameraHeight: 20,
          lensSize: 60,
          gestureBarHeight: 100,
          gestureBarOffset: 100,
        ),
      );
      final top = _px(_props(r.content)['padding-top']);
      // The lens reaches past the pill; the child cannot intrude into it.
      expect(top, greaterThan(60));
      // The bar's own footprint wins over the (smaller) area when it reaches
      // higher.
      expect(
        _px(_props(r.content)['padding-bottom']),
        closeTo((100 + 100) * (144 / 402), 1e-6),
      );
    });

    test('copyWith and style chains preserve independent visibility', () {
      const mockup = MockupDevice(child: Component.text('screen'));
      // Unstated follows the finish — see 'MockupDevice finish'.
      expect(mockup.showCamera, isNull);
      expect(mockup.showStatusBar, isNull);
      expect(mockup.showGestureBar, isNull);
      final hidden = mockup.copyWith(
        showCamera: false,
        showStatusBar: false,
        showGestureBar: false,
      );
      final styled = hidden.copyWith(width: 240).radius8.primary;
      expect(styled.showCamera, isFalse);
      expect(styled.showStatusBar, isFalse);
      expect(styled.showGestureBar, isFalse);
      final cameraOnly = styled.copyWith(showCamera: true);
      expect(cameraOnly.showCamera, isTrue);
      expect(cameraOnly.showStatusBar, isFalse);
      expect(cameraOnly.showGestureBar, isFalse);
      final statusOnly = hidden.copyWith(showStatusBar: true);
      expect(statusOnly.showCamera, isFalse);
      expect(statusOnly.showStatusBar, isTrue);
      expect(statusOnly.showGestureBar, isFalse);
      final barOnly = hidden.copyWith(showGestureBar: true);
      expect(barOnly.showCamera, isFalse);
      expect(barOnly.showStatusBar, isFalse);
      expect(barOnly.showGestureBar, isTrue);
    });

    testComponents('renders the composed body with the child on the screen', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MockupDevice(
          width: _kPhonePortraitWidth,
          child: Component.text('screen'),
        ),
      );
      expect(find.text('screen'), findsOneComponent);
      expect(find.byType(OutlinedContainer), findsOneComponent);
      expect(find.byType(MockupDevice), findsOneComponent);
    });
  });

  group('MockupDevice finish', () {
    const flatWidth = 256.0;

    ResolvedMockupDevice flat(
      ComponentTester tester, {
      CoreMockupDevice device = .phone,
      CoreMockupOrientation orientation = .portrait,
      bool? showCamera,
      bool? showStatusBar,
      bool? showGestureBar,
      CoreMockupDeviceStyle? style,
    }) => _resolve(
      tester,
      device: device,
      orientation: orientation,
      width: flatWidth,
      finish: .flat,
      showCamera: showCamera,
      showStatusBar: showStatusBar,
      showGestureBar: showGestureBar,
      style: style,
    );

    testComponents('realistic is the default and keeps every layer', (
      tester,
    ) async {
      const mockup = MockupDevice(child: Component.text('screen'));
      expect(mockup.finish, CoreMockupDeviceFinish.realistic);
      final r = _resolve(
        tester,
        device: .phone,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
        showCamera: null,
        showStatusBar: null,
        showGestureBar: null,
      );
      expect(r.screenCameraParts, isNotEmpty);
      expect(r.statusBar, isNotNull);
      expect(r.gestureBar, isNotNull);
      expect(r.powerButton, isNotNull);
      expect(r.volumeUpButton, isNotNull);
      expect(r.volumeDownButton, isNotNull);
      expect(r.rimHighlight, isNotNull);
      expect(r.rimGlow, isNotNull);
      expect(r.rimGlowRing, isNotNull);
      expect(r.antennaBands, hasLength(6));
      expect(_props(r.bezel)['box-shadow'], isNotNull);
      expect(
        r.frameStyle.boxShadow,
        CoreMockupDeviceStyle.defaultBodyShadow,
      );
      expect(_props(r.bezel)['background-color'], 'rgb(0, 0, 0)');
    });

    for (final device in CoreMockupDevice.values) {
      for (final orientation in CoreMockupOrientation.values) {
        testComponents('flat $device $orientation emits no hardware part', (
          tester,
        ) async {
          final r = flat(tester, device: device, orientation: orientation);
          expect(r.powerButton, isNull);
          expect(r.volumeUpButton, isNull);
          expect(r.volumeDownButton, isNull);
          expect(r.antennaBands, isEmpty);
          expect(r.rimHighlight, isNull);
          expect(r.rimGlow, isNull);
          expect(r.rimGlowRing, isNull);
          expect(r.frameStyle.boxShadow, isEmpty);
          expect(r.frameStyle.borderWidth, 0);
          expect(r.screenCameraParts, isEmpty);
          expect(r.bezelCameraParts, isEmpty);
          expect(r.statusBar, isNull);
          expect(r.gestureBar, isNull);
          // No bezel line or inner glow: no shadow property at all.
          expect(_props(r.bezel).containsKey('box-shadow'), isFalse);
          // The screen sits one ring in, with the derived radius.
          expect(_px(_props(r.screen)['left']), 8);
          expect(_px(_props(r.screen)['top']), 8);
          expect(_px(_props(r.screen)['width']), 240);
          expect(
            _px(_props(r.screen)['height']),
            orientation == CoreMockupOrientation.landscape ? 120 : 480,
          );
          expect(
            _props(r.screen)['border-radius'],
            const CoreBorderRadius.all(24).toValue(),
          );
          expect(
            _props(r.bezel)['border-radius'],
            const CoreBorderRadius.all(32).toValue(),
          );
          expect(_px(_props(r.content)['padding-top']), 0);
          expect(_px(_props(r.content)['padding-bottom']), 0);
        });
      }
    }

    testComponents('the flat ring is the theme token, not a literal', (
      tester,
    ) async {
      final r = flat(tester);
      expect(r.bezel.className, contains('bg-surface-container-highest'));
      expect(_props(r.bezel).containsKey('background-color'), isFalse);
      // The body is the same token, so no other fill shows at the corners.
      expect(
        r.frameStyle.backgroundColor,
        const CoreColor.token(
          CoreColors.surfaceContainerHighest,
        ),
      );
      expect(r.frameStyle.backgroundGradient, isNull);
    });

    testComponents('every part flat does emit has a non-zero box', (
      tester,
    ) async {
      final r = flat(tester, showCamera: true, showGestureBar: true);
      for (final chrome in _everyChrome(r)) {
        final props = chrome.inlineStyles?.properties ?? const {};
        for (final key in ['width', 'height']) {
          final value = props[key];
          if (value == null || !value.endsWith('rem')) continue;
          expect(
            _px(value),
            greaterThan(0),
            reason: '$key of ${chrome.className}',
          );
        }
      }
    });

    testComponents('flat flags default off and an explicit true turns on', (
      tester,
    ) async {
      final onlyCamera = flat(tester, showCamera: true);
      expect(onlyCamera.screenCameraParts, isNotEmpty);
      expect(onlyCamera.statusBar, isNull);
      expect(onlyCamera.gestureBar, isNull);
      final all = flat(
        tester,
        showCamera: true,
        showStatusBar: true,
        showGestureBar: true,
      );
      expect(all.screenCameraParts, isNotEmpty);
      expect(all.gestureBar, isNotNull);
      expect(all.statusBar, isNotNull);
      expect(_px(_props(all.content)['padding-top']), greaterThan(0));
    });

    testComponents('an instance style still wins over the flat row', (
      tester,
    ) async {
      final r = flat(
        tester,
        style: const CoreMockupDeviceStyle(
          bezelColor: CoreColor(0xFF112233),
          bezelWidth: 4,
          containerStyle: CoreOutlinedContainerStyle(
            boxShadow: CoreShadow.md,
          ),
        ),
      );
      expect(_props(r.bezel)['background-color'], 'rgb(17, 34, 51)');
      expect(_px(_props(r.screen)['left']), 4);
      expect(r.frameStyle.boxShadow, CoreShadow.md);
    });

    testComponents('the theme finishStyles slot restates the flat ring only', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        mockupDevice: CoreMockupDeviceTheme(
          finishStyles: {
            CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
              bezelColor: CoreColor(0xFF112233),
            ),
          },
        ),
      );
      final flatResolved = _resolveUnder(
        tester,
        theme,
        finish: .flat,
      );
      expect(_props(flatResolved.bezel)['background-color'], 'rgb(17, 34, 51)');
      // The realistic resolve never reads the flat row of the slot.
      final realistic = _resolveUnder(
        tester,
        theme,
        finish: .realistic,
        width: _kPhonePortraitWidth,
      );
      expect(_props(realistic.bezel)['background-color'], 'rgb(0, 0, 0)');
    });

    testComponents('a shared mockup theme overrides the flat row; finishStyles '
        'restates it', (tester) async {
      const sharedRadius = CoreBorderRadius.all(CoreRadius.radius8);
      const shared = CoreMockupTheme(
        style: CoreMockupStyle(borderRadius: sharedRadius),
      );
      final overridden = _resolveUnder(
        tester,
        const CoreComponentTheme(mockup: shared),
        finish: .flat,
      );
      // The flat row is the first layer: a shared theme states over it.
      expect(overridden.frameStyle.borderRadius, sharedRadius);
      final restated = _resolveUnder(
        tester,
        const CoreComponentTheme(
          mockup: shared,
          mockupDevice: CoreMockupDeviceTheme(
            finishStyles: {
              CoreMockupDeviceFinish.flat: CoreMockupDeviceStyle(
                borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
              ),
            },
          ),
        ),
        finish: .flat,
      );
      expect(
        restated.frameStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius32),
      );
    });

    testComponents('finish is kept by copyWith and the style chain', (
      tester,
    ) async {
      const mockup = MockupDevice(
        finish: .flat,
        child: Component.text('screen'),
      );
      expect(mockup.copyWith(width: 100).finish, CoreMockupDeviceFinish.flat);
      expect(mockup.radius8.finish, CoreMockupDeviceFinish.flat);
      expect(
        mockup.copyWith(finish: .realistic).finish,
        CoreMockupDeviceFinish.realistic,
      );
    });
  });
}
