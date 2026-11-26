import 'package:coui_flutter/coui_flutter.dart';

/// Destructive-variant Alert example for docs_site Flutter preview.
class AlertDestructiveExample extends StatefulWidget {
  const AlertDestructiveExample({super.key});

  @override
  State<AlertDestructiveExample> createState() => _AlertDestructiveExampleState();
}

class _AlertDestructiveExampleState extends State<AlertDestructiveExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
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
