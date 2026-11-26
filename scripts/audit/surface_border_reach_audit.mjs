// Driver for surface_border_reach_audit.sh — see that file for what
// this looks for and why. Kept separate so the page-side invariant
// reads as one piece of JavaScript rather than as a string inside a
// shell string.

import { createRequire } from 'node:module';

// Resolve from the shared CDP cache rather than from this file: the
// script lives in the repo and its dependency does not.
const require = createRequire(`${process.env.COUI_WS_CACHE}/`);
const WebSocket = require('ws');

const PORT = process.env.COUI_PORT;
const BASE = process.env.COUI_BASE;
const STYLE = process.env.COUI_STYLE;
const FLOOR = Number(process.env.COUI_STROKE_FLOOR || '0');
const SLUGS = (process.env.COUI_SLUGS || '').split(/\s+/).filter(Boolean);
// When set, each page gets one planted anomaly of each kind, and a run
// that does not report them is a broken audit rather than a clean
// codebase.
const SELFTEST = process.env.COUI_SELFTEST === '1';

// The page-side check. Runs after the style is applied and the chrome
// transition has settled — measuring mid-transition reports widths that
// are between the old and the new one, which reads as a defect and is
// not one.
const PROBE = (style, floor, selftest) => `
(async () => {
  const settle = (ms) => new Promise(r => setTimeout(r, ms));
  document.documentElement.setAttribute('data-coui-style', ${JSON.stringify(style)});
  await settle(700);

  const FLOOR = ${floor};

  // What the cast actually computes to, asked of the browser rather
  // than parsed out of the variable — same reasoning as the cast audit.
  const probe = document.createElement('div');
  probe.style.boxShadow = 'var(--coui-control-shadow)';
  document.body.appendChild(probe);
  const castComputed = getComputedStyle(probe).boxShadow;
  probe.remove();
  const castGeometry = (castComputed.match(/(-?[\\d.]+px\\s+-?[\\d.]+px\\s+[\\d.]+px\\s+[\\d.]+px)/) || [])[1];
  const wearsCast = (v) => Boolean(castGeometry) && v.includes(castGeometry);

  const opaque = (v) =>
    v && v !== 'transparent' && !/rgba\\([^)]*,\\s*0\\)$/.test(v);

  const SIDES = ['Top', 'Right', 'Bottom', 'Left'];
  // Every drawn side, with its width. A side whose colour is
  // transparent is not a drawn border: several variants express "no
  // border" that way so an invisible one does not eat layout, and
  // counting it would report those as boxed when nothing is painted.
  const drawnSides = (cs) =>
    SIDES
      .map((s) => ({
        side: s,
        w: parseFloat(cs['border' + s + 'Width'] || '0'),
        c: cs['border' + s + 'Color'],
      }))
      .filter((b) => b.w > 0 && opaque(b.c));

  // An outline counts as a boundary too. It is the property an avatar
  // ring uses, and a component boxed by an outline is boxed.
  const drawnOutline = (cs) => {
    const w = parseFloat(cs.outlineWidth || '0');
    return w > 0 && cs.outlineStyle !== 'none' && opaque(cs.outlineColor)
      ? w
      : 0;
  };

  if (${JSON.stringify(selftest ? 'yes' : 'no')} === 'yes') {
    const host = document.querySelector('.preview-content') || document.body;
    // (G) a drawn border below the floor — a width that reached paint
    // without passing through the constraint.
    const thin = document.createElement('div');
    thin.textContent = 'SELFTEST-G';
    thin.style.cssText =
      'background:#fff;width:40px;height:20px;border:1px solid #000';
    host.appendChild(thin);
    await settle(50);
  }

  const thin = [];
  let boxedCount = 0;
  let sampled = 0;

  // \`.preview-content\` and not \`.live-preview\`: the latter wraps the
  // code viewer and its copy button as well, and those are the docs
  // site's own chrome. Measuring them reports the documentation as a
  // component defect — the first pass did, and buried the four real
  // findings under a page of them.
  for (const el of document.querySelectorAll('.preview-content *')) {
    if (el.offsetParent === null) continue;
    const cs = getComputedStyle(el);
    sampled += 1;

    const sides = drawnSides(cs);
    const outline = drawnOutline(cs);
    const cast = wearsCast(cs.boxShadow);

    // Boxed: something paints this element's boundary at the weight the
    // style asked for, or the style's own hard cast stands in for it.
    if (cast || outline >= FLOOR || sides.some((b) => b.w >= FLOOR)) {
      boxedCount += 1;
    }

    // (G) A boundary is painted, and it is thinner than the floor. The
    // constraint lifts every width it sees, so a survivor is a width
    // that reached paint by some route the constraint does not sit on.
    //
    // Reported per element rather than per side: one <div> with four
    // 1px sides is one defect, not four.
    const under = sides.filter((b) => b.w < FLOOR);
    if (under.length > 0 || (outline > 0 && outline < FLOOR)) {
      thin.push({
        tag: el.tagName.toLowerCase(),
        text: (el.innerText || '').trim().slice(0, 24),
        widths: [
          ...under.map((b) => b.side.toLowerCase() + ':' + b.w),
          ...(outline > 0 && outline < FLOOR ? ['outline:' + outline] : []),
        ].join(' '),
        inlineBorder: /border[a-z-]*-?width|border:/.test(
          el.getAttribute('style') || '',
        ),
      });
    }
  }

  return { castComputed, castGeometry, sampled, boxedCount, thin };
})()
`;

async function connect(wsUrl) {
  const ws = new WebSocket(wsUrl, { perMessageDeflate: false });
  await new Promise((res, rej) => {
    ws.once('open', res);
    ws.once('error', rej);
  });
  let id = 0;
  const pending = new Map();
  ws.on('message', (raw) => {
    const msg = JSON.parse(raw.toString());
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  });
  const send = (method, params = {}) =>
    new Promise((res) => {
      const n = ++id;
      pending.set(n, res);
      ws.send(JSON.stringify({ id: n, method, params }));
    });
  return { ws, send };
}

const version = await (await fetch(`http://localhost:${PORT}/json/version`)).json();
const { ws, send } = await connect(version.webSocketDebuggerUrl);

const { result: target } = await send('Target.createTarget', { url: 'about:blank' });
const { result: session } = await send('Target.attachToTarget', {
  targetId: target.targetId,
  flatten: true,
});
const sid = session.sessionId;

const sendTo = (method, params = {}) =>
  new Promise((res) => {
    const n = Math.floor(Math.random() * 1e9);
    const handler = (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.id === n) {
        ws.off('message', handler);
        res(msg);
      }
    };
    ws.on('message', handler);
    ws.send(JSON.stringify({ id: n, sessionId: sid, method, params }));
  });

let anomalies = 0;
let walked = 0;
const unboxed = [];
const report = [];

for (const slug of SLUGS) {
  walked += 1;
  process.stderr.write(`\r  [${walked}/${SLUGS.length}] ${slug.padEnd(24)}`);
  await sendTo('Page.navigate', { url: `${BASE}/components/${slug}/` });
  await new Promise((r) => setTimeout(r, 900));

  const out = await sendTo('Runtime.evaluate', {
    expression: PROBE(STYLE, FLOOR, SELFTEST),
    awaitPromise: true,
    returnByValue: true,
  });

  const value = out?.result?.result?.value;
  if (!value) {
    report.push(`  ${slug}: probe returned nothing (page may not exist)`);
    continue;
  }
  // An empty preview proves nothing either way — say so rather than
  // counting it as a component the style fails to reach.
  if (value.sampled === 0) {
    report.push(`  ${slug}: preview rendered no elements — not measured`);
    continue;
  }

  // (F) Nothing in the whole preview is boxed. Under a style whose
  // identity is that everything is outlined, that is the style being
  // invisible on this component.
  if (value.boxedCount === 0) {
    anomalies += 1;
    unboxed.push(slug);
  }

  for (const t of value.thin) {
    anomalies += 1;
    report.push(
      `  ${slug}: border under the floor — <${t.tag}> "${t.text}" ` +
        `[${t.widths}]${t.inlineBorder ? ' (inline width)' : ''}`,
    );
  }
}

process.stderr.write('\r' + ' '.repeat(60) + '\r');

console.log(`surface border reach — style=${STYLE} floor=${FLOOR}px`);
console.log(`walked ${walked} component page(s)\n`);

if (unboxed.length > 0) {
  console.log(`(F) no box anywhere in the preview — ${unboxed.length}:`);
  for (const s of unboxed) console.log(`  ${s}`);
  console.log('');
}

if (report.length > 0) {
  console.log('(G) a boundary painted below the floor:');
  for (const line of report) console.log(line);
  console.log('');
}

if (anomalies === 0) {
  console.log('no anomalies.');
}

ws.close();
process.exit(anomalies === 0 ? 0 : 1);
