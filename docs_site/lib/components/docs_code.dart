/// 본문의 코드 블록 — 이름표, 복사, 그 아래 코드.
///
/// ## 코드는 킷의 `CodeSnippet` 이 그린다
///
/// 구문 색은 킷의 `--coui-syntax-*` 슬롯에서 온다. 그래서 밝기를 바꾸면
/// 코드도 따라 바뀌고, 문서의 코드와 컴포넌트 페이지의 `CodeSnippet` 예제가
/// 같은 색으로 읽힌다. 이 파일은 팔레트를 갖지 않는다.
///
/// 언어는 `mode` 로 그대로 넘긴다. 킷이 문법을 가진 언어(Dart)만 색을
/// 입히고, 나머지는 한 색의 글자로 둔다 — 다른 언어의 문법으로 칠하면 덜
/// 칠해지는 것이 아니라 틀리게 칠해진다(YAML 의 URL 이 주석이 된다).
///
/// ## 복사는 정적 스크립트가 한다
///
/// 이 사이트의 본문은 정적으로 생성된다 — 컴포넌트의 `onPressed` 는 서버의
/// 클로저라 브라우저에 가지 않는다. 그래서 버튼은 표시만 하고
/// (`data-docs-copy`), 누름은 `web/docs-shell.js` 가 받는다. 버튼의 문구
/// 셋(쉬는 때 · 복사한 뒤 · 실패)은 여기서 `data-*` 로 건넨다 — 스크립트가
/// 문구를 따로 들면 같은 문장이 두 곳에 산다.
library;

import 'package:coui_web/coui_web.dart';

/// 복사 버튼의 쉬는 문구.
const String kDocsCopyLabel = '복사';

/// 복사한 직후의 문구.
const String kDocsCopiedLabel = '복사됨';

/// 복사하지 못했을 때의 문구.
const String kDocsCopyFailedLabel = '복사 실패';

/// 코드 펜스의 언어 → 이름표.
///
/// 이름표는 "이 코드를 어디에 넣는가" 를 말한다 — 셸 명령이면 터미널이다.
/// 언어를 적지 않은 펜스와 `text` 는 이름표가 없다.
String? docsCodeLabel(String? language) => switch (language?.toLowerCase()) {
  null || '' || 'text' || 'txt' || 'plaintext' => null,
  'dart' => 'Dart',
  'yaml' || 'yml' => 'YAML',
  'json' => 'JSON',
  'bash' || 'sh' || 'shell' || 'zsh' || 'console' => 'Terminal',
  'html' => 'HTML',
  'css' => 'CSS',
  'js' || 'javascript' => 'JavaScript',
  'ts' || 'typescript' => 'TypeScript',
  'sql' => 'SQL',
  final other => other,
};

/// 코드 펜스를 맨 코드로 그리라는 표시 — 카드가 자기 본문의 펜스에 단다.
///
/// 카드 안의 코드는 설명의 일부라 이름표 · 복사 · 면이 없다(Figma 의 권장 ·
/// 금지 카드). 마크다운에 직접 적는 속성이 아니다.
const String kDocsCodePlainAttribute = 'data-docs-plain';

/// 본문의 코드 블록.
class DocsCode extends StatelessComponent {
  /// 코드 블록을 만든다.
  const DocsCode({required this.source, this.language, this.title, this.plain = false, super.key});

  /// 코드 — 끝의 빈 줄은 뺀 것.
  final String source;

  /// 펜스에 적힌 언어. 없으면 한 색의 글자로 그린다.
  final String? language;

  /// 이름표를 직접 정할 때 — 파일 이름처럼.
  final String? title;

  /// 이름표 · 복사 · 면 없이 고정폭 글자만 그린다([kDocsCodePlainAttribute]).
  final bool plain;

  @override
  Component build(BuildContext context) {
    if (plain) {
      return Component.element(
        tag: 'figure',
        classes: 'docs-code docs-code--plain not-content',
        children: [
          CodeSnippet(code: source, mode: 'text', showCopyButton: false, codeSnippetStyle: _plainStyle),
        ],
      );
    }

    final label = title ?? docsCodeLabel(language);

    return Component.element(
      tag: 'figure',
      // `not-content`: 본문의 산문 규칙이 이 안의 `pre` · `code` 를 다시
      // 꾸미지 않는다.
      classes: 'docs-code not-content',
      attributes: {
        'data-docs-code': '',
        'data-language': ?language,
      },
      children: [
        Component.element(
          tag: 'figcaption',
          classes: 'docs-code-head',
          children: [
            if (label != null) span(classes: 'docs-code-label', [Text(label).codeSm]),
            // 복사는 밑줄 글자다 — 면을 칠하지 않는 변형(셸의 시트가 밑줄을 긋는다).
            Button(
              variant: CoreButtonVariant.plain,
              size: CoreComponentSize.xs,
              // 누름은 정적 스크립트가 받는다 — 서버의 핸들러가 없어도
              // 버튼은 켜져 있어야 한다.
              enabled: true,
              attributes: {
                'data-docs-copy': '',
                'data-copy-label': kDocsCopyLabel,
                'data-copied-label': kDocsCopiedLabel,
                'data-failed-label': kDocsCopyFailedLabel,
                'aria-label': label == null ? '코드 복사' : '$label 코드 복사',
              },
              buttonStyle: _copyStyle,
              // 문구가 바뀌면 보조 기술이 읽는다 — 복사는 화면에 다른 흔적을
              // 남기지 않는다.
              child: span(
                attributes: const {'data-copy-label': '', 'aria-live': 'polite'},
                [Text(kDocsCopyLabel)],
              ),
            ),
          ],
        ),
        CodeSnippet(
          code: source,
          mode: language ?? 'text',
          // 복사는 위의 버튼이 한다 — 킷의 버튼은 브라우저에서 깨어나야
          // 동작하는데, 본문은 깨어나지 않는다.
          showCopyButton: false,
          codeSnippetStyle: _snippetStyle,
        ),
      ],
    );
  }

  /// 복사 버튼 — 이름표와 같은 한 단 물러난 글자색. 밑줄 글자라 여백이 없어,
  /// 이름표 줄의 높이가 이름표의 글자 높이와 같다(Figma `Doc/Code`).
  static const CoreButtonStyle _copyStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceSubtle),
    hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
    padding: CoreEdgeInsets.zero,
  );

  /// 코드의 면과 글자.
  ///
  /// 모서리는 바깥 상자가 갖는다(이름표 줄까지 한 상자다). 면은 킷의 기본
  /// 그대로 둔다 — 구문 색이 검증된 면이라서, 다른 면으로 바꾸면 킷이 색을
  /// 끄고 한 색으로 그린다.
  static const CoreCodeSnippetStyle _snippetStyle = CoreCodeSnippetStyle(
    borderRadius: CoreBorderRadius.zero,
    padding: CoreEdgeInsets.fromLTRB(CoreSpace.space20, CoreSpace.space10, CoreSpace.space20, CoreSpace.space16),
    codeTypography: CoreTextStyle.token(CoreTextStyles.codeMd),
  );

  /// 맨 코드 — 면 · 여백 없이 둘레의 글자처럼 놓인다. 면이 없으면 킷이 구문
  /// 색을 끄므로 한 색이다(시안도 한 색이다).
  static const CoreCodeSnippetStyle _plainStyle = CoreCodeSnippetStyle(
    backgroundColor: CoreColor.transparent,
    borderRadius: CoreBorderRadius.zero,
    padding: CoreEdgeInsets.zero,
    codeTypography: CoreTextStyle.token(CoreTextStyles.codeMd),
  );
}
