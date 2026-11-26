/// Marks a `CoreXxxStyle` chrome field whose value is **injected by the host
/// at render time** and therefore has no kit default on purpose.
///
/// The Figma reader treats a declared field with no `default*` as an absence
/// the design decided — "this component draws nothing for that field" — and
/// the canvas fidelity check then asserts that nothing (square corners, no
/// shadow, …). That is the right reading for most valueless fields and the
/// wrong one here: a focus ring's corner radius is not absent, it is whatever
/// the ring is drawn around, so no constant can hold it and the canvas demo
/// can show any host's value. Without this marker the two readings are
/// indistinguishable from the source, and the reader picked the first one —
/// the fidelity report demanded radius 0 on a ring the designer had
/// (correctly) rounded to the demo host's 8.
///
/// Marked fields are exported under `hostDerived` instead of `absent`; the
/// fidelity check lists them as "not compared" rather than asserting a shape
/// the code never stated. Same shape as `BehaviourOnly`: a Core-domain
/// statement about the field, not Figma vocabulary.
class HostDerived {
  /// Use the [hostDerived] constant; the class exists so the annotation has
  /// a type the reader can match by name.
  const HostDerived();
}

/// See [HostDerived].
const hostDerived = HostDerived();
