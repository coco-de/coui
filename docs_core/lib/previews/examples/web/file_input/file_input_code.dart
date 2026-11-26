/// Returns a Web code snippet string for the FileInput component.
String fileInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FileInputChainExample extends StatefulComponent {
  const FileInputChainExample({super.key});

  @override
  State<FileInputChainExample> createState() => _FileInputChainExampleState();
}

class _FileInputChainExampleState extends State<FileInputChainExample> {
  List<String> _selectedFiles = const [];

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FileInput(
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles = [
                for (var i = 0; i < files.length; i++) files.item(i)!.name,
              ];
            });
          },
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        FileInput(
          onFilesSelected: (files) {
            setState(() {
              _selectedFiles = [
                for (var i = 0; i < files.length; i++) files.item(i)!.name,
              ];
            });
          },
          multiple: true,
          hint: 'PNG, JPG, PDF · 최대 10MB',
          selectedFiles: _selectedFiles,
        ).withStyle(
          const CoreFileInputStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
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
    _ =>
      '''
class FileInputDefaultExample extends StatefulComponent {
  const FileInputDefaultExample({super.key});

  @override
  State<FileInputDefaultExample> createState() =>
      _FileInputDefaultExampleState();
}

class _FileInputDefaultExampleState extends State<FileInputDefaultExample> {
  List<String> _selectedFiles = const [];

  @override
  Component build(BuildContext context) {
    return FileInput(
      onFilesSelected: (files) {
        setState(() {
          _selectedFiles = [
            for (var i = 0; i < files.length; i++) files.item(i)!.name,
          ];
        });
      },
      multiple: true,
      hint: 'PNG, JPG, PDF · 최대 10MB',
      selectedFiles: _selectedFiles,
    );
  }
}''',
  };
}
