/// <reference types="@figma/plugin-typings" />

// CoUI Icon Export — plugin entry. Routes UI messages to the two commands:
//   1. generate → generate-icons.ts (builds the 36-variant App Icon +
//      Splash Screen matrix from the currently-selected logo component)
//   2. export   → export-icons.ts   (PNG-exports every variant with the
//      safe-zone guide forced hidden, under its real shipped filename)
//
// esbuild --bundle inlines every module into code.js. See src/spec.ts for the
// single source of truth on platform/flavor/safe-zone numbers.

import { generateIconSystem } from './src/generate-icons';
import { exportIconSystem } from './src/export-icons';

figma.showUI(__html__, { width: 420, height: 640, themeColors: true });

figma.ui.onmessage = async (msg: { type: string; bgLight?: string }) => {
  try {
    if (msg.type === 'generate') {
      const log = await generateIconSystem({ bgLight: msg.bgLight || '#0A56DB' });
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'export') {
      const { files, log } = await exportIconSystem();
      // Uint8Array survives postMessage's structured clone as-is.
      figma.ui.postMessage({ type: 'png-files', files, log });
    }
  } catch (e) {
    figma.ui.postMessage({ type: 'error', message: String(e) });
  }
};
