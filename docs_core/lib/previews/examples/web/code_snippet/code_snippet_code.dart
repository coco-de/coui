/// Returns a Web code snippet string for the CodeSnippet component.
String codeSnippetCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CodeSnippetChainExample extends StatefulComponent {
  const CodeSnippetChainExample({super.key});

  @override
  State<CodeSnippetChainExample> createState() => _CodeSnippetChainExampleState();
}

class _CodeSnippetChainExampleState extends State<CodeSnippetChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        CodeSnippet(
          code: "void main() {\\n  print('Hello, CoUI!');\\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        CodeSnippet(
          code: "void main() {\\n  print('Hello, CoUI!');\\n}",
          mode: 'dart',
          showLineNumbers: true,
          showCopyButton: true,
        ).withStyle(
          const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            codeTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onTertiary),
            ),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'line-tones' =>
      '''
class CodeSnippetLineTonesExample extends StatelessComponent {
  const CodeSnippetLineTonesExample({super.key});

  @override
  Component build(BuildContext context) {
    // 바뀐 줄은 success, 오류가 난 줄은 error — 줄 번호는 1부터 셉니다.
    return const CodeSnippet(
      code: "void main() {\\n  final greeting = 'Hello, CoUI!';\\n  print(greting);\\n}",
      mode: 'dart',
      showLineNumbers: true,
      lineTones: {2: CoreCodeLineTone.success, 3: CoreCodeLineTone.error},
    );
  }
}''',
    _ =>
      '''
class CodeSnippetDefaultExample extends StatefulComponent {
  const CodeSnippetDefaultExample({super.key});

  @override
  State<CodeSnippetDefaultExample> createState() =>
      _CodeSnippetDefaultExampleState();
}

class _CodeSnippetDefaultExampleState
    extends State<CodeSnippetDefaultExample> {
  @override
  Component build(BuildContext context) {
    return CodeSnippet(
      code: "void main() {\\n  print('Hello, CoUI!');\\n}",
      mode: 'dart',
      showLineNumbers: true,
      showCopyButton: true,
    );
  }
}''',
  };
}
