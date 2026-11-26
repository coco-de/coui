import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/foundation_visuals.dart';

import 'docs_code.dart';

/// 색상 페이지의 그림. 값과 글은 `foundation_visuals.dart` 가 정한다.
Component? foundationColorVisual(FoundationVisualKind kind) => switch (kind) {
  .colorPrinciples => _principles(),
  .neutral => _ramp(foundationNeutralSteps, neutral: true),
  .status => _status(),
  .category => _categories(),
  .semantic => _semantics(),
  .brand => _brand(),
  _ => null,
};

Component _principles() => div(classes: 'foundation-principles not-content', [
  for (final principle in kColorPrinciples)
    div(classes: 'foundation-panel foundation-principle', [
      code([Component.text(principle.number)]),
      Text(principle.title).titleMedium.semiBold.onSurface,
      Text(principle.description).bodyMedium.onSurfaceVariant,
    ]),
]);

Component _ramp(Map<int, CoreColor> steps, {bool neutral = false}) => div(
  classes: 'foundation-ramp not-content',
  [
    ol(
      classes: neutral ? 'foundation-ramp-neutral' : null,
      [
        for (final step in steps.entries)
          li(
            attributes: {
              if (!neutral && kStatusKeySteps.contains(step.key)) 'data-key-step': '',
            },
            [
              span(
                classes: 'foundation-ramp-swatch',
                attributes: {'style': 'background-color:${step.value.toHex()}', 'aria-hidden': 'true'},
                [],
              ),
              span(classes: 'foundation-ramp-step', [Component.text('${step.key}')]),
              code([Component.text(step.value.toHex().substring(1))]),
            ],
          ),
      ],
    ),
  ],
);

Component _status() => div(classes: 'foundation-status not-content', [
  for (final ramp in foundationStatusRamps)
    div(classes: 'foundation-status-ramp', [
      div(classes: 'foundation-status-head', [
        Text(ramp.label).titleSmall.onSurface,
        Text(ramp.description).bodySmall.onSurfaceVariant,
      ]),
      _ramp(ramp.steps),
    ]),
  Text(kStatusRampNote).bodySmall.onSurfaceVariant,
]);

Component _categories() => div(classes: 'foundation-categories not-content', [
  div(classes: 'foundation-category-head', [
    Text(kCategoryColumns.container).labelSmall.onSurfaceVariant,
    Text(kCategoryColumns.onContainer).labelSmall.onSurfaceVariant,
  ]),
  for (final hue in CoreCategoryColor.values) _categoryRow(hue),
  Text(kCategoryDotNote).bodySmall.onSurfaceVariant,
  div(classes: 'design-note', [
    Text(kCategoryNaming.title).labelMedium.onSurface,
    code([Component.text(kCategoryNaming.names)]),
  ]),
]);

Component _categoryRow(CoreCategoryColor hue) {
  final tones = foundationCategoryTones(hue);
  final container = tones.container.toHex();
  final ink = tones.onContainer.toHex();
  final fill = tones.fill.toHex();
  return div(
    classes: 'foundation-category',
    attributes: {'style': '--category-container:$container;--category-ink:$ink;--category-fill:$fill'},
    [
      div(classes: 'foundation-category-container', [
        span(classes: 'foundation-category-name', [
          span(classes: 'foundation-category-dot', attributes: const {'aria-hidden': 'true'}, []),
          Component.text(foundationCategoryName(hue)),
        ]),
        code([Component.text(container.substring(1))]),
      ]),
      code(classes: 'foundation-category-ink', [Component.text(ink.substring(1))]),
    ],
  );
}

Component _semantics() => div(classes: 'docs-table foundation-semantic', [
  table([
    thead([
      tr([
        for (final label in kSemanticColumns) th([Component.text(label)]),
      ]),
    ]),
    tbody([
      for (final row in kSemanticRoles)
        tr([
          td([
            code([Component.text(row.token.name)]),
          ]),
          _semanticSwatch(row.token.read(CoreThemePresets.lightColorScheme)),
          _semanticSwatch(row.token.read(CoreThemePresets.darkColorScheme)),
          td([Component.text(row.role)]),
        ]),
    ]),
  ]),
]);

Component _semanticSwatch(CoreColor? color) => td([
  if (color != null)
    span(classes: 'foundation-semantic-swatch', [
      span(attributes: {'style': 'background-color:${color.toHex()}', 'aria-hidden': 'true'}, []),
      code([Component.text(color.toHex().substring(1))]),
    ])
  else
    const Component.text('—'),
]);

Component _brand() => div(classes: 'design-pair not-content', [
  const DocsCode(language: 'dart', title: kBrandThemeTitle, source: kBrandThemeSource),
  div(
    classes: 'foundation-panel foundation-brands',
    attributes: const {'inert': ''},
    [
      for (final sample in kBrandSamples)
        Button(enabled: true, buttonStyle: _brandStyle(sample.brandColor), child: Text(sample.label)),
    ],
  ),
]);

/// 기본 버튼은 테마의 토큰을 따라 다크 모드에서도 바뀌고, 브랜드 버튼은 그
/// 브랜드 색 소스가 라이트 모드에서 만드는 값으로 칠한다.
CoreButtonStyle _brandStyle(CoreColor? brandColor) {
  if (brandColor == null) {
    return const CoreButtonStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      foregroundColor: CoreColor.token(CoreColors.onPrimary),
    );
  }
  final colors = foundationBrandColors(brandColor);
  return CoreButtonStyle(backgroundColor: colors.primary, foregroundColor: colors.onPrimary);
}
