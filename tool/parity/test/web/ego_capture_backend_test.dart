import 'dart:convert';
import 'dart:io';
import 'dart:math' show Rectangle;
import 'dart:typed_data';

import 'package:docs_core/markdown/repo_root.dart' show findRepoRoot;
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/web/ego_capture_backend.dart';
import '../../src/web/element_capture.dart';
import '../../src/web/web_capture_backend.dart';

MatrixEntry entry({bool stage = false}) => MatrixEntry.fromJson({
  'component': 'test',
  'variant': 'default',
  'theme': 'light',
  'surfaceStyle': 'defaultStyle',
  'tier': 't1',
  'probes': [
    for (final role in ['root', if (stage) 'stage'])
      {
        'role': role,
        'webSelector': '#$role',
        'flutterFinder': 'byKey:$role',
        'fields': <String>[],
      },
  ],
});

Map<String, Object?> box(
  double left,
  double top,
  double width,
  double height, {
  double scrollX = 0,
  double scrollY = 0,
}) => {
  'borderQuad': [
    left,
    top,
    left + width,
    top,
    left + width,
    top + height,
    left,
    top + height,
  ],
  'scrollX': scrollX,
  'scrollY': scrollY,
};

// Executes the real transport with a fake native Page and real owned files.
// This tests restoration/error protocol, not a browser screenshot or paint.
Future<Map<String, Object?>> transportProtocol(String mode) async {
  final directory = Directory.systemTemp.createTempSync('ego-native-protocol-');
  try {
    final input = File('${directory.path}/instructions.json');
    final cleanup = File('${directory.path}/cleanup.json');
    final calls = File('${directory.path}/mock-calls.json');
    final clips = File('${directory.path}/clips.json')
      ..writeAsStringSync(
        jsonEncode({
          'root': {'x': 0, 'y': 0, 'width': 100, 'height': 20, 'scale': 1},
        }),
      );
    input.writeAsStringSync(
      jsonEncode({
        'space': 1,
        'page': 'owned',
        'url': 'file:///owned-protocol.html',
        'width': 800,
        'timeoutMs': 1000,
        'cleanupCallTimeoutMs': 1000,
        'softDeadlineEpochMs': DateTime.now()
            .add(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
        'cancelPath': '${directory.path}/cancel.json',
        'imagePatterns': <Object?>[],
        'networkImageBase64': 'AA==',
        'runtimeReady': null,
        'fixedTime': false,
        'probes': [
          {'role': 'root', 'webSelector': '#root', 'fields': <String>[]},
        ],
        'scripts': {
          'iconify': '()=>true',
          'fonts': 'async()=>true',
          'images': 'async()=>true',
          'twoFrames': '()=>true',
          'context': '()=>JSON.stringify({mockContext:true})',
          'box': 'selector=>({mockBox:selector})',
          'probe': 'selector=>JSON.stringify({mockProbe:selector})',
        },
        'geometryPath': '${directory.path}/geometry.json',
        'clipsPath': clips.path,
        'resultPath': '${directory.path}/result.json',
        'cleanupPath': cleanup.path,
        'pngDirectory': directory.path,
      }),
    );
    final journal = File('${input.path}.trace.jsonl');
    if (mode.startsWith('journal-')) {
      Directory(journal.path).createSync();
    }
    final transport = File(
      '${findRepoRoot().path}/tool/parity/src/web/ego_capture_transport.mjs',
    ).readAsStringSync().replaceAll('__INSTRUCTIONS__', jsonEncode(input.path));
    final script = File('${directory.path}/protocol.mjs')
      ..writeAsStringSync('''
const mockMode=${jsonEncode(mode)}, mockCalls=[];
const mockHang=()=>new Promise(()=>{setInterval(()=>{},1000);});
const mockCopy=value=>JSON.parse(JSON.stringify(value));
const mockBefore={width:960,height:891,dpr:2,offline:false,mobile:false,touchPoints:0,
  screen:{width:1728,height:1117,availWidth:1728,availHeight:1084,colorDepth:30,pixelDepth:30,orientation:'landscape-primary',angle:0},
  visual:{width:960,height:891,scale:1,offsetLeft:0,offsetTop:0}};
let mockEnvironment=mockCopy(mockBefore), mockOverrides=0;
let mockPendingRestoration=null, mockRestorationReads=0, mockSettled=false;
const mockDelayRestoration=()=>{
  mockPendingRestoration=mockCopy(mockEnvironment);
  mockEnvironment.screen.availHeight=1000;
  mockRestorationReads=0;
};
const mockPage={
  async cdp(method,params){
    mockCalls.push({method,params});
    if((mockMode==='initial-cdp-stall' && method==='Runtime.evaluate') ||
       (mockMode==='navigation-stall' && method==='Page.navigate') ||
       (mockMode==='cleanup-stall' && method==='Fetch.disable'))await mockHang();
    if(method==='Runtime.evaluate'){
      const code=params.expression;
      if(params.returnByValue===false)return {result:{objectId:'owned-root'}};
      let value=true;
      if(code.includes('screen:{width:screen.width')){
        if(mockPendingRestoration && ++mockRestorationReads===3){
          mockEnvironment=mockPendingRestoration;mockPendingRestoration=null;mockSettled=true;
        }
        if(mockMode==='clear-settling-native-error' && mockPendingRestoration && mockRestorationReads===2){
          const error=new Error('EGO_USER_TAKEOVER');error.code='EGO_USER_TAKEOVER';throw error;
        }
        if(mockMode==='clear-settled-then-drift' && mockSettled && !mockPendingRestoration && ++mockRestorationReads>4)mockEnvironment.screen.availHeight=1000;
        value=mockCopy(mockEnvironment);
      }
      else if(code==='navigator.onLine')value=!mockEnvironment.offline;
      else if(code==='navigator.userAgent')value='Mock protocol only';
      else if(code.includes('mockContext')||code.includes('mockProbe'))value='{}';
      else if(code.includes('scrollX'))value={x:0,y:0};
      else if(code.includes('offline:!navigator.onLine'))value=mockCopy(mockEnvironment);
      return {result:{value}};
    }
    if(method==='Emulation.setDeviceMetricsOverride'){
      mockOverrides++;
      if(mockOverrides===1){
        mockEnvironment.width=params.width;mockEnvironment.height=params.height;
        mockEnvironment.dpr=params.deviceScaleFactor;
        mockEnvironment.visual.width=params.width;mockEnvironment.visual.height=params.height;
      }else{
        mockEnvironment=mockCopy(mockBefore);
        if(mockMode!=='fallback-exact' && mockMode!=='explicit-delayed')mockEnvironment.screen.availHeight=1117;
        if(mockMode==='explicit-delayed')mockDelayRestoration();
      }
    }
    if(method==='Emulation.clearDeviceMetricsOverride'){
      const offline=mockEnvironment.offline;
      mockEnvironment=mockCopy(mockBefore);mockEnvironment.offline=offline;
      if(mockMode!=='clear-exact' && mockMode!=='clear-delayed' && mockMode!=='clear-settling-native-error' && mockMode!=='clear-settled-then-drift'){
        mockEnvironment.width=800;mockEnvironment.height=1200;
        mockEnvironment.visual.width=800;mockEnvironment.visual.height=1200;
        if(mockMode.startsWith('fallback-') || mockMode==='explicit-delayed')mockEnvironment.dpr=1;
      }
      if(mockMode==='clear-delayed' || mockMode==='clear-settling-native-error' || mockMode==='clear-settled-then-drift')mockDelayRestoration();
    }
    if(method==='Emulation.setVisibleSize'){
      if(mockMode==='visible-native-error'){
        const error=new Error('EGO_PAGE_NOT_AGENT_OWNED');error.code='EGO_PAGE_NOT_AGENT_OWNED';throw error;
      }
      if(mockMode==='visible-unsupported')throw new Error('Emulation.setVisibleSize method not supported');
      mockEnvironment.width=params.width;mockEnvironment.height=params.height;
      mockEnvironment.visual.width=params.width;mockEnvironment.visual.height=params.height;
      if(mockMode==='visible-delayed')mockDelayRestoration();
    }
    if(method==='Network.emulateNetworkConditions')mockEnvironment.offline=params.offline;
    if(method==='DOM.getBoxModel')return {model:{border:[0,0,100,0,100,20,0,20]}};
    if(method==='Page.captureScreenshot'){
      if(mockMode==='screenshot-native-error'||mockMode==='journal-native-error'){
        const error=new Error('EGO_CDP_REQUEST_TIMEOUT private-fixture-message');error.code='EGO_CDP_REQUEST_TIMEOUT';throw error;
      }
      return {data:Buffer.from('mock protocol pixels').toString('base64')};
    }
    return {};
  },
  async events(){return [];},
  async snapshot(){mockCalls.push({method:'Page.snapshot'});return 'Mock snapshot';}
};
globalThis.taskSpace=async()=>{
  if(mockMode==='task-space-stall')await mockHang();
  return {ownership:'agent',page:()=>mockPage};
};
$transport
await fs.writeFile(${jsonEncode(calls.path)},JSON.stringify({calls:mockCalls,before:mockBefore,after:mockEnvironment}));
''');
    int exit;
    Object stderr;
    Map<String, Object?>? parent;
    if (mode.endsWith('-stall')) {
      final process = await Process.start('node', [script.path]);
      final output = process.stdout.drain<void>();
      final errors = process.stderr.transform(utf8.decoder).join();
      try {
        final expected = switch (mode) {
          'task-space-stall' => ('taskSpace', 'begin'),
          'initial-cdp-stall' => ('Runtime.evaluate', 'begin'),
          'navigation-stall' => ('Page.navigate', 'begin'),
          _ => ('Fetch.disable', 'cleanup-begin'),
        };
        final until = DateTime.now().add(const Duration(seconds: 5));
        var entered = false;
        while (!entered && DateTime.now().isBefore(until)) {
          if (journal.existsSync()) {
            entered = journal.readAsLinesSync().any((line) {
              final row = jsonDecode(line) as Map;
              return row['operation'] == expected.$1 &&
                  row['phase'] == expected.$2;
            });
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(entered, isTrue, reason: 'Fake operation must be pending');
        final receipt = File('${directory.path}/parent-control.json');
        final result = await superviseEgoCaptureWorker(
          process: process,
          entry: entry(),
          geometry: File('${directory.path}/geometry.json'),
          clips: clips,
          cancel: File('${directory.path}/cancel.json'),
          cleanup: cleanup,
          receipt: receipt,
          softDeadline: DateTime.now(),
          cleanupGrace: const Duration(milliseconds: 100),
        );
        exit = result.exitCode;
        parent = (jsonDecode(receipt.readAsStringSync()) as Map)
            .cast<String, Object?>();
      } finally {
        process.kill();
        await process.exitCode;
      }
      await output;
      stderr = await errors;
    } else {
      final process = await Process.run('node', [script.path]);
      exit = process.exitCode;
      stderr = process.stderr as String;
    }
    return {
      'exit': exit,
      'cleanup': cleanup.existsSync()
          ? jsonDecode(cleanup.readAsStringSync())
          : null,
      'mock': calls.existsSync() ? jsonDecode(calls.readAsStringSync()) : null,
      'stderr': stderr,
      'parent': parent,
      'journal': journal.existsSync()
          ? journal.readAsLinesSync().map(jsonDecode).toList()
          : <Object?>[],
    };
  } finally {
    directory.deleteSync(recursive: true);
  }
}

List<Map<String, Object?>> protocolCalls(Map<String, Object?> result) =>
    ((result['mock']! as Map)['calls']! as List)
        .map((value) => (value as Map).cast<String, Object?>())
        .toList();

void main() {
  group('native metrics restoration protocol', () {
    test(
      'clear preserves the native work area after a visible viewport reset',
      () async {
        final result = await transportProtocol('visible-needed');
        final cleanup = result['cleanup']! as Map;
        expect(
          cleanup['observedEnvironmentEqual'],
          isTrue,
          reason: jsonEncode({
            'before': cleanup['beforeEnvironment'],
            'after': cleanup['afterEnvironment'],
          }),
        );
        expect(result['exit'], 0);
        expect(cleanup['complete'], isTrue);
        final mock = result['mock']! as Map;
        final calls = protocolCalls(result);
        expect(
          calls.where(
            (call) => call['method'] == 'Emulation.setDeviceMetricsOverride',
          ),
          hasLength(1),
        );
        expect(
          calls
              .where(
                (call) => call['method'] == 'Emulation.setVisibleSize',
              )
              .single['params'],
          {'width': 960, 'height': 891},
        );
        expect(mock['after'], mock['before']);
      },
    );
    test('happy clear path needs no visible or explicit restoration', () async {
      final result = await transportProtocol('clear-exact');
      final cleanup = result['cleanup']! as Map;
      expect(result['exit'], 0);
      expect(cleanup['complete'], isTrue);
      final journal = result['journal']! as List;
      var sequence = 0;
      for (final raw in journal) {
        final row = raw as Map;
        expect(row.keys.toSet(), {
          'sequence',
          'operation',
          'phase',
          'errorCode',
        });
        expect(row['sequence'], greaterThan(sequence));
        sequence = row['sequence'] as int;
      }
      expect(journal, isNotEmpty);
      final calls = protocolCalls(result);
      expect(
        calls.where(
          (call) => call['method'] == 'Emulation.setVisibleSize',
        ),
        isEmpty,
      );
      expect(
        calls.where(
          (call) => call['method'] == 'Emulation.setDeviceMetricsOverride',
        ),
        hasLength(1),
      );
    });
    for (final mode in [
      'clear-delayed',
      'visible-delayed',
      'explicit-delayed',
    ]) {
      test('waits for exact environment restoration after $mode', () async {
        final result = await transportProtocol(mode);
        final cleanup = result['cleanup']! as Map;
        expect(result['exit'], 0);
        expect(cleanup['complete'], isTrue);
        expect(cleanup['observedEnvironmentEqual'], isTrue);
        final mock = result['mock']! as Map;
        expect(mock['after'], mock['before']);
        final calls = protocolCalls(result);
        expect(
          calls.where((call) => call['method'] == 'Page.captureScreenshot'),
          hasLength(1),
        );
        expect(
          calls.where((call) => call['method'] == 'Emulation.setVisibleSize'),
          hasLength(mode == 'clear-delayed' ? 0 : 1),
        );
        expect(
          calls.where(
            (call) => call['method'] == 'Emulation.setDeviceMetricsOverride',
          ),
          hasLength(mode == 'explicit-delayed' ? 2 : 1),
        );
      });
    }
    test('native stop while waiting permits no further Page calls', () async {
      final result = await transportProtocol('clear-settling-native-error');
      final cleanup = result['cleanup']! as Map;
      expect(result['exit'], 1);
      expect(cleanup['complete'], isFalse);
      expect(
        (cleanup['terminalStop']! as Map)['error'],
        containsPair('code', 'EGO_USER_TAKEOVER'),
      );
      expect(protocolCalls(result).last['method'], 'Runtime.evaluate');
    });
    test(
      'final observation rejects drift after an exact settled read',
      () async {
        final result = await transportProtocol('clear-settled-then-drift');
        final cleanup = result['cleanup']! as Map;
        expect(result['exit'], 1);
        expect(cleanup['complete'], isFalse);
        expect(cleanup['observedEnvironmentEqual'], isFalse);
        final metrics = cleanup['metricsRestoration']! as Map;
        expect(metrics['settledAfterClear'], cleanup['beforeEnvironment']);
        expect(protocolCalls(result).last['method'], 'Runtime.evaluate');
      },
    );
    test('native screenshot stop permits no cleanup Page calls', () async {
      final result = await transportProtocol('screenshot-native-error');
      final cleanup = result['cleanup']! as Map;
      expect(result['exit'], 1);
      expect(cleanup['complete'], isFalse);
      expect(cleanup['terminalStop'], isNotNull);
      final calls = protocolCalls(result);
      expect(calls.last['method'], 'Page.captureScreenshot');
      expect(
        jsonEncode(result['journal']),
        isNot(contains('private-fixture-message')),
      );
    });
    test(
      'native visible-size stop permits no following readback or fallback',
      () async {
        final result = await transportProtocol('visible-native-error');
        final cleanup = result['cleanup']! as Map;
        expect(result['exit'], 1);
        expect(cleanup['complete'], isFalse);
        expect(
          (cleanup['terminalStop']! as Map)['error'],
          containsPair('code', 'EGO_PAGE_NOT_AGENT_OWNED'),
        );
        final calls = protocolCalls(result);
        expect(calls.last['method'], 'Emulation.setVisibleSize');
      },
    );
    test('unsupported visible-size restoration fails strictly', () async {
      final result = await transportProtocol('visible-unsupported');
      final cleanup = result['cleanup']! as Map;
      expect(result['exit'], 1);
      expect(cleanup['complete'], isFalse);
      expect(cleanup['terminalStop'], isNull);
      final metrics = (cleanup['steps']! as Map)['metrics']! as Map;
      expect(metrics['status'], 'failed');
      expect(
        (metrics['error']! as Map)['message'],
        contains('method not supported'),
      );
    });
    test(
      'a remaining metric difference uses the existing explicit fallback',
      () async {
        final result = await transportProtocol('fallback-exact');
        final cleanup = result['cleanup']! as Map;
        expect(result['exit'], 0);
        expect(cleanup['complete'], isTrue);
        final calls = protocolCalls(result);
        expect(
          calls.where(
            (call) => call['method'] == 'Emulation.setDeviceMetricsOverride',
          ),
          hasLength(2),
        );
      },
    );
    test(
      'explicit fallback still rejects changed native work-area fields',
      () async {
        final result = await transportProtocol('fallback-work-area-mismatch');
        final cleanup = result['cleanup']! as Map;
        expect(result['exit'], 1);
        expect(cleanup['complete'], isFalse);
        expect(cleanup['observedEnvironmentEqual'], isFalse);
        expect(
          ((cleanup['afterEnvironment']! as Map)['screen']!
              as Map)['availHeight'],
          1117,
        );
        expect(
          ((cleanup['beforeEnvironment']! as Map)['screen']!
              as Map)['availHeight'],
          1084,
        );
      },
    );
  });
  for (final mode in [
    'task-space-stall',
    'initial-cdp-stall',
    'navigation-stall',
    'cleanup-stall',
  ]) {
    test('durable diagnostic survives pending $mode', () async {
      final result = await transportProtocol(mode);
      final parent = result['parent']! as Map;
      expect(result['exit'], isNot(0));
      expect(parent['workerEntryConfirmed'], isTrue);
      expect(parent['journalReadFailed'], isFalse);
      final last = parent['lastDurableWorkerState']! as Map;
      expect(last['operation'], switch (mode) {
        'task-space-stall' => 'taskSpace',
        'initial-cdp-stall' => 'Runtime.evaluate',
        'navigation-stall' => 'Page.navigate',
        _ => 'Fetch.disable',
      });
      expect(
        last['phase'],
        mode == 'cleanup-stall' ? 'cleanup-begin' : 'begin',
      );
      expect(parent['overallCleanupComplete'], isFalse);
      expect(parent['unconfirmedRestoration'], ['fetch', 'offline', 'metrics']);
      expect(parent['parentBrowserCalls'], 0);
    });
  }
  for (final mode in ['journal-unwritable', 'journal-native-error']) {
    test('journal IO failure preserves original $mode outcome', () async {
      final result = await transportProtocol(mode);
      final cleanup = result['cleanup']! as Map;
      expect(cleanup['journalWriteFailed'], isTrue);
      expect(result['exit'], mode == 'journal-unwritable' ? 0 : 1);
      expect(cleanup['complete'], mode == 'journal-unwritable');
      if (mode == 'journal-native-error') {
        expect(protocolCalls(result).last['method'], 'Page.captureScreenshot');
        expect(
          (cleanup['terminalStop'] as Map)['error'],
          containsPair('code', 'EGO_CDP_REQUEST_TIMEOUT'),
        );
      }
    });
  }
  group('pinned screenshot transport rounding', () {
    test('integer rectangles retain their original coordinates', () {
      expect(captureCdpClip(const Rectangle<num>(4, 6, 80, 24)), {
        'x': 4,
        'y': 6,
        'width': 80,
        'height': 24,
        'scale': 1,
      });
    });
    test('fractional origin contributes to final raster size', () {
      expect(
        captureCdpClip(const Rectangle<num>(19.375, 17.25, 240.5, 1300.25)),
        {'x': 19, 'y': 17, 'width': 241, 'height': 1301, 'scale': 1},
      );
    });
    test('negative half origins follow Dart rounding', () {
      expect(captureCdpClip(const Rectangle<num>(-0.5, -1.5, 3.5, 4.5)), {
        'x': -1,
        'y': -2,
        'width': 4,
        'height': 5,
        'scale': 1,
      });
    });
    test('box and scroll are summed before the single rounding step', () {
      final clips = egoCaptureClips(
        entry: entry(),
        boxes: {
          'root': box(-0.5, 2.25, 20.5, 30.5, scrollX: 3.25, scrollY: 0.25),
        },
      );
      expect(clips, {
        'root': {'x': 3, 'y': 3, 'width': 20, 'height': 30, 'scale': 1},
      });
    });
  });
  test('DOM border bounds include every transformed corner', () {
    final box = captureBorderQuadBounds([10, 20, 30, 10, 40, 40, 20, 50]);
    expect([box.left, box.top, box.width, box.height], [10, 10, 30, 40]);
    expect(() => captureBorderQuadBounds([0, 0]), throwsArgumentError);
  });
  test(
    'stage capture requests a stage shot only, not an independent body shot',
    () {
      final clips = egoCaptureClips(
        entry: entry(stage: true),
        boxes: {
          'root': box(89.375, 17.25, 100.5, 1300.25),
          'stage': box(19.375, 17.25, 240.5, 1300.25),
        },
      );
      expect(clips.keys, ['stage']);
      expect(clips['stage'], {
        'x': 19,
        'y': 17,
        'width': 241,
        'height': 1301,
        'scale': 1,
      });
    },
  );
  test(
    'missing and degenerate root boxes fail instead of emitting a placeholder',
    () {
      expect(
        () => egoCaptureClips(entry: entry(), boxes: {'root': null}),
        throwsStateError,
      );
      expect(
        () =>
            egoCaptureClips(entry: entry(), boxes: {'root': box(0, 0, 0, 10)}),
        throwsStateError,
      );
    },
  );
  test(
    'the existing image fixture classification includes only HTTP images',
    () {
      expect(
        isCaptureHttpImageRequest('http://example.test/a', image: true),
        isTrue,
      );
      expect(
        isCaptureHttpImageRequest('https://example.test/a', image: true),
        isTrue,
      );
      for (final url in [
        'file:///a.png',
        'data:image/png;base64,AA==',
        'blob:https://example.test/id',
        'ftp://example.test/a',
      ]) {
        expect(isCaptureHttpImageRequest(url, image: true), isFalse);
      }
      expect(
        isCaptureHttpImageRequest('https://example.test/app.js', image: false),
        isFalse,
      );
    },
  );
  test(
    'canonical body crop retains all raster rows and fractional edge columns',
    () {
      final image = img.Image(width: 6, height: 3);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 6; x++) {
          image.setPixelRgba(x, y, x * 20, y * 30, 7, 255);
        }
      }
      final result = captureStageBodyColumn(
        key: 'test',
        stagePng: Uint8List.fromList(img.encodePng(image)),
        rootLeft: 1.5,
        rootTop: 4,
        rootWidth: 2.25,
        rootHeight: 3,
        stageLeft: 0,
        stageTop: 4,
        stageWidth: 5.25,
        stageHeight: 3,
      );
      final cropped = img.decodePng(result.pngBytes)!;
      expect([cropped.width, cropped.height], [3, 3]);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final pixel = cropped.getPixel(x, y);
          expect(
            [pixel.r, pixel.g, pixel.b, pixel.a],
            [(x + 1) * 20, y * 30, 7, 255],
          );
        }
      }
      expect(result.bounds, {
        'left': 1.5,
        'top': 0.0,
        'width': 2.25,
        'height': 3.0,
      });
    },
  );
  test('invalid stage alignment fails before pixel cropping', () {
    expect(
      () => captureStageBodyColumn(
        key: 'bad',
        stagePng: Uint8List(0),
        rootLeft: 1,
        rootTop: 1,
        rootWidth: 2,
        rootHeight: 3,
        stageLeft: 0,
        stageTop: 0,
        stageWidth: 4,
        stageHeight: 3,
      ),
      throwsStateError,
    );
  });
  for (final cooperative in [true, false]) {
    test('owned process cancellation cooperative=$cooperative', () async {
      final dir = Directory.systemTemp.createTempSync('ego-worker-protocol-');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      final cancel = File('${dir.path}/cancel.json');
      final cleanup = File('${dir.path}/cleanup.json');
      final script = File('${dir.path}/worker.dart')
        ..writeAsStringSync(
          cooperative
              ? """
import 'dart:io';
import 'dart:convert';
Future<void> main(List<String> args) async {
  while (!File(args[0]).existsSync()) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  File(args[1]).writeAsStringSync(jsonEncode({
    'complete': true, 'processOnly': true,
  }));
}
"""
              : '''
Future<void> main() async {
  await Future<void>.delayed(const Duration(days: 1));
}
''',
        );
      // Parser fixture: retain the last complete safe record
      // when the final record is truncated.
      if (!cooperative) {
        final entered = {
          'sequence': 1,
          'operation': 'worker',
          'phase': 'entry',
          'errorCode': null,
        };
        final pending = {
          'sequence': 2,
          'operation': 'Runtime.evaluate',
          'phase': 'begin',
          'errorCode': null,
        };
        File('${dir.path}/instructions.json.trace.jsonl').writeAsStringSync(
          '${jsonEncode(entered)}\n${jsonEncode(pending)}\n{"sequence":3',
        );
      }
      final process = await Process.start(Platform.resolvedExecutable, [
        script.path,
        cancel.path,
        cleanup.path,
      ]);
      final output = process.stdout.drain<void>();
      final errors = process.stderr.drain<void>();
      final receipt = File('${dir.path}/parent-control.json');
      final result = await superviseEgoCaptureWorker(
        process: process,
        entry: entry(),
        geometry: File('${dir.path}/geometry.json'),
        clips: File('${dir.path}/clips.json'),
        cancel: cancel,
        cleanup: cleanup,
        receipt: receipt,
        softDeadline: DateTime.now(),
        cleanupGrace: cooperative
            ? const Duration(seconds: 3)
            : const Duration(milliseconds: 100),
      );
      await Future.wait([output, errors]);
      final recorded = jsonDecode(receipt.readAsStringSync()) as Map;
      expect(result.cancelled, isTrue);
      expect(result.hardKilled, !cooperative);
      expect(recorded['parentBrowserCalls'], 0);
      expect(recorded['workerEntryConfirmed'], !cooperative);
      expect(recorded['journalReadFailed'], !cooperative);
      if (cooperative) {
        expect(recorded['lastDurableWorkerState'], isNull);
      } else {
        expect(
          recorded['lastDurableWorkerState'],
          containsPair('operation', 'Runtime.evaluate'),
        );
      }
      if (cooperative) {
        expect(result.exitCode, 0);
        expect((recorded['workerCleanup'] as Map)['processOnly'], isTrue);
        expect(recorded['overallCleanupComplete'], isTrue);
      } else {
        expect(result.exitCode, isNot(0));
        expect(recorded['overallCleanupComplete'], isFalse);
        expect(recorded['unconfirmedRestoration'], [
          'fetch',
          'offline',
          'metrics',
        ]);
      }
    });
  }
}
