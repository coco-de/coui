# Native root text declaration ownership (#6619)

Native Menubar’s root snapshot reported fontWeight 500 while its real
RenderParagraph labels painted 400. The old traversal selected a descendant
Button DefaultTextStyle rather than the Menubar’s already-resolved label style.

A private transparent marker now publishes that genuine resolved style with the
actual producer BuildContext. The existing manifest byType finder identifies the
unique semantic producer separately from the rendered geometry root. A marker
is accepted only for that exact Element inside the capture unit and visible text.
Missing, ambiguous, foreign-owner and empty-text cases retain the legacy path.

No Core/default/public constructor/Resolved/barrel API, inherited style or
RenderObject was changed. No component-name repair table, first-leaf shortcut,
normalizer, criterion, baseline or allowlist changed.

| Check | Actual result |
| --- | --- |
| Original new contract14 + existing owner10 | 10 PASS / 4 FAIL + existing10 PASS |
| Candidate same14 + existing10 + protocol/state/focus/callback7 | 31 PASS / 0 FAIL |
| Original14 fixture bytes | Identical before/after (`58c0cf70…`) |
| Final format | Exit0 / no drift |
| Touched-file analysis | Actual exit1: original-identical Material INFO1; new INFO0 |
| Fresh canonical Native before2 / after2 | Both PNGs byte-exact, same 152×48 geometry |
| Complete canonical JSON delta | Only root.fontWeight 500 → 400 in L/D |
| Real resident Native hot reload | app.restart fullRestart:false code0; 414/3756 libraries, 1044ms |
| Hot reload lifecycle | App/Menubar/Button State identities, actual400 paint and size preserved |
| Cleanup | Explicit disposal5 checks true, own app.stop true, VM/HTTP ports closed |
| Committed-baseline pixel (before / after) | Both exit0; 2 keys × 2 platforms = 4 actual image comparisons PASS |
| Crosspixel (before / after) | Both exit0; 2 PASS / 0 FAIL |
| Property (before / after) | Both exit1; 0 PASS / 2 FAIL; infra/skip0 |

The 31-case run preceded only bounded equivalent lint cleanup; its exact delta
is preserved rather than rerunning unrelated passing checks. The baseline
Material diagnostic was independently reproduced on the Dabd matrix preimage
with the same SDK and equivalent metadata. Fatal exit1 is retained as exit1.

The first direct Flutter-test VM reloadSources attempt failed with
“Error while starting Kernel isolate task”. That original and its wrapper exit
error remain preserved. The later successful action used the official resident
Flutter `run -d flutter-tester --machine` device and incremental compiler, not a
cold restart or Jaspr SSR reload. Its actual Native host was FVM350/darwin-x64;
binary identity with the canonical test backend is not claimed.

Actual tests, Native captures and reload ran on the frozen uncommitted six-file
revision at base Dabd. Commit d80fb03b and integrated c9e4442e have those exact six
files. Main49622 changed no Core/Native library, docs_core library, capture source,
fonts or lock in that closure; earlier executions are source-bound reuse, not
relabeled runs on the integrated commit.

Both fontWeight mismatches changed from Native500/Web400 to 400/400. The two
property keys still FAIL on unchanged paddingPx: normalized Native[4,3,4,3]
versus Web[3,3,3,3]. No status-count improvement or padding repair is claimed.

The pixel reports used actual Git49622 baseline8 blobs and unchanged allowlist,
with the current c9e decoder/criteria; unmerged ICC6620 code was not included.
Root freshWeb2 at c9e is an actual comparison control (Ego26/156, renderer
rasterization unspecified), paired with the source-bound Native observations.

The bounded Native paint control is unchanged. This does not establish that all
remaining text/padding discrepancies have this ownership cause, or that full
Native/Web pixel/property parity passes. Historical raw captures stay immutable.
Jaspr build is N/A for this private Native ownership/tool correction under Root’s
reviewed scope; no Web renderer, Core or docs_site source changed.

Commands, exact source bindings and proof SHA refs are in [verification.json](verification.json).
The final documentation commit changes only these two verification files.
