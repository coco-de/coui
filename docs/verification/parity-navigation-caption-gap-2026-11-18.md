# NavigationBar caption gap ownership - #6412 / PR #6414

Validated product/tests: `14726a72b8a85e686c74b4772b24a899cdc39412`, tree `ecfdc478580fe83d9511d63e26a744a09e882067`, byte-identical to worker df312. Base is main `e2d2dbf21ab7e6ae3c05389f11b271dc7ef39889`. This records local validation; merge status is recorded separately on the PR.

The existing caption fold already owns Core labelSpacing. Its compact parent redundantly declared gap0 through a direct common-token reference, failing the enforced contract guard. The product change omits that parent declaration when a compact form exists. Noncompact gap and caption-owned spacing remain unchanged. No new Core default, public API, token, number, wrapper, guard suppression or baseline change is introduced. The private inline CSS representation changes from 0px to absence (initial normal, used0 on this flex). This is an ownership/guard correction, not a claimed visual spacing repair.

| Verification | Actual evidence |
|---|---|
| Product O2 before/after | 32/32 PNG bytes and RGBA exact: L/D x four caption positions x open/folded x Core gap4/11.25. Public root CSS gap37/classes and ancestor gap39 remain. No temporary DOM mutation in this product execution. |
| Wrong-owner control | Removing the actual caption gap in a separately preserved invalid source fails real geometry: expected4, actual0. Original source fails the ownership assertion; it is not labelled a visual failure. |
| Public onScroll | Open/folded/returned raw measured rects, recorded relevant styles, nodes and callback[1] agree. Dynamic image differences are preserved beside same-source repeat differences. No whole dynamic-RGBA equality or blanket AA cause is claimed. |
| Focused tests | Root Chrome2 + existing Web26 + Native28 = 56 unique, all exit0. Worker repeats/subsets are not added. An initial combined Web command used the wrong fixture cwd; corrected commands and its load-error log are preserved separately. |
| Static checks | Three changed Dart files fatal analyze0/format0; API/Resolved/export declarations unchanged. Official isolated SDK3.50 full verify_contracts.sh exit0, including check11. Existing seven non-enforced warnings remain. Token phases1..7 and chrome passthrough exit0. No guard file changed. |
| Registered capture | Native50 and Web50 freshly captured across five styles. Actual frozen e2 Web-before50 vs candidate Web-after50: all50 PNG byte/RGBA exact, JSON40 byte exact. Native-before was not captured or relabelled. Cross-platform reports retain pixel28/22 and property8/42, infra0/skip0, both exit1. |
| Docs | Optimized build exit0/359 routes; actual NavigationBar/NavItem/Scaffold30 runtime records(12/10/8), L/D/variants/refresh, JS/action errors0. |
| Inputs and cleanup | 22482 tracked files, generated and locks unchanged; clean before evidence docs. All owned browser/capture/report processes ended; docs server SIGTERM/reaped143, ports closed. Other sessions' apps were not touched. |

Independent source review found no new blocker and confirmed the existing Native CaptionFold owns the same resolved spacing. Upstream itemMaxWidth96/API/Figma/baseline changes belong to #6410 in the base, not this patch. Figma contract/canvas and supported API signatures/defaults are unchanged by this PR.

The four raw images on the PR show fresh default Native/Web light/dark references. They are unedited, stored in a private unpublished draft release, expire after three days, and are not committed as baselines. Scope and source hashes are in [the JSON](parity-navigation-caption-gap-2026-11-18.json). Raw artifacts: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6412-integration-20261118.7qq11s5l` and `/tmp/weever-6412-caption-gap-product-20261118.ltqp0zoh`. Full manual CI/deployment/designer approval/all parity completion are not claimed.
