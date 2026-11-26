import 'package:coui_web/coui_web.dart';

/// Default Banner example for docs_site Web preview.
///
/// Demonstrates the canonical interaction pattern — a button toggles
/// whether the banner is rendered, and the banner's own dismiss
/// button hides it again. Mirrors how `Banner` is used in real
/// apps: page-level notifications appear conditionally based on
/// state (session warning, system alert, feature announcement) and
/// users can dismiss them when done reading.
class BannerDefaultExample extends StatefulComponent {
  const BannerDefaultExample({super.key});

  @override
  State<BannerDefaultExample> createState() => _BannerDefaultExampleState();
}

class _BannerDefaultExampleState extends State<BannerDefaultExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
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
