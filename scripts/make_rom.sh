#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=true

# 1. Initialize Workspace
"$SRC_DIR/scripts/internal/create_work_dir.sh" || exit 1
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"

# 2. Skip Build Tools if prebuilt tools are being used
if [ "$PREBUILT_TOOLS" != "true" ]; then
    LOG_STEP_IN true "Building android-tools"
    cmake -B "build" -DCMAKE_SYSTEM_NAME="Linux" -DBUILD_SHARED_LIBS=OFF .
    make -C build -j1 || exit 1
    LOG_STEP_OUT
else
    echo "Using prebuilt tools, skipping compilation."
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
