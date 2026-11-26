import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _id = CoreDragId('row-1');

/// A registry that records what it was told to report.
({CoreDragRegistry registry, List<String> warnings}) _registry() {
  final warnings = <String>[];
  final registry = CoreDragRegistry(
    diagnostics: CoreDragDiagnosticsConfig(onWarning: warnings.add),
  );

  return (registry: registry, warnings: warnings);
}

void main() {
  group('CoreDragRegistry duplicate diagnostics', () {
    test('silent by default', () {
      final registry = CoreDragRegistry();
      final first = Object();
      final second = Object();

      registry.registerItem(_id, owner: first);
      registry.registerItem(_id, owner: second);

      // Nothing to assert but the absence of a throw: the default config
      // has no listener, which is the whole contract.
      expect(registry.hasItem(_id), isTrue);
    });

    test('a second owner on a live id is reported', () {
      final (:registry, :warnings) = _registry();
      final first = Object();
      final second = Object();

      registry.registerItem(_id, owner: first);
      expect(warnings, isEmpty);

      registry.registerItem(_id, owner: second);

      expect(warnings, hasLength(1));
      expect(warnings.single, contains('row-1'));
      expect(warnings.single, contains('item'));
    });

    test('the same owner re-registering is a rebuild, not a duplicate', () {
      final (:registry, :warnings) = _registry();
      final owner = Object();

      registry.registerItem(_id, owner: owner);
      registry.registerItem(_id, owner: owner);
      registry.registerItem(_id, owner: owner);

      expect(warnings, isEmpty);
    });

    test('a fresh id has no predecessor to displace', () {
      final (:registry, :warnings) = _registry();

      registry.registerItem(_id, owner: Object());

      expect(warnings, isEmpty);
    });

    test('unregistering clears the seat, so the next owner is not a '
        'duplicate', () {
      final (:registry, :warnings) = _registry();

      registry.registerItem(_id, owner: Object());
      registry.unregisterItem(_id);
      registry.registerItem(_id, owner: Object());

      expect(warnings, isEmpty);
    });

    test('owners that opt out of identifying themselves are not reported', () {
      final (:registry, :warnings) = _registry();

      registry.registerItem(_id);
      registry.registerItem(_id);

      expect(warnings, isEmpty);
    });

    test('drop zones are reported the same way', () {
      final (:registry, :warnings) = _registry();

      registry.registerDropZone(_id, owner: Object());
      registry.registerDropZone(_id, owner: Object());

      expect(warnings, hasLength(1));
      expect(warnings.single, contains('zone'));
    });

    test('clearing drops the seats too', () {
      final (:registry, :warnings) = _registry();

      registry.registerItem(_id, owner: Object());
      registry.clear();
      registry.registerItem(_id, owner: Object());

      expect(warnings, isEmpty);
    });
  });
}
