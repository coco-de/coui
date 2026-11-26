import 'package:coui_web/coui_web.dart';
import 'package:jaspr_content/jaspr_content.dart' as markdown;

import '../../previews/props/web_doc_demos.dart';
import '../../previews/props/web_prop_previews.dart';
import '../../previews/web_registry.dart';
import '../../shared/playground_spec.dart';
import '../../site_head.dart' show docsContentTheme;
import 'scenes.dart';
import 'selection.dart';
import 'web_card_view.dart';
import 'web_anatomy_view.dart';
import 'web_playground_view.dart';
import 'web_stage.dart';

void requireWebScene(DocsScene scene) {
  for (final selection in scene.selections) {
    final known = switch (selection.kind) {
      PreviewSelectionKind.empty => false,
      PreviewSelectionKind.demo => kWebDocDemos.containsKey(selection.name),
      PreviewSelectionKind.example => kWebPreviewRegistry.containsKey(selection.component),
      PreviewSelectionKind.props => kWebPropPreviews.containsKey(selection.component),
    };
    if (!known) throw StateError('${scene.origins}: unresolved documentation selection ${selection.identity}');
  }
}

/// Captures the existing preview frame, not a substitute component fixture.
Component renderWebScene(DocsScene scene) {
  requireWebScene(scene);
  final Component content;
  switch (scene.tag) {
    case 'Playground':
      final selection = scene.selections.single;
      final component = selection.component!;
      final spec = kDocsPlaygrounds[component]!;
      content = buildWebPlaygroundRoot(
        buildWebPlaygroundView(
          componentName: component,
          spec: spec,
          props: selection.props,
          platform: DocsPlaygroundPlatform.web,
          showWeb: true,
          showFlutter: false,
          flutterContent: null,
          codeView: const Component.empty(),
          onSetProps: (_) {},
          onSetPlatform: (_) {},
        ),
      );
    case 'Card':
      _requireStandardBodyNodes(scene.cardBody, scene.origins, owner: 'Card');
      content = buildWebStandaloneDocsCard(
        scene.attributes,
        buildBody: scene.cardBody.isEmpty ? null : () => const markdown.NodesBuilder([]).build(scene.cardBody),
      );
    case 'SizeSpec':
      content = buildWebSizeSpec(scene.attributes);
    case 'Anatomy':
      for (final node in scene.anatomyBody.whereType<markdown.ElementNode>()) {
        if (node.tag == 'AnatomyItem') {
          _requireStandardBodyNodes(node.children ?? const [], scene.origins, owner: 'AnatomyItem');
        } else if (node.tag != node.tag.toLowerCase()) {
          throw StateError('${scene.origins}: unresolved Anatomy child <${node.tag}>');
        }
      }
      content = buildWebDocsAnatomy(
        markdown.ElementNode('Anatomy', scene.attributes, scene.anatomyBody),
        const markdown.NodesBuilder([]),
      );
    default:
      content = buildWebDocsStage(scene.attributes, compact: scene.tag == 'VariantRow');
  }
  return content;
}

/// The standalone capture document owns this host; scene factories do not.
Component docsSceneHost(DocsScene scene, Component content) => div(
  id: 'docs-shell',
  classes: 'docs manual',
  // A document fills its article containing block. This standalone document
  // is a flex item, so preserve that width instead of intrinsic preview sizing.
  styles: Styles(raw: {'width': '100%', 'min-width': '0'}),
  attributes: {'data-docs-scene': scene.reference},
  [markdown.Content.wrapTheme(docsContentTheme(), child: markdown.Content(content))],
);

void _requireStandardBodyNodes(List<markdown.Node> nodes, List<String> origins, {required String owner}) {
  for (final node in nodes) {
    if (node is markdown.ElementNode) {
      if (node.tag != node.tag.toLowerCase()) {
        throw StateError('$origins: unresolved $owner body component <${node.tag}>');
      }
      _requireStandardBodyNodes(node.children ?? const [], origins, owner: owner);
    }
  }
}
