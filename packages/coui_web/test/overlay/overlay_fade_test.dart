// How a panel that opens or closes fades, in the parts a VM can see: what its
// motion chrome states, what the host's stylesheet says about it, and that the
// page reaches the browser with those rules intact.
//
// What the browser does with them — whether a glass panel keeps its blur while
// it fades — is read in Chrome by `glass_fade_probe_test.dart`. This file reads
// the shape of what the probe is given, and the one thing a browser silently
// gets wrong: a rule it drops.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart'
    show resolveDialogMotion;
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr_test/server_test.dart';

const _kOpen = Duration(milliseconds: CoreDuration.normal);
const _kClose = Duration(milliseconds: CoreDuration.fast);

Map<String, String> _styles(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// The keyframes of a pair that states [from] and [to], as the host writes it.
String _keyframes(String name, String from, String to) =>
    '@keyframes $name{from{$from}to{$to}}';

/// The host's stylesheet text, as the browser is given it.
Future<String> _hostCss(ServerTester tester) async {
  tester.pumpComponent(
    Theme.defaults(child: const OverlayHost(child: div([]))),
  );
  final document = (await tester.request('/')).document;
  final style = document!
      .querySelectorAll('style')
      .firstWhere(
        (element) => element.text.contains('@keyframes co-overlay-enter'),
      );

  return style.text;
}

void main() {
  group('the motion box of a panel the popover engine places', () {
    test('scales, and names the fade its child plays', () {
      final box = resolveOverlayMotion(
        positioned: true,
        closing: false,
        openDuration: _kOpen,
        closeDuration: _kClose,
      );
      final styles = _styles(box);

      expect(box.className, kFadeBoxClass);
      expect(styles['animation'], startsWith('co-overlay-enter '));
      expect(styles['animation'], endsWith(' both'));
      // The box carries the length and the curve of the motion it belongs to,
      // so the fade its child plays is the same length on the same curve.
      expect(
        styles['animation'],
        contains(styles[kFadeDurationVar]),
        reason: 'the fade is not the length of the motion',
      );
      expect(styles['animation'], contains(styles[kFadeEasingVar]));
      expect(styles[kFadeProgressAnimationVar], 'co-fade-in');
      expect(styles[kFadeOpacityNameVar], 'co-fade-opacity-in');
      expect(styles[kFadeGlassPaintNameVar], 'co-fade-paint-in');
      expect(styles[kFadeGlassLayerNameVar], 'co-fade-layer-in');
      // Layers that open hold their start until they play.
      expect(styles[kFadeFillVar], 'backwards');
    });

    test('has no opacity of its own: that would take the blur away', () {
      for (final closing in [false, true]) {
        final box = resolveOverlayMotion(
          positioned: true,
          closing: closing,
          openDuration: _kOpen,
          closeDuration: _kClose,
        );

        expect(_styles(box).keys, isNot(contains('opacity')));
        expect(box.className, isNot(contains('opacity')));
      }
    });

    test('closes by the other half of every pair, and holds its end', () {
      final box = resolveOverlayMotion(
        positioned: true,
        closing: true,
        openDuration: _kOpen,
        closeDuration: _kClose,
      );
      final styles = _styles(box);

      expect(box.className, contains(kFadeBoxClass));
      // Not interactive while it leaves.
      expect(box.className, contains('pointer-events-none'));
      expect(styles['animation'], startsWith('co-overlay-exit '));
      expect(styles[kFadeProgressAnimationVar], 'co-fade-out');
      expect(styles[kFadeOpacityNameVar], 'co-fade-opacity-out');
      expect(styles[kFadeGlassPaintNameVar], 'co-fade-paint-out');
      expect(styles[kFadeGlassLayerNameVar], 'co-fade-layer-out');
      // What leaves stays gone until the panel unmounts.
      expect(styles[kFadeFillVar], 'forwards');
    });

    test('a morph is not scaled, and fades all the same', () {
      final box = resolveOverlayMotion(
        positioned: true,
        closing: false,
        openDuration: _kOpen,
        closeDuration: _kClose,
        morphing: true,
      );

      expect(_styles(box).containsKey('animation'), isFalse);
      expect(_styles(box)[kFadeProgressAnimationVar], 'co-fade-in');
      expect(box.className, kFadeBoxClass);
    });

    test('a panel that is not placed yet is hidden and fades nothing', () {
      final box = resolveOverlayMotion(
        positioned: false,
        closing: false,
        openDuration: _kOpen,
        closeDuration: _kClose,
      );

      expect(box.className, contains('opacity-0'));
      expect(box.className, isNot(contains(kFadeBoxClass)));
      expect(_styles(box), isEmpty);
    });
  });

  group('the dialog panel, which is its own motion box', () {
    test(
      'scales, walks the progress, and names what it plays by what it is',
      () {
        final motion = resolveDialogMotion(
          closing: false,
          transitionDuration: _kOpen,
        );
        final panel = motion.panel;
        final styles = _styles(panel);
        final entries = styles['animation']!.split(', ');

        expect(panel.className, kFadePanelClass);
        expect(entries, hasLength(3));
        // The keyframe that scales it also walks the progress.
        expect(entries[0], startsWith('co-dialog-panel-enter '));
        // The other two are named by custom properties the panel's own rules
        // set: its opacity when it draws no pass, its shadow and edge when it
        // does.
        expect(entries[1], startsWith('var($kFadeOpacityAnimationVar) '));
        expect(entries[2], startsWith('var($kFadePaintAnimationVar) '));
        expect(entries[2], endsWith('var($kFadeFillVar)'));
        expect(styles[kFadeProgressAnimationVar], 'co-fade-in');
        expect(styles.keys, isNot(contains('opacity')));
      },
    );

    test('closes by the exit pair and holds its end', () {
      final panel = resolveDialogMotion(
        closing: true,
        transitionDuration: _kClose,
      ).panel;
      final styles = _styles(panel);

      expect(styles['animation'], startsWith('co-dialog-panel-exit '));
      expect(styles[kFadeProgressAnimationVar], 'co-fade-out');
      expect(styles[kFadeFillVar], 'forwards');
    });

    test('the scrim fades by its opacity: it has no glass to lose', () {
      final scrim = resolveDialogMotion(
        closing: false,
        transitionDuration: _kOpen,
      ).backdrop;

      expect(_styles(scrim)['animation'], startsWith('co-overlay-fade-enter '));
    });
  });

  group('the host stylesheet', () {
    testServer('reaches the browser as written', (tester) async {
      final css = await _hostCss(tester);

      // A `<style>` is not decoded, so a `>` the server escaped is a rule the
      // browser drops — the child combinators and the `<number>` in these
      // rules would all go, with nothing to say so.
      expect(css, isNot(contains('&gt;')));
      expect(css, isNot(contains('&lt;')));
      expect(css, isNot(contains('&amp;')));
      expect(css, contains('.$kFadeBoxClass>*{animation:'));
      expect(css, contains('@property $kFadeProgressVar{syntax:"<number>"'));
    });

    testServer('has the box scale and nothing else', (tester) async {
      final css = await _hostCss(tester);

      expect(
        css,
        contains(
          _keyframes(
            'co-overlay-enter',
            'transform:scale(0.9)',
            'transform:scale(1)',
          ),
        ),
      );
      expect(
        css,
        contains(
          _keyframes(
            'co-overlay-exit',
            'transform:scale(1)',
            'transform:scale(0.9)',
          ),
        ),
      );
      // The scrim's pair is a fade of its own, and has no glass in it.
      expect(css, contains('@keyframes co-overlay-fade-enter{from{opacity:0}'));
    });

    testServer('walks the progress in the dialog keyframe, beside the scale', (
      tester,
    ) async {
      final css = await _hostCss(tester);

      expect(
        css,
        stringContainsInOrder([
          '@keyframes co-dialog-panel-enter{from{$kFadeProgressVar:0;',
          'transform:translate(-50%,-50%) ',
          'scale(var(--coui-dialog-scale-from))}',
          'to{$kFadeProgressVar:1;',
        ]),
        reason: 'the enter pair walks the progress up, beside the scale',
      );
      expect(
        css,
        stringContainsInOrder([
          '@keyframes co-dialog-panel-exit{from{$kFadeProgressVar:1;',
          'to{$kFadeProgressVar:0;transform:translate(-50%,-50%) ',
        ]),
        reason: 'the exit pair walks the progress down',
      );
      expect(css, isNot(contains('co-dialog-panel-enter{from{opacity')));
    });

    testServer('defines every keyframe the motion chrome names', (
      tester,
    ) async {
      final css = await _hostCss(tester);

      for (final closing in [false, true]) {
        final styles = _styles(
          resolveOverlayMotion(
            positioned: true,
            closing: closing,
            openDuration: _kOpen,
            closeDuration: _kClose,
          ),
        );
        for (final key in [
          kFadeProgressAnimationVar,
          kFadeOpacityNameVar,
          kFadeGlassPaintNameVar,
          kFadeGlassLayerNameVar,
        ]) {
          expect(
            css,
            contains('@keyframes ${styles[key]}{'),
            reason: '$key names ${styles[key]}',
          );
        }
      }
    });

    testServer('a slot a panel does not play is the name of no keyframes', (
      tester,
    ) async {
      final css = await _hostCss(tester);

      // A fade root names the opacity and nothing else, which is what a panel
      // with no pass plays. The two it does not play are a name no keyframes
      // go by — not the keyword `none`, which the `animation` shorthand also
      // reads as a fill mode.
      expect(
        css,
        contains(
          '.$kFadeBoxClass,.$kFadePanelClass{'
          '$kFadeOpacityAnimationVar:var($kFadeOpacityNameVar);'
          '$kFadePaintAnimationVar:$kFadeNoAnimation;'
          '$kFadeLayerAnimationVar:$kFadeNoAnimation}',
        ),
      );
      expect(css, isNot(contains('@keyframes $kFadeNoAnimation')));
    });

    testServer('plays the layers of a panel with a pass on what is in it', (
      tester,
    ) async {
      final css = await _hostCss(tester);

      for (final selector in [
        '.$kFadePanelClass>*',
        '.$kFadeBoxClass>*>*',
        '.$kFadePanelClass::before',
        '.$kFadePanelClass::after',
        '.$kFadeBoxClass>*::before',
        '.$kFadeBoxClass>*::after',
      ]) {
        expect(css, contains(selector));
      }
      // Registered as not inherited: only the element that walks the progress
      // reads it, so a surface inside a fading panel does not fade again.
      expect(css, contains('inherits:false'));
    });
  });
}
