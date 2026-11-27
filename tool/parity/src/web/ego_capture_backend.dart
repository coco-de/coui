import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Rectangle;
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:docs_core/internal/preview/scene_file.dart'
    show resolveDocsScene;
import 'package:docs_core/internal/preview/scenes.dart' show docsScenePrefix;
import 'package:docs_core/markdown/repo_root.dart' show findRepoRoot;

import '../model/capture_motion.dart';
import '../model/capture_surface.dart';
import '../model/matrix_entry.dart';
import '../model/network_image_fixture.dart';
import '../source/playground_value_authority.dart';
import 'bottom_action_bar_ssr_source.dart';
import 'box_padding_observation_probe.dart';
import 'breakpoint_showcase_ssr_source.dart';
import 'card_accordion_frame_ssr_source.dart';
import 'client_box_source_protocol.dart';
import 'computed_style_probe.dart';
import 'element_capture.dart';
import 'framed_collection_ssr_source.dart';
import 'public_wrapper_ssr_source.dart';
import 'runtime_capture.dart';
import 'scope_allocation_ssr_source.dart';
import 'showcase_allocation_ssr_source.dart';
import 'stage_callback_ssr_source.dart';
import 'stepper_horizontal_ssr_source.dart';
import 'text_showcase_ssr_source.dart';
import 'web_capture_backend.dart';

// Operational file-bridge polling; unrelated to product animation timing.
const _kClipBridgePollInterval = Duration(milliseconds: 10);

// Operational process deadlines; unrelated to product animation timing.
const _kEgoCleanupGrace = Duration(seconds: 15);
const _kEgoKillGrace = Duration(seconds: 5);
const _kEgoRestoreCallTimeout = Duration(seconds: 2);

/// Gives an owned worker a cancellation and cleanup window before termination.
/// No browser calls are made by this process supervisor.
Future<({int exitCode, bool cancelled, bool hardKilled})>
superviseEgoCaptureWorker({
  required Process process,
  required MatrixEntry entry,
  required File geometry,
  required File clips,
  required File cancel,
  required File cleanup,
  required File receipt,
  required DateTime softDeadline,
  Duration cleanupGrace = _kEgoCleanupGrace,
}) async {
  var ended = false;
  var answered = false;
  var cancelled = false;
  var hardKilled = false;
  Object? bridgeError;
  Object? cancelWriteError;
  DateTime? cancelAt;
  void requestCancel(String reason) {
    cancelled = true;
    cancelAt = DateTime.now();
    try {
      File('${cancel.path}.tmp')
        ..writeAsStringSync(jsonEncode({'reason': reason}))
        ..renameSync(cancel.path);
    } on Object catch (error) {
      cancelWriteError = error;
    }
  }

  final exited = process.exitCode.then((code) {
    ended = true;
    return code;
  });
  while (!ended) {
    if (!answered && geometry.existsSync()) {
      answered = true;
      try {
        final state = (jsonDecode(geometry.readAsStringSync()) as Map)
            .cast<String, Object?>();
        File('${clips.path}.tmp')
          ..writeAsStringSync(
            jsonEncode(
              egoCaptureClips(
                entry: entry,
                boxes: (state['boxes']! as Map).cast<String, Object?>(),
              ),
            ),
          )
          ..renameSync(clips.path);
      } on Object catch (error) {
        bridgeError = error;
        try {
          File('${clips.path}.tmp')
            ..writeAsStringSync(jsonEncode({'error': '$error'}))
            ..renameSync(clips.path);
        } on Object catch (writeError) {
          bridgeError = writeError;
          requestCancel('clip response could not be written');
        }
      }
    }
    if (!cancelled && DateTime.now().isAfter(softDeadline)) {
      requestCancel('parent soft deadline');
    }
    if (cancelled && DateTime.now().isAfter(cancelAt!.add(cleanupGrace))) {
      hardKilled = true;
      File('${receipt.path}.termination-request.json').writeAsStringSync(
        jsonEncode({
          'PID': process.pid,
          'phase': 'cleanup grace expired',
          'overallCleanupComplete': false,
          'unconfirmedRestoration': ['fetch', 'offline', 'metrics'],
          'parentBrowserCalls': 0,
        }),
      );
      process.kill();
      break;
    }
    await Future<void>.delayed(_kClipBridgePollInterval);
  }
  final exitCode = await exited.timeout(
    _kEgoKillGrace,
    onTimeout: () async {
      hardKilled = true;
      File('${receipt.path}.termination-escalated.json').writeAsStringSync(
        jsonEncode({
          'PID': process.pid,
          'phase': 'owned worker SIGKILL requested',
          'overallCleanupComplete': false,
          'unconfirmedRestoration': ['fetch', 'offline', 'metrics'],
          'parentBrowserCalls': 0,
        }),
      );
      process.kill(ProcessSignal.sigkill);
      return await exited.timeout(_kEgoKillGrace);
    },
  );
  Object? workerCleanup;
  try {
    if (cleanup.existsSync()) {
      workerCleanup = jsonDecode(cleanup.readAsStringSync());
    }
  } on Object catch (error) {
    workerCleanup = {'complete': false, 'readError': '$error'};
  }
  // A missing entry is unconfirmed, not proof that the worker never ran.
  // This trace is diagnostic only and never supplies cleanup/success authority.
  var workerEntryConfirmed = false;
  var journalReadFailed = false;
  Map<String, Object?>? lastDurableWorkerState;
  try {
    final journal = File(
      '${cleanup.parent.path}/instructions.json.trace.jsonl',
    );
    if (journal.existsSync()) {
      for (final line in journal.readAsLinesSync()) {
        final row = (jsonDecode(line) as Map).cast<String, Object?>();
        const keys = {'sequence', 'operation', 'phase', 'errorCode'};
        const operations = {
          'worker',
          'instructions',
          'other',
          'taskSpace',
          'Page.events',
          'Runtime.evaluate',
          'Runtime.releaseObject',
          'DOM.getBoxModel',
          'Page.captureScreenshot',
          'Page.navigate',
          'Page.snapshot',
          'Emulation.setDeviceMetricsOverride',
          'Emulation.clearDeviceMetricsOverride',
          'Emulation.setVisibleSize',
          'Fetch.enable',
          'Fetch.disable',
          'Fetch.fulfillRequest',
          'Network.emulateNetworkConditions',
          'geometry',
          'clips',
          'result',
          'cleanup',
        };
        const phases = {
          'entry',
          'begin',
          'end',
          'error',
          'cleanup-begin',
          'cleanup-end',
          'cleanup-error',
        };
        const codes = {
          null,
          'OTHER',
          'CAPTURE_CANCELLED',
          'EGO_CDP_REQUEST_TIMEOUT',
          'EGO_PAGE_NOT_AGENT_OWNED',
          'EGO_SPACE_NOT_AGENT_OWNED',
          'EGO_TASK_SPACE_NOT_FOUND',
          'EGO_USER_TAKEOVER',
          'EACCES',
          'EPERM',
          'ENOENT',
          'EIO',
          'ENOSPC',
          'EROFS',
          'EISDIR',
          'EMFILE',
          'EINVAL',
        };
        if (row.length != 4 ||
            !row.keys.toSet().containsAll(keys) ||
            row['sequence'] is! int ||
            (row['sequence']! as int) <=
                (lastDurableWorkerState?['sequence'] as int? ?? 0) ||
            !operations.contains(row['operation']) ||
            !phases.contains(row['phase']) ||
            !codes.contains(row['errorCode'])) {
          throw const FormatException('Invalid diagnostic journal record');
        }
        lastDurableWorkerState = row;
        if (row['operation'] == 'worker' && row['phase'] == 'entry') {
          workerEntryConfirmed = true;
        }
      }
    }
  } on Object {
    journalReadFailed = true;
  }
  receipt.writeAsStringSync(
    jsonEncode({
      'PID': process.pid,
      'actualExitCode': exitCode,
      'cooperativeCancelRequested': cancelled,
      'cleanupGraceMilliseconds': cleanupGrace.inMilliseconds,
      'hardKilled': hardKilled,
      'bridgeError': bridgeError?.toString(),
      'cancelWriteError': cancelWriteError?.toString(),
      'workerCleanup': workerCleanup,
      'overallCleanupComplete':
          !hardKilled &&
          workerCleanup is Map &&
          workerCleanup['complete'] == true,
      'unconfirmedRestoration': hardKilled || workerCleanup == null
          ? ['fetch', 'offline', 'metrics']
          : null,
      'parentBrowserCalls': 0,
      'workerEntryConfirmed': workerEntryConfirmed,
      'lastDurableWorkerState': lastDurableWorkerState,
      'journalReadFailed': journalReadFailed,
    }),
  );
  return (exitCode: exitCode, cancelled: cancelled, hardKilled: hardKilled);
}

/// Screenshot boxes use the same box-less-wrapper walk as the raw probe.
String get egoCaptureBoxScript =>
    '''
(sel) => {
  $kBoxRootJs
  return boxRoot(document.querySelector(sel));
}
''';

/// Converts genuine DOM.getBoxModel border quads with the pinned Dart geometry.
Map<String, Object?> egoCaptureBoxes(Map<String, Object?> raw) => {
  for (final role in raw.entries)
    role.key: role.value == null
        ? null
        : _egoCaptureBox((role.value! as Map).cast<String, Object?>()),
};

Map<String, Object?> _egoCaptureBox(Map<String, Object?> raw) {
  final box = captureBorderQuadBounds((raw['borderQuad']! as List).cast<num>());
  return {
    'left': box.left,
    'top': box.top,
    'width': box.width,
    'height': box.height,
    'scrollX': raw['scrollX'],
    'scrollY': raw['scrollY'],
  };
}

/// Final CDP clips are computed in Dart, preserving the pinned rounding rules.
Map<String, Object?> egoCaptureClips({
  required MatrixEntry entry,
  required Map<String, Object?> boxes,
}) {
  final measured = egoCaptureBoxes(boxes);
  Map<String, Object?> box(String role) {
    final value = measured[role];
    if (value is! Map) {
      throw StateError('DegenerateCapture: ${entry.key}/$role has no box');
    }
    final result = value.cast<String, Object?>();
    if ((result['width']! as num) <= 0 || (result['height']! as num) <= 0) {
      throw StateError('DegenerateCapture: ${entry.key}/$role has no size');
    }
    return result;
  }

  final root = box('root');
  final stage = entry.probes.where((probe) => probe.role == 'stage');
  final targets = stage.isEmpty
      ? {'root': root}
      : {for (final probe in stage) probe.role: box(probe.role)};
  return {
    for (final target in targets.entries)
      target.key: captureCdpClip(
        Rectangle<num>(
          (target.value['left']! as num) + (target.value['scrollX']! as num),
          (target.value['top']! as num) + (target.value['scrollY']! as num),
          target.value['width']! as num,
          target.value['height']! as num,
        ),
      ),
  };
}

/// Captures through an existing owned Ego page without a Page shim.
Future<WebCaptureResult> captureEgoEntry({
  required MatrixEntry entry,
  required int space,
  required String page,
  required Directory workDir,
  required ThemeConfig themeConfig,
  required String vendoredTailwindScript,
  required String fontFaceCss,
  required String iconifyHeadHtml,
  bool additiveBoxObservations = false,
  File? sourceManifest,
  int timeoutMs = 30000,
  int availableWidthPx = kCaptureAvailableWidthPx,
}) async {
  if (workDir.existsSync() && workDir.listSync().isNotEmpty) {
    throw StateError('Ego work directory must be empty: ${workDir.path}');
  }
  workDir.createSync(recursive: true);
  final client = requiresClientCapture(entry);
  final currentClientBoxSource = clientBoxSourceDescriptor(
    entry,
    additiveBoxObservations: additiveBoxObservations,
  );
  final requiredCurrentSsrKind = additiveBoxObservations
      ? requiredStepperHorizontalSsrKind(entry) ??
            requiredStageCallbackSsrKind(entry) ??
            requiredPublicWrapperSsrKind(entry) ??
            requiredCardAccordionFrameSsrKind(entry) ??
            requiredScopeAllocationSsrKind(entry) ??
            requiredShowcaseAllocationSsrKind(entry) ??
            requiredBreakpointShowcaseSsrKind(entry) ??
            requiredBottomActionBarSsrKind(entry) ??
            requiredTextShowcaseSsrKind(entry) ??
            requiredFramedCollectionSsrKind(entry)
      : null;
  Map<String, Object?>? currentSsrSource;
  final file = await prepareWebCaptureHarness(
    entry: entry,
    themeConfig: themeConfig,
    vendoredTailwindScript: vendoredTailwindScript,
    fontFaceCss: fontFaceCss,
    iconifyHeadHtml: iconifyHeadHtml,
    harnessDir: workDir,
    availableWidthPx: availableWidthPx,
    onCurrentBoxSource: additiveBoxObservations && !client
        ? (witness) => currentSsrSource = witness
        : null,
  );
  final runtimePayload = client
      ? <String, Object?>{
          'key': entry.key,
          'component': entry.component,
          'variant': entry.variant,
          'currentClientBoxSource': ?currentClientBoxSource,
          'width': availableWidthPx,
          if (entry.variant.startsWith(docsScenePrefix))
            'scene': resolveDocsScene(
              entry.component,
              entry.variant,
            ).toJson(),
        }
      : null;
  final url = file.absolute.uri.replace(
    fragment: runtimePayload == null ? null : jsonEncode(runtimePayload),
  );
  Map<String, Object?>? runtimeOperationReceipt;
  if (additiveBoxObservations &&
      entry.probes.any(
        (probe) =>
            probe.boxObservationSource?.nativeAdapterId ==
            'docs-playground-stage-frame-v1',
      )) {
    try {
      if (runtimePayload == null || sourceManifest == null) {
        throw const FormatException(
          'Actual runtime manifest/input unavailable',
        );
      }
      runtimeOperationReceipt = preparePlaygroundNavigationReceipt(
        sourceRoot: findRepoRoot(),
        manifestFile: sourceManifest,
        navigationURL: url,
        actualRuntimePayload: runtimePayload,
      );
    } on Object catch (error) {
      runtimeOperationReceipt = {'error': '$error'};
    }
  }
  final geometry = File('${workDir.path}/geometry.json');
  final clips = File('${workDir.path}/clips.json');
  final resultFile = File('${workDir.path}/result.json');
  final cancel = File('${workDir.path}/cancel.json');
  final cleanup = File('${workDir.path}/cleanup.json');
  final softDeadline = DateTime.now().add(
    Duration(milliseconds: timeoutMs * 3),
  );
  final input = File('${workDir.path}/instructions.json')
    ..writeAsStringSync(
      jsonEncode({
        'space': space,
        'page': page,
        'url': '$url',
        'width': availableWidthPx,
        'timeoutMs': timeoutMs,
        'softDeadlineEpochMs': softDeadline.millisecondsSinceEpoch,
        'cleanupCallTimeoutMs': _kEgoRestoreCallTimeout.inMilliseconds,
        'cancelPath': cancel.absolute.path,
        'imagePatterns': kCaptureImageRequestPatterns,
        'networkImageBase64': base64Encode(loadParityNetworkImageBytes()),
        'probes': entry.probes.map((probe) => probe.toJson()).toList(),
        if (additiveBoxObservations) 'additiveBoxObservations': true,
        'currentClientBoxSource': ?currentClientBoxSource,
        'runtimeOperationReceipt': ?runtimeOperationReceipt,
        'requiredCurrentSsrKind': ?requiredCurrentSsrKind,
        if (currentSsrSource != null)
          'currentSsrSource': {
            ...currentSsrSource!,
            'harnessURL': '$url',
          },
        'runtimeReady': client
            ? runtimeCaptureReadyPredicate(entry, availableWidthPx)
            : null,
        'fixedTime': kFixedTimeCaptureComponents.contains(entry.component),
        'scripts': {
          'iconify': kCaptureIconifyReadyScript,
          'fonts': kCaptureFontsReadyScript,
          'images': kCaptureImageDecodeScript,
          'initialAnimation': kCaptureInitialAnimationScript,
          'twoFrames': kCaptureTwoFramesScript,
          'context': kCaptureContextScript,
          'probe': computedStyleProbeScript,
          if (additiveBoxObservations)
            'probeAndBox': computedStyleAndBoxObservationScript,
          'box': egoCaptureBoxScript,
        },
        'geometryPath': geometry.absolute.path,
        'clipsPath': clips.absolute.path,
        'resultPath': resultFile.absolute.path,
        'cleanupPath': cleanup.absolute.path,
        'pngDirectory': workDir.absolute.path,
      }),
    );
  final worker = File('tool/parity/src/web/ego_capture_transport.mjs')
      .readAsStringSync()
      .replaceAll('__INSTRUCTIONS__', jsonEncode(input.absolute.path));
  final process = await Process.start('ego-browser', ['nodejs']);
  final out = process.stdout.transform(utf8.decoder).join();
  final err = process.stderr.transform(utf8.decoder).join();
  process.stdin.write(worker);
  await process.stdin.close();
  final outcome = await superviseEgoCaptureWorker(
    process: process,
    entry: entry,
    geometry: geometry,
    clips: clips,
    cancel: cancel,
    cleanup: cleanup,
    receipt: File('${workDir.path}/parent-control.json'),
    softDeadline: softDeadline,
  );
  final exitCode = outcome.exitCode;
  final stdout = await out;
  final stderr = await err;
  File('${workDir.path}/worker.stdout.log').writeAsStringSync(stdout);
  File('${workDir.path}/worker.stderr.log').writeAsStringSync(stderr);
  if (exitCode != 0 ||
      outcome.cancelled ||
      outcome.hardKilled ||
      !resultFile.existsSync()) {
    throw StateError('Ego capture ${entry.key} failed ($exitCode): $stderr');
  }
  final result = (jsonDecode(resultFile.readAsStringSync()) as Map)
      .cast<String, Object?>();
  final pngs = (result['pngPaths']! as Map).cast<String, String>();
  final boxes = egoCaptureBoxes(
    (result['boxes']! as Map).cast<String, Object?>(),
  );
  final stages = entry.probes.where((probe) => probe.role == 'stage');
  var png = stages.isEmpty
      ? File(pngs['root']!).readAsBytesSync()
      : Uint8List(0);
  final stagePngs = <String, Uint8List>{};
  Map<String, Object?>? bodyBounds;
  for (final probe in stages) {
    final root = (boxes['root']! as Map).cast<String, num>();
    final stage = (boxes[probe.role]! as Map).cast<String, num>();
    final stagePng = File(pngs[probe.role]!).readAsBytesSync();
    final body = captureStageBodyColumn(
      key: entry.key,
      stagePng: stagePng,
      rootLeft: root['left']!.toDouble(),
      rootTop: root['top']!.toDouble(),
      rootWidth: root['width']!.toDouble(),
      rootHeight: root['height']!.toDouble(),
      stageLeft: stage['left']!.toDouble(),
      stageTop: stage['top']!.toDouble(),
      stageWidth: stage['width']!.toDouble(),
      stageHeight: stage['height']!.toDouble(),
    );
    png = body.pngBytes;
    bodyBounds = body.bounds;
    stagePngs[probe.role] = stagePng;
  }
  return WebCaptureResult(
    pngBytes: png,
    pngByRole: stagePngs,
    rawPropertyByRole: {
      for (final role in (result['byRole']! as Map).entries)
        role.key as String: role.value == null
            ? null
            : (role.value as Map).cast<String, Object?>(),
    },
    boxPaddingByRole: additiveBoxObservations
        ? {
            for (final role in (result['boxPaddingByRole']! as Map).entries)
              role.key as String: (role.value as Map).cast<String, Object?>(),
          }
        : const {},
    chromeVersion: result['userAgent']! as String,
    renderPhase: client
        ? 'client-settled'
        : kFixedTimeCaptureComponents.contains(entry.component)
        ? 'initial-frame'
        : 'ssr',
    captureContext: {
      if (entry.variant.startsWith(docsScenePrefix))
        'docsScene': resolveDocsScene(entry.component, entry.variant).toJson(),
      ...(result['captureContext']! as Map).cast<String, Object?>(),
      'availableWidth': availableWidthPx,
      'bodyBounds': ?bodyBounds,
      'browserBackend': result['backend'],
      'browserEnvironment': result['environment'],
      'rasterBackend': result['rasterBackend'],
      'transportRequests': result['requests'],
    },
  );
}
