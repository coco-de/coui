/// SSR-safe stub for full-page navigation.
///
/// Server builds never invoke this — navigation only fires from a
/// client-side click handler — but the import must still resolve on the
/// server compile target, so this half of the split has no `package:web`
/// dependency.
library;

/// SSR stub — no-op.
void navigateToPath(String path) {}
