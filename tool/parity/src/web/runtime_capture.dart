import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';

import '../model/matrix_entry.dart';

/// These examples require a timer, viewport, or ResizeObserver. Rendering
/// their server fallback and waiting longer cannot produce the runtime state.
bool requiresClientCapture(MatrixEntry entry) {
  if (entry.variant.startsWith(docsScenePrefix)) {
    return resolveDocsScene(entry.component, entry.variant).tag == 'Playground';
  }
  return const {
    'number-ticker',
    'responsive-row-column',
    'stage-container',
  }.contains(entry.component);
}

Future<String>? _compiledScript;

/// One compilation per process, shared across matrix entries and themes.
Future<String> loadRuntimeCaptureScript() =>
    _compiledScript ??= _compileRuntimeCaptureScript();

Future<String> _compileRuntimeCaptureScript() async {
  final directory = Directory.systemTemp.createTempSync(
    'coui-runtime-capture-',
  );
  try {
    final output = File('${directory.path}/entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      output.path,
      'tool/parity/src/web/runtime_capture_entry.dart',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Client capture compilation failed: ${result.stdout}\n${result.stderr}',
      );
    }
    return output.readAsStringSync();
  } finally {
    directory.deleteSync(recursive: true);
  }
}

/// An observable completion condition, not a fixed delay or DOM-idle guess.
/// The number is the registry example's declared destination; layout cases
/// wait for the actual viewport/measurement result, including child boxes.
String runtimeCaptureReadyPredicate(MatrixEntry entry, int width) {
  final root =
      'document.querySelector('
      '${_jsString('[data-parity-key="${entry.key}"] > *')})';
  if (entry.variant.startsWith(docsScenePrefix)) {
    final client = requiresClientCapture(entry)
        ? '[data-parity-client-key="${entry.key}"]'
        : '';
    final frame =
        '[data-parity-key="${entry.key}"]$client '
        '[data-docs-scene="${entry.variant}"]';
    return '() => document.querySelector('
        '${_jsString(frame)}) !== null';
  }
  switch (entry.component) {
    case 'number-ticker':
      return '() => $root?.textContent.trim() === "1234"';
    case 'responsive-row-column':
      final tier = CoreBreakpoint.forWidth(width.toDouble()).toTier();
      final row = tier.isAtLeast(
        entry.variant == 'desktop' ? .desktop : .tablet,
      );
      return '''
() => {
  const root = $root;
  if (!root || getComputedStyle(root).flexDirection !== '${row ? 'row' : 'column'}') return false;
  const children = [...root.children].filter(el => getComputedStyle(el).display !== 'none');
  if (children.length < 2) return false;
  const a = children[0].getBoundingClientRect(), b = children[1].getBoundingClientRect();
  return ${row ? 'Math.abs((b.left - a.right) - parseFloat(getComputedStyle(root).columnGap)) < 0.2' : 'Math.abs((b.top - a.bottom) - parseFloat(getComputedStyle(root).rowGap)) < 0.2'};
}
''';
    case 'stage-container':
      // These are the actual chain fixture's public style overrides.
      // A changed fixture fails readiness rather than certifying its fallback.
      final breakpoint = entry.variant == 'chain'
          ? const CoreConstantStageBreakpoint(CoreSpace.space256)
          : CoreStageBreakpoint.defaultBreakpoints;
      final base = entry.variant == 'chain'
          ? const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space32)
          : CoreStageContainerStyle.defaultPadding;
      final remaining = width > breakpoint.maxSize
          ? (width - breakpoint.maxSize) / 2
          : (width - breakpoint.getMinWidth(width.toDouble())) / 2;
      final left = width < breakpoint.minSize
          ? 0.0
          : math.max(0, base.left + remaining);
      final right = width < breakpoint.minSize
          ? 0.0
          : math.max(0, base.right + remaining);
      return '''
() => {
  const root = $root;
  if (!root || !root.textContent.includes('왼쪽: ${left.toStringAsFixed(0)}, 오른쪽: ${right.toStringAsFixed(0)}')) return false;
  const inner = root.firstElementChild;
  const css = inner && getComputedStyle(inner);
  return Math.abs(root.getBoundingClientRect().width - $width) < 0.1 &&
      css && Math.abs(parseFloat(css.paddingLeft) - $left) < 0.1 &&
      Math.abs(parseFloat(css.paddingRight) - $right) < 0.1;
}
''';
    default:
      throw ArgumentError('No runtime readiness for ${entry.component}');
  }
}

String _jsString(String value) => '"${value.replaceAll('"', r'\"')}"';
