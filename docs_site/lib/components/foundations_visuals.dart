import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/foundation_visuals.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'foundations_colors.dart';

const _assetRoot = '/images/foundations';

/// 파운데이션 페이지의 그림 — `<FoundationVisual kind="…" />`.
///
/// 값과 이름표는 `docs_core` 의 `foundation_visuals.dart` 가 정하고, 네이티브
/// 문서 앱도 같은 값을 표로 그린다. 여기서는 그림의 모양만 정한다.
class FoundationVisual extends CustomComponent {
  const FoundationVisual() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'FoundationVisual', :final attributes)) {
      return switch (FoundationVisualKind.parse(attributes['kind'])) {
        null => null,
        .topics => _topics(),
        .fonts => _fonts(),
        .typography => _typography(),
        .iconSets => _iconSets(),
        .spacing => _bars([for (final step in kFoundationSpacing) (step.token, step.value)], unit: 'px', scale: 4),
        .radii => _radii(),
        .shadows => _shadows(),
        .opacity => _opacity(),
        .focusRing => _focusRing(),
        .duration => _bars([for (final step in kFoundationDurations) (step.alias, step.milliseconds)], unit: 'ms'),
        .easing => _easing(),
        .layers => _layers(),
        final kind => foundationColorVisual(kind),
      };
    }
    return null;
  }
}

Component _topics() => div(classes: 'foundation-topics not-content', [
  for (final topic in docsNavTabFor('/tokens/overview').pages)
    if (kFoundationTopicDescriptions[topic.path] case final description?)
      a(href: topic.path, classes: 'foundation-topic site-box-link', [
        div(
          classes: 'foundation-topic-art foundation-panel',
          attributes: const {'aria-hidden': 'true'},
          [_topicArt(topic.path)],
        ),
        Text(topic.label).labelXl.onSurface,
        Text(description).bodySmall.onSurfaceVariant,
      ]),
]);

Component _topicArt(String path) => switch (path) {
  '/guides/colors' => img(src: '$_assetRoot/colors.svg', alt: ''),
  '/guides/typography' => div(classes: 'foundation-topic-type', [
    Text('Aa').displaySmall.bold.onSurface,
    Text('가').headlineMedium.regular.onSurfaceVariant,
  ]),
  '/guides/icons' => div(classes: 'foundation-topic-icons', [
    for (final name in const ['arrow-right', 'search', 'bell', 'settings']) img(src: '$_assetRoot/$name.svg', alt: ''),
  ]),
  '/guides/layout' => div(classes: 'foundation-topic-layout', [for (var i = 0; i < 4; i++) span([])]),
  '/guides/shape' => div(classes: 'foundation-topic-shape', [for (var i = 0; i < 3; i++) span([])]),
  '/guides/effect' => span(classes: 'foundation-topic-shadow', []),
  '/guides/animation' => img(src: '$_assetRoot/motion.svg', alt: ''),
  '/guides/layering' => div(classes: 'foundation-topic-layer', [for (var i = 0; i < 3; i++) span([])]),
  _ => const Component.fragment([]),
};

Component _fonts() => div(classes: 'design-pair not-content', [
  for (final font in kFoundationFonts)
    div(classes: 'foundation-panel foundation-font', [
      if (font.mono)
        span(classes: 'foundation-font-mono', [Component.text(font.sample)])
      else
        Text(font.sample).headlineMedium.bold,
      Text(font.name).labelXl,
      Text(font.roles).bodySmall.onSurfaceVariant,
    ]),
]);

Component _typography() => div(classes: 'docs-table foundation-specimen', [
  table([
    thead([
      tr([
        for (final label in kTypographyColumns) th([Component.text(label)]),
      ]),
    ]),
    tbody([for (final role in foundationTypeRoles) _typeRow(role.name, role.style)]),
  ]),
]);

Component _typeRow(String name, CoreTextStyle style) {
  final token = '--coui-text-$name';
  return tr([
    td([Component.text(foundationRoleName(name))]),
    td([
      code([Component.text(foundationTypeMeta(style))]),
    ]),
    td([
      span(
        classes: 'foundation-type-sample',
        attributes: {
          'style':
              'font-size:var($token-size);line-height:var($token-line-height);'
              'font-weight:var($token-weight);letter-spacing:var($token-tracking);'
              'font-family:var($token-family, var(--coui-font-family-sans));',
        },
        [Component.text(foundationTypeSpecimen(name))],
      ),
    ]),
  ]);
}

Component _iconSets() => div(classes: 'foundation-icon-sets not-content', [
  for (final set in foundationIconSets)
    div(classes: 'foundation-icon-set', [
      Text(foundationCount(set.count)).headlineMedium.bold.onSurface,
      Text(set.label).labelXl.onSurface,
      if (set.note case final note?) span(classes: 'foundation-icon-default', [Text(note).bodySmall]),
    ]),
]);

Component _bars(List<(String, num)> rows, {required String unit, int scale = 1}) => div(
  classes: 'foundation-panel foundation-bars not-content',
  [
    for (final (name, value) in rows)
      div(classes: 'foundation-bar-row', [
        code([Component.text(name)]),
        div(classes: 'foundation-bar-track', [
          span(
            classes: 'foundation-bar',
            attributes: {'style': '--bar-width:${value * scale}px', 'aria-hidden': 'true'},
            [],
          ),
          code([Component.text('${foundationNumber(value)}$unit')]),
        ]),
      ]),
  ],
);

Component _radii() => div(classes: 'foundation-panel foundation-samples not-content', [
  for (final role in kFoundationRadii)
    div(classes: 'foundation-sample', [
      span(
        classes: 'foundation-radius-sample',
        attributes: {'style': 'border-radius:var(--coui-radius-${role.radius.toInt()})'},
        [],
      ),
      code([Component.text(role.role)]),
      span([Component.text('${role.radius.toInt()}px')]),
    ]),
]);

Component _shadows() => div(classes: 'foundation-panel foundation-samples not-content', [
  for (final shadow in kFoundationShadows)
    div(classes: 'foundation-sample', [
      span(classes: 'foundation-shadow-sample', attributes: {'style': 'box-shadow:var(--shadow-${shadow.token})'}, []),
      code([Component.text(shadow.token)]),
    ]),
]);

Component _opacity() => div(classes: 'foundation-panel foundation-samples not-content', [
  for (final sample in kFoundationOpacity)
    div(classes: 'foundation-sample', [
      span(
        classes: 'foundation-opacity-sample',
        attributes: {'data-state': sample.state, 'style': '--state-opacity:${sample.opacity}'},
        [Text('버튼').labelLarge],
      ),
      span([Component.text(foundationOpacityLabel(sample))]),
    ]),
]);

Component _focusRing() => div(classes: 'foundation-panel foundation-focus not-content', [
  span(classes: 'foundation-focus-example', [Text(kFocusRingSampleLabel).labelLarge]),
  Text(foundationFocusRingCaption).bodySmall.onSurfaceVariant,
]);

Component _easing() => div(classes: 'foundation-easing not-content', [
  for (final easing in kFoundationEasings)
    div(classes: 'foundation-easing-item', [
      div(
        classes: 'foundation-panel foundation-easing-curve',
        // 올리면 두 가지가 같은 이징으로 움직인다 — 곡선 위의 점(가로는 일정한
        // 시간, 세로는 진행)과, 곡선 아래 트랙을 가로지르는 공(진행만).
        attributes: {'style': '--curve-easing:var(--site-easing-${easing.alias})'},
        [
          div(
            classes: 'foundation-easing-stage',
            attributes: const {'style': '--curve-w:${_curveWidth}px;--curve-h:${_curveHeight}px'},
            [
              _curve(easing.curve),
              span(
                classes: 'foundation-easing-time',
                attributes: const {'aria-hidden': 'true'},
                [
                  span(classes: 'foundation-easing-dot', []),
                ],
              ),
              span(
                classes: 'foundation-easing-track',
                attributes: const {'aria-hidden': 'true'},
                [
                  span(classes: 'foundation-easing-ball', []),
                ],
              ),
            ],
          ),
        ],
      ),
      code([Component.text('CoreEasing.${easing.alias}')]),
      Text(easing.description).bodySmall.onSurfaceVariant,
    ]),
]);

const _curveWidth = 100;
const _curveHeight = 72;

/// 이징 곡선 — 가로는 시간, 세로는 진행. 넘침(feedback)은 상자 밖으로 그린다.
Component _curve(CoreCubicBezier curve) {
  const width = _curveWidth;
  const height = _curveHeight;
  String x(double t) => foundationNumber((t * width * 100).round() / 100);
  String y(double v) => foundationNumber(((1 - v) * height * 100).round() / 100);
  return Component.element(
    tag: 'svg',
    attributes: const {
      'width': '$width',
      'height': '$height',
      'viewBox': '0 0 $width $height',
      'fill': 'none',
      'overflow': 'visible',
      'aria-hidden': 'true',
    },
    children: [
      Component.element(
        tag: 'path',
        attributes: {
          'd': 'M0 $height C${x(curve.x1)} ${y(curve.y1)} ${x(curve.x2)} ${y(curve.y2)} $width 0',
          'stroke': 'currentColor',
          'stroke-width': '2',
        },
      ),
    ],
  );
}

Component _layers() => div(classes: 'foundation-panel foundation-layers not-content', [
  ol([
    for (final layer in kFoundationLayers)
      li([
        code([Component.text(layer.token)]),
        Text(layer.label).labelMedium,
      ]),
  ]),
]);
