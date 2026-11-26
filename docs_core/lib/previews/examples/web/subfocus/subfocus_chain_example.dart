import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSubfocusStyle] slot without constructing the
/// widget from scratch.
class SubfocusChainExample extends StatelessComponent {
  const SubfocusChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return SubfocusScope(
      child: div(
        classes: 'flex flex-col items-center gap-${CoreSpace.scale.space8}',
        [
          Subfocus(
            focusId: 'a',
            child: Card(child: Text('항목 A (↑↓ 키로 이동)').bodyMedium),
          ).withStyle(
            const CoreSubfocusStyle(
              focusRingRadius: CoreBorderRadius.all(CoreRadius.radius16),
            ),
          ),
          Subfocus(
            focusId: 'b',
            child: Card(child: Text('항목 B').bodyMedium),
          ),
          Subfocus(
            focusId: 'c',
            child: Card(child: Text('항목 C').bodyMedium),
          ),
        ],
      ),
    );
  }
}
