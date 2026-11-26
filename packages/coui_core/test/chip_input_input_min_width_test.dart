// The floor of the chip input's entry field is one constant both platforms
// read: the width the field needs before it may share a row with the chips.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test('the entry field floor is the 80 size step', () {
    expect(CoreChipInputContract.defaultInputMinWidth, CoreSize.size80);
    expect(CoreChipInputContract.defaultInputMinWidth, 80);
  });
}
