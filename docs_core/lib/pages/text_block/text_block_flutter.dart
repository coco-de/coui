/// TextBlock 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="text-block/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`text_block_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// `pre` 상자의 채움(`surfaceContainer`)은 같은 색의 면 위에서는 구분되지
/// 않는다. 그래서 상자 장면은 둘레의 색과 상관없이 채움이 보이도록
/// `surface` 색의 외곽선 `Card` 안에 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'text_block_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _textBlock;

/// 장면 이름(`text-block/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'text-block/headings': () => _column(
    _spaced([for (final (element, text) in page.demoHeadingBlocks) _block(element, text)]),
  ),
  'text-block/body': () => _column(
    _spaced([for (final (element, text) in page.demoBodyBlocks) _block(element, text)]),
  ),
  'text-block/boxes': () => _surfaceCard([
    _block(CoreTextBlockElement.blockquote, page.demoQuoteText),
    _block(CoreTextBlockElement.pre, page.demoCodeText),
  ]),
  'text-block/override': () => _surfaceCard([
    const TextBlock(
      text: page.demoQuoteText,
      element: CoreTextBlockElement.blockquote,
      textBlockStyle: page.demoQuoteOverride,
    ),
    const TextBlock(
      text: page.demoCodeText,
      element: CoreTextBlockElement.pre,
      textBlockStyle: page.demoCodeOverride,
    ),
  ]),
  'text-block/presets': () => _column(
    _spaced([
      for (final name in page.demoRolePresets) _block(CoreTextBlockElement.p, '$name 프리셋', preset: name),
    ]),
  ),
  'text-block/do-heading': () => _column(width: page.demoCardColumnWidth, [
    _block(CoreTextBlockElement.h3, page.demoSectionTitle),
    _block(CoreTextBlockElement.p, page.demoSectionBody),
  ]),
  'text-block/dont-heading-look': () => _column(width: page.demoCardColumnWidth, [
    _block(CoreTextBlockElement.p, page.demoSectionTitle, preset: 'heading3'),
    _block(CoreTextBlockElement.p, page.demoSectionBody),
  ]),
  'text-block/do-preset': () => _column(width: page.demoCardColumnWidth, [
    _block(CoreTextBlockElement.p, page.demoNotice, preset: 'lead'),
  ]),
  'text-block/dont-element-size': () => _column(width: page.demoCardColumnWidth, [
    _block(CoreTextBlockElement.h4, page.demoNotice),
  ]),
};

Widget _textBlock(Map<String, String> props, String? label) =>
    _block(page.demoElementOf(props), label ?? page.demoLabel, preset: page.demoPresetOf(props));

/// 요소 하나. 프리셋은 `BuildContext` 가 필요해 `Builder` 안에서 만든다.
Widget _block(CoreTextBlockElement element, String text, {String? preset}) {
  if (preset == null) return TextBlock(text: text, element: element);
  return Builder(
    builder: (context) => TextBlock(text: text, element: element, presets: [_preset(context, preset)]),
  );
}

/// 프리셋 이름([page.demoRolePresets]) → 프리셋.
TextBlockStyle _preset(BuildContext context, String name) => switch (name) {
  'heading1' => TextBlock.heading1(context),
  'heading2' => TextBlock.heading2(context),
  'heading3' => TextBlock.heading3(context),
  'heading4' => TextBlock.heading4(context),
  'lead' => TextBlock.lead(context),
  'lg' => TextBlock.lg(context),
  'sm' => TextBlock.sm(context),
  _ => TextBlock.muted(context),
};

/// 블록을 위에서 아래로 놓는 열 — [width] 는 logical px, 좁으면 줄어든다.
Widget _column(List<Widget> children, {double width = page.demoColumnWidth}) => SizedBox(
  width: width,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  ),
);

/// 블록 사이에 간격을 둔다.
List<Widget> _spaced(List<Widget> blocks) => [
  for (final (index, block) in blocks.indexed) ...[
    if (index > 0) const Gap.space12(),
    block,
  ],
];

/// `surface` 색 판 위에 블록을 놓는다.
Widget _surfaceCard(List<Widget> blocks) => Card(
  variant: CoreCardVariant.outlined,
  child: _column(_spaced(blocks)),
);
