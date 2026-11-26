// Landing interactions: scroll reveals, the rolling count, the code tabs,
// copy, the swatches and the layer list.
//
// No duration or curve is written in this file. Each one is read from the
// `--site-duration-*` / `--site-easing-*` variables the landing stylesheet
// declares (lib/components/site_motion.dart), and those point at the CoUI
// motion tokens. So the reduced-motion setting, which zeroes the transition
// tokens, reaches the scripted motion here exactly as it reaches the CSS —
// a count that would have rolled lands on its number at once.
(() => {
  const landing = document.querySelector('.landing');
  if (!landing) return;
  const root = document.documentElement;

  try {
    start();
    // Tells the gate in <head> that reveals are being driven. Without this
    // mark it lifts the hidden state on load, so a failure here shows the
    // page instead of leaving it blank.
    window.__siteLanding = true;
  } catch (error) {
    root.removeAttribute('data-site-motion');
    throw error;
  }

  function start() {
    const computed = getComputedStyle(landing);

    // ── Motion tokens ───────────────────────────────────────────
    // Read on every use rather than once: the reduced-motion preview on
    // this page changes them while the page is open.
    const duration = name => {
      const raw = computed.getPropertyValue(name).trim();
      const value = parseFloat(raw);
      if (!Number.isFinite(value)) return 0;
      return raw.endsWith('ms') ? value : value * 1000;
    };

    // `cubic-bezier(x1, y1, x2, y2)` as a progress function. Anything else
    // (`linear`) is the identity.
    const easing = name => {
      const points = /cubic-bezier\(([^)]+)\)/.exec(computed.getPropertyValue(name));
      if (!points) return progress => progress;
      const [x1, y1, x2, y2] = points[1].split(',').map(Number);
      const axis = (a, b) => t => ((1 - 3 * b + 3 * a) * t + (3 * b - 6 * a)) * t * t + 3 * a * t;
      const x = axis(x1, x2);
      const y = axis(y1, y2);
      return progress => {
        // x(t) rises monotonically on [0, 1], so bisect for the t whose x
        // is `progress`.
        let low = 0;
        let high = 1;
        let t = progress;
        for (let pass = 0; pass < 20; pass++) {
          const at = x(t);
          if (Math.abs(at - progress) < 1e-4) break;
          if (at < progress) low = t;
          else high = t;
          t = (low + high) / 2;
        }
        return y(t);
      };
    };

    // The innermost element holding the text. CoUI `Text` wraps its string
    // in a styled span; writing to the wrapper would drop that style.
    const leaf = element => {
      let node = element;
      while (node.childElementCount === 1) node = node.firstElementChild;
      return node;
    };

    // ── Rolling number ──────────────────────────────────────────
    // One roll per element: a new target starts from wherever the last
    // roll had reached.
    const rolls = new WeakMap();
    const roll = (element, to, tail, time, curve) => {
      const state = rolls.get(element) ?? { value: to };
      rolls.set(element, state);
      cancelAnimationFrame(state.frame);
      const from = state.value;
      const show = value => {
        const whole = Math.round(value);
        // The tail ("+") belongs to the resting number, not to the digits
        // on the way there.
        element.textContent = whole + (whole === to ? tail : '');
        state.value = value;
      };
      const total = duration(time);
      if (total === 0 || from === to) {
        show(to);
        return;
      }
      const ease = easing(curve);
      const began = performance.now();
      const step = now => {
        const progress = Math.min(1, (now - began) / total);
        show(from + (to - from) * ease(progress));
        if (progress < 1) state.frame = requestAnimationFrame(step);
      };
      state.frame = requestAnimationFrame(step);
    };

    const count = landing.querySelector('[data-count-to]');
    const total = Number(count?.dataset.countTo);
    const tail = count?.dataset.countSuffix ?? '';
    const chips = landing.querySelector('[data-count-chips]');
    if (count && chips) {
      // Pointing at a category shows that category's own count; leaving
      // the list returns to the total.
      const peek = event => {
        const chip = event.target.closest('[data-count-chip]');
        if (chip) roll(count, Number(chip.dataset.countChip), '', '--site-duration-normal', '--site-easing-move');
      };
      const rest = () => roll(count, total, tail, '--site-duration-normal', '--site-easing-move');
      chips.addEventListener('pointerover', peek);
      chips.addEventListener('focusin', peek);
      chips.addEventListener('pointerleave', rest);
      chips.addEventListener('focusout', event => {
        if (!chips.contains(event.relatedTarget)) rest();
      });
    }

    // The count arrives when the number itself comes into view, not when its
    // tile does: a tile's top edge is on screen well before the number in
    // its middle. Until then it waits at zero. The page states the total as
    // text for assistive technology and keeps this number out of its reach,
    // so nothing is misread while it waits or while it shows a category.
    // With no transition time there is nothing to roll, and the number the
    // server wrote stays.
    if (count && 'IntersectionObserver' in window && duration('--site-duration-slow') > 0) {
      rolls.set(count, { value: 0 });
      count.textContent = '0';
      const arrival = new IntersectionObserver(
        entries => {
          if (!entries.some(entry => entry.isIntersecting)) return;
          arrival.disconnect();
          roll(count, total, tail, '--site-duration-slow', '--site-easing-enter');
        },
        { threshold: 0.5 },
      );
      arrival.observe(count);
    }

    // ── Reveal on scroll ────────────────────────────────────────
    const reveal = element => {
      element.classList.add('is-revealed');
      // Once it has arrived it stops being a reveal target, so its place
      // in the sequence no longer delays anything else that transitions
      // on it. A sequence ends within the slow duration by construction.
      const settle = () => {
        element.removeAttribute('data-reveal');
        element.classList.remove('is-revealed');
        element.style.removeProperty('--i');
      };
      const wait = duration('--site-duration-slow');
      if (wait === 0) settle();
      else setTimeout(settle, wait);
    };

    const targets = landing.querySelectorAll('[data-reveal]');
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver(
        entries => {
          for (const entry of entries) {
            if (!entry.isIntersecting) continue;
            observer.unobserve(entry.target);
            reveal(entry.target);
          }
        },
        { threshold: 0.15 },
      );
      targets.forEach(target => observer.observe(target));
    } else {
      targets.forEach(reveal);
    }

    // ── Print ───────────────────────────────────────────────────
    // A printed page is taken as it stands: nothing on it can wait for a
    // scroll that will not come. So the targets still waiting stop being
    // targets — that drops their hidden state and their transition
    // together, and a transition left in place would be printed at its
    // first frame, which is the hidden one. The count takes its resting
    // number.
    addEventListener('beforeprint', () => {
      root.removeAttribute('data-site-motion');
      for (const target of landing.querySelectorAll('[data-reveal]')) {
        target.removeAttribute('data-reveal');
        target.style.removeProperty('--i');
      }
      if (!count) return;
      cancelAnimationFrame(rolls.get(count)?.frame);
      rolls.set(count, { value: total });
      count.textContent = total + tail;
    });

    // ── Code tabs ───────────────────────────────────────────────
    for (const tile of landing.querySelectorAll('[data-code-tile]')) {
      const list = tile.querySelector('[role="tablist"]');
      const tabs = [...list.querySelectorAll('[role="tab"]')];
      const panelOf = tab => document.getElementById(tab.getAttribute('aria-controls'));
      let current = tabs.find(tab => tab.getAttribute('aria-selected') === 'true') ?? tabs[0];

      // The pill behind the selected tab takes its box from the tab.
      const place = () => {
        list.style.setProperty('--tab-x', `${current.offsetLeft}px`);
        list.style.setProperty('--tab-w', `${current.offsetWidth}px`);
      };
      const select = tab => {
        current = tab;
        for (const each of tabs) {
          const selected = each === tab;
          each.setAttribute('aria-selected', String(selected));
          each.tabIndex = selected ? 0 : -1;
          panelOf(each).hidden = !selected;
        }
        place();
      };

      list.addEventListener('click', event => {
        const tab = event.target.closest('[role="tab"]');
        if (tab) select(tab);
      });
      list.addEventListener('keydown', event => {
        const move = { ArrowRight: 1, ArrowLeft: -1 }[event.key];
        if (!move) return;
        event.preventDefault();
        const next = tabs[(tabs.indexOf(current) + move + tabs.length) % tabs.length];
        select(next);
        next.focus();
      });

      place();
      // The tab's box moves when the web font arrives or the text scales.
      new ResizeObserver(place).observe(list);
      // From here the pill is the selected state; before it, the tab paints
      // its own.
      tile.dataset.ready = '';
    }

    // ── Copy ────────────────────────────────────────────────────
    landing.addEventListener('click', async event => {
      const button = event.target.closest('[data-code-copy]');
      if (!button) return;
      const tile = button.closest('[data-code-tile]');
      const label = leaf(button.querySelector('[data-code-copy-label]'));
      let outcome = 'copied';
      try {
        await navigator.clipboard.writeText(tile.querySelector('[role="tabpanel"]:not([hidden])').textContent.trimEnd());
      } catch {
        outcome = 'failed';
      }
      const status = tile.querySelector('[data-code-status]');
      label.textContent = button.dataset[outcome];
      status.textContent = button.dataset[outcome];
      button.dataset.copyState = outcome;
      clearTimeout(button.restoreTimer);
      // How long the answer stays is display time, not a transition — it
      // is kept under reduced motion.
      button.restoreTimer = setTimeout(() => {
        label.textContent = button.dataset.idle;
        // Emptied so the same answer is announced again next time: a live
        // region speaks changes, and identical text is not one.
        status.textContent = '';
        delete button.dataset.copyState;
      }, duration('--site-duration-hold'));
    });

    // ── Swatches ────────────────────────────────────────────────
    for (const group of landing.querySelectorAll('[data-swatches]')) {
      const caption = leaf(group.closest('.site-tile').querySelector('[data-swatch-caption]'));
      const idle = caption.textContent;
      const show = swatch => {
        for (const each of group.children) each.toggleAttribute('data-active', each === swatch);
        caption.textContent = swatch ? swatch.dataset.swatch : idle;
      };
      group.addEventListener('pointerover', event => {
        const swatch = event.target.closest('[data-swatch]');
        if (swatch) show(swatch);
      });
      group.addEventListener('pointerleave', () => show(null));
    }

    // ── Layers ↔ response ───────────────────────────────────────
    const layers = landing.querySelector('[data-layers]');
    if (layers) {
      const rows = [...layers.querySelectorAll('[data-layer]')];
      const fields = landing.querySelectorAll('[data-mcp-field]');
      const select = row => {
        for (const each of rows) each.toggleAttribute('data-active', each === row);
        layers.style.setProperty('--layer-y', `${row.offsetTop}px`);
        layers.style.setProperty('--layer-h', `${row.offsetHeight}px`);
        for (const field of fields) {
          const value = row.dataset[field.dataset.mcpField];
          if (field.textContent === value) continue;
          field.textContent = value;
          // Restart the highlight: the class has to leave and come back
          // across a style flush for the animation to run again.
          field.classList.remove('is-changed');
          void field.offsetWidth;
          field.classList.add('is-changed');
        }
      };
      const pick = event => {
        const row = event.target.closest('[data-layer]');
        if (row && !row.hasAttribute('data-active')) select(row);
      };
      layers.addEventListener('pointerover', pick);
      layers.addEventListener('focusin', pick);
      select(rows.find(row => row.hasAttribute('data-active')) ?? rows[0]);
      new ResizeObserver(() => select(rows.find(row => row.hasAttribute('data-active')))).observe(layers);
      layers.dataset.ready = '';
    }
  }
})();
