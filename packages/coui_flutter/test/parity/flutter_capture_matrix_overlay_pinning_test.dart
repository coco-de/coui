// #3859 (original) / #3909 (this version) — pins the harness fact
// `probeRootTextStyle`'s correctness for trigger+closed-overlay
// compositions (`dialog`, `navigation-menu`, `swiper` — #3856's own PR
// description) actually depends on, so it stays a verified fact instead of
// an unexamined coincidence.
//
// `flutter_capture_matrix_test.dart`'s `_captureEntry` builds a fresh
// `Overlay(key: ValueKey(pinnedWidth), initialEntries: [...])` on every
// `buildApp` call and wraps its `OverlayEntry` content in a `Center` that
// loosens `Overlay`'s own forced-tight sizing (`_RenderTheatre
// .performLayout`'s `size = constraints.biggest` + `BoxConstraints
// .tight(size)` for every non-positioned child — #3909's own issue). The
// combined effect: root's own render box now reflects each entry's *real*
// natural size, not the ambient `flutter_test` view (800×600) every entry
// used to be force-sized to before #3909 (measured then: 48/48 sampled
// captures were exactly 800×600, `Overlay`'s `initialEntries`-read-once
// staleness bug meant `Overlay` never even noticed a rebuild happened).
//
// For a "trigger + closed overlay" composition, a real natural size is not
// automatically safe. `dialog`'s root is `Column([Button('Open Dialog'),
// Dialog(open: false, ...)])` — the closed `Dialog` paints nothing, so the
// `Column` collapses to *exactly* the trigger `Button`'s own footprint.
// `probeRootTextStyle`'s pre-#3909 implementation disambiguated "root's
// own" from "a foreign nested sub-component's" by comparing candidate
// render-box *size* against root's — a test that cannot distinguish these
// two boxes once they're the same box. This file proves, with the real
// two-pass build this composition actually goes through, that (a) root's
// box really does collapse to the trigger's footprint (fix 1 — the capture
// boundary is genuinely narrow now, not incidentally safe because
// everything was 800×600) and (b) `probeRootTextStyle` still correctly
// returns `null` despite that (fix 2 — `root_scoped_walk.dart`'s
// structural single-path descent disambiguates by tree shape, not size, so
// the coincidence in (a) cannot fool it: `Column` has two real children —
// `Button` and `Dialog` — and the walk stops there, never reaching either
// one's own chrome).
//
// If either assertion below goes red, `root_text_probe.dart`'s
// `probeRootTextStyle` (or `root_scoped_walk.dart`'s `nextOnSinglePath`)
// needs to be re-examined before anything downstream (the property/pixel
// parity gate) can trust its output again — see #3909, #3859.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/dialog/dialog_default_example.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import 'capture_host.dart';
import 'integer_capture.dart';
import 'root_text_probe.dart';

/// Mirrors `flutter_capture_matrix_test.dart`'s `buildApp` closely enough
/// to reproduce its `Overlay` behaviour exactly — `Theme`/`Directionality`/
/// `Material` wrapping, the `Center`/`OverflowBox` pinned-width escape
/// hatch, the shared `captureHost` that loosens `Overlay`'s forced-tight
/// sizing for its `OverlayEntry` content (and releases the height), and the
/// `Overlay`'s own `key: ValueKey(pinnedWidth)` — while dropping the
/// `surfaceStyle`/`RepaintBoundary`/manifest-entry plumbing that file needs
/// but this narrower reproduction (which only ever inspects `rootKey`'s
/// render geometry and `probeRootTextStyle`'s output, never rasterizes
/// anything) doesn't.
Widget _buildApp(PinnedWidth? pin, GlobalKey rootKey, Widget root) {
  Widget content = KeyedSubtree(key: rootKey, child: root);
  if (pin != null) {
    // The same shared box the matrix harness uses — a copy here would be a
    // fourth tree to keep in step, and the fill-width case below pins a
    // property of that box itself.
    content = pinnedWidthBox(pin, child: content);
  }
  final styledTheme = ThemeData.fromCore(CoreThemePresets.dark);
  return Theme(
    data: styledTheme,
    child: Directionality(
      textDirection: .ltr,
      child: material.Material(
        color: material.Colors.transparent,
        textStyle: styledTheme.typography.bodyMedium
            .toValue(theme: styledTheme)
            .copyWith(color: styledTheme.colorScheme.onSurface.toValue()),
        child: Overlay(
          key: ValueKey(pin?.width),
          initialEntries: [
            OverlayEntry(builder: (_) => captureHost(child: content)),
          ],
        ),
      ),
    ),
  );
}

/// The two passes exactly as `captureAtIntegerWidth` runs them, returning
/// the root's rendered size after pass 2.
Future<Size> _pinnedRootSize(
  WidgetTester tester,
  GlobalKey rootKey,
  Widget root,
) async {
  await tester.pumpWidget(_buildApp(null, rootKey, root));
  await tester.pumpAndSettle();
  final naturalWidth = tester.getSize(find.byKey(rootKey)).width;
  final pin = PinnedWidth(
    width: chromeRoundedPx(naturalWidth).toDouble(),
    naturalWidth: naturalWidth,
  );

  await tester.pumpWidget(_buildApp(pin, rootKey, root));
  await tester.pumpAndSettle();
  return tester.renderObject<RenderBox>(find.byKey(rootKey)).size;
}

void main() {
  testWidgets(
    'trigger + closed-overlay composition — root 는 trigger 크기로 '
    'collapse 하지만 probeRootTextStyle 은 구조적 disambiguation 덕에 '
    '여전히 null 을 반환한다',
    (tester) async {
      final rootKey = GlobalKey();

      // Pass 1 (natural) then pass 2 (pinned), exactly
      // `captureAtIntegerWidth`'s own two `pumpWidget` calls. `Overlay`'s own
      // `key: ValueKey(pin?.width)` (distinct from pass 1's `ValueKey(null)`)
      // forces a genuinely fresh `OverlayState`, exactly matching
      // `_captureEntry` today — unlike the pre-#3909 harness, this rebuild's
      // `content` really does reach the render tree.
      final rootSize = await _pinnedRootSize(
        tester,
        rootKey,
        const DialogDefaultExample(),
      );

      // Fix 1 — root's box is the trigger `Button`'s own true footprint
      // now, not the ambient 800×600 view. A literal `800`/`600` assertion
      // would be brittle against a future `flutter_test` default view size
      // change; the actual claim being pinned is "root collapsed to
      // trigger size, not the ambient view", which these bounds capture
      // without over-specifying the exact view size.
      expect(
        rootSize.width,
        lessThan(250),
        reason:
            'root 가 trigger 크기로 collapse 하지 않았다 — Overlay 의 강제 '
            'tight 사이징이 다시 root 를 뷰 전체 크기로 부풀리고 있다는 뜻. '
            'flutter_capture_matrix_test.dart 의 Center/OverflowBox 배선을 '
            '다시 확인해라 (#3909).',
      );
      expect(rootSize.height, lessThan(60));

      final style = probeRootTextStyle(tester, rootFinder: find.byKey(rootKey));

      // Fix 2 — despite root's box now coinciding with the trigger's own,
      // the structural walk still refuses to attribute the trigger's
      // `onPrimary` label style to root: `Column` has two real children
      // and `nextOnSinglePath` stops there.
      expect(
        style,
        isNull,
        reason:
            '오늘의 안전한 결과(#3856: "16개 trigger+closed-overlay 엔트리가 '
            '정직하게 비교 불가로 처리됨")가 깨졌다 — probeRootTextStyle 이 '
            'trigger 의 onPrimary 를(혹은 다른 값을) 반환하기 시작했다는 뜻. '
            'root_scoped_walk.dart 의 단일-경로 disambiguation 을 다시 '
            '검토해라 (#3909, #3859).',
      );
    },
  );

  testWidgets(
    'fill-width root — pass 2 lays it out at exactly the pinned width, '
    'not one pixel over',
    (tester) async {
      // The 801px defect. A container-driven root measures the ambient
      // 800 in pass 1; the old pinned box then offered `pinnedWidth + 1`
      // unconditionally, a fill-width child took it, and every such cell
      // read `widthPx: flutter=801.0 web=800.0` — 88 of them on the nightly
      // sweep — while its PNG was cropped half a pixel off both edges.
      final rootKey = GlobalKey();
      final rootSize = await _pinnedRootSize(
        tester,
        rootKey,
        const SizedBox(width: double.infinity, height: 20),
      );
      final viewWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      expect(
        rootSize.width,
        viewWidth,
        reason:
            'a fill-width root came out ${rootSize.width}px wide inside a '
            '${viewWidth}px pinned box — the OverflowBox slack was granted '
            'to content that did not overhang (integer_capture.dart, '
            '`PinnedWidth.overflowMaxWidth`).',
      );
    },
  );

  testWidgets(
    'shrink-wrapped root with a fractional width still gets its slack — '
    'no RenderFlex overflow when the pin rounds down',
    (tester) async {
      // The case the slack exists for: natural width 121.3 pins to 121, and
      // a non-flexible Row must be allowed to lay out at 121.3 rather than
      // throw. Granting the slack conditionally must not lose this.
      final rootKey = GlobalKey();
      final rootSize = await _pinnedRootSize(
        tester,
        rootKey,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 60.3, height: 10),
            SizedBox(width: 61, height: 10),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(rootSize.width, closeTo(121.3, 1e-6));
    },
  );

  testWidgets(
    'a root that fills a bounded height takes its natural height — the host '
    'releases the vertical axis',
    (tester) async {
      // 31 components measured 1200 tall against Web's 74–675 because the
      // host used to offer `0..1200`: `Column(mainAxisSize: max)` and the
      // `Align` / `Center` roots took all of it. Web's wrapper is `auto`
      // tall, so the Flutter host must not offer a height to fill
      // (`capture_host.dart`).
      final rootKey = GlobalKey();
      final columnSize = await _pinnedRootSize(
        tester,
        rootKey,
        const Column(children: [SizedBox(width: 40, height: 20)]),
      );
      expect(
        columnSize.height,
        20,
        reason:
            'a default Column (mainAxisSize: max) filled the host height — '
            'the host is offering a bounded height again (capture_host.dart).',
      );

      final alignKey = GlobalKey();
      final alignSize = await _pinnedRootSize(
        tester,
        alignKey,
        const Align(child: SizedBox(width: 40, height: 20)),
      );
      expect(alignSize.height, 20);
    },
  );

  testWidgets(
    'the host keeps the width bounded — an Align root still fills it',
    (tester) async {
      // Releasing the height must not release the width: a container-driven
      // root has to fill the available width the way a Web `w-full` root
      // does. `Align` under a bounded width fills it — the documented limit
      // of the host (`capture_host.dart`).
      final rootKey = GlobalKey();
      final size = await _pinnedRootSize(
        tester,
        rootKey,
        const Align(child: SizedBox(width: 40, height: 20)),
      );
      final viewWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(size.width, viewWidth);
    },
  );
}
