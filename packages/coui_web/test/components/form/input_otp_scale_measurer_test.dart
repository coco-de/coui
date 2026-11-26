import 'package:coui_web/src/components/form/input_otp/input_otp_scale_measurer.dart';
import 'package:test/test.dart';

void main() {
  test('SSR scale measurer retains the row id and its lifecycle is safe', () {
    const measurer = InputOtpScaleMeasurer(rowId: 'otp-row');
    expect(measurer.rowId, 'otp-row');
    measurer
      ..attach()
      ..attach()
      ..dispose()
      ..dispose();
  });
}
