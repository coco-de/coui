import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreJoinStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreJoinStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
///
/// `borderRadius` is the whole of [CoreJoinStyle], so this pairing also
/// shows the precedence rule: patch fields win on conflict, and the
/// trailing getter is applied last — `.radius16` overrides the
/// `radius4` supplied to `withStyle`.
class JoinChainExample extends StatelessComponent {
  const JoinChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
          children: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('1'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('2'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('3'),
            ),
          ],
        )
        .withStyle(
          const CoreJoinStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        )
        .radius16;
  }
}
