// The Web harness renders every entry at the fixed capture moment, whatever
// clock its caller runs under — a calendar reads the month it opens on and
// the day it marks as today from the clock.

import 'package:clock/clock.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../../src/model/capture_clock.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/web_capture_backend.dart';

void main() {
  test(
    'a calendar renders at the capture moment, not the caller clock',
    () async {
      final entry = MatrixEntry(
        component: 'calendar',
        variant: 'none',
        theme: ParityTheme.light,
        surfaceStyle: CoreSurfaceStyleId.defaultStyle,
        tier: ParityTier.t1,
        probes: [
          rootProbeSpec(
            key: 'calendar-none-light-defaultStyle',
            flutterClassName: 'Calendar',
          ),
        ],
      );
      // A caller clock far from the capture moment stands in for the wall
      // clock: the harness must not inherit either.
      final body = await withClock(
        Clock.fixed(DateTime(2024, 3, 15)),
        () => renderCaptureBodyHtml(entry),
      );

      const l10n = DefaultCouiLocalizations.instance;
      expect(
        body,
        contains(l10n.formatMonthYear(kCaptureNow.month, kCaptureNow.year)),
      );
      expect(body, isNot(contains(l10n.formatMonthYear(3, 2024))));
    },
  );
}
