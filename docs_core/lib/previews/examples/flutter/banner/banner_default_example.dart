import 'package:coui_flutter/coui_flutter.dart';

/// Default Banner example for docs_site Flutter preview.
///
/// Mirrors the Web side — same toggle/dismiss interaction so the two
/// preview panes line up visually side-by-side on the docs page.
class BannerDefaultExample extends StatefulWidget {
  const BannerDefaultExample({super.key});

  @override
  State<BannerDefaultExample> createState() => _BannerDefaultExampleState();
}

class _BannerDefaultExampleState extends State<BannerDefaultExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.info(
        message: const Text('일반 안내예요.'),
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
