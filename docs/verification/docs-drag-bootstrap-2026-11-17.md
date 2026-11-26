# Initialize both sides of the docs drag bridge before hydration

Part of #6131. Base main `c2ad35fc14730184ce65c2335c3b619f5e8170f2` (2026-11-17 KST).

## Merged work and defect

#6330 was squash-merged at this base, pinned to verified head `ac75f25af45ec1d4c83438efeaa2172c0233f44b`. Both full trees are `c9eff9ff04f0f4daf667dd611720f8cf3ffae943`. Release43994620225 succeeded. No new deployment is claimed.

Generated Jaspr client options register DesktopDropWeb's window handlers immediately. The plugin sends `entered`/`updated`/`exited` messages to its real Flutter receiver, but that receiver is normally installed only when the first deferred DropTarget mounts. A drag on a page without that target therefore throws MissingPluginException. The problem also reproduces after the same Flutter artifact merge the deployment workflow performs.

The docs client now initializes WidgetsFlutterBinding and calls the installed plugin's public, idempotent `DesktopDrop.instance.init()` before hydrating ClientApp. The browser sender and actual receiver are ready together. Later DropTargets retain their normal listener registration. Direct desktop_drop0.8.4 and Flutter SDK dependencies declare these existing imports; the lock file and resolved versions do not change.

No generated options file, plugin registration, callback, dependency cache or consumer component API is edited. There is no fake channel handler, catch-and-ignore, event suppression, disabled plugin, render correction or new design value.

## Verification

- `jaspr build` succeeds for357/357 routes. The accepted build is pinned to the accepted main.client.dart SHA. A second build uses a byte-identical copy of the original main bootstrap; after the control, the exact accepted source and its archived build are restored. Both builds receive main.dart.js/flutter.js using the deployment's merge procedure.
- `dart run tool/parity/docs_drag_probe.dart --url=<served built site> --out=<JSON> --screenshots=<directory>` checks `/` and `/embed/file-input/` in light/dark. It requires the real global browser drag handlers to remain registered, sends body drag events without a DropTarget and uses a real disposable file through CDP. The file must appear exactly once, the border must switch solid and return dashed, and both pointer and Enter activation must open a real file chooser (cancelled without changing selection).
- Original bootstrap: all4 cases fail with desktop_drop MissingPluginException. Accepted bootstrap: all4 cases pass, runtime errors0. The probe records runtime errors as failures and returns exit1; no error is filtered from the result.
- Settled light/dark Web FileInput screenshots after the same file operation are214×257 and byte-for-byte RGBA identical between both builds. The pointer is placed outside the control and existing finite transitions are allowed to finish on both sides; no animation policy or image pixels are changed.
- The paired `/components/file-input/` page also creates its actual Flutter view, glass pane and semantics host with zero runtime errors before and after the change. The deferred Flutter preview still mounts after eager receiver initialization.
- Existing docs pubspec/deploy/FlutterPreview tests:30 pass. Analyze on main.client.dart and the new browser probe: no issues. Format:0 changed. `git diff --check`: clean.
- Core, Flutter/Web component libraries, docs_core examples, capture/normalizer code, baseline and pubspec.lock are unchanged. Their offline parity inputs are identical to #6330's verified748-key matrix,461 pass/287 fail. A newly executed full offline matrix is not claimed for this startup-only change. Full CI, designer approval and a new deployment are not claimed.

[Source hashes, negative/accepted results and unchanged-pixel evidence](docs-drag-bootstrap-2026-11-17.json).
