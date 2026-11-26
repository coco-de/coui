import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('widget style overrides project border preservation', (
    tester,
  ) async {
    ResolvedOutlinedContainer? inherited;
    ResolvedOutlinedContainer? overridden;
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            inherited = resolveOutlinedContainer(context);
            overridden = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                preserveTransparentBorder: false,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
        componentTheme: const CoreComponentTheme(
          outlinedContainer: CoreOutlinedContainerTheme(
            style: CoreOutlinedContainerStyle(
              borderColor: CoreColor.transparent,
              borderWidth: 2,
              preserveTransparentBorder: true,
            ),
          ),
        ),
      ),
    );
    expect(inherited!.borderWidth, 2);
    expect(overridden!.borderWidth, 0);
  });

  for (final preserve in [false, true]) {
    testWidgets('opaque none has no inset with preserve=$preserve', (
      tester,
    ) async {
      const childKey = Key('none-child');
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                borderStyle: .none,
                borderColor: const CoreColor(0xffff0000),
                borderWidth: 2,
                preserveTransparentBorder: preserve,
              ),
              child: const SizedBox.expand(key: childKey),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(childKey)), const Size(40, 40));
    });
  }

  for (final style in CoreOutlinedContainerBorderStyle.values) {
    for (final preserve in [false, true]) {
      testWidgets('transparent $style layout, preserve=$preserve', (
        tester,
      ) async {
        const childKey = Key('matrix-child');
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 40,
              height: 40,
              child: OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  borderStyle: style,
                  borderColor: CoreColor.transparent,
                  borderWidth: 2,
                  preserveTransparentBorder: preserve,
                ),
                child: const SizedBox.expand(key: childKey),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final inset =
            preserve && style != CoreOutlinedContainerBorderStyle.none;
        expect(
          tester.getSize(find.byKey(childKey)),
          Size(inset ? 36 : 40, inset ? 36 : 40),
        );
      });
    }
  }

  for (final style in [
    CoreOutlinedContainerBorderStyle.dashed,
    CoreOutlinedContainerBorderStyle.dotted,
  ]) {
    testWidgets('$style keeps its inset across transparent and opaque colors', (
      tester,
    ) async {
      const childKey = Key('transition-child');
      for (final color in [
        CoreColor.transparent,
        const CoreColor(0xffff0000),
      ]) {
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 40,
              height: 40,
              child: OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  borderStyle: style,
                  borderColor: color,
                  borderWidth: 2,
                  preserveTransparentBorder: true,
                ),
                child: const SizedBox.expand(key: childKey),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byKey(childKey)), const Size(36, 36));
      }
    });
  }

  testWidgets('transparent width changes the child inset', (tester) async {
    const childKey = Key('border-child');
    Future<Size> childSize({required bool preserve}) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        buildTestApp(
          Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  borderColor: CoreColor.transparent,
                  borderWidth: 1,
                  preserveTransparentBorder: preserve,
                ),
                child: const SizedBox.expand(key: childKey),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(childKey));
    }

    expect(await childSize(preserve: false), const Size(40, 40));
    expect(await childSize(preserve: true), const Size(38, 38));
  });

  testWidgets('transparent border reserves width only when requested', (
    tester,
  ) async {
    ResolvedOutlinedContainer? normal;
    ResolvedOutlinedContainer? preserved;
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            normal = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                borderColor: CoreColor.transparent,
                borderWidth: 1,
              ),
            );
            preserved = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                borderColor: CoreColor.transparent,
                borderWidth: 1,
                preserveTransparentBorder: true,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(normal!.borderWidth, 0);
    expect(preserved!.borderWidth, 1);
    expect(preserved!.borderColor.a, 0);
  });
}
