import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTreeController', () {
    test('startRename reaches every registered tree with the node id', () {
      final controller = CoreTreeController();
      final first = <String>[];
      final second = <String>[];
      controller
        ..addRenameListener(first.add)
        ..addRenameListener(second.add)
        ..startRename('lib/main.dart');

      expect(first, ['lib/main.dart']);
      expect(second, ['lib/main.dart']);
    });

    test('a removed listener hears nothing more', () {
      final controller = CoreTreeController();
      final heard = <String>[];
      void listener(String id) => heard.add(id);
      controller
        ..addRenameListener(listener)
        ..startRename('a')
        ..removeRenameListener(listener)
        ..startRename('b');

      expect(heard, ['a']);
    });

    test('a listener may remove itself while a request is delivered', () {
      final controller = CoreTreeController();
      final heard = <String>[];
      late void Function(String) once;
      once = (id) {
        heard.add(id);
        controller.removeRenameListener(once);
      };
      controller
        ..addRenameListener(once)
        ..addRenameListener(heard.add)
        ..startRename('a')
        ..startRename('b');

      expect(heard, ['a', 'a', 'b']);
    });

    test('dispose releases every listener', () {
      final controller = CoreTreeController();
      final heard = <String>[];
      controller
        ..addRenameListener(heard.add)
        ..dispose()
        ..startRename('a');

      expect(heard, isEmpty);
    });
  });
}
