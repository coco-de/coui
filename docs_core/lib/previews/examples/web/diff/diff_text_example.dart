import 'package:coui_web/coui_web.dart';

class DiffTextExample extends StatelessComponent {
  const DiffTextExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Diff(
      ariaLabel: '채운 배경과 표면 배경 글자 비교',
      before: Component.element(
        tag: 'div',
        classes: 'w-full h-full grid place-content-center bg-${cs.primary}',
        children: [Text('CoUI').displayLarge.onPrimary],
      ),
      after: Component.element(
        tag: 'div',
        classes:
            'w-full h-full grid place-content-center '
            'bg-${cs.surfaceContainer}',
        children: [Text('CoUI').displayLarge.onSurface],
      ),
    );
  }
}
