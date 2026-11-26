// External, same-origin companion to iconScript(). No fetcher or global DOM
// observer: each hidden light-DOM child owns just its icon's subscription.
// The ratio is resolved by CoreIconStroke in Dart, before CSS/layout scaling.
(() => {
  const tag = 'coui-iconify-stroke';
  if (customElements.get(tag)) return;
  // Hydration may replace the empty companion while retaining its parent.
  // Retain that parent's canonical source without retaining detached nodes.
  const sources = new WeakMap();
  const waiting = new Set();
  let awaitingDefinition = false;

  function waitForIconify(element) {
    waiting.add(element);
    if (awaitingDefinition) return;
    awaitingDefinition = true;
    // One shared promise: a permanently absent Iconify script must not retain
    // a separate whenDefined callback for every detached or rebuilt instance.
    customElements.whenDefined('iconify-icon').then(() => {
      const connected = [...waiting];
      waiting.clear();
      for (const element of connected) {
        if (element.isConnected) element.refresh();
      }
    });
  }

  customElements.define(tag, class extends HTMLElement {
    static get observedAttributes() { return ['ratio', 'prefix']; }

    connectedCallback() {
      const host = this.parentElement;
      if (host?.localName !== 'iconify-icon') return;
      if (this.host !== host) {
        const previous = sources.get(host);
        const ownValue = previous?.written === host.getAttribute('icon');
        this.source = ownValue ? previous.source : null;
        this.written = ownValue ? previous.written : null;
      }
      this.host = host;
      this.observer = new MutationObserver(() => {
        if (host.getAttribute('icon') !== this.written) this.refresh();
      });
      this.observer.observe(host, { attributes: true, attributeFilter: ['icon'] });
      this.refresh();
    }

    disconnectedCallback() {
      waiting.delete(this);
      this.revision++;
      this.abort?.();
      this.abort = null;
      this.observer?.disconnect();
    }

    attributeChangedCallback() {
      if (this.isConnected && this.host) this.refresh();
    }

    restoreSource() {
      if (!this.source || this.host.getAttribute('icon') !== this.written) return;
      this.written = null;
      sources.delete(this.host);
      this.host.setAttribute('icon', this.source);
    }

    refresh() {
      const revision = this.revision = (this.revision || 0) + 1;
      this.abort?.();
      this.abort = null;
      const host = this.host;
      const value = host.getAttribute('icon');
      if (value !== this.written) this.source = value;
      const source = this.source;
      const ratio = Number(this.getAttribute('ratio'));
      if (!source) return;
      if (!Number.isFinite(ratio) || ratio <= 0) {
        this.restoreSource();
        return;
      }

      const ready = () => {
        if (!this.isConnected || this.revision !== revision) return;
        const api = customElements.get('iconify-icon');
        const apply = (data) => {
          if (!data || !this.isConnected || this.revision !== revision) return;
          // Iconify's documented default grid is 16; getIcon() expands it,
          // while a caller-supplied JSON icon can omit it.
          const width = data.width ?? 16;
          if (!(width > 0) || !Number.isFinite(width)) return;
          // Same positive-number rounding as CoreIconStroke.formatNumber.
          const stroke = String(Math.round(ratio * width * 10000) / 10000);
          const body = data.body.replace(/(\s)stroke-width=(["'])2\2/g,
            (_, space, quote) => `${space}stroke-width=${quote}${stroke}${quote}`);
          if (body === data.body) {
            // Size 15 on the standard grid, for example, needs authored 2.
            // A previous normalized copy must not survive that transition.
            this.restoreSource();
            return;
          }
          // Never register a size-specific glyph in the shared Iconify cache.
          // The public icon-data setter retains modes and all customisations.
          this.written = JSON.stringify({ ...data, body });
          sources.set(host, { source, written: this.written });
          host.setAttribute('icon', this.written);
        };

        if (source.trimStart().startsWith('{')) {
          if (this.getAttribute('prefix') !== 'lucide') return;
          try {
            const data = JSON.parse(source);
            if (typeof data.body === 'string') apply(data);
          } catch (_) { /* Iconify owns invalid-icon behavior. */ }
          return;
        }
        if (!/^(?:@[^:]+:)?lucide:[^:]+$/.test(source)) return;
        const data = api.getIcon(source);
        if (data) {
          apply(data);
        } else {
          this.abort = api.loadIcons([source], () => apply(api.getIcon(source)));
        }
      };
      if (customElements.get('iconify-icon')) ready();
      else waitForIconify(this);
    }
  });
})();
