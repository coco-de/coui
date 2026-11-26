/// How much of the pipeline a matrix entry participates in.
///
/// T1 gets both signals baselined (`pixel` + `property`, per
/// `ParitySignal`) — PNGs are only ever committed for T1 to keep the repo
/// small (architecture doc, Data Architecture design note). T2 still gets a
/// property baseline (cheap, KB-sized) but no pixel baseline.
///
/// There is no third value. An entry the tier policy does not recognize is
/// T2, not an error and not silently dropped — #3604's completion
/// definition requires unclassified components to *fall* to T2, not
/// disappear.
enum ParityTier {
  t1,
  t2;

  static ParityTier? tryParse(String raw) => switch (raw) {
    't1' => .t1,
    't2' => .t2,
    _ => null,
  };
}
