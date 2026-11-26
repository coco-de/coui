import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';

String _digest(List<int> bytes) => sha256.convert(bytes).toString();

/// Separate value-level parse under the caller's frozen source/input boundary.
/// This is not the actual scene object held by the private factory result.
Map<String, String> readPlaygroundValueAuthority({
  required Directory sourceRoot,
  required File manifestFile,
  required String entryKey,
  required String component,
  required String reference,
  Map<String, Object?>? actualRuntimePayloadScene,
}) {
  final manifestBytes = manifestFile.readAsBytesSync();
  final manifest =
      (jsonDecode(utf8.decode(manifestBytes)) as Map)['entries'] as List;
  final entries = manifest.where((value) {
    final entry = value as Map;
    return entry['key'] == entryKey &&
        entry['component'] == component &&
        entry['variant'] == reference;
  }).toList();
  if (entries.length != 1) {
    throw const FormatException(
      'Expected one actual manifest entry for the operation',
    );
  }
  final document = File(
    '${sourceRoot.path}/docs_core/content/components/$component.md',
  );
  final before = document.readAsBytesSync();
  final scene = resolveDocsScene(
    component,
    reference,
    contentDir: '${sourceRoot.path}/docs_core/content/components',
  );
  if (scene.tag != 'Playground' || scene.reference != reference) {
    throw const FormatException('Not the declared Playground value contract');
  }
  if (actualRuntimePayloadScene != null) {
    final prepared = DocsScene.fromJson(actualRuntimePayloadScene);
    // The real runtime navigation payload is compared before navigation.
    // Origins are path diagnostics, excluded by the existing identity API.
    if (prepared.reference != reference ||
        prepared.identity != scene.identity) {
      throw const FormatException('Runtime scene differs from frozen document');
    }
  }
  const sources = [
    'docs_core/lib/previews/flutter_registry.dart',
    'docs_core/lib/internal/preview/scene_file.dart',
    'docs_core/lib/internal/preview/scenes.dart',
    'docs_core/lib/internal/preview/flutter_scene.dart',
    'docs_core/lib/internal/preview/flutter_stage.dart',
    'docs_core/lib/internal/preview/web_scene.dart',
    'docs_core/lib/internal/preview/web_playground_view.dart',
    'tool/parity/src/web/runtime_capture_entry.dart',
  ];
  final sourceRows = [
    for (final path in sources)
      {
        'path': path,
        'sha256': _digest(File('${sourceRoot.path}/$path').readAsBytesSync()),
      },
  ];
  if (_digest(before) != _digest(document.readAsBytesSync())) {
    throw const FormatException('Document changed during value preparation');
  }
  return Map.unmodifiable({
    'component': component,
    'reference': reference,
    'tag': scene.tag,
    'documentPath': document.absolute.path,
    'documentSha256': _digest(before),
    'sourceClosureSha256': _digest(utf8.encode(jsonEncode(sourceRows))),
    'manifestSha256': _digest(manifestBytes),
    'sceneValueSha256': _digest(
      utf8.encode(
        actualRuntimePayloadScene == null
            ? scene.identity
            : DocsScene.fromJson(actualRuntimePayloadScene).identity,
      ),
    ),
  });
}

/// Binds the value proof to the very payload used by canonical navigation.
/// The sampler must still observe the current page URL/hash before reading CSS.
Map<String, Object?> preparePlaygroundNavigationReceipt({
  required Directory sourceRoot,
  required File manifestFile,
  required Uri navigationURL,
  required Map<String, Object?> actualRuntimePayload,
}) {
  final fromURL =
      (jsonDecode(Uri.decodeComponent(navigationURL.fragment)) as Map)
          .cast<String, Object?>();
  if (jsonEncode(fromURL) != jsonEncode(actualRuntimePayload)) {
    throw const FormatException(
      'Navigation URL does not contain the actual runtime payload',
    );
  }
  final component = actualRuntimePayload['component']! as String;
  final reference = actualRuntimePayload['variant']! as String;
  final entryKey = actualRuntimePayload['key']! as String;
  final authority = readPlaygroundValueAuthority(
    sourceRoot: sourceRoot,
    manifestFile: manifestFile,
    entryKey: entryKey,
    component: component,
    reference: reference,
  );
  final payloadAuthority = readPlaygroundValueAuthority(
    sourceRoot: sourceRoot,
    manifestFile: manifestFile,
    entryKey: entryKey,
    component: component,
    reference: reference,
    actualRuntimePayloadScene: (actualRuntimePayload['scene']! as Map)
        .cast<String, Object?>(),
  );
  return {
    'kind': 'canonical-runtime-navigation-v1',
    'navigationURL': '$navigationURL',
    'preparedPayload': actualRuntimePayload,
    'authority': authority,
    'payloadAuthority': payloadAuthority,
  };
}
