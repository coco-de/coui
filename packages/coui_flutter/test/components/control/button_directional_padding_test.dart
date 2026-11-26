import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// A `Button` padding stated with start / end resolves against the reading
/// direction, so a composing component (NavigationMenu's trigger, which sits
/// its chevron at the end) can state an inset that differs per side without
/// writing left and right — and the button still hands its widget a physical
/// `EdgeInsets`.
class _Capture extends StatelessWidget {
  const _Capture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);

    return const SizedBox.shrink();
  }
}

void main() {
  const directional = CoreButtonStyle(
    padding: CoreEdgeInsets.directional(
      start: CoreSpace.space12,
      end: CoreSpace.space8,
      top: CoreSpace.space4,
      bottom: CoreSpace.space2,
    ),
  );

  Future<ResolvedButton> resolveUnder(
    WidgetTester tester,
    TextDirection direction, {
    CoreButtonStyle? style = directional,
  }) async {
    late BuildContext context;
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpTestApp(
      tester,
      _Capture((c) => context = c),
      textDirection: direction,
    );

    return resolveButton(
      context,
      variant: .menubar,
      size: .md,
      shape: .rectangle,
      buttonStyle: style,
    );
  }

  testWidgets('start is the left in a left-to-right locale', (tester) async {
    final r = await resolveUnder(tester, .ltr);

    expect(r.padding, const EdgeInsets.fromLTRB(12, 4, 8, 2));
  });

  testWidgets('start is the right in a right-to-left locale', (tester) async {
    final r = await resolveUnder(tester, .rtl);

    expect(r.padding, const EdgeInsets.fromLTRB(8, 4, 12, 2));
  });

  testWidgets('a symmetric inset is direction-invariant', (tester) async {
    const symmetric = CoreButtonStyle(
      padding: CoreEdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    final ltr = await resolveUnder(tester, .ltr, style: symmetric);
    final rtl = await resolveUnder(tester, .rtl, style: symmetric);

    expect(
      ltr.padding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    expect(rtl.padding, ltr.padding);
  });
}
