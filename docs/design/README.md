# Console design

The visual design of the console and the brand, exported from their Claude Design canvas so they
can be seen without access to it:

- [`api-gateway-console-design.pdf`](api-gateway-console-design.pdf): every screen worth keeping,
  one per page, grouped by section.
- [`screens/`](screens): the same screens as PNG (1536 × 730), used by
  [`../console.md`](../console.md) and the [README](../../README.md).
- [`brand/`](brand): the icon as SVG, and [`brand/images/`](brand/images), the identity image, the
  identity sheet and the app icon as PNG, described in [`../brand.md`](../brand.md).

The intermediate states of the forms (a field with an error, a half-typed search) and the menu of
the language stay only in the canvas.

## Source

One Claude Design canvas, "API Gateway Console": https://claude.ai/artifact/JJsr56r92JUPHJqwdZqFfw.
Its pages are **Screens** (a replica of every screen and state of the console, all driven by one
artboard, `Prototype`, and its props) and **Visual identity** (the identity sheet, the app icon
and the identity image).

## Keeping it up to date

**When a change touches what the console looks like, in that same change: update the canvas,
regenerate this export, update [`../console.md`](../console.md) and compare in the browser what was
built with the canvas until they match** (a new screen, URL or action gets its section there).

1. Download the canvas files into a folder, as the artifact serves them: `project/canvas.json` and
   `project/*.dc.html`.
2. From the root of the repo, with Chrome and ffmpeg installed:

   ```bash
   python docs/design/tool/export.py <that folder>
   ```

   It renders the artboards listed in `SCREENS` and `BRAND` with headless Chrome
   (`tool/support.js` stands in for the canvas runtime: it runs each artboard's `renderVals()`
   with its default props, with animations off) and rewrites `screens/`, `brand/images/` and the
   PDF. A new screen goes into `SCREENS`; a shot of an artboard in another state passes its props
   in the query (`state=error`, `mode=edit`, `menu=true`).
3. Look at the result and commit it with the change.

The SVGs in `brand/` are kept by hand, with the values of the canvas's `AppIcon` artboard.
