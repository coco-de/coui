/// Resting border value consumed on the actual text-area box.
const kTextAreaRestBorderVar = '--coui-text-area-rest-border-color';

/// Raw hover border value on the same box, independent of its rest value.
const kTextAreaHoverBorderVar = '--coui-text-area-hover-border-color';

/// Enabled box whose editing surface is inside this wrapper.
const kTextAreaRestWithinMarker = 'co-text-area-rest-within';

/// Enabled footer frame, following only its first-row editing surface.
const kTextAreaRestFrameMarker = 'co-text-area-rest-frame';

/// Disabled raw idle override; hover returns to the dedicated disabled token.
const kTextAreaRestDisabledMarker = 'co-text-area-rest-disabled';

/// Raw hover readers with the same focus exclusions as each enabled box.
const kTextAreaHoverWithinMarker = 'co-text-area-hover-within';

/// Raw hover reader following only the footer frame's editing surface.
const kTextAreaHoverFrameMarker = 'co-text-area-hover-frame';
