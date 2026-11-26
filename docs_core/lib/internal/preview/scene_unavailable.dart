import 'scenes.dart';

/// Browser callers carry the actual selection; source files belong to the VM.
DocsScene resolveDocsScene(String component, String reference, {String? contentDir}) => throw UnsupportedError(
  '$component/$reference requires its document input. Browser callers must pass the DocsScene to the scene factory.',
);
