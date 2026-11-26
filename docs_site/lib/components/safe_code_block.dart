import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'docs_code.dart';

/// 마크다운의 코드 펜스와 `<Code>` 태그를 [DocsCode] 로 그린다.
///
/// 이름이 "safe" 인 이유: 언어가 무엇이든 블록이 그려진다. 킷이 문법을 갖지
/// 않은 언어는 색 없이 그려질 뿐, 빌드를 멈추지 않는다.
class SafeCodeBlock extends CustomComponent {
  /// 코드 블록 컴포넌트를 만든다.
  SafeCodeBlock() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node
        case ElementNode(
              tag: 'Code' || 'CodeBlock',
              :final children,
              :final attributes,
            ) ||
            ElementNode(
              tag: 'pre',
              children: [
                ElementNode(tag: 'code', :final children, :final attributes),
              ],
            )) {
      var language = attributes['language'];
      if (language == null && (attributes['class']?.startsWith('language-') ?? false)) {
        language = attributes['class']!.substring('language-'.length);
      }

      // 텍스트 조각은 자기 줄바꿈을 들고 온다 — 사이에 공백을 넣으면
      // `<Code>` 태그 안의 첫 줄이 한 칸 밀린다.
      final source = children?.map((c) => c.innerText).join() ?? '';

      return DocsCode(
        // 펜스의 내용은 줄바꿈으로 끝난다 — 그대로 두면 빈 줄이 하나 더 그려진다.
        // `<Code>` 태그는 여는 태그 다음 줄에서 시작하므로 앞의 빈 줄도 뺀다.
        source: source.replaceFirst(RegExp(r'^\n+'), '').replaceFirst(RegExp(r'\n+$'), ''),
        language: language,
        title: attributes['title'],
        plain: attributes.containsKey(kDocsCodePlainAttribute),
      );
    }
    return null;
  }
}
