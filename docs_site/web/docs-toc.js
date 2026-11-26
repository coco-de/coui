// "On this page" reading position.
//
// Contract (all attributes are written by ManualLayout):
//   [data-toc]                one table of contents. Its `a[href*="#"]` point
//                             at the headings it tracks.
//   [data-toc-line="0.35"]    reading line, as a fraction of the viewport
//                             height. Default 0.35.
//
// Output: the active link gets `.is-active` and `aria-current="location"`. The
// stylesheet grows that link's marker; this file only names which link it is.
// Active is the last heading whose top has passed the reading line, none before
// the first one does, and the last heading once the page cannot scroll further
// (a closing section is often too short to ever reach the line).
//
// A link click scrolls in place instead of navigating. Its href is the page's
// own path plus a fragment, and a path without the trailing slash the site is
// served under is a different document: following it reloads the page.
//
// The scroll is smooth unless the reader asked for less motion; the browser
// times it, so no duration is written here.
(() => {
  'use strict';

  const rails = Array.from(document.querySelectorAll('[data-toc]'));
  if (!rails.length) return;

  // Motion variables the document root declares (site_motion.dart).
  const duration = (name) => {
    const raw = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    const value = parseFloat(raw);
    if (!Number.isFinite(value)) return 0;
    return raw.endsWith('ms') ? value : value * 1000;
  };

  const reduceMotion = window.matchMedia ? window.matchMedia('(prefers-reduced-motion: reduce)') : null;
  const behavior = () => (reduceMotion && reduceMotion.matches ? 'auto' : 'smooth');

  // How the list follows the page. While the page is still loading (a deep link
  // lands mid-article) it jumps rather than visibly scrolling.
  const followBehavior = () => (document.readyState === 'complete' ? behavior() : 'auto');

  // The scroll box around a link when the list is taller than the viewport.
  const scrollBoxOf = (el) => {
    for (let p = el.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
      const overflowY = getComputedStyle(p).overflowY;
      if ((overflowY === 'auto' || overflowY === 'scroll') && p.scrollHeight > p.clientHeight) return p;
    }
    return null;
  };

  // Keep the active link inside a scrolling list, so the marker is never
  // somewhere the reader cannot see it.
  const reveal = (link) => {
    const box = scrollBoxOf(link);
    if (!box) return;
    const edge = 16;
    const boxRect = box.getBoundingClientRect();
    const rect = link.getBoundingClientRect();
    if (!rect.height) return; // the other list of the pair, hidden at this width
    const above = boxRect.top + edge - rect.top;
    const below = rect.bottom - (boxRect.bottom - edge);
    if (above > 0) box.scrollBy({ top: -above, behavior: followBehavior() });
    else if (below > 0) box.scrollBy({ top: below, behavior: followBehavior() });
  };

  // Back above the first heading nothing is active, and a list left scrolled
  // down would start in the middle: bring it back to its beginning.
  const rewind = (link) => {
    const box = scrollBoxOf(link);
    if (box && box.scrollTop) box.scrollTo({ top: 0, behavior: followBehavior() });
  };

  for (const rail of rails) {
    const pairs = Array.from(rail.querySelectorAll('a[href*="#"]'))
      .map((link) => {
        // `hash` is read off the resolved URL: the document has <base href="/">.
        let id = '';
        try {
          id = decodeURIComponent((link.hash || '').slice(1));
        } catch (_) {
          /* a malformed %-escape: this link is left alone */
        }
        const target = id ? document.getElementById(id) : null;
        return target ? { link, target } : null;
      })
      .filter(Boolean);
    if (!pairs.length) continue;

    const ratio = parseFloat(rail.dataset.tocLine);
    const lineRatio = Number.isFinite(ratio) ? ratio : 0.35;

    let current = -2;
    const setActive = (index) => {
      if (index === current) return;
      if (current >= 0) {
        pairs[current].link.classList.remove('is-active');
        pairs[current].link.removeAttribute('aria-current');
      }
      current = index;
      if (index >= 0) {
        const { link } = pairs[index];
        link.classList.add('is-active');
        link.setAttribute('aria-current', 'location');
        reveal(link);
      } else {
        rewind(pairs[0].link);
      }
    };

    // A click names the section the reader wants, so the clicked entry keeps
    // the marker instead of handing it to whichever heading sits inside the
    // reading line when the scroll ends (a heading is often followed at once by
    // its first sub-heading). The hold has two stages. While the smooth scroll
    // runs it passes every heading on the way, and showing each in turn would
    // flicker half-grown markers; the reader's own input ends this stage at
    // once. After it settles, the hold lasts until the reader scrolls on.
    let held = null; // { y }: where the scroll settled, null while it still runs
    let settle = 0;
    // "Settled" is the page holding still for one short transition's time.
    const settleSoon = () => {
      clearTimeout(settle);
      const wait = duration('--site-duration-fast') || duration('--site-duration-hold') / 10;
      settle = setTimeout(() => {
        if (held) held.y = window.scrollY;
      }, wait);
    };
    const hold = () => {
      held = { y: null };
      settleSoon();
    };
    const letGo = () => {
      held = null;
      clearTimeout(settle);
      update();
    };

    const update = () => {
      const vh = window.innerHeight;
      // A heading that was just scrolled to rests at its scroll-margin, so the
      // line never sits above that: a short viewport must not leave the clicked
      // heading short of the line.
      const margin = parseFloat(getComputedStyle(pairs[0].target).scrollMarginTop) || 0;
      const line = Math.max(vh * lineRatio, margin + 8);

      if (held && held.y !== null && Math.abs(window.scrollY - held.y) > 1) held = null;
      if (!held) {
        let index = -1;
        for (let k = 0; k < pairs.length; k++) {
          if (pairs[k].target.hidden) continue;
          if (pairs[k].target.getBoundingClientRect().top <= line) index = k;
          else break;
        }
        const doc = document.scrollingElement || document.documentElement;
        if (vh + window.scrollY >= doc.scrollHeight - 4) {
          index = pairs.findLastIndex(pair => !pair.target.hidden);
        }
        setActive(index);
      }
    };

    let ticking = false;
    const schedule = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        ticking = false;
        update();
      });
    };
    window.addEventListener(
      'scroll',
      () => {
        if (held && held.y === null) settleSoon();
        schedule();
      },
      { passive: true },
    );
    for (const type of ['wheel', 'touchstart', 'keydown']) {
      window.addEventListener(type, () => held && held.y === null && letGo(), { passive: true });
    }
    window.addEventListener('resize', schedule);
    window.addEventListener('load', schedule);
    window.addEventListener('pageshow', schedule);
    // Where the headings sit changes after load (embedded previews) without a
    // scroll to notice it.
    if (window.ResizeObserver) new ResizeObserver(schedule).observe(document.body);
    update();

    for (const { link, target } of pairs) {
      link.addEventListener('click', (event) => {
        if (event.defaultPrevented || event.button !== 0) return;
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        event.preventDefault();

        setActive(pairs.findIndex((pair) => pair.target === target));
        hold();
        target.scrollIntoView({ behavior: behavior(), block: 'start' });
        try {
          // Replace, not push: a reader going back wants the page before this
          // one, not every section they clicked past.
          history.replaceState(history.state, '', location.pathname + location.search + '#' + encodeURIComponent(target.id));
        } catch (_) {
          /* file:// and the like: the scroll is enough */
        }
        // The next Tab starts at the heading, as a native fragment jump would.
        if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
        target.focus({ preventScroll: true });
      });
    }
  }
})();
