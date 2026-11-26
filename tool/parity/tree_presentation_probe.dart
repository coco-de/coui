/// Builds the live Tree fixture for an agent-controlled browser session.
///
/// From the repository root:
///   dart run tool/parity/tree_presentation_probe.dart /tmp/coui-tree-probe
///   python3 -m http.server 18764 --bind 127.0.0.1 --directory /tmp/coui-tree-probe
///   ego-browser nodejs < tool/parity/test/web/tree_presentation_ego_probe.mjs
///
/// The browser probe creates its own task Space by default. An ongoing goal can
/// supply treeProbeSpaceId and treeProbeKeepSpace globals to reuse its Space.
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:path/path.dart' as p;

import 'src/web/offline_tailwind_harness.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/parity/tree_presentation_probe.dart <output>',
    );
    exitCode = 64;
    return;
  }
  final output = Directory(p.absolute(args.single))
    ..createSync(recursive: true);
  final compiled = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O1',
    '-o',
    p.join(output.path, 'entry.js'),
    'tool/parity/src/web/tree_presentation_entry.dart',
  ]);
  if (compiled.exitCode != 0) {
    stderr.write('${compiled.stdout}\n${compiled.stderr}');
    exitCode = compiled.exitCode;
    return;
  }
  final html = buildOfflineTailwindHarnessHtml(
    bodyHtml: '<script src="entry.js"></script>',
    themeConfig: ThemeConfig.defaults(),
    vendoredTailwindScript: loadVendoredTailwindScript(),
    additionalHeadHtml: '''
<style>body{margin:0}</style>
<script>
window.probeErrors=[];
window.addEventListener('error',e=>probeErrors.push(e.message));
window.addEventListener('unhandledrejection',e=>probeErrors.push(String(e.reason)));
</script>''',
  );
  File(p.join(output.path, 'index.html')).writeAsStringSync(html);
  stdout.writeln('Tree live fixture: ${output.path}');
}
