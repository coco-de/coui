# Remove Native measurement-only style publication (#6624)

PR #6623 made Native Menubar publish its resolved text style through a private
production wrapper so the parity collector could read it. The wrapper had no
production rendering consumer. Passing tests and unchanged pixels did not
justify coupling the widget to measurement. This correction removes that
publisher, its collector/finder hooks and its two marker-specific test files.
No replacement marker, fabricated value, null injection or component-name
exception is introduced. The original collector behavior is restored.

The earlier [#6619 verification](../native-root-text-owner-6619/README.md) is
preserved as history; its architectural conclusion is superseded here. Issue
#6619 remains unresolved: actual resting Menubar text paints at weight400,
while the restored collector reports500. This PR corrects the architecture,
not that measurement error or the unrelated padding discrepancy.

The Native audit read 474 production Dart files, 65 changed files from the
original1e5 revision to6d905, and the two additional Native files throughd732.
Its eight ledger entries distinguish this confirmed measurement publisher from
existing test seams, real rendering scopes and separate render-only concerns.
They are not eight confirmed bugs or proof that all conventions are satisfied.

No public API, Core/default token, inherited text style, paint policy, Web code,
normalizer, comparator, criterion, baseline or allowlist changes. Legitimate
Menubar doc/collection/default-alignment lint cleanups are retained.

| Check | Actual result |
| --- | --- |
| Existing root probe10 + Menubar37 + external paint diagnostic2 | 49 PASS / 0 FAIL |
| Functional run source | d732 plus intermediate parent restoration, before equivalent lint cleanup |
| Final format | Exit0; no drift |
| Final touched-file analysis | Actual exit1; existing Material INFO1, new INFO0 |
| Fresh Native default L/D at6af4b3dd | 2 JSON + 2 PNG; matrix2 PASS; no omitted root |
| Against preceding publisher revision | Both PNGs byte-exact; JSON changes only root.fontWeight400 → 500 |
| Real Native resident hot reload | app.restart fullRestart:false code0; 414/3756 libraries; 1056ms |
| Reload observations | Marker instances1 → 0; paint400, size and App/Menubar/Button State identities preserved |
| Cleanup | Disposal5 checks true; app.stop true; owned VM/HTTP ports closed; jobboxes reclaimed |
| Native-only actual Git baseline | Exit0; 2 PASS with unchanged diff-ratio criterion0.001 |
| Per-image Git baseline delta | 1/7296 pixels (0.0001370614); max channel delta37 light /44 dark |
| Fresh Web attempt | Actual exit2: Ego task space26 not found; 0 JSON /0 PNG; no retry or historical substitution |
| Paired pixel/property reports | Not run because fresh Web inputs are unavailable |

The Git baseline images were extracted from real6af Git blobs; no baseline was
promoted. Their one-pixel differences are distinct from the byte-exact
before/after publisher-removal comparison. Neither result repairs or hides the
collector's incorrect500 metadata.

The 49-case run is not relabeled as a run on final bytes. Final analysis/format
cover the later equivalent lint cleanup; fresh Native capture and resident
reload bind the final6af code commit. The resident app used an owned temporary
source clone and the real Flutter tester device, not a cold restart or SSR
reload. The clone's old utility existed only for the before state and was
reclaimed; current production has no such utility or import.

Owned metadata validates232 names/versions/roots and all dependency edges.
Only four workspace graph versions followed the existing release integration;
external220 roots, graph ordering and lock are preserved. Project pubget,
dependency installation and downloads are0. Tracked25158 source files stayed
unchanged during fresh Native capture. These two verification files are the
only changes after code commit6af4b3dd.

Jaspr build and Figma are N/A for this Native/tool architecture correction;
Web/Core/docs_site code did not change. No fresh Web, cross-platform parity,
full-suite or all-padding-fixes claim is made. Original captures and earlier
verification records remain immutable.

Commands, source hashes and retained proof references are in
[verification.json](verification.json).
