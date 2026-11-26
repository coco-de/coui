import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

// A consumer implementing the original contract needs no new member.
class _LegacyOtp implements CoreInputOtpContract<String> {
  @override
  int get length => 6;
  @override
  bool get obscured => false;
  @override
  bool get enabled => true;
  @override
  bool get autofocus => false;
  @override
  int get separatorInterval => 3;
  @override
  String? get initialValue => null;
  @override
  void Function(String)? get onChanged => null;
  @override
  void Function(String)? get onCompleted => null;
  @override
  String? get errorText => null;
  @override
  CoreInputOtpSize get size => CoreInputOtpSize.defaultSize;
  @override
  CoreInputOtpStyle? get inputOtpStyle => null;
}

void main() {
  test('legacy implementations need not adopt cell editing', () {
    final legacy = _LegacyOtp();
    expect(legacy.length, 6);
    expect(legacy, isNot(isA<CoreInputOtpCellEditingContract>()));
  });
}
