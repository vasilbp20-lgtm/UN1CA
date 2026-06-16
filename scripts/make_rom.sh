#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=true

# Ensure the work directory structure is created
LOG_STEP_IN true "Preparing build environment"
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { echo "Failed to create work dir"; exit 1; }
LOG_STEP_OUT

# Ensure the required configs exist to avoid the "No such file" error
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"

# Apply patches and build components
if [ -d "$SRC_DIR/unica/mods" ]; then
    LOG_STEP_IN true "Applying ROM mods"
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
    LOG_STEP_OUT
fi

# Final Packaging
LOG_STEP_IN true "Creating flashable zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/target_files.zip" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/target_files.zip" || exit 1
LOG_STEP_OUT

exit 0
