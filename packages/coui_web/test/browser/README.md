# Web browser regressions

## Iconify Lucide stroke

From the repository root, with system Chrome installed:

```sh
COUI_ICON_STROKE_EVIDENCE=/tmp/coui-icon-stroke \
  dart test tool/parity/test/web/icon_stroke_rendering_test.dart -r expanded
```

This runs the actual SSR `Icon` tree and hydrates the same fixture with
optimized Dart. It measures SVG paths and the decoded SVG actually used by
Iconify's mask/background modes at 16/20/24/28, concurrent sizes, ambient and
instance overrides, rem scaling, custom grids and preserved authored widths.
It also checks source/size replacement, events, companion replacement,
subscription disposal, canonical cache preservation and non-Lucide controls.
Scripts/data load before and after the hosts, including a delayed request
through Iconify's existing loader to an isolated local provider.

All scripts are served externally under `script-src 'self'`; no inline
script execution is enabled. The test closes its temporary HTTP server and
Chrome, and removes its compiled fixture. The optional evidence directory
retains actual SVG/encoded-SVG measurements and light/dark screenshots.

## InputOtp

This smoke test exercises a real Jaspr input and `FormController`, including
initial value, delete, replacement, retry, and the value read during actual
form submission. It tests both the default tail-only contract and opt-in
cell editing. The fixture is isolated test data (digits only).

Use a clean, isolated CoUI checkout with dependencies already installed:

1. Temporarily copy `test/browser/fixtures/input_otp_form_probe.dart` over
   `docs_core/lib/previews/examples/web/input_otp/input_otp_default_example.dart`.
   Both paths are relative to the CoUI root except the first, which is under
   `packages/coui_web`. Preserve the original file and restore it afterward.
2. Start the docs site in that checkout, for example with `jaspr serve --port
   19876` from `docs_site`. Open the `components/input-otp` route in an
   existing agent-owned Ego Lite task space.
3. Prepend the space ID and fixture URL to the regression script and run it
   through Ego Lite (do not launch another browser):

   ```sh
   (printf '%s\n' 'const OTP_TASK_SPACE = 65;' \
     'const OTP_FIXTURE_URL = "http://127.0.0.1:19876/components/input-otp";'; \
     cat packages/coui_web/test/browser/input_otp_form_ego.js) | ego-browser nodejs
   ```

The space ID and port are examples: use the owned space and local port created
for the run. The script removes the docs page's unrelated Flutter preview to
prevent it stealing focus and prevents test-form navigation; it does not change
production code. Browser, OS, actual WebOTP/SMS, and physical screen-reader
coverage are separate checks.

For keyboard verification, serve the built fixture using
`python3 packages/coui_web/test/browser/serve_otp_fixture.py --directory
 docs_site/build/jaspr --port 19883` and run the same prefix command with
`http://127.0.0.1:19883/components/input-otp/` and
`input_otp_keyboard_ego.js`. This fixture server removes only the Flutter
bootstrap tag from the served HTML. Removing `flutter-view` after startup is
not sufficient: the embedded Flutter engine retains a global keyboard
listener and can intercept arrow keys even in an unrelated HTML input.
