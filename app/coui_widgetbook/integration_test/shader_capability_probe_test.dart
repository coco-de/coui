// M1 of the Tier 2 refraction feasibility measurement (R — 굴절 타당성 측정).
//
// Answers two questions on a real device, and nothing else:
//
//   M1-a  Does this runtime expose `ImageFilter.shader` at all?
//   M1-b  Does a minimal displacement shader, run through `BackdropFilter`,
//         actually move the pixels behind a surface?
//
// ## Why this cannot be a widget test
//
// `flutter_tester` renders with Skia, so `isShaderFilterSupported` answers
// `false` there no matter what the platform can do. A value collected that way
// is not a small error — it is a number that means nothing, and it means
// nothing in the direction that looks like a finding ("refraction is
// impossible"). Putting the file under `integration_test/` does not prevent
// that by itself: `flutter test integration_test/…` without `-d <device>`
// falls straight back to `flutter_tester`.
//
// So the device is not documentation, it is a precondition. Run it as:
//
//   flutter test integration_test/shader_capability_probe_test.dart \
//     -d <deviceId> --dart-define=PROBE_DEVICE_ID=<deviceId>
//
// ## Why this is not in CI
//
// `melos run test:flutter` filters on `dirExists: test`, which this package
// does not have, and `integration_test/` is not a default `flutter test`
// target. There is no device matrix on the runners, so a required check here
// would either be skipped or lie.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

// `foundation` and `rendering` are imported by name rather than leaned on
// through `material.dart`. The analyzer resolves `defaultTargetPlatform` and
// `RenderRepaintBoundary` without them; the device compiler does not, and it
// is the one that decides whether a measurement can be collected at all.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Supplied by the runner alongside `-d`, so every reported value carries the
/// device it came from. Empty means the probe refuses to report.
const kProbeDeviceId = String.fromEnvironment('PROBE_DEVICE_ID');

/// A valid filter program: leading `vec2`, at least one `sampler2D`.
const kProbeShaderAsset = 'shaders/probe.frag';

/// The same program minus the sampler — the counter-example that keeps "no
/// throw" from being ambiguous.
const kProbeNoSamplerShaderAsset = 'shaders/probe_no_sampler.frag';

/// Capture size. Wide enough that a mirror across x lands the two halves in
/// visibly different places.
const kProbeWidth = 200.0;
const kProbeHeight = 100.0;

/// Fraction of pixels that must differ before the backdrop counts as moved.
/// A mirror of two solid halves changes essentially all of them; this is well
/// below that and well above the noise an encoder rounding difference makes.
const kMovedPixelThreshold = 0.25;

/// Bytes per pixel in [ui.ImageByteFormat.rawRgba].
const kBytesPerPixel = 4;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('M1 — refraction capability on this runtime', () {
    setUpAll(() {
      // Fail here rather than in each measurement, so a run without a device
      // produces no values at all instead of values that look collected.
      expect(
        kProbeDeviceId,
        isNotEmpty,
        reason:
            'Pass --dart-define=PROBE_DEVICE_ID=<deviceId> matching the -d '
            'flag. Without it this run cannot say which runtime it measured, '
            'and an unattributed value is not a measurement.',
      );
    });

    testWidgets('M1-a — isShaderFilterSupported, with its device', (
      tester,
    ) async {
      final supported = ui.ImageFilter.isShaderFilterSupported;

      // The report is the deliverable, so print it whichever way it goes —
      // `false` is a result, not a failure.
      debugPrint(
        'M1-a  device=$kProbeDeviceId  platform=${defaultTargetPlatform.name}'
        '  isShaderFilterSupported=$supported',
      );

      expect(supported, isA<bool>());
    });

    testWidgets('M1-a-negative — the SDK check is live, not vacuous', (
      tester,
    ) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint(
          'M1-a-negative  device=$kProbeDeviceId  skipped: '
          'ImageFilter.shader is unsupported here, so there is no accepting '
          'path whose strictness could be measured.',
        );
        return;
      }

      final program = await tester.runAsync(
        () => ui.FragmentProgram.fromAsset(kProbeNoSamplerShaderAsset),
      );
      final shader = program!.fragmentShader();

      // If this did not throw, "the valid shader was accepted" would carry no
      // information — it would be consistent with the SDK validating nothing.
      expect(
        () => ui.ImageFilter.shader(shader),
        throwsA(isA<StateError>()),
        reason: 'a program declaring no sampler must be rejected',
      );

      debugPrint(
        'M1-a-negative  device=$kProbeDeviceId  '
        'sampler-less program rejected as expected',
      );
    });

    testWidgets('M1-b — a displacement shader moves the backdrop', (
      tester,
    ) async {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        debugPrint(
          'M1-b  device=$kProbeDeviceId  not run: M1-a is false, so there is '
          'no filter to put in front of a backdrop. Recorded as not-run, not '
          'as zero displacement.',
        );
        return;
      }

      final program = await tester.runAsync(
        () => ui.FragmentProgram.fromAsset(kProbeShaderAsset),
      );
      final filter = ui.ImageFilter.shader(program!.fragmentShader());

      final control = await _captureBackdrop(tester, filter: null);
      final filtered = await _captureBackdrop(tester, filter: filter);

      // A dead harness returns uniform bytes for both captures, and "they
      // differ" would then be false for the wrong reason. Check the control
      // actually drew the two halves before comparing anything to it.
      expect(
        _isUniform(control),
        isFalse,
        reason: 'the control capture is blank — the harness drew nothing',
      );

      final moved = _differingFraction(control, filtered);

      // "Every pixel changed" on its own cannot tell a displaced backdrop from
      // a destroyed one — a shader that returned a flat colour would score the
      // same. The shader mirrors across x, so the backdrop moved if and only
      // if each sample equals its opposite number in the control.
      final row = (kProbeHeight ~/ 2).toInt();
      final leftColumn = (kProbeWidth ~/ 4).toInt();
      final rightColumn = kProbeWidth.toInt() - 1 - leftColumn;

      final filteredLeft = _pixelAt(filtered, leftColumn, row);
      final controlRight = _pixelAt(control, rightColumn, row);
      final filteredRight = _pixelAt(filtered, rightColumn, row);
      final controlLeft = _pixelAt(control, leftColumn, row);

      debugPrint(
        'M1-b  device=$kProbeDeviceId  platform=${defaultTargetPlatform.name}'
        '  movedPixelFraction=${moved.toStringAsFixed(4)}'
        '  control[L]=$controlLeft control[R]=$controlRight'
        '  filtered[L]=$filteredLeft filtered[R]=$filteredRight',
      );

      expect(moved, greaterThan(kMovedPixelThreshold));
      expect(
        filteredLeft,
        controlRight,
        reason: 'the left sample did not take the right half of the backdrop',
      );
      expect(
        filteredRight,
        controlLeft,
        reason: 'the right sample did not take the left half of the backdrop',
      );
    });
  });
}

/// Renders two solid halves and captures them, optionally behind [filter].
///
/// `toImage` / `toByteData` never complete inside `testWidgets`' fake-async
/// zone — they hang until the test times out, which reads exactly like the
/// feature failing. `runAsync` is what makes them finish.
Future<Uint8List> _captureBackdrop(
  WidgetTester tester, {
  required ui.ImageFilter? filter,
}) async {
  final boundaryKey = GlobalKey();

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: kProbeWidth,
            height: kProbeHeight,
            child: Stack(
              children: [
                // Explicit rects rather than Row/Expanded. A childless
                // `ColoredBox` under a Row's loose cross-axis constraints
                // collapses to zero height and paints nothing, which reaches
                // the comparison as "the backdrop did not move" — a layout
                // mistake wearing the costume of a finding.
                const Positioned(
                  left: 0,
                  top: 0,
                  width: kProbeWidth / 2,
                  height: kProbeHeight,
                  child: ColoredBox(color: Color(0xFFFF0000)),
                ),
                const Positioned(
                  left: kProbeWidth / 2,
                  top: 0,
                  width: kProbeWidth / 2,
                  height: kProbeHeight,
                  child: ColoredBox(color: Color(0xFF0000FF)),
                ),
                if (filter != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: filter,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    return data!.buffer.asUint8List();
  });

  // `_pixelAt` computes its offset from [kProbeWidth]. If the capture ever
  // came back at a different scale the reads would silently land on the wrong
  // pixels and still produce a plausible-looking number.
  expect(
    bytes!.length,
    kProbeWidth.toInt() * kProbeHeight.toInt() * kBytesPerPixel,
    reason: 'capture is not at the 1:1 scale the offset maths assumes',
  );

  return bytes;
}

/// The RGBA bytes at ([x], [y]) as a hex string, for both comparison and the
/// printed report — a measurement no one can read is hard to trust.
String _pixelAt(Uint8List pixels, int x, int y) {
  final at = ((y * kProbeWidth.toInt()) + x) * kBytesPerPixel;

  return pixels
      .sublist(at, at + kBytesPerPixel)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Whether every pixel carries the same bytes — the signature of a capture
/// that recorded nothing rather than a surface that is genuinely flat.
bool _isUniform(Uint8List pixels) {
  for (var at = kBytesPerPixel; at < pixels.length; at += kBytesPerPixel) {
    for (var channel = 0; channel < kBytesPerPixel; channel++) {
      if (pixels[at + channel] != pixels[channel]) return false;
    }
  }

  return true;
}

/// Fraction of pixels whose bytes differ between the two captures.
double _differingFraction(Uint8List a, Uint8List b) {
  if (a.length != b.length) return 1;

  final total = a.length ~/ kBytesPerPixel;
  var differing = 0;
  for (var at = 0; at < a.length; at += kBytesPerPixel) {
    for (var channel = 0; channel < kBytesPerPixel; channel++) {
      if (a[at + channel] != b[at + channel]) {
        differing++;
        break;
      }
    }
  }

  return differing / total;
}
