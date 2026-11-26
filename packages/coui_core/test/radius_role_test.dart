import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreRadiusRole — each role names one step of the ladder', () {
    test('part · control · panel · surface · modal = 4 · 8 · 12 · 16 · 20', () {
      expect(CoreRadiusRole.part, 4);
      expect(CoreRadiusRole.control, 8);
      expect(CoreRadiusRole.panel, 12);
      expect(CoreRadiusRole.surface, 16);
      expect(CoreRadiusRole.modal, 20);
    });

    test('a role is the primitive it aliases, not a copy of its number', () {
      expect(CoreRadiusRole.part, CoreRadius.radius4);
      expect(CoreRadiusRole.control, CoreRadius.radius8);
      expect(CoreRadiusRole.panel, CoreRadius.radius12);
      expect(CoreRadiusRole.surface, CoreRadius.radius16);
      expect(CoreRadiusRole.modal, CoreRadius.radius20);
    });

    test('every role sits on the ladder, so Web resolves it to a variable', () {
      // `radiusCss` emits `var(--coui-radius-N)` only for a value on
      // `CoreRadius.steps`; anything else is a literal that no preset
      // reaches. A role off the ladder would opt its components out of
      // every surface style.
      for (final role in _roles.entries) {
        expect(
          CoreRadius.steps,
          contains(role.value),
          reason: '${role.key} = ${role.value} is not a ladder step',
        );
      }
    });

    test('roles ascend: part < control < panel < surface < modal', () {
      final values = _roles.values.toList();
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i],
          greaterThan(values[i - 1]),
          reason:
              '${_roles.keys.elementAt(i)} must be rounder than '
              '${_roles.keys.elementAt(i - 1)}',
        );
      }
    });

    test('no role is one of the two sentinels', () {
      // full and square are statements about the shape, not a size of
      // element — they stay primitives.
      for (final role in _roles.entries) {
        expect(role.value, isNot(CoreRadius.radius0), reason: role.key);
        expect(role.value, isNot(CoreRadius.radius9999), reason: role.key);
      }
    });

    test('a role composes into CoreBorderRadius like the primitive does', () {
      // `const` is the point: a role is a compile-time constant, so it can
      // sit in a `static const` style default exactly where a primitive does.
      const fromRole = CoreBorderRadius.all(CoreRadiusRole.panel);
      const fromStep = CoreBorderRadius.all(CoreRadius.radius12);
      expect(fromRole, fromStep);
      expect(const CoreBorderRadius.all(CoreRadiusRole.surface).topLeft, 16);
    });
  });
}

/// Declaration order is part of the contract — the ascending test reads it.
const Map<String, double> _roles = {
  'part': CoreRadiusRole.part,
  'control': CoreRadiusRole.control,
  'panel': CoreRadiusRole.panel,
  'surface': CoreRadiusRole.surface,
  'modal': CoreRadiusRole.modal,
};
