/// Shared Puppeteer browser launch — reused by `tool/screenshot.dart`
/// (docs_site captures) and `tool/parity/capture_web.dart` (#3605, parity
/// captures) so browser startup never forks between the two capture paths
/// (architecture doc, Component ③ completion definition: "브라우저 기동
/// 로직이 `tool/screenshot.dart` 와 공유 모듈, fork 금지 — NFR-009").
library;

import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

/// `ubuntu-latest`'s AppArmor policy blocks unprivileged user namespaces
/// by default, which Chromium's setuid sandbox needs — the browser exits
/// with `FATAL: No usable sandbox!` before any page loads (#3675). Every
/// caller of [launchCaptureBrowser] only ever renders content this repo
/// built itself (an offline SSR harness file, or a `localhost` docs_site
/// build) — never a third-party/untrusted URL — so the sandbox has no
/// hostile renderer process to contain here; the usual reason to keep it
/// on (browsing attacker-controlled pages) doesn't apply to this specific
/// use. Scoped to hosted Linux CI only, so local dev keeps the sandbox
/// (any OS), and the macOS self-hosted `parity-gate` runner (`ci.yaml`)
/// — a different OS with no such AppArmor policy, unaffected by this
/// crash — is left untouched.
bool _sandboxUnavailable() =>
    Platform.isLinux && Platform.environment['CI'] == 'true';

/// Launches a headless browser sized to [width]x[height].
///
/// [deviceScaleFactor] defaults to `1` — NFR-006 reproducibility needs a
/// fixed scale factor so captures don't come out at 2x on a Retina dev
/// machine and 1x on a CI runner.
///
/// Parity captures use [softwareRasterization] because repeated macOS GPU
/// rasterization of the same preview can change antialiased pixels
/// (coco-de/coui#6532). Chrome still composites with the GPU.
Future<Browser> launchCaptureBrowser({
  required int width,
  required int height,
  double deviceScaleFactor = 1,
  String? executablePath,
  bool softwareRasterization = false,
}) => puppeteer.launch(
  executablePath: executablePath,
  args: [if (softwareRasterization) '--disable-gpu-rasterization'],
  // `noSandboxFlag` is puppeteer's own escape hatch (defaults to reading
  // `CHROME_FORCE_NO_SANDBOX`, e.g. for Docker) — `null` here (not
  // `false`) so that convention still applies outside hosted Linux CI
  // instead of being overridden.
  noSandboxFlag: _sandboxUnavailable() ? true : null,
  defaultViewport: DeviceViewport(
    width: width,
    height: height,
    deviceScaleFactor: deviceScaleFactor,
  ),
);
