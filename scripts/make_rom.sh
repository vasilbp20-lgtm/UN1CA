#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=true

# 1. INITIALIZE WORKSPACE FIRST
LOG_STEP_IN true "Initializing workspace"
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { echo "Failed to create work dir"; exit 1; }
# Explicitly create the config directory to avoid "No such file" errors
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"
LOG_STEP_OUT

# 2. APPLY PATCHES ONLY AFTER INITIALIZATION
if [ -d "$SRC_DIR/unica/mods" ]; then
    LOG_STEP_IN true "Applying ROM mods"
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
    LOG_STEP_OUT
fi

# 3. PACKAGING
# Use a static name to ensure the subsequent script finds the file
ZIP_FILE_NAME="r9q_final_build.zip"
LOG_STEP_IN true "Creating flashable zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
LOG_STEP_OUT

exit 0
