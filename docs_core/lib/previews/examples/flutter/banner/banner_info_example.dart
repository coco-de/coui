import 'package:coui_flutter/coui_flutter.dart';

/// Info-variant Banner example for docs_site Flutter preview.
class BannerInfoExample extends StatefulWidget {
  const BannerInfoExample({super.key});

  @override
  State<BannerInfoExample> createState() => _BannerInfoExampleState();
}

class _BannerInfoExampleState extends State<BannerInfoExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.info(
        message: const Text('새로운 업데이트가 준비되었습니다.'),
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
