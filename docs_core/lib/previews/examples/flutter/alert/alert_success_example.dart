import 'package:coui_flutter/coui_flutter.dart';

/// Success-variant Alert example for docs_site Flutter preview.
class AlertSuccessExample extends StatefulWidget {
  const AlertSuccessExample({super.key});

  @override
  State<AlertSuccessExample> createState() => _AlertSuccessExampleState();
}

class _AlertSuccessExampleState extends State<AlertSuccessExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.success(
        title: '저장 완료',
        description: '변경 사항이 성공적으로 저장되었습니다.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}
