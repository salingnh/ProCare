#!/bin/bash
# SessionStart hook for Claude Code on the web.
# Installs the pinned Flutter SDK and resolves Dart package dependencies so that
# `flutter analyze` and `flutter test` work during the session.
set -euo pipefail

# Only run in the remote (Claude Code on the web) environment. Locally, the
# developer is expected to manage their own Flutter installation.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Keep this in sync with FLUTTER_VERSION in .github/workflows/android-release.yml
FLUTTER_VERSION="3.41.9"
FLUTTER_CHANNEL="stable"
FLUTTER_HOME="${HOME}/flutter"
SDK_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/${SDK_ARCHIVE}"

# Persist a shared pub cache so dependencies survive across hook runs.
export PUB_CACHE="${HOME}/.pub-cache"
mkdir -p "${PUB_CACHE}"

# Install the Flutter SDK (idempotent: skip if the pinned version is present).
installed_version="$("${FLUTTER_HOME}/bin/flutter" --version 2>/dev/null | sed -nE 's/^Flutter ([0-9.]+).*/\1/p' | head -n1 || true)"
if [ "${installed_version}" != "${FLUTTER_VERSION}" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})..."
  rm -rf "${FLUTTER_HOME}"
  tmp_archive="$(mktemp -d)/${SDK_ARCHIVE}"
  curl -fsSL --retry 4 --retry-delay 2 -o "${tmp_archive}" "${SDK_URL}"
  tar -xJf "${tmp_archive}" -C "${HOME}"
  rm -f "${tmp_archive}"
else
  echo "Flutter ${FLUTTER_VERSION} already installed."
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

# Avoid git "dubious ownership" errors when Flutter inspects its own checkout.
git config --global --add safe.directory "${FLUTTER_HOME}" || true

# Disable analytics/telemetry for non-interactive CI-like use.
flutter config --no-analytics >/dev/null 2>&1 || true

# Bootstrap the Flutter tool and download required engine artifacts.
flutter precache --universal >/dev/null 2>&1 || true

# Resolve package dependencies for the project.
cd "${CLAUDE_PROJECT_DIR}"
flutter pub get

# Persist environment for the rest of the session.
{
  echo "export PATH=\"${FLUTTER_HOME}/bin:\$PATH\""
  echo "export PUB_CACHE=\"${PUB_CACHE}\""
} >> "${CLAUDE_ENV_FILE}"

echo "Flutter environment ready."
