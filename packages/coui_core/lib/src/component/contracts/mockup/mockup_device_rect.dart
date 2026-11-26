/// The rectangle every `MockupDevice` geometry value is stated in.
library;

/// An axis-aligned rectangle in unscaled logical px.
///
/// A record rather than a class: nothing merges or overrides it, it is
/// only carried from the computation in `CoreMockupDeviceLayout` to a platform
/// paint call.
typedef CoreMockupDeviceRect = ({
  double left,
  double top,
  double width,
  double height,
});
