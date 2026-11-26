import 'package:coui_web/coui_web.dart';

// A phone-width column: too narrow for the message to keep its minimum
// width beside the action and dismiss.
const String _kNarrowWidth = '320px';

/// Narrow-width Banner example for docs_site Web preview.
///
/// At 320 the message can't keep its minimum width beside the action and
/// dismiss, so the trailing group drops to its own line under the text.
class BannerNarrowExample extends StatefulComponent {
  const BannerNarrowExample({super.key});

  @override
  State<BannerNarrowExample> createState() => _BannerNarrowExampleState();
}

class _BannerNarrowExampleState extends State<BannerNarrowExample> {
  bool _show = true;

  @override
  Component build(BuildContext context) {
    if (_show) {
      return div(
        styles: const Styles(raw: {'width': _kNarrowWidth}),
        [
          Banner.warning(
            message: const Text('체험 기간이 3일 남았어요.'),
            description: const Text('업그레이드하면 프로젝트를 계속 쓸 수 있어요.'),
            action: Button(
              variant: CoreButtonVariant.outline,
              size: CoreComponentSize.sm,
              onPressed: () {},
              child: const Text('업그레이드'),
            ),
            onDismiss: () => setState(() => _show = false),
          ),
        ],
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}
