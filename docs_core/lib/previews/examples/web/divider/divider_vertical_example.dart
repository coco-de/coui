import 'package:coui_web/coui_web.dart';

/// Vertical [Divider] showcased inside a fixed-height wrapper.
class DividerVerticalExample extends StatelessComponent {
  /// Creates a [DividerVerticalExample].
  const DividerVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [const Divider(orientation: .vertical)],
      styles: Styles(raw: {'height': '${CoreSpace.space32}px'}),
    );
  }
}
