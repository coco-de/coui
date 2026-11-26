import 'package:coui_web/coui_web.dart';

/// Warning-variant Banner example for docs_site Web preview.
class BannerWarningExample extends StatefulComponent {
  const BannerWarningExample({super.key});

  @override
  State<BannerWarningExample> createState() => _BannerWarningExampleState();
}

class _BannerWarningExampleState extends State<BannerWarningExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
    if (_show) {
      return Banner.warning(
        message: const Text('세션이 5분 후에 만료됩니다.'),
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
