#!/usr/bin/env bash
#
# Chrome DevTools Protocol (CDP) inspector for unify-component verify.
#
# Loads `<docs_url>` in a headless Chrome, waits for hydration, and
# evaluates a JS snippet against the live DOM — printing the JSON
# result to stdout. Used in Step 7 / verify.md to confirm Web
# computed styles (focus ring, transitions, browser-default leakage)
# match the intended cross-platform rendering before reporting a
# component as ✅.
#
# Usage:
#   scripts/cdp_inspect.sh <docs_url> <selector> [<extra-js>]
#
# Examples:
#   # Default focus-state inspection of an input element
#   scripts/cdp_inspect.sh \
#     http://localhost:8080/components/input-otp/ \
#     'input[data-index="0"]'
#
#   # Custom JS — `el` is the matched element, return any JSON-able value
#   scripts/cdp_inspect.sh \
#     http://localhost:8080/components/text-field/ \
#     '.ringedBody' \
#     'el.focus(); await frame(); return { focused: getComputedStyle(el).boxShadow };'
#
# Default snippet (when <extra-js> is omitted) reports the most
# common ring / outline / border / box-shadow / transition values
# for the focused state plus the closest `.relative` wrapper.
#
# The Chrome it drives is its own: a throw-away profile and a debugging
# port the OS picks (`--remote-debugging-port=0`), read back from that
# profile's `DevToolsActivePort`. It never connects to, or signals, any
# other browser — one already listening on 9222 (a dev browser, an MCP
# server's Chrome, another run of this script) can neither be measured
# by mistake nor be killed by the cleanup.
#
# Requires: node, npm, Google Chrome.app (macOS).

set -euo pipefail

URL="${1:-}"
SELECTOR="${2:-}"
EXTRA_JS="${3:-}"

if [[ -z "$URL" || -z "$SELECTOR" ]]; then
  echo "Usage: $0 <docs_url> <selector> [<extra-js>]" >&2
  exit 2
fi

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [[ ! -x "$CHROME" ]]; then
  echo "Google Chrome not found at $CHROME" >&2
  exit 1
fi

PROFILE="$(mktemp -d -t coui-cdp.XXXXXX)"
CHROME_PID=""
cleanup() {
  local rc=$?
  if [[ -n "$CHROME_PID" ]]; then
    # The browser this run launched, by PID.
    kill "$CHROME_PID" 2>/dev/null || true
    for _ in $(seq 1 25); do
      kill -0 "$CHROME_PID" 2>/dev/null || break
      sleep 0.2
    done
    if kill -0 "$CHROME_PID" 2>/dev/null; then
      kill -9 "$CHROME_PID" 2>/dev/null || true
    fi
  fi
  # A renderer can outlive the browser process. Whatever still carries this
  # run's private profile path is this run's — the path is unique to the
  # run, so unlike a port or flag pattern it cannot reach another browser.
  pkill -f -- "--user-data-dir=$PROFILE" 2>/dev/null || true
  # Chrome's Cache_Data can still be written while it shuts down — retry
  # the recursive remove instead of failing on the macOS "directory not
  # empty" race.
  for _ in 1 2 3 4 5; do
    rm -rf "$PROFILE" 2>/dev/null && break
    sleep 0.2
  done
  exit $rc
}
trap cleanup EXIT

# Launch headless Chrome. Port 0 lets the OS pick a free port, so nothing
# else's debugging port is ever contended for.
"$CHROME" \
  --remote-debugging-port=0 \
  --user-data-dir="$PROFILE" \
  --no-first-run --no-default-browser-check \
  --headless=new --disable-gpu \
  "$URL" >/dev/null 2>&1 &
CHROME_PID=$!

# Wait for CDP to come up. `DevToolsActivePort` is written into the profile
# only this Chrome owns (line 1 = port, line 2 = browser path), so the port
# it names is this Chrome's own.
PORT=""
for _ in $(seq 1 50); do
  if [[ -s "$PROFILE/DevToolsActivePort" && -n "$(sed -n 2p "$PROFILE/DevToolsActivePort")" ]]; then
    PORT="$(sed -n 1p "$PROFILE/DevToolsActivePort")"
    break
  fi
  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    echo "Chrome exited before opening a debugging port" >&2
    exit 1
  fi
  sleep 0.2
done
if [[ -z "$PORT" ]]; then
  echo "Timed out waiting for Chrome's debugging port" >&2
  exit 1
fi

# The tab we launched with: a page target that has left about:blank.
PICK_PAGE_JS='
const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
const pages = d.filter((t) => t.type === "page");
const p = pages.find((t) => t.url && t.url !== "about:blank") || pages[0];
if (!p) process.exit(1);
console.log(p.webSocketDebuggerUrl + "\t" + p.url);
'
WS_URL=""
for _ in $(seq 1 50); do
  TARGET="$(curl -sf "http://127.0.0.1:$PORT/json/list" 2>/dev/null | \
    node -e "$PICK_PAGE_JS" 2>/dev/null || true)"
  if [[ -n "$TARGET" ]]; then
    WS_URL="${TARGET%%$'\t'*}"
    [[ "${TARGET#*$'\t'}" != "about:blank" ]] && break
  fi
  sleep 0.2
done
if [[ -z "$WS_URL" ]]; then
  echo "No page target on Chrome's debugging port $PORT" >&2
  exit 1
fi

# Default JS body — focus the matched element and report common style props
DEFAULT_JS=$(cat <<'JS'
el.focus();
await frame(); await frame();
const cs = getComputedStyle(el);
const wrap = el.closest('.relative') || el.parentElement;
const ws = wrap ? getComputedStyle(wrap) : null;
return {
  selector: el.tagName + '.' + (el.className || '').split(' ').slice(0, 3).join('.'),
  outline: cs.outline,
  outlineColor: cs.outlineColor,
  borderColor: cs.borderColor,
  boxShadow: cs.boxShadow,
  transition: cs.transition,
  wrapperTag: wrap ? wrap.tagName : null,
  wrapperBoxShadow: ws ? ws.boxShadow : null,
  wrapperOutline: ws ? ws.outline : null,
  wrapperTransition: ws ? ws.transition : null,
};
JS
)

JS_BODY="${EXTRA_JS:-$DEFAULT_JS}"

# Build evaluation script (passed via env to avoid quoting issues)
export COUI_CDP_WS="$WS_URL"
export COUI_CDP_SELECTOR="$SELECTOR"
export COUI_CDP_JS="$JS_BODY"

# Ensure ws module is available in a stable cache dir
WS_CACHE="$HOME/.cache/coui-cdp"
mkdir -p "$WS_CACHE"
if [[ ! -d "$WS_CACHE/node_modules/ws" ]]; then
  (cd "$WS_CACHE" && npm init -y >/dev/null 2>&1 && npm install ws --silent >/dev/null 2>&1)
fi

cd "$WS_CACHE"
node -e '
const WebSocket = require("ws");
const WS = process.env.COUI_CDP_WS;
const SEL = process.env.COUI_CDP_SELECTOR;
const BODY = process.env.COUI_CDP_JS;
const EXPR = `
(async () => {
  const frame = () => new Promise(r => requestAnimationFrame(r));
  await new Promise(r => requestAnimationFrame(() => setTimeout(r, 800)));
  const el = document.querySelector(${JSON.stringify(SEL)});
  if (!el) return { error: "selector not found", selector: ${JSON.stringify(SEL)} };
  ${BODY}
})()
`;
const ws = new WebSocket(WS, { perMessageDeflate: false });
let timeout = setTimeout(() => { console.error("CDP timeout"); ws.close(); process.exit(3); }, 15000);
ws.on("open", () => {
  ws.send(JSON.stringify({
    id: 1, method: "Runtime.evaluate",
    params: { expression: EXPR, awaitPromise: true, returnByValue: true }
  }));
});
ws.on("message", (data) => {
  const m = JSON.parse(data.toString());
  if (m.id === 1) {
    clearTimeout(timeout);
    const v = m.result && m.result.result && m.result.result.value;
    const exception = m.result && m.result.exceptionDetails;
    if (exception) {
      console.error(JSON.stringify(exception, null, 2));
      ws.close();
      process.exit(4);
    }
    console.log(JSON.stringify(v ?? m, null, 2));
    ws.close();
  }
});
ws.on("error", (e) => { console.error("WS error:", e.message); process.exit(5); });
'
