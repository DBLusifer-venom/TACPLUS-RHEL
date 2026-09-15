#!/bin/bash
# ============================================================================
# pam-tacplus-src Repository Setup Script
# Purpose: Create a self-contained local Git repo for pam_tacplus v1.7.0
#          with RHEL 9 patches, eliminating external dependencies.
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
# Source included locally - no remote clone required
# gnulib included locally - no remote clone required
PATCH_DIR="${REPO_ROOT}/patches"
SOURCE_DIR="${REPO_ROOT}/pam_tacplus-1.7.0"

echo "============================================"
echo "  pam-tacplus-src Repository Builder"
echo "============================================"
echo ""

# ---- Step 1: Initialize Git repo ----
if [ ! -d "${REPO_ROOT}/.git" ]; then
    echo "[1/2] Initializing Git repository..."
    git -C "${REPO_ROOT}" init
    git -C "${REPO_ROOT}" config user.email "security-engineering@company.local"
    git -C "${REPO_ROOT}" config user.name "Security Engineering"
else
    echo "[1/2] Git repository already initialized."
fi

# ---- Step 2: Apply RHEL 9 patch ----
echo "[2/2] Applying RHEL 9 compatibility patch..."
cd "${SOURCE_DIR}"
if grep -q 'gl_PREREQ_EXPLICIT_BZERO' configure.ac; then
    sed -i '/^[[:space:]]*gl_PREREQ_EXPLICIT_BZERO[[:space:]]*$/d' configure.ac
    echo "  -> Patched configure.ac (removed gl_PREREQ_EXPLICIT_BZERO)"
else
    echo "  -> configure.ac already patched or macro not found."
fi

# ---- Verify patch state ----
if grep -q 'gl_PREREQ_EXPLICIT_BZERO' configure.ac; then
    echo "  [ERROR] configure.ac still contains gl_PREREQ_EXPLICIT_BZERO"
    exit 1
else
    echo "  [OK] configure.ac is clean."
fi

# ---- Stage everything ----
echo "Staging files for initial commit..."
cd "${REPO_ROOT}"
git add -A
git commit -m "Initial import: pam_tacplus v1.7.0 with RHEL 9 patches

- Source: pam_tacplus v1.7.0 (local)
- Patch: gl_PREREQ_EXPLICIT_BZERO removed for RHEL 9
- gnulib: included locally (build-time only)
- RPM spec: pam-tacplus-rhel9.spec (release 3)
- Targets: RHEL 9.x"

echo ""
echo "============================================"
echo "  Repository setup complete!"
echo "============================================"
echo ""
echo "  Location: ${REPO_ROOT}"
echo "  Source:   ${SOURCE_DIR}"
echo "  gnulib:   ${REPO_ROOT}/gnulib"
echo ""
echo "  Verify: git -C ${REPO_ROOT} log --oneline"
echo "============================================"
