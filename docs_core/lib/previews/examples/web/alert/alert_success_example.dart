import 'package:coui_web/coui_web.dart';

/// Success-variant Alert example for docs_site Web preview.
class AlertSuccessExample extends StatefulComponent {
  const AlertSuccessExample({super.key});

  @override
  State<AlertSuccessExample> createState() => _AlertSuccessExampleState();
}

class _AlertSuccessExampleState extends State<AlertSuccessExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
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
