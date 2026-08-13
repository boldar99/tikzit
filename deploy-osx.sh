#!/usr/bin/env bash
set -Eeuo pipefail

# Build a distributable macOS application and disk image from the CMake build.
#
# Usage: ./deploy-osx.sh [BUILD_DIR] [APP_NAME] [DIST_DIR]
# Example: ./deploy-osx.sh cmake-build-release tikzit dist

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${1:-cmake-build-release}"
APP_NAME="${2:-tikzit}"
DIST_DIR="${3:-dist}"

if [[ "${BUILD_DIR}" != /* ]]; then
    BUILD_DIR="${SCRIPT_DIR}/${BUILD_DIR}"
fi
if [[ "${DIST_DIR}" != /* ]]; then
    DIST_DIR="${SCRIPT_DIR}/${DIST_DIR}"
fi

SOURCE_APP="${BUILD_DIR}/${APP_NAME}.app"
DIST_APP="${DIST_DIR}/${APP_NAME}.app"
DIST_DMG="${DIST_DIR}/${APP_NAME}.dmg"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: deploy-osx.sh must be run on macOS." >&2
    exit 1
fi

if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
    echo "Error: '${BUILD_DIR}' is not a configured CMake build directory." >&2
    echo "Configure it first with: cmake -S '${SCRIPT_DIR}' -B '${BUILD_DIR}'" >&2
    exit 1
fi

echo "Building ${APP_NAME} from ${BUILD_DIR}..."
cmake --build "${BUILD_DIR}" --target "${APP_NAME}"

if [[ ! -x "${SOURCE_APP}/Contents/MacOS/${APP_NAME}" ]]; then
    echo "Error: CMake did not produce '${SOURCE_APP}'." >&2
    exit 1
fi

# Prefer the macdeployqt belonging to the Qt installation used by CMake. This
# avoids accidentally packaging an app with a different Qt major version.
MACDEPLOYQT=""
QTPATHS=""
QT_CORE_CMAKE_DIR="$(sed -n 's/^Qt[56]Core_DIR:PATH=//p' "${BUILD_DIR}/CMakeCache.txt" | head -n 1)"
if [[ -n "${QT_CORE_CMAKE_DIR}" ]]; then
    QT_PREFIX="$(cd "${QT_CORE_CMAKE_DIR}/../../.." && pwd)"
    if [[ -x "${QT_PREFIX}/bin/macdeployqt" ]]; then
        MACDEPLOYQT="${QT_PREFIX}/bin/macdeployqt"
    fi
    if [[ -x "${QT_PREFIX}/bin/qtpaths6" ]]; then
        QTPATHS="${QT_PREFIX}/bin/qtpaths6"
    elif [[ -x "${QT_PREFIX}/bin/qtpaths" ]]; then
        QTPATHS="${QT_PREFIX}/bin/qtpaths"
    fi
fi
if [[ -z "${MACDEPLOYQT}" ]]; then
    MACDEPLOYQT="$(command -v macdeployqt || true)"
fi
if [[ -z "${MACDEPLOYQT}" ]]; then
    echo "Error: macdeployqt was not found." >&2
    echo "Install Qt (for example, 'brew install qt') or add its bin directory to PATH." >&2
    exit 1
fi
if [[ -z "${QTPATHS}" ]]; then
    QTPATHS="$(command -v qtpaths6 || command -v qtpaths || true)"
fi
if [[ -z "${QTPATHS}" ]]; then
    echo "Error: qtpaths was not found, so the required Qt plugins cannot be located." >&2
    exit 1
fi

mkdir -p "${DIST_DIR}"
rm -rf -- "${DIST_APP}"
rm -f -- "${DIST_DMG}"

echo "Staging ${DIST_APP}..."
ditto "${SOURCE_APP}" "${DIST_APP}"

# macdeployqt normally copies every available plugin. Homebrew's Qt formula
# exposes plugins from several optional formulae, which makes that mode very
# slow and produces an unnecessarily large image. TikZiT only requires the
# Cocoa platform and native widget-style plugins, plus SVG and GIF support.
QT_PLUGIN_DIR="$("${QTPATHS}" --plugin-dir)"
COCOA_PLUGIN="${QT_PLUGIN_DIR}/platforms/libqcocoa.dylib"
MAC_STYLE_PLUGIN="${QT_PLUGIN_DIR}/styles/libqmacstyle.dylib"
SVG_PLUGIN="${QT_PLUGIN_DIR}/imageformats/libqsvg.dylib"
GIF_PLUGIN="${QT_PLUGIN_DIR}/imageformats/libqgif.dylib"
for plugin in "${COCOA_PLUGIN}" "${MAC_STYLE_PLUGIN}" "${SVG_PLUGIN}" "${GIF_PLUGIN}"; do
    if [[ ! -f "${plugin}" ]]; then
        echo "Error: required Qt plugin '${plugin}' was not found." >&2
        exit 1
    fi
done

mkdir -p "${DIST_APP}/Contents/PlugIns/platforms"
mkdir -p "${DIST_APP}/Contents/PlugIns/styles"
mkdir -p "${DIST_APP}/Contents/PlugIns/imageformats"
cp -L "${COCOA_PLUGIN}" "${DIST_APP}/Contents/PlugIns/platforms/"
cp -L "${MAC_STYLE_PLUGIN}" "${DIST_APP}/Contents/PlugIns/styles/"
cp -L "${SVG_PLUGIN}" "${GIF_PLUGIN}" "${DIST_APP}/Contents/PlugIns/imageformats/"

echo "Deploying Qt frameworks and creating ${DIST_DMG}..."
"${MACDEPLOYQT}" "${DIST_APP}" \
    -no-plugins \
    -executable="${DIST_APP}/Contents/PlugIns/platforms/libqcocoa.dylib" \
    -executable="${DIST_APP}/Contents/PlugIns/styles/libqmacstyle.dylib" \
    -executable="${DIST_APP}/Contents/PlugIns/imageformats/libqsvg.dylib" \
    -executable="${DIST_APP}/Contents/PlugIns/imageformats/libqgif.dylib" \
    -always-overwrite -verbose=1 -dmg

if [[ ! -f "${DIST_DMG}" ]]; then
    echo "Error: macdeployqt completed without producing '${DIST_DMG}'." >&2
    exit 1
fi

echo "Created ${DIST_DMG}"
