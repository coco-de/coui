# NumberTicker exact-zero duration — #6560

Web previously used its 16 ms interpolation timer even for explicit `Duration.zero`. With initial0/target100, SSR and the first client frame showed0; updates/retargets showed the old value. Changing only a running ticker's duration to zero also failed to finish. Native's existing public API displays the target in that frame.

The private State now finishes exact-zero work through the existing duration resolver and normal dependency/update lifecycle. A pending-work check preserves idle custom builders that previously worked without a Theme. Completion cancels the existing timer and updates its endpoint together. Public constructors/const/copyWith/style chain, Core, resolver APIs, defaults, positive-duration timing, builder/formatter/child/root CSS/events, dependency inputs, baselines and comparison criteria are unchanged. Nonzero startup retains its mounted/unawaited microtask. Zero+initialValue SSR intentionally changes from the initial value to the target; positive/default SSR policy is preserved.

## Executed verification

| Check | Actual evidence and result |
|---|---|
| Original zero SSR + optimized Chrome light/dark | Final original4:3FAIL → same3 fixture bytes:3PASS. Instance/theme/chain, first display, update, retarget, same-value live duration change. Late values after the800ms control remain current targets. Curve call counts are observations, not a contract. |
| Idle builder compatibility | Original b04 SSR200; initial0be6 candidateSSR500. Separate final plainText/no-Theme SSR+CSR controls:2FAIL →2PASS with identical fixture bytes. Same-value parent refresh twice, child event and State/DOM/child identities pass. No hydration claim or lint ignore. |
| Existing behavior | Native4 public controls +31 existing widget/style tests at37f450; executed Native/Core inputs remain exact. Web5 new+11 existing at final81f3 working tree, byte-exact to committedb3add/integrated5f. Fatal7 exit0; format7 changed0. Positive500µs starts at0, distinct from exactzero; Web's existing sub-ms timer quantization is unchanged. |
| Integrated main | #6561 at6f8 changes only docs-site rule/layout/newtests. Normal merge into `5f0137db0042dee3b0c5aa67106e4cbcb0b186b9` preserves all executed component/capture/report/asset/dependency inputs. New upstream layout suite12PASS. |
| Actual integrated docs build | exit0/107.10s;361routes,363Jaspr+2FlutterHTML.24,996 tracked bytes/modes/symlinks exact. Config/graph/lock raw exact and232 package tuples/roots/edge sets exact. Actual automatic Flutter Pub preflight is disclosed; worker direct pub commands0 does not mean total pub activity/downloads0.5046 generated-file hashes+3representativeHTML retained; whole build reclaimed. |
| Canonical captures | Fresh Native2+Web2 atb3add (all8/default2 descriptors),8raw files,NoRoot0/reuse0. Input closure to integrated5f verified. All8 PNG/JSON byte-exact to historicalf065. Four original images were visually inspected; this is static default coverage, not all styles/animation frames. |
| Committed-baseline regression | **1PASS/1FAIL(Native dark)/exit1**, infra0. Real report uses unchanged Git6f8 baseline blobs+allowlist. Historicalf065 raw with the same baseline/criterion gives the identical matrix. Failure remainsFAIL; no waiver/promotion. |
| Cross-platform reports | Pixel0PASS/2FAIL/exit1; property2PASS/0FAIL/exit0; infra/skip0. Static delta0 is not a reduction of the global remaining matrix. |
| Actual SSR VM reload | Loaded NumberTicker library atb3add, reloadSources success, HTTP200 before/after, two ticker roots+child and first values200/100. Each request has a fresh SSR binding; HTML SHA differs. This is not browser client hotreload or persistent browser State validation. All own ports/groups/jobboxes closed. |

Initial0be6 successful zero tests/docs are retained as historical because the later idle-builder witness found a compatibility regression before publication. Earlier source-count/lint/constructor setup failures and superseded test assumptions are preserved, rather than relabelled as passing checks. The final public-source and raw bindings are recorded in [verification.json](verification.json) with28 SHA256 references.

Figma: not applicable; no design defaults/tokens or canvas change. Last full default sweep remains f065:606PASS/228FAIL; it is not a current-main full sweep. The task's evidence root is `/Users/minhyeok/orca/artifacts/coui/weever-number-ticker-zero-7mu53og3`. Generated builds, browser profiles and owned processes were reclaimed; source/fixtures/raw failure evidence remain.
