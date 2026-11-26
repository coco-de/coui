import 'package:coui_flutter/coui_flutter.dart';

/// Default Alert example for docs_site Flutter preview.
///
/// Demonstrates the canonical interaction pattern — a button toggles
/// whether the alert is rendered, and the alert's own dismiss button
/// hides it again. Mirrors how `Alert` is used in real apps:
/// inline notification surfaces conditionally based on state, and
/// users can dismiss them when done reading.
class AlertDefaultExample extends StatefulWidget {
  const AlertDefaultExample({super.key});

  @override
  State<AlertDefaultExample> createState() => _AlertDefaultExampleState();
}

class _AlertDefaultExampleState extends State<AlertDefaultExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert(
        title: '확인이 필요해요',
        description: '결제 수단을 다시 확인해 주세요.',
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
