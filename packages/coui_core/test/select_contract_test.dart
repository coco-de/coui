import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A sample `int` value used to verify the generic type parameter of
/// [CoreSelectItem] is preserved.
const int _kIntValue = 42;

void main() {
  test('existing Select contract implementations need no width member', () {
    const CoreSelectContract<Object, String> select = _LegacySelect();
    expect(select.value, 'USD');
    expect(select, isNot(isA<CoreSelectPopoverWidthContract>()));
  });
  group('CoreSelectItem', () {
    test('creates with required fields', () {
      const item = CoreSelectItem(value: 'a', label: 'Apple');
      expect(item.value, 'a');
      expect(item.label, 'Apple');
      expect(item.enabled, isTrue);
      expect(item.child, isNull);
    });

    test('child defaults to null when omitted', () {
      const item = CoreSelectItem(value: 'b', label: 'Banana');
      expect(item.child, isNull);
    });

    test('child accepts a platform-agnostic Object instance', () {
      // Type-erased so the contract layer compiles without depending on
      // Flutter Widget or Web Component types.
      const sentinel = _SentinelChild();
      const item = CoreSelectItem(
        value: 'c',
        label: 'Cherry',
        child: sentinel,
      );
      expect(item.child, isA<_SentinelChild>());
      expect(identical(item.child, sentinel), isTrue);
    });

    test('enabled flag defaults to true and can be overridden', () {
      const enabled = CoreSelectItem(value: 'a', label: 'A');
      const disabled = CoreSelectItem(
        value: 'b',
        label: 'B',
        enabled: false,
      );
      expect(enabled.enabled, isTrue);
      expect(disabled.enabled, isFalse);
    });

    test('preserves generic type parameter on value', () {
      const intItem = CoreSelectItem(value: _kIntValue, label: '42');
      expect(intItem.value, _kIntValue);
      expect(intItem.value, isA<int>());
    });
  });
}

/// An implementation of the contract before the optional width capability.
class _LegacySelect implements CoreSelectContract<Object, String> {
  const _LegacySelect();

  @override
  List<CoreSelectItem<String>> get items => const [];
  @override
  String? get value => 'USD';
  @override
  String? get placeholder => null;
  @override
  CoreSelectVariant get variant => CoreSelectVariant.defaultVariant;
  @override
  CoreSelectSize get size => CoreSelectSize.md;
  @override
  String? get label => null;
  @override
  int? get labelMaxLines => null;
  @override
  CoreTextOverflow? get labelOverflow => null;
  @override
  String? get description => null;
  @override
  String? get errorText => null;
  @override
  bool get required => false;
  @override
  Object? get suffix => null;
  @override
  bool get enabled => true;
  @override
  void Function(String)? get onChanged => null;
  @override
  CorePopoverPlacement get popoverPlacement =>
      CorePopoverStyle.defaultDropdownPlacement;
  @override
  Set<CorePopoverCollision> get popoverCollision =>
      CorePopoverStyle.defaultCollision;
  @override
  bool get closeOnScroll => true;
  @override
  CoreSelectStyle? get selectStyle => null;
}

class _SentinelChild {
  const _SentinelChild();
}
