#!/usr/bin/env dart

/// Prints the headless Chromium/Chrome version `browser_launch.dart`'s
/// shared launcher actually starts (#3620's completion definition:
/// "Chrome / Flutter 버전을 리포트에 기록") — capture conditions matter
/// for reproducibility the same way `tool/screenshot.dart`'s own capture
/// backend records them (#3378), and the version is only knowable by
/// actually launching the browser, not by reading a pinned config value
/// (puppeteer resolves/downloads its own revision).
///
/// Usage:
///   `dart run tool/parity/browser_info.dart`
library;

import 'dart:io';

import '../browser_launch.dart';

Future<void> main() async {
  final browser = await launchCaptureBrowser(
    width: 1,
    height: 1,
    softwareRasterization: true,
  );
  try {
    stdout.writeln(await browser.version);
  } finally {
    await browser.close();
  }
}
