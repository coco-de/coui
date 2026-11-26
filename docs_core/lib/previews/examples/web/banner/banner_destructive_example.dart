import 'package:coui_web/coui_web.dart';

/// Destructive-variant Banner example for docs_site Web preview.
class BannerDestructiveExample extends StatefulComponent {
  const BannerDestructiveExample({super.key});

  @override
  State<BannerDestructiveExample> createState() => _BannerDestructiveExampleState();
}

class _BannerDestructiveExampleState extends State<BannerDestructiveExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
    if (_show) {
      return Banner.destructive(
        message: const Text('요청을 처리하는 중 문제가 발생했습니다.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}
