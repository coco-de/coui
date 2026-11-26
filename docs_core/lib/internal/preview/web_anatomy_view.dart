import 'package:coui_web/coui_web.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'web_stage.dart';

Component buildWebDocsAnatomy(ElementNode node, NodesBuilder builder) {
  final items = [
    for (final child in node.children ?? const <Node>[])
      if (child case ElementNode(tag: 'AnatomyItem')) child,
  ];
  return div(classes: 'docs-anatomy not-content', [
    // 번호 표시는 `web/docs-shell.js` 가 렌더된 부분 위에 만든다 — 부분의
    // 자리는 라벨 폭과 글꼴이 정하므로 서버가 알 수 없다. 스크립트가 없는
    // 문서에서는 표시 없이 그림과 번호 붙은 설명만 남는다.
    buildWebAnatomyStage(node.attributes, [
      for (final item in items)
        '${item.attributes['select'] ?? item.attributes['part'] ?? ''}@${item.attributes['side'] ?? ''}',
    ]),
    div(classes: 'docs-anatomy-legend', [
      for (final (index, item) in items.indexed)
        div(classes: 'docs-anatomy-item', [
          div(classes: 'docs-anatomy-item-head', [
            span(classes: 'docs-anatomy-number', [Component.text('${index + 1}')]),
            code([Component.text(item.attributes['name'] ?? item.attributes['part'] ?? '')]),
          ]),
          div(classes: 'docs-anatomy-item-body', [builder.build(item.children ?? const [])]),
        ]),
    ]),
  ]);
}
