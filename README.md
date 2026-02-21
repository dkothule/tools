# md2pdf

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Convert Markdown to PDF with high-resolution Mermaid diagrams (SVG embedded in PDF output).

## Why this tool

- Mermaid diagrams are rendered as SVG for PDF output by default, so diagrams stay crisp at any zoom level.
- Uses a PDF-safe Mermaid renderer config by default (`flowchart.htmlLabels=false`) to preserve diagram text in PDFs.
- Improves flowchart edge-label readability by forcing opaque label backgrounds (prevents line strike-through in PDF output).
- Auto-fallback for flowchart/graph diagrams: if SVG uses `foreignObject` labels, md2pdf can render Mermaid PDF for that diagram to preserve node text.
- Mermaid PDF rendering uses fit-to-content page bounds by default (`MERMAID_PDF_FIT=true`) so diagrams do not force full-page layout.
- Works on macOS and Linux (CLI).
- macOS Finder Quick Action support for right-click conversion.
- Configurable defaults via config file (PDF engine, margins, temp asset behavior, more).
- Cleans Mermaid temp assets by default after conversion.

## Package layout

- `bin/`: user-facing CLI commands (`md2pdf`, Finder Quick Action installers).
- `lib/`: internal runtime helpers (Pandoc Mermaid filter + wrapper).
- `assets/`: bundled static assets (`table-style.tex`, `mermaid.config.json`).
- `scripts/`: helper scripts exposed as secondary commands.
- `tests/`: repo-only smoke tests and Mermaid samples (not published to npm).

## Platform support

- macOS: fully supported (CLI + Finder Quick Action).
- Linux: supported for CLI conversion.
- Finder context menu integration: macOS only.

## Install

### 1) Install system dependencies

From repo checkout:

```bash
./install-system-deps.sh
```

You need:
- `pandoc`
- a PDF engine (`xelatex` by default)
- `librsvg` / `rsvg-convert`
- `node` + `npm`
- `python3`
- Python package: `pandocfilters`

### 2) Install md2pdf

Global npm install:

```bash
npm i -g @dkothule/md2pdf
python3 -m pip install pandocfilters
```

Repo-local setup:

```bash
./setup-local-deps.sh
```

## First conversion

```bash
md2pdf /path/to/file.md
```

Output defaults to `/path/to/file.pdf`.

Custom output:

```bash
md2pdf /path/to/file.md -o /path/to/output.pdf
```

## CLI options

```bash
md2pdf --help
md2pdf --version
md2pdf --init
md2pdf --init /path/to/config.env --force
```

## Where npm installs it

For global install (`npm i -g @dkothule/md2pdf`):

- package files: `$(npm prefix -g)/lib/node_modules/@dkothule/md2pdf`
- executable command: `$(npm prefix -g)/bin/md2pdf`

For local project install:

- package files: `./node_modules/@dkothule/md2pdf`
- executable shim: `./node_modules/.bin/md2pdf`

## Configuration

`md2pdf` loads config in this order (later overrides earlier):

1. `$HOME/.config/md2pdf/config.env`
2. `<input-markdown-directory>/.md2pdfrc`
3. `--config /path/to/config.env`
4. environment variables

Initialize default config automatically:

```bash
md2pdf --init
```

This creates:

- `~/.config/md2pdf/config.env`

Initialize to a custom path:

```bash
md2pdf --init ./md2pdf.config.env
```

If target file already exists, re-run with `--force` to overwrite.

Manual template copy (optional):

```bash
mkdir -p ~/.config/md2pdf
cp ./md2pdf.config.example ~/.config/md2pdf/config.env
```

If installed globally from npm, template path is:

```bash
$(npm root -g)/@dkothule/md2pdf/md2pdf.config.example
```

Example config:

```bash
PDF_ENGINE=xelatex
MERMAID_CONFIG=/absolute/path/to/mermaid.config.json
MERMAID_LATEX_FORMAT=svg
MERMAID_PDF_FIT=true
MERMAID_AUTO_PDF_FALLBACK=true
LR_MARGIN=0.7in
TB_MARGIN=0.5in
CLEANUP_MERMAID_ASSETS=true
MERMAID_ASSET_PREFIX=md2pdf-mermaid
```

Useful flags:

```bash
md2pdf input.md --config ./my-config.env
md2pdf input.md --keep-mermaid-assets
md2pdf input.md --cleanup-mermaid-assets
```

## Mermaid temp assets

When Mermaid blocks are present, md2pdf creates:

- `<MERMAID_ASSET_PREFIX>-<run-id>-images/`

By default, this folder is deleted after conversion (`CLEANUP_MERMAID_ASSETS=true`).

## macOS Finder Quick Action

Install:

```bash
md2pdf-install-finder-action
```

Or from repo:

```bash
./scripts/install_md2pdf_quick_action.sh
```

Use in Finder:

- Right click `.md` file -> `Quick Actions` -> `Convert Markdown to PDF`

Remove:

```bash
md2pdf-uninstall-finder-action
```

Or from repo:

```bash
./scripts/uninstall_md2pdf_quick_action.sh
```

If menu entries do not refresh immediately:

```bash
killall Finder
```

## Architecture and test samples

- Architecture doc: `docs/ARCHITECTURE.md`
- Smoke test markdown: `tests/architecture-smoke-test.md`
- Mermaid all-diagram sample pack: `tests/samples/mermaid-all-diagram-types.md`

Run demo:

```bash
md2pdf ./tests/architecture-smoke-test.md
```

Run the full Mermaid sample suite:

```bash
md2pdf ./tests/samples/mermaid-all-diagram-types.md --keep-mermaid-assets
```

## Publish (maintainer)

```bash
npm login
npm pack --dry-run
npm publish
```

Package: `@dkothule/md2pdf`

## Troubleshooting

- `mmdc not found`: install npm deps (`./setup-local-deps.sh`) or set `MERMAID_BIN`.
- Flowchart/graph node labels missing in PDF: keep `MERMAID_AUTO_PDF_FALLBACK=true` (default) so affected SVG diagrams auto-fallback to Mermaid PDF per-diagram.
- To force pure SVG only (disable fallback): set `MERMAID_AUTO_PDF_FALLBACK=false`.
- Mermaid diagrams consuming a full page in output PDF: keep `MERMAID_PDF_FIT=true` (default) so Mermaid PDF assets use tight bounds.
- Mermaid still generating `.svg` instead of `.pdf`: check `~/.config/md2pdf/config.env` and remove/adjust `MERMAID_LATEX_FORMAT=svg`.
- PDF engine not found: install `xelatex` or set `PDF_ENGINE` to an installed engine.
- Finder Quick Action not visible: run `killall Finder`.

## License

MIT License, Copyright (c) 2026 Deepak Kothule
