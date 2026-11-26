import 'package:coui_web/coui_web.dart';

/// Destructive-variant Alert example for docs_site Web preview.
class AlertDestructiveExample extends StatefulComponent {
  const AlertDestructiveExample({super.key});

  @override
  State<AlertDestructiveExample> createState() => _AlertDestructiveExampleState();
}

class _AlertDestructiveExampleState extends State<AlertDestructiveExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
    if (_show) {
      return Alert.destructive(
        title: '오류 발생',
        description: '요청을 처리하는 중 문제가 발생했습니다.',
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
