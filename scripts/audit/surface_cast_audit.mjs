// Driver for surface_cast_audit.sh — see that file for what this looks
// for and why. Kept separate so the page-side invariant reads as one
// piece of JavaScript rather than as a string inside a shell string.

import { createRequire } from 'node:module';

// Resolve from the shared CDP cache rather than from this file: the
// script lives in the repo and its dependency does not.
const require = createRequire(`${process.env.COUI_WS_CACHE}/`);
const WebSocket = require('ws');

const PORT = process.env.COUI_PORT;
const BASE = process.env.COUI_BASE;
const STYLE = process.env.COUI_STYLE;
const SLUGS = (process.env.COUI_SLUGS || '').split(/\s+/).filter(Boolean);
// When set, each page gets one planted anomaly of each kind, and a
// run that does not report them is a broken audit rather than a
// clean codebase.
const SELFTEST = process.env.COUI_SELFTEST === '1';

// The page-side check. Runs after the style is applied and the chrome
// transition has settled — measuring mid-transition reports values that
// are between the old and the new one, which reads as a defect and is
// not one.
const PROBE = (style, selftest) => `
(async () => {
  const settle = (ms) => new Promise(r => setTimeout(r, ms));
  document.documentElement.setAttribute('data-coui-style', ${JSON.stringify(style)});
  await settle(700);

  // What the cast actually computes to, asked of the browser rather
  // than parsed out of the variable: the first pass matched any
  // box-shadow at all and reported every focus ring in the kit as a
  // defect. A check that cries wolf is worse than none — it teaches
  // people to skip the output.
  const probe = document.createElement('div');
  probe.style.boxShadow = 'var(--coui-control-shadow)';
  document.body.appendChild(probe);
  const castComputed = getComputedStyle(probe).boxShadow;
  probe.remove();

  // A style that injects nothing cannot produce either anomaly, so say
  // so rather than reporting a clean run that proved nothing.
  const injects = castComputed !== 'none'
    && !/rgba\\(0, 0, 0, 0\\) 0px 0px 0px 0px/.test(castComputed);

  // The material half, asked the same way. A style that states no blur
  // cannot produce a material anomaly, so the three checks below are
  // gated on this rather than reported as a clean run that proved
  // nothing — the same reasoning as \`injects\` above.
  // The preset writes \`backdrop-filter\` straight onto the marker class
  // under a \`[data-coui-style]\` scope — there is no variable to read,
  // so the probe wears the class and asks what that computes to.
  const mProbe = document.createElement('div');
  mProbe.className = 'coui-surface';
  document.body.appendChild(mProbe);
  const mStyle = getComputedStyle(mProbe);
  const mComputed = mStyle.backdropFilter || mStyle.webkitBackdropFilter || 'none';
  mProbe.remove();
  const materialInjects = mComputed !== 'none'
    && !/^blur\\(0px\\)$/.test(mComputed);

  const wearsMaterial = (cs) => {
    const v = cs.backdropFilter || cs.webkitBackdropFilter || 'none';
    return v !== 'none' && !/^blur\\(0px\\)$/.test(v);
  };

  // The geometry alone: a surface may stack the cast behind its own
  // layers, so this has to match as a substring rather than whole.
  const castGeometry = (castComputed.match(/(-?[\\d.]+px\\s+-?[\\d.]+px\\s+[\\d.]+px\\s+[\\d.]+px)/) || [])[1];
  const wearsCast = (v) => Boolean(castGeometry) && v.includes(castGeometry);

  const opaque = (v) =>
    v && v !== 'transparent' && !/rgba\\([^)]*,\\s*0\\)$/.test(v);
  // All four sides: the first pass read only the top, so a tab bar with
  // nothing but a bottom border counted as having no box at all.
  const anyBorder = (cs) =>
    ['Top', 'Right', 'Bottom', 'Left'].some((side) =>
      parseFloat(cs['border' + side + 'Width'] || '0') > 0
      && opaque(cs['border' + side + 'Color']));

  const castless = [];
  const boxless = [];
  const materialless = [];
  const unmarkedMaterial = [];
  const nestedMaterial = [];

  // Self-test: plant one of each anomaly and see whether the checks
  // below find them. A run that reports nothing proves nothing until
  // the detectors have been shown to fire, and these two are cheap to
  // construct — no rebuild, no fixture page.
  if (${JSON.stringify(selftest ? 'yes' : 'no')} === 'yes') {
    const host = document.querySelector('.live-preview') || document.body;
    const noBox = document.createElement('div');
    noBox.textContent = 'SELFTEST-A';
    noBox.style.cssText =
      'background:transparent;border:0;width:40px;height:20px;' +
      'box-shadow:var(--coui-control-shadow)';
    host.appendChild(noBox);
    const noCast = document.createElement('div');
    noCast.textContent = 'SELFTEST-B';
    noCast.className = 'coui-control-shadow-rest';
    noCast.style.cssText = 'background:#fff;width:40px;height:20px;box-shadow:none';
    host.appendChild(noCast);

    // The material trio. Same reasoning: a 0-count report from a dead
    // detector is indistinguishable from a clean codebase.
    const markedNoMaterial = document.createElement('div');
    markedNoMaterial.textContent = 'SELFTEST-C';
    markedNoMaterial.className = 'coui-surface';
    markedNoMaterial.style.cssText =
      'background:#fff;width:40px;height:20px;backdrop-filter:none';
    host.appendChild(markedNoMaterial);

    const materialNoMarker = document.createElement('div');
    materialNoMarker.textContent = 'SELFTEST-D';
    materialNoMarker.style.cssText =
      'background:#fff;width:40px;height:20px;backdrop-filter:blur(8px)';
    host.appendChild(materialNoMarker);

    const nestOuter = document.createElement('div');
    nestOuter.className = 'coui-surface';
    nestOuter.style.cssText =
      'background:#fff;width:60px;height:40px;backdrop-filter:blur(8px)';
    const nestInner = document.createElement('div');
    nestInner.textContent = 'SELFTEST-E';
    nestInner.className = 'coui-surface';
    nestInner.style.cssText =
      'background:#fff;width:40px;height:20px;backdrop-filter:blur(8px)';
    nestOuter.appendChild(nestInner);
    host.appendChild(nestOuter);

    await settle(50);
  }

  for (const el of document.querySelectorAll('.live-preview *, .variant-gallery *')) {
    if (el.offsetParent === null) continue;
    const cs = getComputedStyle(el);
    const marked = el.classList.contains('coui-control-shadow-rest');
    const shadowed = wearsCast(cs.boxShadow);

    if (materialInjects) {
      const isSurface = el.classList.contains('coui-surface');
      const hasMaterial = wearsMaterial(cs);
      const label = { tag: el.tagName.toLowerCase(),
                      text: (el.innerText || '').trim().slice(0, 24) };

      // A surface inside another surface is *supposed* to compute to
      // no material: the preset suppresses the nested pass so glass
      // does not stack on glass. Checking (C) against it would report
      // that suppression as the defect it exists to prevent.
      let markedAncestor = null;
      for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
        if (a.classList.contains('coui-surface')) { markedAncestor = a; break; }
      }

      // (C) opted in, computes to nothing — wiring missing, or an
      // inline rule on the same element out-ranked the preset.
      if (isSurface && !hasMaterial && !markedAncestor) {
        materialless.push(label);
      }
      // (D) blurs without opting in — the blur came from somewhere
      // other than the preset, which is a second source for it.
      if (!isSurface && hasMaterial) {
        unmarkedMaterial.push(label);
      }
      // (E) a backdrop pass inside a backdrop pass. Cheap to make by
      // accident and visible when it happens: the inner one samples a
      // surface that is already blurred.
      if (hasMaterial) {
        let anc = el.parentElement;
        while (anc && anc !== document.body) {
          if (wearsMaterial(getComputedStyle(anc))) {
            nestedMaterial.push({
              ...label,
              parent: anc.tagName.toLowerCase(),
            });
            break;
          }
          anc = anc.parentElement;
        }
      }
    }

    // (B) carries the opt-in, paints nothing — an inline rule on the
    // same element out-ranked the class.
    if (marked && !shadowed) {
      boxless.push({
        tag: el.tagName.toLowerCase(),
        text: (el.innerText || '').trim().slice(0, 24),
        inlineShadow: (el.getAttribute('style') || '').includes('box-shadow'),
      });
      continue;
    }
    if (!shadowed) continue;

    // (A) paints a cast with nothing to throw it: no fill and no border.
    // "Has a box" is about what paints, not about which property did
    // it. A card image fills its whole surface with an <img> and no
    // background colour, and the cast it throws is the image's — the
    // first pass called that a defect, which would have sent someone to
    // fix a card that looks right.
    const fill = opaque(cs.backgroundColor);
    const painted = Boolean(el.querySelector('img, svg, canvas, video'));
    if (!fill && !anyBorder(cs) && !painted) {
      castless.push({
        tag: el.tagName.toLowerCase(),
        text: (el.innerText || '').trim().slice(0, 24),
        shadow: cs.boxShadow.slice(0, 40),
      });
    }
  }
  return { injects, castComputed, materialInjects, mComputed,
           castless, boxless, materialless, unmarkedMaterial,
           nestedMaterial };
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

// One target reused across every page: a fresh tab per component costs
// more than the whole audit does.
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
let injectingPages = 0;
const report = [];

let materialPages = 0;
let walked = 0;
for (const slug of SLUGS) {
  walked += 1;
  // A silent quarter of an hour reads as a hang. Stream to stderr so
  // piping stdout to a file still gives a report and not a progress log.
  process.stderr.write(`\r  [${walked}/${SLUGS.length}] ${slug.padEnd(24)}`);
  const url = `${BASE}/components/${slug}/`;
  await sendTo('Page.navigate', { url });
  await new Promise((r) => setTimeout(r, 900));

  const out = await sendTo('Runtime.evaluate', {
    expression: PROBE(STYLE, SELFTEST),
    awaitPromise: true,
    returnByValue: true,
  });

  const value = out?.result?.result?.value;
  if (!value) {
    report.push(`  ${slug}: probe returned nothing (page may not exist)`);
    continue;
  }
  if (value.materialInjects) materialPages += 1;

  for (const m of value.materialless) {
    anomalies += 1;
    report.push(
      `  ${slug}: marker with no material — <${m.tag}> "${m.text}"`,
    );
  }
  for (const u of value.unmarkedMaterial) {
    anomalies += 1;
    report.push(
      `  ${slug}: material with no marker — <${u.tag}> "${u.text}"` +
        ' (a blur from outside the preset is a second source for it)',
    );
  }
  for (const n of value.nestedMaterial) {
    anomalies += 1;
    report.push(
      `  ${slug}: material inside material — <${n.tag}> "${n.text}"` +
        ` inside <${n.parent}>`,
    );
  }

  if (!value.injects) continue;
  injectingPages += 1;

  for (const c of value.castless) {
    anomalies += 1;
    report.push(
      `  ${slug}: cast with no box — <${c.tag}> "${c.text}" ${c.shadow}`,
    );
  }
  for (const b of value.boxless) {
    anomalies += 1;
    report.push(
      `  ${slug}: marker with no cast — <${b.tag}> "${b.text}"` +
        (b.inlineShadow ? ' (inline box-shadow out-ranks the class)' : ''),
    );
  }
}

ws.close();
process.stderr.write('\n');

console.log(`surface cast audit — style: ${STYLE}`);
console.log(`  components walked: ${SLUGS.length}`);
console.log(`  pages where the style injects a cast: ${injectingPages}`);
console.log(`  pages where the style injects a material: ${materialPages}`);

if (injectingPages === 0 && materialPages === 0) {
  console.log('\nNo page reported an injecting style — neither a cast nor');
  console.log('a material. That is not a pass: the audit measured nothing.');
  console.log('Check the style id.');
  process.exit(1);
}

if (SELFTEST) {
  const saw = (tag) => report.some((l) => l.includes(tag));
  // A detector only gets to answer about a defect this style can
  // actually produce. `liquidGlass` injects a material and no cast;
  // `neoBrutalism` the reverse. Calling the unexercised half DEAD would
  // be the audit lying about itself — the exact failure self-test
  // exists to prevent — so each half is reported only when its style
  // half is present, and the other is named as not exercised.
  const castDetectors = injectingPages === 0
    ? []
    : [
        ['cast-with-no-box       ', saw('SELFTEST-A')],
        ['marker-with-no-cast    ', saw('SELFTEST-B')],
      ];
  const materialDetectors = materialPages === 0
    ? []
    : [
        ['marker-with-no-material', saw('SELFTEST-C')],
        ['material-with-no-marker', saw('SELFTEST-D')],
        ['material-inside-material', saw('SELFTEST-E')],
      ];
  for (const [name, fires] of [...castDetectors, ...materialDetectors]) {
    console.log(`  self-test — ${name} detector: ${fires ? 'fires' : 'DEAD'}`);
  }
  if (injectingPages === 0) {
    console.log('  self-test — cast detectors: not exercised (this style');
    console.log('    injects no cast; try neoBrutalism)');
  }
  if (materialPages === 0) {
    console.log('  self-test — material detectors: not exercised (this style');
    console.log('    injects no material; try liquidGlass)');
  }
  const all = [...castDetectors, ...materialDetectors];
  // Nothing exercised is not a pass. It is the same shape as a run
  // against a style id that does not exist.
  if (all.length === 0) {
    console.log('\n  no detector was exercised — that proves nothing.');
    process.exit(1);
  }
  process.exit(all.every(([, fires]) => fires) ? 0 : 1);
}

if (anomalies === 0) {
  console.log('  anomalies: none');
  process.exit(0);
}

console.log(`  anomalies: ${anomalies}\n`);
for (const line of report) console.log(line);
process.exit(1);
