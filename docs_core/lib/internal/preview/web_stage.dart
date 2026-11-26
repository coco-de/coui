import 'package:coui_web/coui_web.dart';
import '../../components/web_preview.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';
import 'selection.dart';
import 'web_selection.dart';

const Set<String> kDocsStageHeights = {'140', '240', '340', 'hug'};

Component buildWebDocsStage(Map<String, String> attributes, {bool compact = false}) {
  final height = attributes['height'];
  final heightClass = height != null && kDocsStageHeights.contains(height) ? ' docs-stage--$height' : '';
  return div(
    classes: 'docs-stage${compact ? ' docs-stage--compact' : ''}$heightClass not-content',
    [webDocsContent(attributes)],
  );
}

Component webDocsContent(Map<String, String> attributes) {
  final selection = PreviewSelection.attributes(attributes);
  if (selection.kind == PreviewSelectionKind.example) {
    return WebPreviewContent(component: selection.component!, variant: selection.name, fitContent: true);
  }
  final result = renderWebSelection(selection);
  if (result != null) return result;
  final message = selection.kind == PreviewSelectionKind.demo
      ? 'Demo not available: "${selection.name}"'
      : 'Preview not available for "${selection.component}"';
  return div(classes: 'preview-unavailable', [Component.text(message)]);
}

Component buildWebSizeSpec(Map<String, String> attributes) {
  final component = attributes['component'];
  final spec = component == null ? null : docsSizeSpecFor(component);
  if (component == null || spec == null) return const Component.empty();
  final base = parsePreviewProps(attributes['props']);
  final label = attributes['label'];

  return div(classes: 'docs-size-spec', [
    div(classes: 'docs-stage docs-stage--hug docs-stage--row', [
      for (final row in spec.rows)
        figure(classes: 'docs-size-item', [
          renderWebSelection(PreviewSelection.properties(component, {...base, 'size': row.size.name}, label))!,
          figcaption([
            code([Component.text(row.size.name)]),
          ]),
        ]),
    ]),
    div(classes: 'docs-table', [
      table([
        thead([
          tr([
            for (final column in spec.columns) th([Component.text(column)]),
          ]),
        ]),
        tbody([
          for (final row in spec.rows)
            tr([
              td([
                code([Component.text(row.size.name)]),
              ]),
              for (final cell in row.cells) td([Component.text(cell)]),
            ]),
        ]),
      ]),
    ]),
  ]);
}

Component buildWebPlaygroundPane(Component? content, {bool hidden = false}) => div(
  classes: 'docs-playground-pane${hidden ? ' is-hidden' : ''}',
  [?content],
);

Component buildWebAnatomyStage(Map<String, String> attributes, List<String> parts) => div(
  classes: 'docs-stage docs-stage--240 docs-anatomy-stage',
  attributes: {
    // 부분마다 `무엇@어느 쪽` — 무엇은 이름 붙은 부분(container ·
    // leading · label · trailing)이나 미리보기 안의 CSS 선택자, 어느
    // 쪽은 번호를 놓을 자리(top · left · right).
    'data-docs-anatomy': parts.join(';'),
  },
  [
    div(classes: 'docs-anatomy-target', [webDocsContent(attributes)]),
  ],
);
