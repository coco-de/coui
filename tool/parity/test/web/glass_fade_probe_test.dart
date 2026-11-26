// Web glass panels while their open/close keyframe runs — the Chrome half of
// the fade rule (`CoreSurfaceDissolve`).
//
// What is asked: a glass panel that is half way into its open keyframe — how
// much of the page's own detail still shows through its middle? A glass panel
// blurs what is behind it, so a fine stripe pattern under a fully open panel
// is gone; under a faded one the answer says whether the panel is still glass.
//
// The page is a stripe pattern one pixel wide, and the answer is the contrast
// of the stripes in a band across the panel's middle, as a share of their
// contrast beside the panel. The panel is built from the chrome the
// resolvers emit and the stylesheet the theme emits, in Chrome; its keyframe
// is held at one point by pausing the animation there (the easing is made
// linear, so a fraction of the time is the same fraction of the progress).
//
// Measured on this page before the fade moved off the panel's opacity: the
// popover family kept 0.88 / 0.75 / 0.62 of the stripes at a quarter, a half
// and three quarters of the way in — a plain translucent plate, because the
// opacity on its motion box left the glass nothing to blur — and the dialog
// 0.75 / 0.51 / 0.26, the sharp page showing through a translucent glass.
// Flutter keeps 0.03 at half way.
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart'
    show resolveOverlayMotion;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:puppeteer/protocol/emulation.dart' as cdp show MediaFeature;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const int _kViewportWidth = 800;
const int _kViewportHeight = 600;

/// The popover family's keyframe, long enough that a held fraction is not a
/// rounding of it. The dialog plays the length its own style states.
const int _kKeyframeMs = 1000;

/// The panel's body: a box with nothing in its middle, so the band across the
/// panel holds only the panel's own material and what shows through it. The
/// small block at its top is the content the fade is read off.
const int _kBodyWidthPx = 320;
const int _kBodyHeightPx = 200;

/// Where the probe looks for Chrome: `CHROME_EXECUTABLE` when it is set, then
/// the system installs the other probes look in.
List<String> _chromeCandidates() => [
  if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome
      when chrome.isNotEmpty)
    chrome,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];

/// The page's detail: black and white stripes, one pixel each.
const String _kStripesCss = '''
html,body{margin:0;height:100%}
body{background:repeating-linear-gradient(90deg,#000 0,#000 1px,#fff 1px,#fff 2px)}
''';

/// Every keyframe in the page runs on a linear clock and starts paused, so the
/// probe says where it stands. The lengths are the panel's own: a panel that
/// plays an animation only some of the time names a different animation for
/// the time it does not, and a length the probe overrode would change which.
const String _kHoldCss = '''
*,*::before,*::after{
  animation-timing-function:linear !important;
  animation-delay:0s !important;
  animation-play-state:paused !important;
  transition:none !important;
}
''';

/// No keyframe at all: the rest state to compare to.
const String _kRestCss = '''
*,*::before,*::after{animation:none !important;transition:none !important}
''';

/// The Dialog scrim is a dim over the whole page, which would be measured as
/// part of what the panel blurs. It is the panel's glass that is asked about.
const String _kNoScrimCss =
    '.coui-dialog > :first-child{display:none !important}';

class _Body extends StatelessComponent {
  const _Body();

  @override
  Component build(BuildContext context) => const div(
    [
      div(
        [],
        id: 'probe-content',
        styles: Styles(
          raw: {
            'width': '48px',
            'height': '16px',
            'background-color': 'rgb(200 40 40)',
          },
        ),
      ),
    ],
    id: 'probe-body',
    styles: Styles(
      raw: {'width': '${_kBodyWidthPx}px', 'height': '${_kBodyHeightPx}px'},
    ),
  );
}

/// The popover family's panel as the component builds it: the positioned outer
/// box, the motion box, the bubble.
class _PopoverPanel extends StatelessComponent {
  const _PopoverPanel({required this.closing});

  final bool closing;

  @override
  Component build(BuildContext context) {
    final resolved = resolvePopover(context, left: 240, top: 160);
    final motion = resolveOverlayMotion(
      positioned: true,
      closing: closing,
      openDuration: const Duration(milliseconds: _kKeyframeMs),
      closeDuration: const Duration(milliseconds: _kKeyframeMs),
    );

    return div(
      [
        div(
          [
            div(
              const [_Body()],
              classes: resolved.bubble.className,
              styles: resolved.bubble.inlineStyles,
              attributes: const {'role': 'dialog', 'id': 'probe-surface'},
            ),
          ],
          classes: motion.className,
          styles: motion.inlineStyles,
        ),
      ],
      id: 'probe-panel',
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
    );
  }
}

/// What the page looked like at one hold.
class _Held {
  const _Held({
    required this.kept,
    required this.surface,
    required this.box,
    required this.content,
    required this.pseudo,
    required this.names,
  });

  /// The share of the page's stripes that show through the panel's middle.
  final double kept;

  /// What the glass panel computed to: `filter` (`backdrop-filter`), `fill`,
  /// `shadow`, `border` and `opacity`.
  final Map<String, String> surface;

  /// The opacity of the motion box (the popover family) or of the dialog's
  /// root.
  final String box;

  /// The opacities of what is directly in the panel.
  final List<double> content;

  /// The panel's `::after`: how opaque it is and whether it draws at all.
  final ({double opacity, bool drawn}) pseudo;

  /// The names the panel's own `animation` computed to.
  final List<String> names;

  double get opacity => double.parse(surface['opacity']!);

  double get blur => double.parse(
    RegExp(r'blur\(([\d.]+)px\)').firstMatch(surface['filter']!)!.group(1)!,
  );

  /// The number inside `fn(…)`, or [absent] where the list has no such term.
  double term(String fn, double absent) {
    final match = RegExp('$fn\\(([\\d.]+)\\)').firstMatch(surface['filter']!);

    return match == null ? absent : double.parse(match.group(1)!);
  }

  /// The alpha of the fill.
  double get fillAlpha {
    final parts = RegExp(r'rgba?\(([^)]*)\)')
        .firstMatch(surface['fill']!)!
        .group(1)!
        .split(RegExp('[,/ ]+'))
        .where((e) => e.isNotEmpty)
        .toList();

    return parts.length > 3 ? double.parse(parts[3]) : 1;
  }
}

/// What a band across the middle of [panel] keeps of the page's stripes, as a
/// share of what the same band beside the panel keeps.
double _kept(img.Image pixels, math.Rectangle<int> panel, int reference) {
  double contrast(int left, int top, int width, int height) {
    // The mean of each column over the band, so one noisy row cannot move it.
    final columns = <double>[];
    for (var x = left; x < left + width; x++) {
      var sum = 0.0;
      for (var y = top; y < top + height; y++) {
        sum += pixels.getPixel(x, y).r.toDouble();
      }
      columns.add(sum / height);
    }

    return columns.reduce(math.max) - columns.reduce(math.min);
  }

  const bandHeight = 24;
  final centerY = panel.top + (panel.height ~/ 2) - (bandHeight ~/ 2);
  final inside = contrast(
    panel.left + (panel.width ~/ 2) - 40,
    centerY,
    80,
    bandHeight,
  );
  final beside = contrast(reference, centerY, 80, bandHeight);

  return inside / beside;
}

void main() {
  final chromePath = _chromeCandidates()
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;
  final skip = chromePath == null ? 'no Chrome installed' : false;

  late pptr.Browser browser;
  late Directory workDir;
  late String hostCss;
  late String popoverBody;
  late String popoverExitBody;
  late String dialogBody;
  late String dialogExitBody;

  setUpAll(() async {
    if (chromePath == null) return;
    // The overlay host's own stylesheet: where the keyframes and the fade
    // rules live.
    final host = await renderComponentBodyHtml(
      Theme.defaults(
        child: const OverlayHost(child: div([], id: 'x')),
      ),
    );
    hostCss = RegExp(r'<style>([\s\S]*?)</style>').firstMatch(host)!.group(0)!;
    Future<String> render(Component component) =>
        renderComponentBodyHtml(Theme.defaults(child: component));
    popoverBody = await render(const _PopoverPanel(closing: false));
    popoverExitBody = await render(const _PopoverPanel(closing: true));
    dialogBody = await render(
      Dialog(content: const _Body(), onClose: () {}),
    );
    // The dialog closes by replaying its panel's exit keyframe when its `open`
    // goes false, which a server render cannot do. The same panel with the
    // names of the exit pair and the side the layers hold stands in for it.
    dialogExitBody = dialogBody
        .replaceAll('co-dialog-panel-enter', 'co-dialog-panel-exit')
        .replaceAll('co-fade-opacity-in', 'co-fade-opacity-out')
        .replaceAll('co-fade-paint-in', 'co-fade-paint-out')
        .replaceAll('co-fade-layer-in', 'co-fade-layer-out')
        .replaceAll(
          '--coui-fade-progress: co-fade-in',
          '--coui-fade-progress: co-fade-out',
        )
        .replaceAll(
          '--coui-fade-fill: backwards',
          '--coui-fade-fill: forwards',
        );
    expect(dialogExitBody, contains('co-dialog-panel-exit'));
    expect(dialogExitBody, contains('co-fade-out'));
    expect(dialogExitBody, contains('--coui-fade-fill: forwards'));
    browser = await launchCaptureBrowser(
      width: _kViewportWidth,
      height: _kViewportHeight,
      executablePath: chromePath,
    );
    workDir = Directory.systemTemp.createTempSync('glass-fade-probe-');
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    workDir.deleteSync(recursive: true);
  });

  /// Opens [body] in Chrome and holds its keyframes at [at] (a fraction of
  /// each keyframe, or null to take them off), then reports what the page
  /// shows.
  ///
  /// [atEnd] holds every keyframe at its end instead: the panel once it has
  /// opened, with the fade's own rules still in force.
  Future<_Held> hold(
    String name,
    String body, {
    required double? at,
    bool dialog = false,
    String? style = 'liquidGlass',
    String theme = 'light',
    String? quality,
    List<(String, String)> media = const [],
    bool atEnd = false,
  }) async {
    var html = buildOfflineTailwindHarnessHtml(
      bodyHtml: body,
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      surfaceStyleId: style,
      theme: theme,
      animationFreezeCss: '',
      additionalHeadHtml:
          '$hostCss<style>$_kStripesCss$_kNoScrimCss'
          '${at == null && !atEnd ? _kRestCss : _kHoldCss}</style>',
    );
    if (quality != null) {
      html = html.replaceFirst(
        '<html ',
        '<html $kQualityAttribute="$quality" ',
      );
    }
    final file = File(p.join(workDir.path, '$name.html'))
      ..writeAsStringSync(html);

    final surfaceSelector = dialog
        ? '.coui-dialog > [role=dialog]'
        : '#probe-surface';
    final boxSelector = dialog ? '.coui-dialog' : '.$kFadeBoxClass';

    final page = await browser.newPage();
    try {
      if (media.isNotEmpty) {
        await page.devTools.emulation.setEmulatedMedia(
          features: [
            for (final (feature, value) in media)
              cdp.MediaFeature(name: feature, value: value),
          ],
        );
      }
      await page.goto(Uri.file(file.absolute.path).toString(), wait: .load);
      // The surface rules are injected by script after the sheet loads.
      await page.waitForFunction(
        '''
() => Array.from(document.querySelectorAll('style'))
          .some(s => s.textContent.includes('data-coui-style="liquidGlass"'))''',
      );
      await page.evaluate<void>(
        '''
(f, end) => {
          for (const a of document.getAnimations()) {
            a.pause();
            const d = a.effect.getComputedTiming().duration;
            if (end) a.currentTime = d;
            else if (f !== null) a.currentTime = f * d;
          }
        }''',
        args: [at, atEnd],
      );
      // Two frames, so what was set is what is painted.
      await page.evaluate<void>(
        '() => new Promise(r => '
        'requestAnimationFrame(() => requestAnimationFrame(r)))',
      );
      final facts = await page.evaluate<Map<String, dynamic>>(
        '''
() => {
          const surface = document.querySelector('$surfaceSelector');
          const box = document.querySelector('$boxSelector');
          const cs = getComputedStyle(surface);
          const b = surface.getBoundingClientRect();
          const after = getComputedStyle(surface, '::after');
          return {
            left: Math.round(b.left), top: Math.round(b.top),
            width: Math.round(b.width), height: Math.round(b.height),
            surface: {
              filter: cs.backdropFilter,
              fill: cs.backgroundColor,
              shadow: cs.boxShadow,
              border: cs.borderTopColor,
              opacity: cs.opacity,
            },
            box: getComputedStyle(box).opacity,
            content: Array.from(surface.children).map(c => Number(getComputedStyle(c).opacity)),
            pseudo: {
              opacity: Number(after.opacity),
              drawn: after.content !== 'none' && after.content !== 'normal',
            },
            names: cs.animationName.split(',').map(s => s.trim()),
          };
        }''',
      );
      final pixels = img.decodePng(await page.screenshot())!;
      final rect = math.Rectangle<int>(
        facts['left'] as int,
        facts['top'] as int,
        facts['width'] as int,
        facts['height'] as int,
      );
      final pseudo = facts['pseudo'] as Map;

      return _Held(
        kept: _kept(pixels, rect, 40),
        surface: (facts['surface'] as Map).cast<String, String>(),
        box: facts['box'] as String,
        content: [
          for (final c in facts['content'] as List) (c as num).toDouble(),
        ],
        pseudo: (
          opacity: (pseudo['opacity'] as num).toDouble(),
          drawn: pseudo['drawn'] as bool,
        ),
        names: (facts['names'] as List).cast<String>(),
      );
    } finally {
      await page.close();
    }
  }

  // What the preset states, read from Core: the numbers the stylesheet has to
  // dissolve.
  final glass = CoreSurfaceRecipe.of(
    CoreSurfaceStyleId.liquidGlass,
  ).surfaceFor(CoreSurfaceRole.functional)!;

  /// The filter terms at [progress], from the rule Core states.
  ({double blur, double saturate, double brightness}) expected(
    double progress,
    CoreBrightness mode,
  ) => (
    blur: CoreSurfaceDissolve.scaled(glass.blurRadius!, progress),
    saturate: CoreSurfaceDissolve.towardIdentity(
      glass.saturationFor(mode),
      progress,
    ),
    brightness: CoreSurfaceDissolve.towardIdentity(
      mode == CoreBrightness.dark
          ? glass.backdropBrightness.dark
          : glass.backdropBrightness.light,
      progress,
    ),
  );

  /// The first tier of the adaptive-quality ladder that goes without the
  /// backdrop pass.
  final droppingTier = CoreQualityLadder.standard.tiers
      .firstWhere(
        (tier) => CoreQualityLadder.standard.withholds(
          tier,
          CoreQualityEffect.backdropPass,
        ),
      )
      .name;

  const surfaces = <(String, bool)>[('popover', false), ('dialog', true)];
  String bodyOf(bool dialog, {required bool closing}) => dialog
      ? (closing ? dialogExitBody : dialogBody)
      : (closing ? popoverExitBody : popoverBody);

  group('glass panel under its open and close keyframes (Chrome)', () {
    for (final (label, dialog) in surfaces) {
      group(label, () {
        test(
          'at the end of its keyframe the panel is the panel it was',
          () async {
            for (final mode in ['light', 'dark']) {
              final rest = await hold(
                '$label-rest-$mode',
                bodyOf(dialog, closing: false),
                at: null,
                dialog: dialog,
                theme: mode,
              );
              final ended = await hold(
                '$label-ended-$mode',
                bodyOf(dialog, closing: false),
                at: null,
                atEnd: true,
                dialog: dialog,
                theme: mode,
              );
              expect(ended.surface, rest.surface, reason: mode);
              expect(ended.box, rest.box, reason: mode);
              expect(ended.content, rest.content, reason: mode);
              expect(ended.pseudo, rest.pseudo, reason: mode);
              expect(ended.kept, closeTo(rest.kept, 0.001), reason: mode);
            }
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 2)),
        );

        test(
          'keeps its blur while it opens: the page does not show through',
          () async {
            for (final progress in [0.25, 0.5, 0.75]) {
              final held = await hold(
                '$label-open-$progress',
                bodyOf(dialog, closing: false),
                at: progress,
                dialog: dialog,
              );
              // Flutter keeps 0.03 of the stripes at half way. A plate keeps
              // most of them, and so does a glass faded by its opacity.
              expect(
                held.kept,
                lessThan(0.05),
                reason: '$label at $progress opening',
              );
              // No opacity on the panel or the box it sits in: that is what
              // takes the blur away.
              expect(held.opacity, 1, reason: 'panel at $progress');
              expect(double.parse(held.box), 1, reason: 'box at $progress');
            }
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 2)),
        );

        test(
          'keeps its blur while it closes',
          () async {
            for (final progress in [0.25, 0.5, 0.75]) {
              final held = await hold(
                '$label-close-$progress',
                bodyOf(dialog, closing: true),
                at: progress,
                dialog: dialog,
              );
              expect(
                held.kept,
                lessThan(0.05),
                reason: '$label at $progress closing',
              );
              expect(held.opacity, 1);
              expect(double.parse(held.box), 1);
            }
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 2)),
        );

        test(
          'the blur, chroma and dimming follow the share Core states',
          () async {
            for (final mode in [CoreBrightness.light, CoreBrightness.dark]) {
              for (final progress in [0.25, 0.5, 0.75]) {
                final held = await hold(
                  '$label-share-${mode.name}-$progress',
                  bodyOf(dialog, closing: false),
                  at: progress,
                  dialog: dialog,
                  theme: mode.name,
                );
                final want = expected(progress, mode);
                const tolerance = 0.02;
                expect(
                  held.blur,
                  closeTo(want.blur, tolerance * 4),
                  reason: '$label ${mode.name} blur at $progress',
                );
                expect(
                  held.term('saturate', 1),
                  closeTo(want.saturate, tolerance),
                  reason: '$label ${mode.name} saturate at $progress',
                );
                expect(
                  held.term('brightness', 1),
                  closeTo(want.brightness, tolerance),
                  reason: '$label ${mode.name} brightness at $progress',
                );
              }
            }
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 3)),
        );

        test(
          'the fill, the shadow, the content and the decoration fade with it',
          () async {
            final rest = await hold(
              '$label-layers-rest',
              bodyOf(dialog, closing: false),
              at: null,
              dialog: dialog,
            );
            final half = await hold(
              '$label-layers-half',
              bodyOf(dialog, closing: false),
              at: 0.5,
              dialog: dialog,
            );
            expect(rest.content, everyElement(1));
            // Each goes from nothing to the value it has at rest, by the
            // progress itself.
            expect(half.content, isNotEmpty);
            expect(half.content, everyElement(closeTo(0.5, 0.03)));
            expect(half.fillAlpha, closeTo(rest.fillAlpha / 2, 0.03));
            expect(
              half.surface['shadow'],
              isNot(rest.surface['shadow']),
              reason: 'the shadow is part of the way',
            );
            expect(half.surface['shadow'], isNot('none'));
            // The decoration the glass draws on its edge is drawn at rest, and
            // at half its strength half way.
            expect(rest.pseudo.drawn, isTrue);
            expect(half.pseudo.opacity, closeTo(0.5, 0.03));
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 2)),
        );

        test(
          'a panel that draws no pass fades by its opacity',
          () async {
            for (final progress in [0.25, 0.5]) {
              final held = await hold(
                '$label-plain-$progress',
                bodyOf(dialog, closing: false),
                at: progress,
                dialog: dialog,
                style: null,
              );
              expect(held.surface['filter'], 'none');
              expect(held.opacity, closeTo(progress, 0.01));
              expect(held.names, contains('co-fade-opacity-in'));
              // And plays nothing for the layers it has no pass to lose.
              expect(held.content, everyElement(1));
            }
          },
          skip: skip,
          timeout: const Timeout(Duration(minutes: 2)),
        );

        for (final (reason, quality, media)
            in <(String, String?, List<(String, String)>)>[
              (
                'reduced transparency',
                null,
                [('prefers-reduced-transparency', 'reduce')],
              ),
              ('a quality tier without the pass', droppingTier, []),
              ('forced colours', null, [('forced-colors', 'active')]),
            ]) {
          test(
            'a glass panel whose pass is dropped by $reason fades by opacity',
            () async {
              final held = await hold(
                '$label-drop-${reason.hashCode}',
                bodyOf(dialog, closing: false),
                at: 0.5,
                dialog: dialog,
                quality: quality,
                media: media,
              );
              expect(held.opacity, closeTo(0.5, 0.01), reason: reason);
              expect(held.names, contains('co-fade-opacity-in'));
              expect(held.names, isNot(contains('co-fade-paint-in')));
              expect(held.content, everyElement(1));
            },
            skip: skip,
            timeout: const Timeout(Duration(minutes: 2)),
          );
        }
      });
    }

    test(
      'prints what the page keeps, for the record',
      () async {
        final rows = <String>[];
        for (final (label, dialog) in surfaces) {
          for (final at in <double?>[null, 0.05, 0.1, 0.25, 0.5, 0.75, 0.95]) {
            final held = await hold(
              'record-$label-${at ?? 'rest'}',
              bodyOf(dialog, closing: false),
              at: at,
              dialog: dialog,
            );
            rows.add(
              '$label @ ${at ?? 'rest'}: kept ${held.kept.toStringAsFixed(3)}'
              '  ${held.surface['filter']}',
            );
          }
        }
        // The table is what a reader runs this test for.
        // ignore: avoid_print
        print(rows.join('\n'));
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
