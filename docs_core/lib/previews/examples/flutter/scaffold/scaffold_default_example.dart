import 'package:coui_flutter/coui_flutter.dart';

class ScaffoldDefaultExample extends StatelessWidget {
  const ScaffoldDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed-height frame, like the Web twin's: a `Scaffold` lays its body
    // out with `Expanded`, so it needs a height to fill. 384 is the 400px
    // docs stage less its 8px inset on each side — anything taller overflows.
    return SizedBox(
      height: 384,
      child: Scaffold(
        headers: [
          AppBar(
            title: const Text('대시보드').titleMedium,
            trailing: const [Icon(LucideIcons.settings)],
          ),
        ],
        footers: [
          AppBar(
            title: const Text('준비됨').bodySmall.onSurfaceVariant,
          ),
        ],
        child: const Center(child: Text('본문 영역')),
      ),
    );
  }
}
