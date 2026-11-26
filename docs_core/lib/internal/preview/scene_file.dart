import 'dart:io';

import '../../markdown/repo_root.dart';
import 'scenes.dart';

List<DocsScene> readDocsScenes(String component, {String? contentDir}) {
  final directory = contentDir ?? '${findRepoRoot().path}/docs_core/content/components';
  final file = File('$directory/$component.md');
  return visibleDocsScenes(file.readAsStringSync(), sourcePath: file.path);
}

DocsScene resolveDocsScene(String component, String reference, {String? contentDir}) {
  if (!reference.startsWith(docsScenePrefix)) throw ArgumentError.value(reference, 'reference', 'Not a docs scene');
  for (final scene in readDocsScenes(component, contentDir: contentDir)) {
    if (scene.reference == reference) return scene;
  }
  throw StateError('$component/$reference: scene is not declared by the current document');
}
