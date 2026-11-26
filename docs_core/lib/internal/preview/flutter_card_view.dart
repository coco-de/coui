import 'package:coui_flutter/coui_flutter.dart';

import 'docs_card_shape.dart';
import 'flutter_stage.dart';
import 'native_inline_renderer.dart';
import 'native_paragraph_body.dart';

export 'docs_card_shape.dart';

/// 카드 한 장이 한 줄에 놓일 때의 최소 폭 — 이보다 좁으면 다음 줄로 넘긴다.
const double kDocsCardMinWidth = CoreSpace.space240;

/// The original Native Cards width allocation, shared without changing grouping.
class FlutterDocsCardsLayout extends StatelessWidget {
  const FlutterDocsCardsLayout({required this.cards, super.key});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 폭이 허락하는 만큼 나란히, 아니면 아래로 — 사이트의 격자와 같은 답.
        final perRow = (constraints.maxWidth / kDocsCardMinWidth).floor().clamp(
          1,
          cards.length,
        );
        final width = (constraints.maxWidth - CoreSpace.space16 * (perRow - 1)) / perRow;

        return Wrap(
          spacing: CoreSpace.space16,
          runSpacing: CoreSpace.space16,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

/// The actual Native documentation Card view used by the application and scenes.
///
/// 모양은 사이트의 카드(`web_card_view.dart`)와 같다 — 면 카드(`filled`, 기본),
/// 선 카드(`outlined`), 숫자 카드(`value`), 미리보기 카드(`component` ·
/// `demo`). [variant] 는 묶음(`<Cards variant>`)이 정한 모양이고 카드가 자기
/// `variant` 를 적으면 그것이 이긴다.
Widget buildNativeDocsCardView({
  required Map<String, String> attributes,
  required String? rawBody,
  required Widget Function(String markdown) nested,
  required DocsInternalLinkCallback? onInternalLink,
  String? variant,
}) {
  final title = attributes['title'];
  final eyebrow = attributes['eyebrow'];
  final value = attributes['value'];
  final badge = attributes['badge'];
  final href = attributes['href'];
  final more = attributes['more'];
  final body = rawBody?.trim() ?? '';
  final tone = attributes['tone'];

  // 미리보기를 단 카드 — 카드 위쪽에 무대를 둔다(사이트의 `docs-card--preview`).
  final hasPreview = attributes['component'] != null || attributes['demo'] != null;
  final shape = docsCardShape(attributes, groupVariant: variant);
  final stat = value != null;

  // 권장 · 금지는 미리보기 카드에서만 테두리가 거든다 — 문서 페이지의
  // 카드는 이름표의 색이 거든다(사이트와 같다).
  final cardStyle = hasPreview
      ? switch (tone) {
          'do' => const CoreCardStyle(borderColor: CoreColor.token(CoreColors.successContainer)),
          'dont' => const CoreCardStyle(borderColor: CoreColor.token(CoreColors.errorContainer)),
          _ => null,
        }
      : shape == 'outlined'
      ? _kOutlinedCardStyle
      : _kFilledCardStyle;

  final captionChildren = <Widget>[
    if (eyebrow != null)
      switch ((hasPreview, tone)) {
        (true, 'do') => Text(eyebrow).labelSmall.onSuccessContainer,
        (true, 'dont') => Text(eyebrow).labelSmall.onErrorContainer,
        (true, _) => Text(eyebrow).labelSmall.onSurfaceVariant,
        (false, 'do') => _tinted(eyebrow, _kToneEyebrow, CoreColors.success),
        (false, 'dont') => _tinted(eyebrow, _kToneEyebrow, CoreColors.error),
        // 순번 같은 짧은 표시는 고정폭 글자다.
        (false, _) => _tinted(eyebrow, const CoreTextStyle.token(CoreTextStyles.codeSm), CoreColors.onSurfaceSubtle),
      },
    if (value != null) Text(value).headlineMedium.onSurface,
    if (title != null || badge != null)
      Row(
        spacing: CoreSpace.space8,
        children: [
          if (title != null)
            Expanded(
              // 제목의 역할은 모양이 정한다 — 면 카드는 한 단 크고, 선 카드 ·
              // 숫자 카드는 그 안의 이름이라 한 단 작다.
              child: switch ((hasPreview, shape, stat)) {
                (true, _, _) => Text(title).titleSmall.onSurface,
                (_, _, true) || (_, 'outlined', _) => Text(title).labelXl.onSurface,
                _ => Text(title).titleMedium.onSurface,
              },
            ),
          if (badge != null) Badge(variant: .outlined, child: Text(badge).labelSmall),
        ],
      ),
    if (body.isNotEmpty) nested(body),
    if (href != null && more != null)
      if (hasPreview)
        Text('$more →').labelLarge.onSurface.semiBold
      else
        // 링크는 밑줄이 말한다 — 화살표를 덧붙이지 않는다.
        Text(more).labelLarge.medium.onSurface.underline,
  ];
  final caption = Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    spacing: hasPreview || shape == 'outlined'
        ? CoreSpace.space8
        : stat
        ? CoreSpace.space6
        : CoreSpace.space10,
    children: captionChildren,
  );
  final card = hasPreview
      ? Card(
          variant: .outlined,
          cardStyle: cardStyle,
          media: DocsStage(attributes: attributes, flatBottom: true),
          body: captionChildren.isEmpty ? null : caption,
        )
      : Card(
          variant: shape == 'outlined' ? .outlined : .filled,
          cardStyle: cardStyle,
          child: caption,
        );

  if (href == null) return card;

  return Semantics(
    link: true,
    child: Clickable(onPressed: () => onInternalLink?.call(href), child: card),
  );
}

/// 권장 · 금지 이름표 — 라벨 역할에 한 단 굵게.
final CoreTextStyle _kToneEyebrow = const CoreTextStyle.token(
  CoreTextStyles.labelSmall,
).copyWith(fontWeight: CoreFontWeight.medium);

/// [role] 의 글자를 테마의 [token] 색으로 그린다.
///
/// Text 체인에는 이 색들(성공 · 오류 · 한 단 물러난 글자)의 이름이 없고, 역할
/// 체인은 글자색을 다시 정하므로 바깥의 `DefaultTextStyle` 로는 입힐 수 없다.
Widget _tinted(String text, CoreTextStyle role, CoreColorToken token) => Builder(
  builder: (context) => Text(
    text,
    style: role.merge(CoreTextStyle(color: CoreColor.token(token))).toValue(theme: Theme.of(context)),
  ),
);

/// 면 카드 — 면 위에 가는 선을 하나 두르고 모서리가 넉넉하다(Figma 개요 · 색상 원칙).
const CoreCardStyle _kFilledCardStyle = CoreCardStyle(
  padding: CoreEdgeInsets.all(CoreSpace.space24),
  borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
  borderWidth: CoreStrokeWidth.stroke1,
  borderColor: CoreColor.token(CoreColors.outlineSubtle),
);

/// 선 카드 — 면 없이 선만, 카드보다 작은 모서리.
const CoreCardStyle _kOutlinedCardStyle = CoreCardStyle(
  padding: CoreEdgeInsets.all(CoreSpace.space20),
  borderRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
  backgroundColor: CoreColor.transparent,
  borderColor: CoreColor.token(CoreColors.outlineSubtle),
);

/// A whole Card rendered through the original official standalone Card layout.
class FlutterDocsCardView extends StatelessWidget {
  const FlutterDocsCardView({required this.attributes, required this.rawBody, super.key});

  final Map<String, String> attributes;
  final String rawBody;

  @override
  Widget build(BuildContext context) => FlutterDocsCardsLayout(
    cards: [
      buildNativeDocsCardView(
        attributes: attributes,
        rawBody: rawBody,
        nested: (markdown) => FlutterDocsParagraphBody(markdown: markdown),
        onInternalLink: null,
      ),
    ],
  );
}

/// Renders a whole standalone Card with the original Native paragraph renderer.
Widget buildFlutterDocsCardScene(Map<String, String> nativeAttrs, String rawBody) =>
    FlutterDocsCardView(attributes: nativeAttrs, rawBody: rawBody);
