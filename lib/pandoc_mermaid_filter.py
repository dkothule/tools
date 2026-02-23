#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Deepak Kothule
"""
Pandoc filter for mermaid code blocks. Outputs SVG by default (vector quality in PDF).
Based on timofurrer/pandoc-mermaid-filter; modified to use SVG for LaTeX/PDF.

Requires: mmdc (mermaid-cli) on PATH or MERMAID_BIN.
For PDF: install librsvg so pandoc can embed SVG (e.g. brew install librsvg).
Python: pip install pandocfilters (or use PYTHON env to point to a venv that has it).
Optional: set MERMAID_CONFIG to pass a Mermaid config JSON to mmdc.
Optional: set MERMAID_IMAGE_PREFIX to control temporary Mermaid asset directory prefix.
Optional: set MERMAID_LATEX_FORMAT (pdf|svg|png). Default is svg.
Optional: set MERMAID_PDF_FIT=true|false (default true). If true, Mermaid PDF
output uses fit-to-content page boxes to avoid page-sized diagram assets.
Optional: set MERMAID_AUTO_PDF_FALLBACK=true|false (default true). If SVG uses
foreignObject labels in PDF output pipeline, fallback rendering uses Mermaid PDF.
"""
import os
import sys
import subprocess

try:
    from pandocfilters import toJSONFilter, Para, Image
    from pandocfilters import get_filename4code, get_caption, get_extension
except ImportError:
    sys.stderr.write(
        "Missing Python dependency: pandocfilters.\n"
        "Install with: python3 -m pip install pandocfilters\n"
    )
    raise SystemExit(1)

MERMAID_BIN = os.environ.get("MERMAID_BIN", "mmdc")
MERMAID_CONFIG = os.environ.get("MERMAID_CONFIG", None)
PUPPETEER_CFG = os.environ.get("PUPPETEER_CFG", None)
MERMAID_IMAGE_PREFIX = os.environ.get("MERMAID_IMAGE_PREFIX", "mermaid")
MERMAID_LATEX_FORMAT = os.environ.get("MERMAID_LATEX_FORMAT", "svg")
MERMAID_HTML_FORMAT = os.environ.get("MERMAID_HTML_FORMAT", "svg")
MERMAID_FORCE_FORMAT = os.environ.get("MERMAID_FORCE_FORMAT", "")


def env_bool(name, default):
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


MERMAID_AUTO_PDF_FALLBACK = env_bool("MERMAID_AUTO_PDF_FALLBACK", True)
MERMAID_PDF_FIT = env_bool("MERMAID_PDF_FIT", True)


def render_mermaid(src, dest):
    cmd = [MERMAID_BIN, "-i", src, "-o", dest, "-q"]
    if dest.lower().endswith(".pdf") and MERMAID_PDF_FIT:
        cmd.append("--pdfFit")
    if MERMAID_CONFIG is not None:
        cmd.extend(["-c", MERMAID_CONFIG])
    if PUPPETEER_CFG is not None:
        cmd.extend(["-p", PUPPETEER_CFG])
    if os.path.isfile(".puppeteer.json"):
        cmd.extend(["-p", ".puppeteer.json"])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write("Failed to render Mermaid diagram with mermaid-cli.\n")
        sys.stderr.write("Command: " + " ".join(cmd) + "\n")
        if result.stderr:
            sys.stderr.write(result.stderr.strip() + "\n")
        raise SystemExit(result.returncode)


def svg_has_foreign_object(path):
    try:
        with open(path, "rb") as f:
            return b"<foreignObject" in f.read()
    except OSError:
        return False


def mermaid(key, value, format_, _):
    if key == "CodeBlock":
        [[ident, classes, keyvals], code] = value
        if "mermaid" in classes:
            caption, typef, keyvals = get_caption(keyvals)
            filename = get_filename4code(MERMAID_IMAGE_PREFIX, code)
            if MERMAID_FORCE_FORMAT:
                filetype = MERMAID_FORCE_FORMAT.lower()
            else:
                filetype = get_extension(
                    format_,
                    MERMAID_LATEX_FORMAT,
                    html=MERMAID_HTML_FORMAT,
                    latex=MERMAID_LATEX_FORMAT,
                    pdf=MERMAID_LATEX_FORMAT,
                )
            src = filename + ".mmd"
            dest = filename + "." + filetype
            txt = code.encode(sys.getfilesystemencoding())
            with open(src, "wb") as f:
                f.write(txt)

            if not os.path.isfile(dest):
                render_mermaid(src, dest)
                sys.stderr.write("Created image " + dest + "\n")

            # Flowchart/graph SVG labels may be emitted via <foreignObject>, which
            # some SVG->PDF pipelines drop. Keep SVG default, but fallback to Mermaid
            # PDF for only affected diagrams when generating PDF output.
            if (
                MERMAID_AUTO_PDF_FALLBACK
                and filetype == "svg"
                and format_ in {"", "pdf", "latex"}
                and svg_has_foreign_object(dest)
            ):
                fallback_dest = filename + ".pdf"
                if not os.path.isfile(fallback_dest):
                    render_mermaid(src, fallback_dest)
                    sys.stderr.write(
                        "Created PDF fallback image "
                        + fallback_dest
                        + " (foreignObject detected)\n"
                    )
                dest = fallback_dest

            return Para([Image([ident, [], keyvals], caption, [dest, typef])])


def main():
    toJSONFilter(mermaid)


if __name__ == "__main__":
    main()
