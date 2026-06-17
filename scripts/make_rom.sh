#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=true

# 1. Initialize Workspace
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { echo "Failed to create work dir"; exit 1; }
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"

# 2. Hard Stop for Tool Compilation (Circuit Breaker)
# If the environment variable SKIP_TOOL_BUILD is not set to true, abort.
if [ "$SKIP_TOOL_BUILD" != "true" ]; then
    echo "CRITICAL ERROR: Build environment attempted to compile tools. Aborting to prevent OOM crash."
    exit 1
fi

# 3. Patching
if [ -d "$SRC_DIR/unica/mods" ]; then
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
fi

# 4. Packaging
ZIP_FILE_NAME="r9q_final_build.zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1

exit 0
