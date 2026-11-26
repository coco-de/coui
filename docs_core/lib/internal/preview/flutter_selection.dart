import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/flutter_registry.dart';
import '../../previews/props/flutter_doc_demos.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'selection.dart';

/// Returns the existing factory output, without adding a host or changing it.
Widget? renderFlutterSelection(PreviewSelection selection) => switch (selection.kind) {
  PreviewSelectionKind.empty => const SizedBox.shrink(),
  PreviewSelectionKind.demo => kFlutterDocDemos[selection.name]?.call(),
  PreviewSelectionKind.example => kFlutterPreviewRegistry[selection.component]?.call(selection.name),
  PreviewSelectionKind.props => kFlutterPropPreviews[selection.component]?.call(selection.props, selection.label),
};
