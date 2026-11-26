// A popup that does not know what it holds pads 16; the components that hold
// a list state 6. Both reach the resolved padding.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ResolvedPopup> resolve(
    WidgetTester tester, {
    CorePopupStyle? style,
  }) async {
    late ResolvedPopup resolved;
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: Builder(
            builder: (context) {
              resolved = resolvePopup(context, popupStyle: style);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    return resolved;
  }

  testWidgets('the bare popup pads the content preset', (tester) async {
    final resolved = await resolve(tester);
    expect(resolved.padding, const EdgeInsets.all(CoreSpace.space16));
  });

  testWidgets('a list panel states the list preset', (tester) async {
    final resolved = await resolve(
      tester,
      style: CoreMenuStyle.defaultPopupStyle,
    );
    expect(resolved.padding, const EdgeInsets.all(CoreSpace.space6));
  });
}
