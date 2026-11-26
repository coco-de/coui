# Compare captured padding without border reconstruction (#6625)

The comparator added Native border width to top/bottom padding for every
cross-platform pair. A Button-specific layout explanation did not establish
that other captured values used that layout path or that authored padding
could be recovered after alignment and constraint clamping.

This correction removes that arithmetic and compares normalized captured
padding directly. It preserves the existing 0.5px tolerance, null/zero meaning,
expected-token classification and all other field gates. The optional
reconcilePlatforms flag remains accepted for caller compatibility; either
flag value compares captured padding directly. No name allowlist, replacement
offset, forced null, producer injection or new API is introduced.

Native's existing geometric padding probe already subtracts border width;
Web's normalizer reads the computed CSS sides. Those observations can still
have genuine differences or independent producer/ownership limitations.
This change does not infer authored design values, alter either producer,
or declare those limitations solved. Captured 7/8 remains a 1px field
mismatch even if the screenshots happen to match.

| Check | Actual result |
| --- | --- |
| New 15 controls on original code | 4 PASS / 11 FAIL |
| Same final 15 fixture on candidate | 15 PASS / 0 FAIL; fixture SHA unchanged |
| Existing property/pruned 39 | Original 39 PASS; candidate 39 PASS |
| Related comparator/report 53 | Candidate 53 PASS |
| Candidate total | 107 PASS / 0 FAIL |
| Final format check / touched 5 fatal-infos | Both exit0; format 0 changed; no issues |
| Owned pure-Dart VM hot reload | reloadSources success; same PID/state/input objects; 0.348s |
| Live comparator transitions | Equal captured values F→P; actual 7/8 P→F; same-platform P→P |
| After ICC main integration | Pruned 6 + comparator/report 53 = 59 PASS / 0 FAIL |
| Historical 566 projected padding roles | 196 roles: old 10 matches; candidate 120 matches |
| Direction of field verdict changes | 120 mismatch→match; 10 match→mismatch |
| Equal captured four sides | All 120 now match; descriptions retain original values |
| Production/Core/public CoUI API/producer/normalizer/baseline/criteria edits | 0 |

The existing 7/8 PASS expectation encoded the unsupported reconstruction;
it now expects a mismatch under the observed-field contract. Horizontal,
vertical, signed/fractional values, expected-token direction, null/zero and
half-pixel boundary controls remain explicit. No tolerance was relaxed.

The first original fixture used common platform labels; before changing the
comparator, these were refined to explicit Flutter/Web labels and rerun.
Both originals remain preserved, with the same 4/11 verdicts. Candidate uses
the exact final original fixture. The 107-case run and tool VM reload bind
base 4c28 plus working-file hashes. The candidate formatter applied one test
line-wrap before that run; the final no-drift check ran at code commit e20.

Main f683 (#6631 ICC decoding) was merged normally into 89b18e7c with no
intersection with the five frozen files or metadata. The 59 integration
checks ran on 89b18e7c. Earlier executions are not relabeled as runs there.

The 196-role evaluation reuses immutable source 566 observations from the
producer-convention audit. It executes the candidate on that padding-field
projection, not a new capture or full report. Original 566 and base 4c28 have
the same original property-diff Git blob. No historic raw capture or report
is rewritten; changed counts are measurement corrections, not product
improvements or a fresh full-parity result.

Owned 232 metadata preserves external 220 roots, graph bytes/order/edges and
lock; only 12 workspace roots are rebound. Project pubget/install/download,
browser actions and renderer changes are 0. Generated test wrappers and
jobboxes were reclaimed. The actual tool VM reload used an owned comparator
clone, not a process restart or Flutter/browser reload; both ports closed.
Native/Web screenshots, app hot reload, Jaspr build and Figma are N/A here.

Commands, exact source hashes and proof references are in
[verification.json](verification.json).
