import 'dart:convert';
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';

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
    final url = 'data:${file.mimeType};base64,${base64Encode(file.bytes)}';
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
          initialValue: '## 사진 추가\n\n이미지 버튼을 눌러 파일을 골라 보세요.',
          // The demo keeps each file inside the Markdown, so keep it small.
          maxImageBytes: 1024 * 1024,
          onImageUpload: _upload,
          onImageDelete: _delete,
        ),
        const Gap.space8(),
        Text(
          '데모 서버: 파일 ${_server.length}개 · 지운 이미지는 10초 뒤 서버에서도 지워져요.',
        ).bodySmall.onSurfaceVariant,
      ],
    );
  }
}
