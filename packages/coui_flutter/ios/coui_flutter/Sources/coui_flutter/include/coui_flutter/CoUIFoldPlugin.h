#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// Measures the fold of a folding iPhone for coui_flutter.
///
/// Flutter's iOS embedder hands Dart the safe area and nothing about a fold,
/// so `MediaQuery.displayFeatures` is empty on a folding iPhone. This plugin
/// is the missing measurement: where the system reserves a division of the
/// Flutter view, and how far the hinge is open. It answers `read` on the
/// `coui_flutter/fold` channel and calls `changed` when the reading differs.
///
/// It measures and decides nothing. Whether a reading is a fold that splits
/// the viewport is the Dart half's (`FoldReading`), and what a layout reads
/// from that is the rule every platform shares (`CoreFoldLayout`).
@interface CoUIFoldPlugin : NSObject <FlutterPlugin>
@end

NS_ASSUME_NONNULL_END
