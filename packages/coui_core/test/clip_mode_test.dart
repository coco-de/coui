import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreClipMode', () {
    test('has all four modes', () {
      expect(CoreClipMode.values, hasLength(4));
      expect(CoreClipMode.values, [
        CoreClipMode.none,
        CoreClipMode.hardEdge,
        CoreClipMode.antiAlias,
        CoreClipMode.antiAliasWithSaveLayer,
      ]);
    });
  });
}
