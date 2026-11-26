/// Frame timing of the glass, scene by scene and tier by tier, on both
/// platforms.
///
/// Adaptive quality (`CoreAdaptiveQuality`) trades the glass for smoothness,
/// and every number it decides by — the order of the tiers, the multiples of
/// the frame budget that call a window over or comfortable — is a starting
/// point until it has been set against what each tier costs on the hardware
/// that matters. This tool draws the same scenes at each tier and writes down
/// how
/// steadily the platform delivered frames, so those numbers can be replaced by
/// measurements.
///
/// What each platform can see differs, and the report keeps it apart:
///
///   Flutter   the engine's own timings of every frame, build and raster
///             separately (`SchedulerBinding.addTimingsCallback`), in profile
///             mode on a device — `flutter drive --profile`. Raster is the
///             stage a tier can lower.
///   Web       the interval between `requestAnimationFrame` callbacks in
///             Chrome. A browser publishes no per-frame cost; a compositor that
///             cannot keep up delays the next frame, and that is what a page
///             can see.
///
/// The scenes are named alike on both (see `--help`); the Flutter scenes are
/// `app/coui_widgetbook/integration_test/frame_timing_test.dart`, the Web ones
/// `tool/frame_timing/src/web_scenes_entry.dart`.
///
/// A run writes, into `--out`: `frame_timing_flutter.json`,
/// `frame_timing_web.json`, `frame_timing.csv` (both platforms, one row per
/// scene and tier) and `machine.json` (the machine, its load before and after,
/// the versions). The load matters: a number measured on a machine that was
/// busy with something else is a statement about that machine's afternoon.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../parity/src/web/offline_tailwind_harness.dart';

const List<String> _kSceneNames = [
  'glass-grid-1',
  'glass-grid-5',
  'glass-grid-20',
  'glass-grid-50',
  'glass-chain-5',
  'glass-chain-20',
  'swipe-list-100',
  'swipe-list-1000',
  'drawer-open',
  'menu-open',
];

/// Flutter-only scenes, run on request: the bound on what sharing the backdrop
/// between blurs could save. They are not CoUI surfaces, so a tier does not
/// apply to them.
const List<String> _kFlutterOnlyScenes = [
  'blur-plain-5',
  'blur-group-5',
  'blur-plain-20',
  'blur-group-20',
  'blur-plain-50',
  'blur-group-50',
];

const String _kUsage = '''
Frame timing of the glass, scene by scene and tier by tier.

Usage: dart run tool/frame_timing/frame_timing.dart [options]

  --platform=all|flutter|web   what to measure (default all)
  --scenes=a,b,c | all         scenes to draw (default all):
                               glass-grid-{1,5,20,50}  glass-chain-{5,20}
                               swipe-list-{100,1000}   drawer-open  menu-open
                               Flutter only, on request (not in `all`; run at
                               one tier): blur-plain-{5,20,50} against
                               blur-group-{5,20,50} — what sharing the backdrop
                               between plain blurs could save
  --tiers=full,noRefraction,solid
                               quality tiers to draw each scene at
  --seconds=4                  how long each scene is recorded
  --warmup-ms=1500             how long each scene runs before it is recorded
  --out=build/frame_timing     where the JSON, the CSV and machine.json go
  --device=macos               Flutter device id (`flutter devices`)
  --headed                     Web: a visible Chrome window (GPU compositing;
                               a headless Chrome is not representative)
  --chrome=<path>              Web: the Chrome to drive (default: the system's)
  --summarize=a.json[,b.json]  print the table of earlier runs and exit
  --help                       this text

Flutter runs `flutter drive --profile` in app/coui_widgetbook and needs a
device that can run the app in profile mode (macOS desktop: Xcode). The Web run
compiles tool/frame_timing/src/web_scenes_entry.dart with dart2js and needs a
local Chrome. Run it from the repository root.

Read the load average in machine.json before trusting a number.
''';

class _Options {
  _Options(this.values, this.flags);

  factory _Options.parse(List<String> arguments) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      if (!argument.startsWith('--')) {
        throw FormatException('unexpected argument "$argument"');
      }
      final body = argument.substring(2);
      final equals = body.indexOf('=');
      if (equals >= 0) {
        values[body.substring(0, equals)] = body.substring(equals + 1);
      } else if (const {'help', 'headed'}.contains(body)) {
        flags.add(body);
      } else if (i + 1 < arguments.length) {
        values[body] = arguments[++i];
      } else {
        throw FormatException('--$body needs a value');
      }
    }

    return _Options(values, flags);
  }

  final Map<String, String> values;
  final Set<String> flags;

  String get platform => values['platform'] ?? 'all';
  List<String> get scenes {
    final raw = values['scenes'];
    if (raw == null || raw == 'all') return _kSceneNames;
    final names = raw.split(',').map((name) => name.trim()).toList();
    final unknown = names.where(
      (name) =>
          !_kSceneNames.contains(name) && !_kFlutterOnlyScenes.contains(name),
    );
    if (unknown.isNotEmpty) {
      throw FormatException('unknown scenes ${unknown.toList()}');
    }

    return names;
  }

  List<String> get tiers => (values['tiers'] ?? 'full,noRefraction,solid')
      .split(',')
      .map((name) => CoreQualityTier.values.byName(name.trim()).name)
      .toList();
  int get seconds => int.parse(values['seconds'] ?? '4');
  int get warmupMs => int.parse(values['warmup-ms'] ?? '1500');
  String get out => values['out'] ?? 'build/frame_timing';
  String get device => values['device'] ?? 'macos';
  bool get headed => flags.contains('headed');
  String? get chrome => values['chrome'];
}

Future<int> main(List<String> arguments) async {
  final _Options options;
  try {
    options = _Options.parse(arguments);
    if (options.flags.contains('help')) {
      stdout.write(_kUsage);

      return 0;
    }
    final summarize = options.values['summarize'];
    if (summarize != null) {
      for (final file in summarize.split(',')) {
        _printTable(
          jsonDecode(File(file.trim()).readAsStringSync())
              as Map<String, Object?>,
          file.trim(),
        );
      }

      return 0;
    }
    options
      ..scenes
      ..tiers;
  } on FormatException catch (error) {
    stderr
      ..writeln('frame_timing: ${error.message}')
      ..writeln('Try --help.');

    return 64;
  }

  final out = Directory(options.out)..createSync(recursive: true);
  final machine = <String, Object?>{
    'startedAt': DateTime.now().toIso8601String(),
    'loadBefore': await _loadAverage(),
    ...await _machine(),
  };
  stdout.writeln(
    'frame_timing: load before ${machine['loadBefore']}  scenes '
    '${options.scenes.length}  tiers ${options.tiers.join(",")}  '
    '${options.seconds}s each',
  );

  final reports = <String, Map<String, Object?>>{};
  if (options.platform == 'all' || options.platform == 'flutter') {
    final report = await _runFlutter(options, out);
    if (report != null) reports['flutter'] = report;
  }
  if (options.platform == 'all' || options.platform == 'web') {
    reports['web'] = await _runWeb(options, out, machine);
  }

  machine['loadAfter'] = await _loadAverage();
  File(p.join(out.path, 'machine.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(machine),
  );
  _writeCsv(File(p.join(out.path, 'frame_timing.csv')), reports);
  for (final entry in reports.entries) {
    _printTable(entry.value, entry.key);
  }
  stdout.writeln(
    'frame_timing: load after ${machine['loadAfter']}; wrote ${out.path}',
  );

  return reports.isEmpty ? 1 : 0;
}

/// `uptime`'s three load averages, as the machine reports them.
Future<String> _loadAverage() async {
  final result = await Process.run('uptime', const []);
  final text = (result.stdout as String).trim();
  final at = text.indexOf('load average');

  return at < 0
      ? text
      : text.substring(at).replaceFirst(RegExp('^[^:]*: '), '');
}

Future<String> _run(String executable, List<String> arguments) async {
  try {
    final result = await Process.run(executable, arguments);

    return (result.stdout as String).trim();
  } on ProcessException {
    return 'unavailable';
  }
}

Future<Map<String, Object?>> _machine() async => {
  'cpu': await _run('sysctl', const ['-n', 'machdep.cpu.brand_string']),
  'cores': Platform.numberOfProcessors,
  'os': await _run('sw_vers', const ['-productVersion']),
  'flutter': (await _run('flutter', const ['--version'])).split('\n').first,
  'dart': Platform.version.split(' ').first,
  'commit': await _run('git', const ['rev-parse', '--short', 'HEAD']),
};

// ---------------------------------------------------------------- Flutter ---

Future<Map<String, Object?>?> _runFlutter(
  _Options options,
  Directory out,
) async {
  final app = Directory('app/coui_widgetbook');
  if (!app.existsSync()) {
    stderr.writeln('frame_timing: run from the repository root');

    return null;
  }
  final target = p.absolute(out.path);
  final json = File(p.join(target, 'frame_timing_flutter.json'));
  if (json.existsSync()) json.deleteSync();
  final process = await Process.start(
    Platform.environment['FLUTTER'] ?? 'flutter',
    [
      'drive',
      '--profile',
      '-d',
      options.device,
      '--driver=test_driver/frame_timing_driver.dart',
      '--target=integration_test/frame_timing_test.dart',
      '--dart-define=FT_SCENES=${options.scenes.join(",")}',
      '--dart-define=FT_TIERS=${options.tiers.join(",")}',
      '--dart-define=FT_SECONDS=${options.seconds}',
      '--dart-define=FT_WARMUP_MS=${options.warmupMs}',
    ],
    workingDirectory: app.path,
    environment: {'FT_OUT': target},
  );
  final log = File(p.join(target, 'flutter-drive.log')).openWrite();
  void forward(String line) {
    log.writeln(line);
    if (line.contains('FT  ')) stdout.writeln(line);
  }

  final done = Future.wait([
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(forward),
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(forward),
  ]);
  final code = await process.exitCode;
  await done;
  await log.close();
  if (code != 0 || !json.existsSync()) {
    stderr.writeln(
      'frame_timing: flutter drive exited $code and wrote no result; '
      'see ${p.join(target, 'flutter-drive.log')}',
    );
    // A run that failed part-way still printed one JSON line per finished
    // scene and tier.
    final partial = [
      for (final line in File(
        p.join(target, 'flutter-drive.log'),
      ).readAsLinesSync())
        if (line.contains('FTJSON '))
          jsonDecode(line.substring(line.indexOf('FTJSON ') + 7))
              as Map<String, Object?>,
    ];
    if (partial.isEmpty) return null;
    stderr.writeln('frame_timing: keeping the ${partial.length} finished runs');
    final report = <String, Object?>{
      'results': partial,
      'machine': {'partial': true},
      'settings': {
        'seconds': options.seconds,
        'warmupMs': options.warmupMs,
        'tiers': options.tiers,
      },
    };
    json.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

    return report;
  }

  return jsonDecode(json.readAsStringSync()) as Map<String, Object?>;
}

// -------------------------------------------------------------------- Web ---

/// The page's recorder: the intervals between frames over a number of
/// milliseconds, with the list scrolled at 2400 px/s in `scroll` mode, and the
/// long animation frames the browser reported meanwhile.
const String _kRecorder = '''
<script>
window.couiFtRecord = function (ms, mode) {
  return new Promise(function (done) {
    var out = [], last = null, start = null, loaf = [], dir = 1, y = 0;
    var list = mode === 'scroll' ? document.getElementById('ft-list') : null;
    var observer = null;
    try {
      observer = new PerformanceObserver(function (entries) {
        entries.getEntries().forEach(function (e) { loaf.push(e.duration); });
      });
      observer.observe({ type: 'long-animation-frame' });
    } catch (e) { observer = null; }
    function frame(t) {
      if (start === null) start = t;
      if (last !== null) out.push(t - last);
      if (list) {
        var dt = last === null ? 0 : (t - last) / 1000;
        var top = list.scrollHeight - list.clientHeight;
        y += dir * 2400 * dt;
        if (y > top) { y = top; dir = -1; } else if (y < 0) { y = 0; dir = 1; }
        list.scrollTop = y;
      }
      last = t;
      if (t - start < ms) requestAnimationFrame(frame);
      else {
        if (observer) observer.disconnect();
        done({ intervals: out, longFrames: loaf });
      }
    }
    requestAnimationFrame(frame);
  });
};
</script>
''';

String? _systemChrome() {
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

Map<String, int> _percentiles(List<int> sorted) => {
  'p50': CoreFrameStats.percentile(sorted, 50),
  'p75': CoreFrameStats.percentile(sorted, 75),
  'p95': CoreFrameStats.percentile(sorted, 95),
  'p99': CoreFrameStats.percentile(sorted, 99),
  'max': sorted.isEmpty ? 0 : sorted.last,
};

Future<Map<String, Object?>> _runWeb(
  _Options options,
  Directory out,
  Map<String, Object?> machine,
) async {
  final chrome = options.chrome ?? _systemChrome();
  if (chrome == null) {
    throw StateError('no Chrome found; pass --chrome=<path>');
  }
  machine['chrome'] = await _run(chrome, const ['--version']);
  final work = Directory.systemTemp.createTempSync('coui-frame-timing-');
  final js = p.join(work.path, 'scenes.js');
  stdout.writeln('frame_timing: compiling the Web scenes');
  final compiled = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O2',
    '-o',
    js,
    'tool/frame_timing/src/web_scenes_entry.dart',
  ]);
  if (compiled.exitCode != 0) {
    throw StateError('compiling the Web scenes failed:\n${compiled.stderr}');
  }
  final html = buildOfflineTailwindHarnessHtml(
    bodyHtml: '$_kRecorder<script>${File(js).readAsStringSync()}</script>',
    themeConfig: ThemeConfig.defaults(),
    vendoredTailwindScript: loadVendoredTailwindScript(),
    surfaceStyleId: 'liquidGlass',
  ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
  final page = File(p.join(work.path, 'index.html'))..writeAsStringSync(html);

  final browser = await pptr.puppeteer.launch(
    executablePath: chrome,
    headless: !options.headed,
    args: const [
      // A window that is behind another must not be throttled: the point is to
      // see how steadily the page is given frames.
      '--disable-background-timer-throttling',
      '--disable-renderer-backgrounding',
      '--disable-backgrounding-occluded-windows',
    ],
    defaultViewport: const pptr.DeviceViewport(
      width: 800,
      height: 560,
      deviceScaleFactor: 2,
    ),
  );
  final results = <Map<String, Object?>>[];
  try {
    for (final name in options.scenes) {
      if (_kFlutterOnlyScenes.contains(name)) continue;
      for (final tier in options.tiers) {
        final tab = await browser.newPage();
        await tab.goto(Uri.file(page.path).toString(), wait: pptr.Until.load);
        await tab.waitForFunction('() => typeof couiFtMount === "function"');
        final match = RegExp(r'^(.*?)(?:-(\d+))?$').firstMatch(name)!;
        final scene = match.group(1)!;
        final n = int.tryParse(match.group(2) ?? '') ?? 1;
        await tab.evaluate<void>(
          '(json) => couiFtMount(json)',
          args: [
            jsonEncode({'scene': scene, 'n': n, 'tier': tier}),
          ],
        );
        // Let the scene mount and the first frames pass, then warm up.
        await Future<void>.delayed(
          Duration(milliseconds: 600 + options.warmupMs),
        );

        var mode = 'plain';
        if (scene == 'swipe-list') {
          mode = 'scroll';
        } else if (scene == 'drawer-open') {
          await tab.evaluate<void>('() => couiFtDrawer()');
        } else if (scene == 'menu-open') {
          final box = await (await tab.$('#ft-menu-target')).boundingBox;
          if (box != null) {
            await tab.mouse.click(
              pptr.Point(box.left + box.width / 2, box.top + box.height / 2),
              button: pptr.MouseButton.right,
            );
          }
        }
        final recorded = await tab.evaluate<Map<String, dynamic>>(
          '(ms, mode) => couiFtRecord(ms, mode)',
          args: [options.seconds * 1000, mode],
        );
        await tab.close();

        final intervals = [
          for (final value in recorded['intervals'] as List)
            ((value as num) * Duration.microsecondsPerMillisecond).round(),
        ];
        final hz = intervals.length >= CoreFrameBudget.minimumEstimateIntervals
            ? CoreFrameBudget.estimateRefreshRate(
                intervals.take(CoreFrameBudget.estimateIntervals).toList(),
              )
            : CoreFrameBudget.defaultRefreshRate;
        final budget = CoreFrameBudget.microsFor(hz);
        final sorted = [...intervals]..sort();
        final long = (recorded['longFrames'] as List).length;
        results.add({
          'scene': name,
          'tier': tier,
          'frames': intervals.length,
          'refreshHz': hz,
          'budgetMicros': budget,
          'interval': _percentiles(sorted),
          'overBudget': intervals.where((i) => i > budget * 3 ~/ 2).length,
          'longAnimationFrames': long,
        });
        stdout.writeln(
          'FT  web  $name  $tier  frames=${intervals.length}  '
          'interval p95=${_percentiles(sorted)['p95']}us  '
          'over=${results.last['overBudget']}',
        );
      }
    }
  } finally {
    await browser.close();
    work.deleteSync(recursive: true);
  }

  final report = <String, Object?>{
    'results': results,
    'machine': {
      'chrome': machine['chrome'],
      'headed': options.headed,
    },
    'settings': {
      'seconds': options.seconds,
      'warmupMs': options.warmupMs,
      'tiers': options.tiers,
    },
  };
  File(p.join(out.path, 'frame_timing_web.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  return report;
}

// ------------------------------------------------------------- the report ---

void _writeCsv(File file, Map<String, Map<String, Object?>> reports) {
  final rows = <String>[
    [
      'platform',
      'scene',
      'tier',
      'frames',
      'refresh_hz',
      'budget_us',
      'build_p50_us',
      'build_p95_us',
      'raster_p50_us',
      'raster_p75_us',
      'raster_p95_us',
      'raster_max_us',
      'total_p95_us',
      'interval_p50_us',
      'interval_p75_us',
      'interval_p95_us',
      'interval_max_us',
      'over_budget',
    ].join(','),
  ];
  for (final entry in reports.entries) {
    for (final row
        in (entry.value['results']! as List).cast<Map<String, Object?>>()) {
      Object? at(String stage, String key) =>
          (row[stage] as Map<String, Object?>?)?[key] ?? '';
      rows.add(
        [
          entry.key,
          row['scene'],
          row['tier'],
          row['frames'],
          row['refreshHz'],
          row['budgetMicros'],
          at('build', 'p50'),
          at('build', 'p95'),
          at('raster', 'p50'),
          at('raster', 'p75'),
          at('raster', 'p95'),
          at('raster', 'max'),
          at('total', 'p95'),
          at('interval', 'p50'),
          at('interval', 'p75'),
          at('interval', 'p95'),
          at('interval', 'max'),
          row['rasterOverBudget'] ?? row['overBudget'] ?? '',
        ].join(','),
      );
    }
  }
  file.writeAsStringSync('${rows.join("\n")}\n');
}

/// The table of one platform's report: per scene, each tier's key number and
/// what the step down from the tier above saved.
void _printTable(Map<String, Object?> report, String label) {
  final results = (report['results']! as List).cast<Map<String, Object?>>();
  final flutter = results.isNotEmpty && results.first.containsKey('raster');
  final metric = flutter ? 'raster' : 'interval';
  stdout
    ..writeln()
    ..writeln(
      '== $label: ${flutter ? "raster time" : "frame interval"}, '
      'p50 / p95 / max (µs), and the p95 saved against the tier above ==',
    );
  final scenes = <String>[];
  for (final row in results) {
    if (!scenes.contains(row['scene'])) scenes.add(row['scene']! as String);
  }
  final width = scenes.fold<int>(0, (w, s) => max(w, s.length));
  for (final scene in scenes) {
    int? previous;
    for (final row in results.where((r) => r['scene'] == scene)) {
      final stats = row[metric]! as Map<String, Object?>;
      final p95 = stats['p95']! as int;
      final difference = previous == null ? 0 : previous - p95;
      final saved = previous == null
          ? ''
          : difference >= 0
          ? '  (saves $difference)'
          : '  (costs ${-difference} more)';
      final name = scene.padRight(width);
      final tier = (row['tier']! as String).padRight(13);
      stdout.writeln(
        '$name  $tier ${stats['p50']} / $p95 / ${stats['max']}$saved'
        '   frames ${row['frames']}',
      );
      previous = p95;
    }
  }
}
