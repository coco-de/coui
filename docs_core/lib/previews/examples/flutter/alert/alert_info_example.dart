import 'package:coui_flutter/coui_flutter.dart';

/// Info-variant Alert example for docs_site Flutter preview.
///
/// Mirrors the Web side — same toggle/dismiss interaction so the two
/// preview panes line up visually side-by-side on the docs page.
class AlertInfoExample extends StatefulWidget {
  const AlertInfoExample({super.key});

  @override
  State<AlertInfoExample> createState() => _AlertInfoExampleState();
}

class _AlertInfoExampleState extends State<AlertInfoExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.info(
        title: '정보',
        description: '새로운 업데이트가 있습니다.',
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
