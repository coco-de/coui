import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/flutter_registry.dart';
import '../../previews/props/flutter_doc_demos.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/size_spec.dart';
import 'flutter_selection.dart';
import 'flutter_stage.dart';
import 'flutter_card_view.dart';
import 'scenes.dart';
import 'selection.dart';

Widget renderFlutterScene(DocsScene scene) {
  final selections = scene.tag == 'Card'
      ? [PreviewSelection.attributes(scene.nativeCardAttributes!)]
      : scene.selections;
  for (final selection in selections) {
    final known = switch (selection.kind) {
      PreviewSelectionKind.empty => false,
      PreviewSelectionKind.demo => kFlutterDocDemos.containsKey(selection.name),
      PreviewSelectionKind.example => kFlutterPreviewRegistry.containsKey(selection.component),
      PreviewSelectionKind.props => kFlutterPropPreviews.containsKey(selection.component),
    };
    if (!known) throw StateError('${scene.origins}: unresolved documentation selection ${selection.identity}');
  }
  if (scene.tag == 'Card') return buildFlutterDocsCardScene(scene.nativeCardAttributes!, scene.nativeCardBody!);
  if (scene.tag == 'Playground') return _PlaygroundFrame(scene);
  if (scene.tag == 'SizeSpec') {
    final component = scene.attributes['component']!;
    return FlutterDocsSizeSpec(component: component, spec: docsSizeSpecFor(component)!, attributes: scene.attributes);
  }
  return DocsStage(attributes: scene.attributes, compact: scene.tag == 'VariantRow');
}

class _PlaygroundFrame extends StatelessWidget {
  const _PlaygroundFrame(this.scene);
  final DocsScene scene;

  @override
  Widget build(BuildContext context) =>
      buildFlutterPlaygroundStage(context, renderFlutterSelection(scene.selections.single)!);
}
