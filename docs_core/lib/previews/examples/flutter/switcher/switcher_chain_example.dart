import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwitcherStyle] slot without constructing the widget
/// from scratch. The patch slows the view transition and swaps its
/// easing for the decelerate alias.
class SwitcherChainExample extends StatefulWidget {
  const SwitcherChainExample({super.key});

  @override
  State<SwitcherChainExample> createState() => _SwitcherChainExampleState();
}

class _SwitcherChainExampleState extends State<SwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['보기 A', '보기 B', '보기 C'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: CoreSpace.space256,
          height: CoreSize.size96,
          child:
              Switcher(
                index: _index,
                onIndexChanged: (next) => setState(() => _index = next),
                items: [
                  for (final label in _labels) Center(child: Text(label).titleMedium),
                ],
              ).withStyle(
                const CoreSwitcherStyle(
                  duration: Duration(milliseconds: CoreDuration.slow),
                  curve: CoreEasing.enter,
                ),
              ),
        ),
        const Gap.space16(),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var idx = 0; idx < _labels.length; idx++)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space4,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Button(
                  variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                  onPressed: () => setState(() => _index = idx),
                  child: Text(_labels[idx]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
