/// `<FoundationVisual kind="…" />` — 파운데이션 페이지의 그림.
///
/// 문서 사이트는 이 태그를 그림(색 띠 · 막대 · 견본)으로 그리고, 이 앱은 그
/// 그림이 보여 주는 **같은 값**을 표로 그린다. 값과 이름표는 둘 다
/// `docs_core` 의 `foundation_visuals.dart` 에서 읽으므로 한쪽만 고친 글이나
/// 숫자가 갈라지지 않는다.
///
/// 표는 마크다운으로 만들어 본문 렌더러에 다시 넘긴다 — 표 · 코드 · 내부
/// 링크를 그리는 방법이 본문과 같아진다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/foundation_visuals.dart';

/// 파운데이션 그림 태그 이름 → 빌더.
///
/// [nested] 는 만든 마크다운을 그리는 본문 렌더러다.
Map<String, DocsTagBuilder> docsFoundationVisualTagBuilders({
  required Widget Function(String markdown) nested,
}) => {
  'FoundationVisual': (context, tag) {
    final kind = FoundationVisualKind.parse(tag.attribute('kind'));
    return kind == null ? null : nested(foundationVisualMarkdown(kind));
  },
};

/// [kind] 의 그림이 보여 주는 값을 마크다운(표 · 문단 · 코드)으로 쓴다.
String foundationVisualMarkdown(FoundationVisualKind kind) => switch (kind) {
  .topics => _table(
    ['파운데이션', '다루는 것'],
    [
      for (final page in docsNavTabFor('/tokens/overview').pages)
        if (kFoundationTopicDescriptions[page.path] case final description?)
          ['[${page.label}](${page.path})', description],
    ],
  ),
  .colorPrinciples => _table(
    ['번호', '원칙', '설명'],
    [
      for (final principle in kColorPrinciples)
        [principle.number, principle.title, principle.description],
    ],
  ),
  .neutral => _ramp(foundationNeutralSteps),
  .status => [
    for (final ramp in foundationStatusRamps) ...[
      '**${ramp.label}** · ${ramp.description}',
      _ramp(ramp.steps, keySteps: kStatusKeySteps),
    ],
    kStatusRampNote,
  ].join('\n\n'),
  .category => [
    _table(
      ['색', kCategoryColumns.container, kCategoryColumns.onContainer, '점'],
      [
        for (final hue in CoreCategoryColor.values)
          [
            foundationCategoryName(hue),
            _hex(foundationCategoryTones(hue).container),
            _hex(foundationCategoryTones(hue).onContainer),
            _hex(foundationCategoryTones(hue).fill),
          ],
      ],
    ),
    kCategoryDotNote,
    '**${kCategoryNaming.title}** · `${kCategoryNaming.names}`',
  ].join('\n\n'),
  .semantic => _table(kSemanticColumns, [
    for (final row in kSemanticRoles)
      [
        '`${row.token.name}`',
        _hexOrDash(row.token.read(CoreThemePresets.lightColorScheme)),
        _hexOrDash(row.token.read(CoreThemePresets.darkColorScheme)),
        row.role,
      ],
  ]),
  .brand => [
    '```dart\n$kBrandThemeSource\n```',
    _table(
      ['예', 'primary', 'onPrimary'],
      [
        for (final sample in kBrandSamples) _brandRow(sample),
      ],
    ),
  ].join('\n\n'),
  .fonts => _table(
    ['서체', '견본', '쓰는 역할'],
    [
      for (final font in kFoundationFonts)
        [
          font.name,
          if (font.mono) '`${font.sample}`' else font.sample,
          font.roles,
        ],
    ],
  ),
  .typography => _table(kTypographyColumns, [
    for (final role in foundationTypeRoles)
      [
        foundationRoleName(role.name),
        '`${foundationTypeMeta(role.style)}`',
        foundationTypeSpecimen(role.name),
      ],
  ]),
  .iconSets => _table(
    ['세트', '아이콘 수', ''],
    [
      for (final set in foundationIconSets)
        [set.label, foundationCount(set.count), set.note ?? ''],
    ],
  ),
  .spacing => _table(
    ['토큰', '값'],
    [
      for (final step in kFoundationSpacing)
        ['`${step.token}`', '${foundationNumber(step.value)}px'],
    ],
  ),
  .radii => _table(
    ['역할', '반경'],
    [
      for (final role in kFoundationRadii)
        ['`${role.role}`', '${foundationNumber(role.radius)}px'],
    ],
  ),
  .shadows => _table(
    ['토큰', '레이어'],
    [
      for (final shadow in kFoundationShadows)
        ['`${shadow.token}`', shadow.layers.map(_layer).join(' · ')],
    ],
  ),
  .opacity => _table(
    ['상태', '겹치는 투명도'],
    [
      for (final sample in kFoundationOpacity)
        [sample.state, '${(sample.opacity * 100).round()}%'],
    ],
  ),
  .focusRing => '`$foundationFocusRingCaption`',
  .duration => _table(
    ['alias', '값'],
    [
      for (final duration in kFoundationDurations)
        ['`${duration.alias}`', '${duration.milliseconds}ms'],
    ],
  ),
  .easing => _table(
    ['alias', '곡선 · 쓰임', 'cubic-bezier'],
    [
      for (final easing in kFoundationEasings)
        [
          '`CoreEasing.${easing.alias}`',
          easing.description,
          '`${foundationCubicBezier(easing.curve)}`',
        ],
    ],
  ),
  .layers => _table(
    ['토큰', '쌓이는 것'],
    [
      for (final layer in kFoundationLayers) ['`${layer.token}`', layer.label],
    ],
  ),
};

/// 사다리 하나 — 단계 · 값. [keySteps] 의 단계는 굵게 쓴다.
String _ramp(Map<int, CoreColor> steps, {List<int> keySteps = const []}) =>
    _table(
      ['단계', '값'],
      [
        for (final MapEntry(key: step, value: color) in steps.entries)
          [
            if (keySteps.contains(step)) '**$step**' else '$step',
            _hex(color),
          ],
      ],
    );

/// 브랜드 예제 한 줄 — 이름 · 그 색 소스가 만드는 primary · onPrimary.
List<String> _brandRow(({String label, CoreColor? brandColor}) sample) {
  final colors = foundationBrandColors(sample.brandColor);
  return [sample.label, _hex(colors.primary), _hex(colors.onPrimary)];
}

/// 그림자 레이어 하나 — `y 1 · blur 2 · 4%`.
String _layer(CoreShadowLayer layer) => [
  if (layer.inset) 'inset',
  if (layer.offsetX != 0) 'x ${foundationNumber(layer.offsetX)}',
  'y ${foundationNumber(layer.offsetY)}',
  'blur ${foundationNumber(layer.blurRadius)}',
  if (layer.spreadRadius != 0) 'spread ${foundationNumber(layer.spreadRadius)}',
  '${foundationNumber((layer.opacity * 1000).round() / 10)}%',
].join(' ');

/// `#F9FAFB` → `` `F9FAFB` `` — 사이트의 그림이 적는 것과 같은 모양.
String _hex(CoreColor color) => '`${color.toHex().substring(1)}`';

String _hexOrDash(CoreColor? color) => color == null ? '—' : _hex(color);

/// GFM 표.
String _table(List<String> header, List<List<String>> rows) => [
  '| ${header.join(' | ')} |',
  '| ${[for (final _ in header) '---'].join(' | ')} |',
  for (final row in rows) '| ${row.join(' | ')} |',
].join('\n');
