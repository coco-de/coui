/// Exercises the built docs client's real drag bridge and Web FileInput.
///
/// Run after `cd docs_site && jaspr build` and serving build/jaspr:
/// dart run tool/parity/docs_drag_probe.dart --url=http://localhost:8080
/// --out=/tmp/docs-drag.json --screenshots=/tmp/docs-drag-images
///
/// Uses a real CDP file drop, pointer/keyboard file choosers and the existing
/// window drag bridge. Runtime failures make the command exit with code 1.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:puppeteer/protocol/input.dart' show DragData;
import 'package:puppeteer/puppeteer.dart' show Key, Page;

import '../browser_launch.dart';
import 'src/cli/flags.dart';
import 'src/web/element_capture.dart';

Future<void> _settle(Page page) => page.evaluate<void>(
  '''
  () => new Promise(resolve => requestAnimationFrame(() =>
    requestAnimationFrame(resolve)))
  '''
      .trim(),
);

Future<void> main(List<String> args) async {
  final flags = parseFlags(args);
  final base = Uri.parse(flags['url'] ?? 'http://localhost:8080');
  final output = flags['out'];
  final screenshots = flags['screenshots'];
  final directory = Directory.systemTemp.createTempSync('docs-drag-probe-');
  final file = File('${directory.path}/docs-drag-probe.txt')
    ..writeAsStringSync('A local, disposable drag regression fixture.');
  final browser = await launchCaptureBrowser(width: 1200, height: 1000);
  final results = <Map<String, Object?>>[];
  try {
    for (final (route, theme) in [
      for (final route in ['/', '/embed/file-input/'])
        for (final theme in ['light', 'dark']) (route, theme),
    ]) {
      final page = await browser.newPage();
      final failures = <String>[];
      try {
        await page.evaluateOnNewDocument(
          '''
          () => {
            window.docsDragErrors = [];
            addEventListener('error', e => docsDragErrors.push(
              e.error?.dartException?.a ?? e.message));
            addEventListener('unhandledrejection', e => docsDragErrors.push(
              e.reason?.dartException?.a ?? String(e.reason)));
          }
          '''
              .trim(),
        );
        await page.goto(base.resolve(route).toString(), wait: .load);
        await page.evaluate<void>('() => document.fonts.ready');
        await page.evaluate<void>(
          '''
          (theme) => {
            document.documentElement.setAttribute('data-theme', theme);
          }
          '''
              .trim(),
          args: [theme],
        );
        await _settle(page);

        final handlers = await page.evaluate<List<Object?>>(
          '''
          () => ['ondragenter','ondragover','ondragleave','ondrop']
            .map(name => typeof window[name])
          '''
              .trim(),
        );
        if (handlers.any((type) => type != 'function')) {
          failures.add('The real browser drag bridge is not registered');
        }

        // No DropTarget is required for these window-level plugin events.
        await page.evaluate<void>(
          '''
          () => {
            for (const type of ['dragenter', 'dragover', 'dragleave']) {
              document.body.dispatchEvent(new DragEvent(type, {
                bubbles: true, cancelable: true, clientX: 1, clientY: 1
              }));
            }
          }
          '''
              .trim(),
        );
        await _settle(page);

        if (route == '/embed/file-input/') {
          await page.waitForSelector('.coui-file-input');
          await page.evaluate<void>(
            '''
            () => {
              const zone = document.querySelector('.coui-file-input');
              zone.scrollIntoView({block:'center'});
              zone.closest('[role="button"]').focus();
            }
            '''
                .trim(),
          );
          final zone = await page.$('.coui-file-input');
          final bounds = (await zone.boundingBox)!;
          final x = bounds.left + bounds.width / 2;
          final y = bounds.top + bounds.height / 2;
          final drag = DragData(
            items: [],
            files: [file.path],
            dragOperationsMask: 1,
          );
          await page.devTools.input.dispatchDragEvent('dragEnter', x, y, drag);
          await page.devTools.input.dispatchDragEvent('dragOver', x, y, drag);
          await page.waitForFunction(
            '''
            () => getComputedStyle(document.querySelector(
              '.coui-file-input svg rect')).strokeDasharray === 'none'
            '''
                .trim(),
          );
          await page.devTools.input.dispatchDragEvent('drop', x, y, drag);
          await page.waitForFunction(
            '''
            () => document.querySelector('.coui-file-input').textContent
              .includes('docs-drag-probe.txt')
            '''
                .trim(),
          );
          await page.waitForFunction(
            '''
            () => getComputedStyle(document.querySelector(
              '.coui-file-input svg rect')).strokeDasharray !== 'none'
            '''
                .trim(),
          );
          final selected = await page.evaluate<int>(
            '''
            () => [...document.querySelectorAll('.coui-file-input span')]
              .filter(e => e.children.length === 0 &&
                e.textContent === 'docs-drag-probe.txt').length
            '''
                .trim(),
          );
          if (selected != 1) {
            failures.add('Expected one selected file, got $selected');
          }
          // Eager Flutter bindings must not intercept the Web control's
          // pointer or keyboard activation. Cancel without changing files.
          var chooser = page.waitForFileChooser();
          await page.click('.coui-file-input');
          await (await chooser).cancel();
          await page.evaluate<void>(
            '''
            () => document.querySelector('.coui-file-input')
              .closest('[role="button"]').focus()
            '''
                .trim(),
          );
          chooser = page.waitForFileChooser();
          await page.keyboard.press(Key.enter);
          await (await chooser).cancel();
          await page.mouse.move(const Point(1199, 1));
          await page.waitForFunction(
            '''
            () => document.querySelector('.coui-file-input')
              .getAnimations({subtree:true}).every(a =>
                !Number.isFinite(a.effect.getComputedTiming().endTime) ||
                a.playState === 'finished')
            '''
                .trim(),
          );
          if (screenshots != null) {
            final image = File('$screenshots/file-input-$theme.png');
            image.parent.createSync(recursive: true);
            image.writeAsBytesSync(
              await captureElementPng(page, await page.$('.coui-file-input')),
            );
          }
        }
        await _settle(page);
      } on Exception catch (error) {
        failures.add('$error');
      }
      final pageErrors = await page.evaluate<List<Object?>>(
        '() => window.docsDragErrors ?? []',
      );
      failures.addAll(pageErrors.map((error) => '$error'));
      results.add({
        'route': route,
        'theme': theme,
        'passed': failures.isEmpty,
        'failures': failures,
      });
      stdout.writeln('${failures.isEmpty ? 'PASS' : 'FAIL'} $route $theme');
      await page.close();
    }
  } finally {
    await browser.close();
    directory.deleteSync(recursive: true);
  }
  if (output != null) {
    File(output)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));
  }
  if (results.any((result) => result['passed'] != true)) {
    exitCode = 1;
  }
}
