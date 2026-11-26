// Document shell interactions: the menu drawer, code copy, content tabs,
// scroll reveals, and the documentation tools (catalog filter, theme tools,
// preview code).
//
// No duration is written in this file. Each one is read from the
// `--site-duration-*` variables the document root declares
// (lib/components/site_motion.dart), and those point at the CoUI motion
// tokens. So the reduced-motion setting, which zeroes the transition tokens,
// reaches the scripted timing here exactly as it reaches the stylesheet.
//
// The header, the sidebar and the pager need no script: they are links the
// server rendered, and the drawer is a `popover` its button opens natively.
(() => {
  const root = document.documentElement;

  // Read on every use rather than once: the motion variables change while
  // the page is open (the OS reduced-motion setting, the landing's preview).
  const duration = name => {
    const raw = getComputedStyle(root).getPropertyValue(name).trim();
    const value = parseFloat(raw);
    if (!Number.isFinite(value)) return 0;
    return raw.endsWith('ms') ? value : value * 1000;
  };

  // ── Menu drawer ───────────────────────────────────────────────
  // The drawer and the sidebar are one element. Wide, the stylesheet lays it
  // out as a column beside the article; an open popover lives in the top
  // layer and cannot be that column, so widening past the breakpoint closes
  // it. The breakpoint is the stylesheet's.
  const drawer = document.getElementById('site-drawer');
  if (drawer && typeof drawer.hidePopover === 'function' && window.matchMedia) {
    const wide = window.matchMedia('(min-width: 1024px)');
    const closeWhenWide = () => {
      if (wide.matches && drawer.matches(':popover-open')) drawer.hidePopover();
    };
    wide.addEventListener('change', closeWhenWide);
    // A page restored from the back-forward cache comes back as it was left.
    addEventListener('pageshow', () => {
      if (drawer.matches(':popover-open')) drawer.hidePopover();
    });
  }

  // ── Code copy ─────────────────────────────────────────────────
  // The button, its labels and the code are all in the markup the server
  // rendered (`DocsCode`): the copied text is the block's own `<code>`, and
  // the confirmation is the button's `data-copied-label`. The label returns
  // after the hold time — a display duration, which reduced motion keeps.
  const copyTimers = new WeakMap();
  const leaf = element => {
    let node = element;
    while (node.childElementCount === 1) node = node.firstElementChild;
    return node;
  };
  const confirmCopy = (button, key) => {
    const label = button.querySelector('[data-copy-label]');
    if (!label) return;
    const text = leaf(label);
    const rest = button.dataset.copyLabel;
    text.textContent = button.dataset[key] || rest;
    clearTimeout(copyTimers.get(button));
    const wait = duration('--site-duration-hold');
    copyTimers.set(button, setTimeout(() => {
      text.textContent = rest;
    }, wait));
  };
  document.addEventListener('click', event => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const button = target.closest('[data-docs-copy]');
    if (!button) return;
    const code = button.closest('[data-docs-code]')?.querySelector('code');
    if (!code || !navigator.clipboard) {
      confirmCopy(button, 'failedLabel');
      return;
    }
    navigator.clipboard.writeText(code.textContent).then(
      () => confirmCopy(button, 'copiedLabel'),
      () => confirmCopy(button, 'failedLabel'),
    );
  });

  // ── Content tabs ──────────────────────────────────────────────
  // The server renders the whole pattern (`DocsTabs`): the tab list, which
  // tab is selected (`aria-selected`, and the one tab stop) and which panel
  // shows (`hidden`). Choosing a tab rewrites those attributes; nothing here
  // draws.
  //
  // Groups that share a `data-group` change together, and the choice is
  // carried to the next page: a reader who picks one platform reads the
  // whole site in it.
  const tabSelector = '[data-docs-tabs] > [role="tablist"] > [role="tab"]';
  const tabGroups = () => Array.from(document.querySelectorAll('[data-docs-tabs]'));
  const tabsIn = group => Array.from(group.querySelectorAll(':scope > [role="tablist"] > [role="tab"]'));
  const tabStorageKey = name => `coui-docs:tabs:${name}`;
  const focusable = 'a[href], button, input, select, textarea, summary, [tabindex]:not([tabindex="-1"])';

  // Shows the tab of `value` in `group`. A group that has no such tab keeps
  // what it shows.
  const showTab = (group, value) => {
    const tabs = tabsIn(group);
    const chosen = tabs.find(tab => tab.dataset.value === value);
    if (!chosen) return;
    for (const tab of tabs) {
      tab.setAttribute('aria-selected', String(tab === chosen));
      tab.tabIndex = tab === chosen ? 0 : -1;
    }
    let shown = false;
    for (const panel of group.querySelectorAll(':scope > [role="tabpanel"]')) {
      // Values are distinct within a group; were two the same, one panel
      // shows, as one tab is selected.
      const show = !shown && panel.dataset.value === value;
      panel.hidden = !show;
      shown = shown || show;
    }
  };

  // A panel with nothing to tab to is itself the stop after its tab list, so
  // a keyboard reader can reach what the tab revealed.
  const markPanels = group => {
    for (const panel of group.querySelectorAll(':scope > [role="tabpanel"]')) {
      if (panel.querySelector(focusable)) panel.removeAttribute('tabindex');
      else panel.tabIndex = 0;
    }
  };

  const chooseTab = tab => {
    const group = tab.closest('[data-docs-tabs]');
    const value = tab.dataset.value;
    const name = group.dataset.group;
    const before = tab.getBoundingClientRect().top;
    showTab(group, value);
    if (!name) return;
    for (const other of tabGroups()) {
      if (other !== group && other.dataset.group === name) showTab(other, value);
    }
    try {
      localStorage.setItem(tabStorageKey(name), value);
    } catch (_) {
      // Storage is a convenience; the choice still holds for this page.
    }
    // Groups above the one that was pressed changed height with it: put the
    // pressed tab back under the pointer.
    const moved = tab.getBoundingClientRect().top - before;
    if (moved) scrollBy({ top: moved, behavior: 'instant' });
  };

  for (const group of tabGroups()) {
    const name = group.dataset.group;
    if (name) {
      let stored = null;
      try {
        stored = localStorage.getItem(tabStorageKey(name));
      } catch (_) {
        // No storage: the server's choice stands.
      }
      if (stored !== null) showTab(group, stored);
    }
    markPanels(group);
  }

  document.addEventListener('click', event => {
    const tab = event.target instanceof Element ? event.target.closest(tabSelector) : null;
    if (tab) chooseTab(tab);
  });

  // Arrows, Home and End move focus along the tab list without choosing;
  // Enter and Space choose, as the button's own click. The CoUI `Tabs`
  // component moves the same way.
  //
  // Heard on the window, in the capture phase. An embedded Flutter preview
  // listens there as well and stops a key it has handled from travelling any
  // further — arrows are its scroll keys — so a listener lower in the tree
  // never hears an arrow the preview took. Listeners on the window itself
  // all run.
  addEventListener('keydown', event => {
    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
    const tab = event.target instanceof Element ? event.target.closest(tabSelector) : null;
    if (!tab) return;
    const tabs = tabsIn(tab.closest('[data-docs-tabs]'));
    const forward = getComputedStyle(tab).direction === 'rtl' ? 'ArrowLeft' : 'ArrowRight';
    const backward = forward === 'ArrowRight' ? 'ArrowLeft' : 'ArrowRight';
    const at = tabs.indexOf(tab);
    const to = {
      [forward]: tabs[(at + 1) % tabs.length],
      [backward]: tabs[(at - 1 + tabs.length) % tabs.length],
      Home: tabs[0],
      End: tabs[tabs.length - 1],
    }[event.key];
    if (!to) return;
    event.preventDefault();
    to.focus();
  }, true);

  // ── Scroll reveals ────────────────────────────────────────────
  // A group (`[data-docs-reveal]`) is hidden only once this script has taken
  // it (`.is-armed`), and it takes only the groups still below the fold. A
  // group already on screen, a document without this script, and a browser
  // without the observer never have a hidden moment.
  const groups = Array.from(document.querySelectorAll('[data-docs-reveal]'));
  if (groups.length && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add('is-in');
        observer.unobserve(entry.target);
      }
    }, { rootMargin: '0px 0px -10% 0px' });
    for (const group of groups) {
      if (group.getBoundingClientRect().top < innerHeight) continue;
      group.classList.add('is-armed');
      observer.observe(group);
    }
    // Printing photographs the moment a transition starts, so a group still
    // waiting would print blank: release them all first.
    addEventListener('beforeprint', () => {
      for (const group of groups) group.classList.remove('is-armed');
    });
  }
})();

(() => {
  const catalog = document.querySelector('.showcase');
  const queryControl = catalog?.querySelector('[data-catalog-query]');
  const queryInput = queryControl?.matches('input') ? queryControl : queryControl?.querySelector('input');
  let category = 'all';
  const normalized = value => value.toLowerCase().replace(/[\s_-]+/g, '');
  const filterCatalog = () => {
    if (!catalog) return;
    const query = normalized(queryInput?.value || '');
    let total = 0;
    catalog.querySelectorAll('[data-catalog-group]').forEach(group => {
      const categoryMatches = category === 'all' || category === group.dataset.catalogGroup;
      let visible = 0;
      group.querySelectorAll('[data-catalog-search]').forEach(card => {
        const parentMatches = categoryMatches && normalized(card.dataset.catalogSearch).includes(query);
        let matches = Number(parentMatches);
        card.querySelectorAll('[data-catalog-member]').forEach(member => {
          const memberMatches = categoryMatches && normalized(member.dataset.catalogMember).includes(query);
          member.parentElement.hidden = query !== '' && !parentMatches && !memberMatches;
          matches += Number(memberMatches);
        });
        card.hidden = matches === 0;
        visible += matches;
      });
      group.querySelectorAll('[data-catalog-utility-group]').forEach(subgroup => {
        subgroup.hidden = !subgroup.querySelector('[data-catalog-search]:not([hidden])');
      });
      group.hidden = visible === 0;
      total += visible;
    });
    catalog.querySelectorAll('[data-catalog-category]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.catalogCategory === category)));
    const filtering = query !== '' || category !== 'all';
    const count = catalog.querySelector('[data-catalog-count]');
    count.textContent = filtering ? `${total}개 컴포넌트` : count.dataset.catalogCount;
    catalog.querySelector('[data-catalog-reset]').hidden = !filtering;
    catalog.querySelector('[data-catalog-empty]').hidden = total !== 0;
  };
  queryInput?.addEventListener('input', filterCatalog);
  const themeTools = document.querySelector('[data-theme-tools]');
  const updateThemeCode = () => {
    if (!themeTools) return;
    const style = document.documentElement.getAttribute('data-coui-style') || 'defaultStyle';
    const mode = document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
    const platform = themeTools.dataset.themePlatform;
    const key = `${style}|${mode}|${platform}`;
    const template = Array.from(themeTools.querySelectorAll('template')).find(item => item.dataset.themeSnippet === key);
    if (template) themeTools.querySelector('[data-theme-code]').textContent = template.content.querySelector('pre').textContent;
    themeTools.querySelectorAll('[data-theme-platform-option]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.themePlatformOption === platform)));
  };
  if (themeTools) {
    new MutationObserver(updateThemeCode).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme', 'data-coui-style'] });
    updateThemeCode();
  }
  const copyTheme = async (value, success) => {
    const status = themeTools.querySelector('[data-theme-status]');
    try {
      await navigator.clipboard.writeText(value);
      status.textContent = success;
    } catch (_) {
      status.textContent = '복사하지 못했습니다. 브라우저 권한을 확인하거나 표시된 코드를 직접 복사해 주세요.';
    }
  };
  document.addEventListener('click', event => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const categoryButton = target.closest('[data-catalog-category]');
    if (categoryButton) {
      category = categoryButton.dataset.catalogCategory;
      filterCatalog();
    }
    if (target.closest('[data-catalog-reset]')) {
      category = 'all';
      if (queryInput) queryInput.value = '';
      filterCatalog();
    }
    const platformButton = target.closest('[data-theme-platform-option]');
    if (platformButton) {
      themeTools.dataset.themePlatform = platformButton.dataset.themePlatformOption;
      updateThemeCode();
    }
    if (target.closest('[data-theme-copy]')) copyTheme(themeTools.querySelector('[data-theme-code]').textContent, '선택한 플랫폼의 설정 코드를 복사했습니다.');
    if (target.closest('[data-theme-share]')) {
      const url = new URL(location.href);
      url.searchParams.set('style', document.documentElement.getAttribute('data-coui-style') || 'defaultStyle');
      url.searchParams.set('theme', document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'light');
      copyTheme(url.href, '현재 스타일과 밝기 조합의 링크를 복사했습니다.');
    }
    const codeTab = target.closest('.preview-code-tab');
    if (codeTab) {
      const container = codeTab.closest('.preview-code');
      container.querySelectorAll('.preview-code-tab').forEach(button => {
        const active = button === codeTab;
        button.classList.toggle('preview-code-tab--active', active);
        button.setAttribute('aria-pressed', String(active));
      });
      container.querySelectorAll('.preview-code-panel').forEach(panel => panel.classList.toggle('preview-code-panel--active', panel.dataset.panel === codeTab.dataset.tab));
      container.querySelector('.preview-copy-btn').dataset.code = container.querySelector('.preview-code-panel--active code').textContent;
    }
    const copyButton = target.closest('.preview-copy-btn');
    if (copyButton) {
      navigator.clipboard?.writeText(copyButton.dataset.code).then(() => {
        copyButton.textContent = '복사 완료';
      }).catch(() => { copyButton.textContent = '복사 실패'; });
    }
  });
  addEventListener('hashchange', () => {
    if (!catalog) return;
    const heading = document.getElementById(decodeURIComponent(location.hash.slice(1)));
    const group = heading?.closest('[data-catalog-group]');
    if (!group) return;
    category = 'all';
    if (queryInput) queryInput.value = '';
    filterCatalog();
    heading.scrollIntoView({ block: 'start' });
  });
  // ── Anatomy markers ───────────────────────────────────────────
  // The server renders the component and names its parts in order
  // (`data-docs-anatomy`). Where a part sits depends on the label's width
  // and the font, so the numbered markers are made and placed here against
  // the rendered parts: the container's marker on its left (read first,
  // where the eye starts), the slots'
  // markers above them. Without the script there are no markers — the
  // numbered legend still names every part.
  // A component may write its scoped `<style>` (or a script) before its
  // visible markup; that text is not a label, and a marker placed on it
  // lands outside the stage. Only drawn elements name a part.
  // `docs_site/test/components/anatomy_parts_test.dart` reads this list
  // and resolves every page's parts the same way.
  const anatomySkippedTags = ['STYLE', 'SCRIPT', 'TEMPLATE', 'NOSCRIPT'];
  const anatomyDrawn = el =>
    !anatomySkippedTags.some(tag => el.closest(tag.toLowerCase())) && el.getClientRects().length > 0;
  const anatomyLabel = root => {
    for (const el of root.querySelectorAll('*')) {
      if (!anatomyDrawn(el)) continue;
      if (el.querySelector('svg') || el.tagName === 'svg' || el.closest('svg')) continue;
      if (el.children.length === 0 && el.textContent.trim()) return el;
    }
    return null;
  };
  // Named parts a marker can point at; anything else is a CSS selector
  // inside the rendered component.
  const anatomyPart = (root, what) => {
    const icons = [...root.querySelectorAll('svg')].filter(anatomyDrawn);
    switch (what) {
      case 'container': return root;
      case 'leading': return icons.length > 0 ? icons[0] : null;
      case 'label': return anatomyLabel(root);
      case 'trailing': return icons.length > 1 ? icons[icons.length - 1] : null;
      default:
        try { return what ? root.querySelector(what) : null; } catch { return null; }
    }
  };
  const placeAnatomy = () => {
    for (const stage of document.querySelectorAll('[data-docs-anatomy]')) {
      const root = stage.querySelector('.docs-anatomy-target')?.firstElementChild;
      if (!root) continue;
      const specs = stage.dataset.docsAnatomy.split(';').map(spec => {
        const at = spec.lastIndexOf('@');
        const what = at < 0 ? spec : spec.slice(0, at);
        const side = (at < 0 ? '' : spec.slice(at + 1)) || (what === 'container' ? 'left' : 'top');
        return { what, side };
      });
      if (!stage.querySelector('.docs-anatomy-marker')) {
        specs.forEach((spec, index) => {
          if (!spec.what) return;
          const marker = document.createElement('span');
          marker.className = 'docs-anatomy-marker';
          marker.dataset.index = String(index);
          marker.setAttribute('aria-hidden', 'true');
          marker.textContent = String(index + 1);
          stage.append(marker);
        });
      }
      const box = stage.getBoundingClientRect();
      for (const marker of stage.querySelectorAll('.docs-anatomy-marker')) {
        const spec = specs[Number(marker.dataset.index)];
        const el = anatomyPart(root, spec.what);
        marker.hidden = !el;
        if (!el) continue;
        const r = el.getBoundingClientRect();
        marker.classList.remove('is-top', 'is-left', 'is-right');
        marker.classList.add(`is-${spec.side}`);
        const [x, y] = {
          top: [r.left + r.width / 2, r.top - 24],
          left: [r.left - 24, r.top + r.height / 2],
          right: [r.right + 24, r.top + r.height / 2],
        }[spec.side] || [r.left + r.width / 2, r.top - 24];
        marker.style.left = `${x - box.left}px`;
        marker.style.top = `${y - box.top}px`;
      }
    }
  };
  placeAnatomy();
  addEventListener('resize', placeAnatomy);
  document.fonts?.ready.then(placeAnatomy);
})();

(() => {
  const timeline = document.querySelector('[data-release-timeline]');
  if (!timeline) return;
  const history = timeline.querySelector('#release-history');
  const filters = [...timeline.querySelectorAll('[data-release-filter]')];

  timeline.addEventListener('click', event => {
    const filter = event.target instanceof Element && event.target.closest('[data-release-filter]');
    if (!filter) return;
    const kind = filter.dataset.releaseFilter;
    filters.forEach(button => button.setAttribute('aria-pressed', String(button === filter)));

    let releases = 0;
    for (const entry of timeline.querySelectorAll('[data-release-entry]')) {
      for (const section of entry.querySelectorAll('[data-release-type]')) {
        section.hidden = kind !== 'all' && section.dataset.releaseType !== kind;
      }
      for (const pkg of entry.querySelectorAll('[data-release-package]')) {
        pkg.hidden = kind !== 'all' && !pkg.querySelector('[data-release-type]:not([hidden])');
      }
      entry.hidden = !entry.querySelector('[data-release-package]:not([hidden])');
      if (!entry.hidden) releases++;
    }
    if (history) {
      history.hidden = !history.querySelector('[data-release-entry]:not([hidden])');
      if (kind !== 'all') history.open = !history.hidden;
    }

    for (const link of document.querySelectorAll('[data-toc] a[href*="#"]')) {
      const target = document.getElementById(link.hash.slice(1));
      if (target) link.closest('li').hidden = target.hidden;
    }
    timeline.querySelector('[data-release-empty]').hidden = releases !== 0;
    window.dispatchEvent(new Event('resize'));
  });
})();
