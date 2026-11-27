/// Text 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="text/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Web
/// 파일(`text_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 chain 은 모든 위젯에 붙고 `Widget` 을 돌려준다. 그래서 글을
/// 만드는 도우미의 타입이 `Text` 가 아니라 `Widget` 이다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_flutter.dart';
import 'text_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _playgroundText;

/// 장면 이름(`text/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'text/roles-heading': () => _roleList(page.textHeadingRoleNames),
  'text/roles-body': () => _roleList(page.textBodyRoleNames),
  'text/weights': () => docsFlutterDemoRow([
    const Text('thin').titleMedium.thin,
    const Text('extraLight').titleMedium.extraLight,
    const Text('light').titleMedium.light,
    const Text('regular').titleMedium.regular,
    const Text('medium').titleMedium.medium,
    const Text('semiBold').titleMedium.semiBold,
    const Text('bold').titleMedium.bold,
    const Text('extraBold').titleMedium.extraBold,
    const Text('black').titleMedium.black,
  ]),
  'text/primitives': () => _box(CoreSpace.space240, [
    const Text('.s10').s10,
    const Text('.s14').s14,
    const Text('.s20').s20,
    const Text('.s32').s32,
    const Text('.tighter').titleMedium.tighter,
    const Text('.widest').titleMedium.widest,
    const Text('.sans 가나다 123').bodyMedium.sans,
    const Text('.mono 가나다 123').bodyMedium.mono,
    const Text('.h200').codeXs.onSurfaceVariant,
    const Text(page.textSampleNotice).bodySmall.h200,
  ]),
  'text/modifiers': () => docsFlutterDemoRow([
    const Text('italic').bodyMedium.onSurface.italic,
    const Text('underline').bodyMedium.onSurface.underline,
    const Text('lineThrough').bodyMedium.onSurface.lineThrough,
    const Text('overline').bodyMedium.onSurface.overline,
    const Text('opacity').bodyMedium.onSurface.opacity(CoreOpacity.opacity60),
  ]),
  'text/colors': () => _column([
    for (final name in page.textColorSampleNames) _color(Text(name).bodyMedium, name),
  ]),
  'text/wrap': () => _box(CoreSpace.space240, [
    const Text('제한 없음').labelSmall.onSurfaceVariant,
    const Text(page.textSampleNotice).bodyMedium.onSurface,
    const Text('.lineLimit(2)').codeXs.onSurfaceVariant,
    const Text(page.textSampleNotice).bodyMedium.onSurface.lineLimit(2),
    const Text('.lineLimit(1).ellipsis').codeXs.onSurfaceVariant,
    const Text(page.textSampleNotice).bodyMedium.onSurface.lineLimit(1).ellipsis,
  ]),
  'text/keep-all': () => docsFlutterDemoRow([
    _captioned('기본', _box(CoreSpace.space120, [const Text(page.textSampleTitle).titleMedium.onSurface])),
    _captioned('.keepAll', _box(CoreSpace.space120, [const Text(page.textSampleTitle).titleMedium.onSurface.keepAll])),
  ]),
  'text/rich': _rich,
  'text/do-role-order': () => const Text(page.textSampleSales).bodyMedium.s24.onSurface,
  'text/dont-role-order': () => const Text(page.textSampleSales).s24.bodyMedium.onSurface,
  'text/do-error-color': () => const Text(page.textSampleError).bodyMedium.onErrorContainer,
  'text/dont-faint-color': () => const Text(page.textSampleError).bodyMedium.outlineVariant,
  'text/do-keep-all': () => _box(CoreSpace.space120, [const Text(page.textSampleTitle).titleMedium.onSurface.keepAll]),
  'text/dont-split-word': () => _box(CoreSpace.space120, [const Text(page.textSampleTitle).titleMedium.onSurface]),
  'text/related-link': () => Link(href: '/components/link', onPressed: () {}, child: const Text('환불 정책 보기')),
  'text/related-selectable-text': () => const SelectableText('A1B2-C3D4'),
  'text/related-text-block': () => const TextBlock(
    text: '수업 시작 두 시간 전까지 취소할 수 있습니다.',
    element: CoreTextBlockElement.blockquote,
  ),
  'text/related-badge': () => const Badge(child: Text('신규')),
};

Widget _playgroundText(Map<String, String> props, String? label) {
  var result = _color(
    _role(Text(label ?? page.textSampleTitle), page.textPreviewRole(props)),
    page.textPreviewColor(props),
  );
  if (previewFlag(props, 'bold')) result = result.bold;
  if (previewFlag(props, 'italic')) result = result.italic;
  if (previewFlag(props, 'underline')) result = result.underline;
  if (previewFlag(props, 'clamp')) result = result.lineLimit(2).ellipsis;
  if (previewFlag(props, 'keepAll')) result = result.keepAll;
  return _box(CoreSpace.space240, [result]);
}

/// 역할 이름 → 그 역할 chain 을 건 글.
Widget _role(Widget text, String name) => switch (name) {
  'displayLarge' => text.displayLarge,
  'displayMedium' => text.displayMedium,
  'displaySmall' => text.displaySmall,
  'headlineLarge' => text.headlineLarge,
  'headlineMedium' => text.headlineMedium,
  'headlineSmall' => text.headlineSmall,
  'titleLarge' => text.titleLarge,
  'titleMedium' => text.titleMedium,
  'titleSmall' => text.titleSmall,
  'bodyLarge' => text.bodyLarge,
  'bodyMedium' => text.bodyMedium,
  'bodySmall' => text.bodySmall,
  'bodyXs' => text.bodyXs,
  'labelXl2' => text.labelXl2,
  'labelXl' => text.labelXl,
  'labelLarge' => text.labelLarge,
  'labelMedium' => text.labelMedium,
  'labelSmall' => text.labelSmall,
  'labelXs' => text.labelXs,
  'codeXs' => text.codeXs,
  'codeSm' => text.codeSm,
  'codeMd' => text.codeMd,
  _ => text.bodyMedium,
};

/// 색 이름 → 그 색 chain 을 건 글.
Widget _color(Widget text, String name) => switch (name) {
  'onSurfaceVariant' => text.onSurfaceVariant,
  'outline' => text.outline,
  'onPrimaryContainer' => text.onPrimaryContainer,
  'onSecondaryContainer' => text.onSecondaryContainer,
  'onTertiaryContainer' => text.onTertiaryContainer,
  'onErrorContainer' => text.onErrorContainer,
  'onSuccessContainer' => text.onSuccessContainer,
  'onWarningContainer' => text.onWarningContainer,
  'onInfoContainer' => text.onInfoContainer,
  _ => text.onSurface,
};

Widget _roleList(List<String> names) => _column([
  for (final name in names) _role(Text(name), name).onSurface,
]);

Widget _rich() => Builder(
  builder: (context) {
    final colors = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: page.textRichLead,
        children: [
          TextSpan(
            text: page.textRichStrong,
            style: TextStyle(color: colors.onInfoContainer.toValue(), fontWeight: CoreFontWeight.semiBold.weight),
          ),
          const TextSpan(text: ' + '),
          TextSpan(
            text: page.textRichError,
            style: TextStyle(color: colors.onErrorContainer.toValue(), fontStyle: FontStyle.italic),
          ),
          const TextSpan(text: ' + '),
          const TextSpan(
            text: page.textRichUnderline,
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ],
      ),
    ).bodyMedium.onSurface;
  },
);

/// 내용만큼의 폭으로 세로로 쌓는다.
Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: children,
);

/// [width](logical px) 폭의 열 — 좁으면 줄어든다.
Widget _box(double width, List<Widget> children) => SizedBox(width: width, child: _column(children));

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => _column([Text(caption).labelSmall.onSurfaceVariant, child]);
