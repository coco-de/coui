// Canvas-only parts the designer approved, by component, with the note the
// component's description carries. The parts have no code API: the code
// draws the same picture through data (Pagination's page) or composition
// (TextBlock's elements), so the canvas names them for the designer alone.
// The builder writes the note when it draws the component, and Generate
// keeps it after the docs description it writes over the builder's.
export const kCanvasOnlyApiNotes: Record<string, string> = {
  Countdown: 'Figma 전용, 코드 API 없음',
  Pagination:
    'Variant=compact 는 Figma 전용, 코드 API 없음 — 코드는 현재 페이지와 폭에 따라 보이는 페이지를 스스로 줄인다.',
  TextBlock:
    'Show title · Title · Show paragraph · Paragraph · Show quote · Show code 는 Figma 전용, 코드 API 없음 — 코드의 TextBlock 은 요소 하나를 그린다.',
};
