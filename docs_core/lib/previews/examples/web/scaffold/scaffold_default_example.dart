import 'package:coui_web/coui_web.dart';

class ScaffoldDefaultExample extends StatelessComponent {
  const ScaffoldDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // Fixed-height frame (matches the Flutter preview canvas height)
    // so the scaffold's `min-h-full` has a definite parent to fill —
    // the Flutter twin fills its canvas constraints the same way.
    return div(
      [
        Scaffold(
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
          // `flex-1` fills the scaffold's body column (Flutter
          // `Center` fills the available body the same way).
          child: div(
            [const Text('본문 영역')],
            classes: 'flex items-center justify-center flex-1',
          ),
        ),
      ],
      classes: 'w-full',
      styles: Styles(raw: const {'height': '${384 / 16}rem'}),
    );
  }
}
