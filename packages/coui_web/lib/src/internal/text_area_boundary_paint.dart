/// The actual footer frame that publishes its active-boundary layer.
///
/// Internal paint protocol shared by the resolver and ThemeConfig. This
/// marker consumes the existing instance variable on the same box.
const kTextAreaFrameBoundaryMarker = 'co-text-area-frame-active-boundary';

/// Only the main editing surface, in the frame's first text row, owns focus.
/// Footer buttons and additional footer textareas do not activate the frame.
const kTextAreaFrameFocusSelector =
    ':has(>:first-child>textarea:focus-visible)';
