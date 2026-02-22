#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Deepak Kothule
set -euo pipefail

YES=0
OS="$(uname -s)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Install md2pdf runtime dependencies (system packages + pandocfilters).

Options:
  -y, --yes   Skip confirmation prompt and proceed immediately
  -h, --help  Show this help message

Supported platforms:
  - macOS (Homebrew)
  - Debian/Ubuntu Linux (apt)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes)
        YES=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Error: unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

confirm_install() {
  if [[ "$YES" -eq 1 ]]; then
    return
  fi

  if [[ ! -t 0 ]]; then
    echo "Non-interactive shell detected. Re-run with --yes to proceed." >&2
    exit 1
  fi

  echo "This command will install system packages for md2pdf and may prompt for sudo password."
  echo "Detected OS: $OS"
  printf "Continue? [y/N] "
  local response
  local normalized_response
  read -r response
  normalized_response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"

  case "$normalized_response" in
    y|yes)
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
}

has_pandocfilters() {
  python3 - <<'PY' >/dev/null 2>&1
import pandocfilters
PY
}

install_python_dependency() {
  if has_pandocfilters; then
    echo "Python dependency already installed: pandocfilters"
    return
  fi

  echo "Installing Python dependency: pandocfilters"
  if python3 -m pip install --user pandocfilters; then
    return
  fi

  if python3 -m pip install pandocfilters --break-system-packages; then
    return
  fi

  echo "Failed to install pandocfilters automatically." >&2
  echo "Please install manually with one of:" >&2
  echo "  python3 -m pip install --user pandocfilters" >&2
  echo "  python3 -m pip install pandocfilters --break-system-packages" >&2
  exit 1
}

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS. Install from https://brew.sh and retry."
    exit 1
  fi

  brew update
  brew install pandoc librsvg python

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    brew install node
  fi

  if ! command -v xelatex >/dev/null 2>&1; then
    echo "Installing BasicTeX for xelatex..."
    brew install --cask basictex
    echo "BasicTeX installed. You may need to restart your shell before retrying."
  fi
}

install_debian_ubuntu() {
  sudo apt-get update
  sudo apt-get install -y \
    pandoc \
    librsvg2-bin \
    python3 \
    python3-venv \
    python3-pip \
    python3-pandocfilters \
    texlive-xetex

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    sudo apt-get install -y nodejs npm
  fi
}

parse_args "$@"
confirm_install

if [[ "$OS" == "Darwin" ]]; then
  install_macos
elif [[ "$OS" == "Linux" ]]; then
  if [[ -f /etc/debian_version ]]; then
    install_debian_ubuntu
  else
    echo "Unsupported Linux distro by this script."
    echo "Please install: pandoc, xelatex, librsvg (rsvg-convert), node/npm, python3+venv."
    exit 1
  fi
else
  echo "Unsupported OS: $OS"
  exit 1
fi

install_python_dependency

echo "Runtime dependencies installed."
