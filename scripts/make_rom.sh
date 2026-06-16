#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

# Force build
FORCE=true

# 1. INITIALIZE WORKSPACE FIRST
LOG_STEP_IN true "Initializing workspace and work directory"
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { LOGE "Failed to create work dir"; exit 1; }
LOG_STEP_OUT

# 2. APPLY PATCHES ONLY AFTER INITIALIZATION
if [ -d "$SRC_DIR/unica/mods" ]; then
    LOG_STEP_IN true "Applying ROM mods"
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
    LOG_STEP_OUT
fi

# 3. APK BUILDING
if [ -d "$APKTOOL_DIR" ]; then
    LOG_STEP_IN true "Building APKs/JARs"
    # ... (your existing loop to build APKs/JARs) ...
    wait $(jobs -p) || exit 1
    LOG_STEP_OUT
fi

# 4. PACKAGING
LOG_STEP_IN true "Creating target-files and flashable zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/target_files.zip" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/target_files.zip" || exit 1
LOG_STEP_OUT

exit 0
