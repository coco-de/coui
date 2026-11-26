// A surface that clips its own content adds, to whatever padding it states, the
// padding it owes a folded border:
// `calc(P + var(--coui-surface-clip-pad,<zero>))`. Unset the hook is zero, so a
// test about the *layout* a component states looks through it; the hook itself
// is pinned in `surface_clip_publication_test.dart`.

final RegExp _pad = RegExp(
  r'calc\((.+?) \+ var\(--coui-surface-clip-pad,var\(--coui-space-0\)\)\)',
);

/// [stated] with the clip padding looked through: `calc(P + var(...))` is `P`.
String unfoldSurfaceEdge(String stated) =>
    stated.replaceAllMapped(_pad, (m) => m.group(1)!);
