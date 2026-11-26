import 'package:coui_flutter/coui_flutter.dart';

class DiffTextExample extends StatelessWidget {
  const DiffTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Diff(
      ariaLabel: '채운 배경과 표면 배경 글자 비교',
      before: ColoredBox(
        color: colors.primary.toValue(),
        child: Center(child: const Text('CoUI').displayLarge.onPrimary),
      ),
      after: ColoredBox(
        color: colors.surfaceContainer.toValue(),
        child: Center(child: const Text('CoUI').displayLarge.onSurface),
      ),
    );
  }
}
