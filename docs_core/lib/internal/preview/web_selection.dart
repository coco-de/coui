import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_doc_demos.dart';
import '../../previews/props/web_prop_previews.dart';
import '../../previews/web_registry.dart';
import 'selection.dart';

/// Returns the existing factory output, without adding a host or changing it.
Component? renderWebSelection(PreviewSelection selection, {BuildContext? context}) => switch (selection.kind) {
  PreviewSelectionKind.empty => const Component.empty(),
  PreviewSelectionKind.demo => kWebDocDemos[selection.name]?.call(),
  PreviewSelectionKind.example =>
    context == null
        ? _ExampleSelection(selection)
        : kWebPreviewRegistry[selection.component]?.call(context, selection.name),
  PreviewSelectionKind.props => kWebPropPreviews[selection.component]?.call(selection.props, selection.label),
};

class _ExampleSelection extends StatelessComponent {
  const _ExampleSelection(this.selection);
  final PreviewSelection selection;
  @override
  Component build(BuildContext context) => renderWebSelection(selection, context: context) ?? const Component.empty();
}
