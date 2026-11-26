import 'package:coui_web/coui_web.dart';

/// Info-variant Alert example for docs_site Web preview.
///
/// Same toggle/dismiss interaction pattern as `AlertDefaultExample`,
/// just with the `.info` constructor for the brand-blue tone. Keeping
/// the pattern uniform across all five variants lets readers focus on
/// the visual difference (icon + color) without redoing the
/// interaction grammar.
class AlertInfoExample extends StatefulComponent {
  const AlertInfoExample({super.key});

  @override
  State<AlertInfoExample> createState() => _AlertInfoExampleState();
}

class _AlertInfoExampleState extends State<AlertInfoExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
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
