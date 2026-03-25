#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PRODUCT_NAME="EyeBreak"
BUILD_CONFIGURATION="release"

INFO_PLIST_SRC="${ROOT_DIR}/Resources/Info.plist"
BIN_SRC="${ROOT_DIR}/.build/${BUILD_CONFIGURATION}/${PRODUCT_NAME}"
SVG_ICON_SRC="${ROOT_DIR}/coffee.svg"

DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${PRODUCT_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICNS_OUT="${RESOURCES_DIR}/AppIcon.icns"

build_icns_from_svg() {
  local svg_path="$1"
  local icns_path="$2"

  if [[ ! -f "${svg_path}" ]]; then
    return 0
  fi

  if ! command -v sips >/dev/null 2>&1; then
    echo "warning: 'sips' not found; skipping app icon generation" >&2
    return 0
  fi
  if ! command -v iconutil >/dev/null 2>&1; then
    echo "warning: 'iconutil' not found; skipping app icon generation" >&2
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' RETURN

  local png_1024="${tmp_dir}/icon_1024.png"

  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 1024 -h 1024 "${svg_path}" -o "${png_1024}"
  elif command -v inkscape >/dev/null 2>&1; then
    inkscape "${svg_path}" --export-type=png --export-filename="${png_1024}" -w 1024 -h 1024 >/dev/null 2>&1
  elif command -v qlmanage >/dev/null 2>&1; then
    qlmanage -t -s 1024 -o "${tmp_dir}" "${svg_path}" >/dev/null 2>&1 || true
    local base
    base="$(basename "${svg_path}")"
    base="${base%.*}"
    if [[ -f "${tmp_dir}/${base}.png" ]]; then
      mv "${tmp_dir}/${base}.png" "${png_1024}"
    elif [[ -f "${tmp_dir}/${base}.svg.png" ]]; then
      mv "${tmp_dir}/${base}.svg.png" "${png_1024}"
    elif [[ -f "${tmp_dir}/$(basename "${svg_path}").png" ]]; then
      mv "${tmp_dir}/$(basename "${svg_path}").png" "${png_1024}"
    fi
  fi

  if [[ ! -f "${png_1024}" ]]; then
    echo "warning: failed to render ${svg_path} to png; skipping app icon generation" >&2
    return 0
  fi

  local iconset_dir="${tmp_dir}/AppIcon.iconset"
  mkdir -p "${iconset_dir}"

  local size
  for size in 16 32 128 256 512; do
    sips -z "${size}" "${size}" "${png_1024}" --out "${iconset_dir}/icon_${size}x${size}.png" >/dev/null
    local size2=$((size * 2))
    sips -z "${size2}" "${size2}" "${png_1024}" --out "${iconset_dir}/icon_${size}x${size}@2x.png" >/dev/null
  done
  # 32@2x is 64, already covered by 32@2x; 512@2x is 1024 from source.

  iconutil -c icns "${iconset_dir}" -o "${icns_path}"
}

cd "${ROOT_DIR}"

swift build -c "${BUILD_CONFIGURATION}"

if [[ ! -f "${BIN_SRC}" ]]; then
  echo "Expected binary not found at: ${BIN_SRC}" >&2
  exit 1
fi

if [[ ! -f "${INFO_PLIST_SRC}" ]]; then
  echo "Expected Info.plist not found at: ${INFO_PLIST_SRC}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${INFO_PLIST_SRC}" "${CONTENTS_DIR}/Info.plist"
cp "${BIN_SRC}" "${MACOS_DIR}/${PRODUCT_NAME}"
chmod +x "${MACOS_DIR}/${PRODUCT_NAME}"

# Finder/Dock icon comes from .icns inside the bundle (not from runtime NSImage).
build_icns_from_svg "${SVG_ICON_SRC}" "${ICNS_OUT}"

echo "Built: ${APP_DIR}"
echo "Run:   open \"${APP_DIR}\""
