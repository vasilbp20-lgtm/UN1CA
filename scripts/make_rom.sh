#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

# 1. Initialize Workspace
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { echo "Failed to create work dir"; exit 1; }
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"

# 2. Hard Stop for Tool Compilation
# If any internal script tries to trigger the compiler, stop here.
if [ "$SKIP_TOOL_BUILD" = "true" ]; then
    echo "Skipping tool build as requested."
else
    # Prevent compilation to stop OOM/Linker crashes
    echo "Tool compilation is disabled to prevent build crashes."
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
