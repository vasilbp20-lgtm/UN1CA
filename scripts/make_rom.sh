#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

# Force build and packaging
FORCE=true
BUILD_ROM=true
BUILD_TARGET_FILES=true
BUILD_FLASHABLE_ZIP=true

# 1. Initialize directory structure before patching
LOG_STEP_IN true "Preparing build environment"
"$SRC_DIR/scripts/internal/create_work_dir.sh" || exit 1
LOG_STEP_OUT

# 2. Patching and APK building
if [ -d "$SRC_DIR/unica/mods" ]; then
    LOG_STEP_IN true "Applying ROM mods"
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
    LOG_STEP_OUT
fi

# 3. Packaging
ZIP_FILE_NAME="r9q_build_${GITHUB_RUN_ID}.zip"
LOG_STEP_IN true "Creating flashable zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
LOG_STEP_OUT

exit 0
