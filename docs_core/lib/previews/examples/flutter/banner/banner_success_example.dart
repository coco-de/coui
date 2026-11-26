import 'package:coui_flutter/coui_flutter.dart';

/// Success-variant Banner example for docs_site Flutter preview.
class BannerSuccessExample extends StatefulWidget {
  const BannerSuccessExample({super.key});

  @override
  State<BannerSuccessExample> createState() => _BannerSuccessExampleState();
}

class _BannerSuccessExampleState extends State<BannerSuccessExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.success(
        message: const Text('변경 사항이 성공적으로 저장되었습니다.'),
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
