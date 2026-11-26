/// Plays a haptic cue the browser's way — `navigator.vibrate`.
///
/// A component that wants a cue has its own opt-in flag and calls
/// `playHapticCue` with the one cue it asked for; this file is where a
/// `CoreHapticCue` meets the platform. The browser can only be told how long
/// to pulse, so the cue carries that length (`CoreHapticCue.pulseMilliseconds`)
/// and nothing here decides it.
///
/// What is and is not on the other side of the call, because a cue that does
/// not play looks exactly like one that was never asked for:
///
/// * Safari does not implement `navigator.vibrate`, so nothing plays there.
///   The call is skipped when the function is absent, never an error.
/// * Desktop browsers implement it and have no motor to run: the call
///   succeeds and nothing is felt.
/// * A browser may refuse the pulse until the page has had a tap or a key
///   press (a user activation) and says so only by returning `false`. A cue
///   asked for before the first one can be dropped, and so is not guaranteed
///   to be felt.
/// * The pulse is a length of motor time, not a feeling: how short a pulse a
///   device renders at all differs from one phone to the next.
///
/// Server-rendered output has no navigator, so the stub plays nothing.
library;

export 'haptics_stub.dart' if (dart.library.js_interop) 'haptics_web.dart';
