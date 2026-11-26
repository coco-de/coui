/// Conditional barrel selecting the SSR stub or the web implementation of
/// the dock's flight measurement.
///
/// Keeps every `package:web` import out of `dock.dart` so it stays
/// SSR-safe. The server never measures: a flight is a transition between
/// two states and the server only ever renders the second one.
library;

export 'dock_flight_dom_stub.dart'
    if (dart.library.js_interop) 'dock_flight_dom_web.dart';
