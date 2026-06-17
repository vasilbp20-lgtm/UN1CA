#!/usr/bin/env bash
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

# 1. Инициализация
"$SRC_DIR/scripts/internal/create_work_dir.sh" || { echo "Failed to create work dir"; exit 1; }
mkdir -p "$OUT_DIR/target/r9q/work_dir/configs/"

# 2. ЗАЩИТА: Прескачаме компилацията на инструменти
if [ "$SKIP_TOOL_BUILD" = "true" ]; then
    echo "Компилацията на инструменти е пропусната (използват се системни бинарни файлове)."
else
    # Ако някой скрипт се опита да компилира, спираме го веднага
    echo "ГРЕШКА: Build средата се опитва да компилира инструменти локално. Прекратяване."
    exit 1
fi

# 3. Patching
if [ -d "$SRC_DIR/unica/mods" ]; then
    "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
fi

# 4. Пакетиране
ZIP_FILE_NAME="r9q_final_build.zip"
"$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
"$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1

exit 0

