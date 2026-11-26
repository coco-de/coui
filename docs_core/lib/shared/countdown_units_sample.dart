import 'package:coui_core/coui_core.dart';

/// Caller-owned chrome for the four-unit Countdown documentation example.
/// Countdown itself continues to render just one integer.
const countdownUnitContainerStyle = CoreOutlinedContainerStyle(
  backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  borderStyle: CoreOutlinedContainerBorderStyle.none,
  padding: CoreEdgeInsets.all(CoreSpace.space8),
);

const countdownUnitLabels = ['일', '시간', '분', '초'];
