import 'dart:io';

import 'package:test/test.dart';

import '../browser_launch.dart';

/// Mirrors `offline_tailwind_harness_test.dart`'s system-Chrome lookup —
/// avoids Puppeteer's own Chromium download so this test doesn't need
/// network access to run.
String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

void main() {
  final chromePath = _systemChromePath();

  group('launchCaptureBrowser', () {
    test(
      'launches with the requested viewport and a fixed deviceScaleFactor',
      () async {
        final browser = await launchCaptureBrowser(
          width: 640,
          height: 480,
          executablePath: chromePath,
        );
        try {
          final page = await browser.newPage();
          final viewport = page.viewport;
          expect(viewport?.width, 640);
          expect(viewport?.height, 480);
          expect(viewport?.deviceScaleFactor, 1);
        } finally {
          await browser.close();
        }
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );

    test(
      'deviceScaleFactor is overridable',
      () async {
        final browser = await launchCaptureBrowser(
          width: 320,
          height: 240,
          deviceScaleFactor: 2,
          executablePath: chromePath,
        );
        try {
          final page = await browser.newPage();
          expect(page.viewport?.deviceScaleFactor, 2);
        } finally {
          await browser.close();
        }
      },
      skip: chromePath == null ? '로컬 Chrome 실행 파일을 찾지 못해 건너뜀' : null,
    );
  });
}
