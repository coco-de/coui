import 'package:coui_web/coui_web.dart';

/// Warning-variant Alert example for docs_site Web preview.
class AlertWarningExample extends StatefulComponent {
  const AlertWarningExample({super.key});

  @override
  State<AlertWarningExample> createState() => _AlertWarningExampleState();
}

class _AlertWarningExampleState extends State<AlertWarningExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
    if (_show) {
      return Alert.warning(
        title: '주의',
        description: '이 작업은 되돌릴 수 없습니다.',
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
