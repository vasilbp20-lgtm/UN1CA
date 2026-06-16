#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

# Force build and packaging for CI environment
FORCE=true
BUILD_ROM=true
BUILD_TARGET_FILES=true
BUILD_FLASHABLE_ZIP=true

START_TIME="$(date +%s)"

# Static filename to match the expectation of the next script
ZIP_FILE_NAME="r9q_3.1.0-0386a97-dirty-target_files.zip"

GET_WORK_DIR_HASH()
{
    find "$SRC_DIR/unica" "$SRC_DIR/target/$TARGET_CODENAME" -type f -print0 | \
        sort -z | xargs -0 sha1sum | sha1sum | cut -d " " -f 1
}

PRINT_BUILD_OUTCOME()
{
    local EXIT_CODE="$?"
    local END_TIME
    local ESTIMATED
    END_TIME="$(date +%s)"
    ESTIMATED="$((END_TIME - START_TIME))"
    if [ "$EXIT_CODE" != "0" ]; then
        echo -n -e '\n\033[1;31m'"Build failed "
    else
        echo -n -e '\n\033[1;32m'"Build completed "
    fi
    echo -e "in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."'\033[0m\n'
}

trap 'PRINT_BUILD_OUTCOME' EXIT
trap 'echo' INT

# 1. ROM Compilation Logic
if [ -d "$APKTOOL_DIR" ] && [ "$FORCE" = true ]; then
    rm -rf "$APKTOOL_DIR"
fi

if [ -d "$SRC_DIR/unica/mods" ]; then
    LOG_STEP_IN true "Applying ROM mods"
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
    LOG_STEP_OUT
fi

if [ -d "$APKTOOL_DIR" ]; then
    LOG_STEP_IN true "Building APKs/JARs"
    while IFS= read -r f; do
        f="${f/$APKTOOL_DIR\//}"
        PARTITION="$(cut -d "/" -f 1 -s <<< "$f")"
        if [[ "$PARTITION" == "system" ]]; then
            "$SRC_DIR/scripts/apktool.sh" b "system" "$f" &
        else
            "$SRC_DIR/scripts/apktool.sh" b "$PARTITION" "$(cut -d "/" -f 2- -s <<< "$f")" &
        fi
    done < <(find "$APKTOOL_DIR" -type d \( -name "*.apk" -o -name "*.jar" \))
    wait $(jobs -p) || exit 1
    LOG_STEP_OUT
fi

# 2. Packaging Logic
mkdir -p "$OUT_DIR"

if [ ! -f "$OUT_DIR/$ZIP_FILE_NAME" ]; then
    LOG_STEP_IN true "Creating target-files zip: $ZIP_FILE_NAME"
    "$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
    LOG_STEP_OUT
fi

if [ "$BUILD_FLASHABLE_ZIP" = true ]; then
    if [ -f "$OUT_DIR/$ZIP_FILE_NAME" ]; then
        LOG_STEP_IN true "Creating flashable zip"
        "$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
        LOG_STEP_OUT
    else
        LOGE "CRITICAL: $ZIP_FILE_NAME not found after creation step."
        exit 1
    fi
fi

exit 0
