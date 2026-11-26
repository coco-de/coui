import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

void main() {
  test('Escape only notifies the open controlled dialog', () async {
    final dir = Directory.systemTemp.createTempSync('coui-dialog-keyboard-');
    try {
      final entry = File('${dir.path}/entry.dart')..writeAsStringSync(_fixture);
      final js = File('${dir.path}/entry.js');
      final compile = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-Djaspr.flags.release=true',
        '--packages=${File('.dart_tool/package_config.json').absolute.path}',
        entry.path,
        '-o',
        js.path,
      ]);
      expect(
        compile.exitCode,
        0,
        reason: '${compile.stdout}\n${compile.stderr}',
      );
      final html = File('${dir.path}/index.html')
        ..writeAsStringSync(
          buildOfflineTailwindHarnessHtml(
            bodyHtml: '<script>${js.readAsStringSync()}</script>',
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: loadVendoredTailwindScript(),
          ),
        );
      final browser = await launchCaptureBrowser(width: 800, height: 600);
      try {
        final page = await browser.newPage();
        final errors = <String>[];
        page.onError.listen((error) => errors.add('$error'));
        await page.setOfflineMode(true);
        await page.goto(html.uri.toString(), wait: .load);
        await page.waitForSelector('#counts');

        Future<void> counts(String expected) => page.waitForFunction(
          '() => document.getElementById("counts").textContent === '
          '${jsonEncode(expected)}',
        );
        Future<void> escape() async {
          await page.keyboard.press(pptr.Key.escape);
          await page.evaluate<void>(
            '() => new Promise(r => requestAnimationFrame(() => '
            'requestAnimationFrame(r)))',
          );
        }

        await escape();
        expect(
          await page.$eval<String>('#counts', 'e => e.textContent'),
          '0/0',
        );
        for (var closed = 1; closed <= 2; closed++) {
          // These are parent prop updates, including while the modal makes
          // its background inert. Escape itself is a real keyboard event.
          await page.evaluate<void>(
            '() => document.getElementById("open").click()',
          );
          await page.waitForSelector('[role="dialog"]');
          await page.keyboard.press(pptr.Key.enter);
          expect(
            await page.$eval<String>('#counts', 'e => e.textContent'),
            '${closed - 1}/0',
          );
          await escape();
          await counts('$closed/0');
          // A closing animation may still be visible. It has already
          // notified the owner and must not notify it a second time.
          await escape();
          expect(
            await page.$eval<String>('#counts', 'e => e.textContent'),
            '$closed/0',
          );
          await page.waitForFunction(
            '() => !document.querySelector("[role=dialog]")',
          );
          await escape();
          expect(
            await page.$eval<String>('#counts', 'e => e.textContent'),
            '$closed/0',
          );
        }
        expect(errors, isEmpty);
      } finally {
        await browser.close();
      }
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}

const String _fixture = r'''
import 'package:coui_web/coui_web.dart';
void main() => runApp(CoUIWeb(theme: .coui, child: const Probe()));
class Probe extends StatefulComponent {
  const Probe({super.key});
  @override State<Probe> createState() => ProbeState();
}
class ProbeState extends State<Probe> {
  bool open = false;
  int closes = 0, hiddenCloses = 0;
  @override Component build(BuildContext context) => div([
    button([const Text('Open')], id: 'open',
      onClick: () => setState(() => open = true)),
    span([Text('$closes/$hiddenCloses')], id: 'counts'),
    Dialog(open: open, title: const Text('Controlled dialog'),
      content: const Text('Body'),
      onClose: () => setState(() { closes++; open = false; })),
    Dialog(open: false, title: const Text('Closed sibling'),
      onClose: () => setState(() => hiddenCloses++)),
  ]);
}
''';
