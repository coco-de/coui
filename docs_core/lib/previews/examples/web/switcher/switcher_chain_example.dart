import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwitcherStyle] slot without constructing the widget
/// from scratch. The patch slows the view transition and swaps its
/// easing for the decelerate alias.
class SwitcherChainExample extends StatefulComponent {
  const SwitcherChainExample({super.key});

  @override
  State<SwitcherChainExample> createState() => _SwitcherChainExampleState();
}

class _SwitcherChainExampleState extends State<SwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['보기 A', '보기 B', '보기 C'];

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            Switcher(
              index: _index,
              onIndexChanged: (next) => setState(() => _index = next),
              items: [
                for (final label in _labels)
                  div(
                    [Text(label).titleMedium],
                    classes: 'flex items-center justify-center h-full',
                  ),
              ],
            ).withStyle(
              const CoreSwitcherStyle(
                duration: Duration(milliseconds: CoreDuration.slow),
                curve: CoreEasing.enter,
              ),
            ),
          ],
          styles: const Styles(
            raw: {'width': '16rem', 'height': '6rem'},
          ),
        ),
        Gap.space16(),
        div(
          [
            for (var idx = 0; idx < _labels.length; idx++)
              Button(
                variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                onPressed: () => setState(() => _index = idx),
                child: Text(_labels[idx]),
              ),
          ],
          classes: 'flex flex-row flex-wrap justify-center gap-${CoreSpace.scale.space8}',
        ),
      ],
      classes: 'inline-flex flex-col items-center',
    );
  }
}
