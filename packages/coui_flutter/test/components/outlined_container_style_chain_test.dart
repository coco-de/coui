import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('style chain preserves role, refraction, child and key', () {
    const refraction = CoreSurfaceRefraction(bezel: 0.1);
    const key = ValueKey('container');
    const child = SizedBox();
    final widget = const OutlinedContainer(
      key: key,
      role: CoreSurfaceRole.functional,
      refraction: refraction,
      child: child,
    ).radius4;
    expect(widget.role, CoreSurfaceRole.functional);
    expect(widget.refraction, refraction);
    expect(widget.key, key);
    expect(widget.child, same(child));
    expect(
      widget.containerStyle!.borderRadius,
      const CoreBorderRadius.all(CoreRadius.radius4),
    );
  });
}
