/// Returns a Flutter code snippet string for the RichEditor component.
String richEditorCode(String? variant) {
  return switch (variant) {
    'image' =>
      '''
class RichEditorImageExample extends StatefulWidget {
  const RichEditorImageExample({super.key});

  @override
  State<RichEditorImageExample> createState() => _RichEditorImageExampleState();
}

class _RichEditorImageExampleState extends State<RichEditorImageExample> {
  // A stand-in for the server's storage: address -> file. Nothing leaves
  // the page, so the example works offline.
  final Map<String, Uint8List> _server = {};

  Future<String> _upload(CoreRichEditorImageFile file) async {
    // Pretend the network takes a moment.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final url = 'data:\${file.mimeType};base64,\${base64Encode(file.bytes)}';
    if (mounted) setState(() => _server[url] = file.bytes);
    return url;
  }

  Future<void> _delete(String url) async {
    if (mounted) setState(() => _server.remove(url));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichEditor(
          placeholder: '댓글을 입력해 주세요',
          initialValue: '## 사진 추가\\n\\n이미지 버튼을 눌러 파일을 골라 보세요.',
          // The demo keeps each file inside the Markdown, so keep it small.
          maxImageBytes: 1024 * 1024,
          onImageUpload: _upload,
          onImageDelete: _delete,
        ),
        const Gap.space8(),
        Text(
          '데모 서버: 파일 \${_server.length}개 · 지운 이미지는 10초 뒤 서버에서도 지워져요.',
        ).bodySmall.onSurfaceVariant,
      ],
    );
  }
}''',
    'max-length' =>
      '''
class RichEditorMaxLengthExample extends StatelessWidget {
  const RichEditorMaxLengthExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      maxLength: 140,
      initialValue:
          '**짧게 써 주세요.** 140자 이내의 답글은 '
          '알림 미리보기에서 바로 다 보여요.',
    );
  }
}''',
    'no-toolbar' =>
      '''
class RichEditorNoToolbarExample extends StatelessWidget {
  const RichEditorNoToolbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      showToolbar: false,
      initialValue: '툴바가 없어도 **단축키**와 `Markdown` 문법은 그대로 쓸 수 있어요.',
    );
  }
}''',
    _ =>
      '''
class RichEditorDefaultExample extends StatelessWidget {
  const RichEditorDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      initialValue:
          '## 리뷰 메모\\n'
          '\\n'
          '**좋아요!** 작은 수정 두 가지만 부탁해요.\\n'
          '\\n'
          '- 툴바 그룹 이름 바꾸기\\n'
          '- 빠진 툴팁 추가하기\\n'
          '\\n'
          '> CI가 통과하면 배포해 주세요.',
    );
  }
}''',
  };
}
