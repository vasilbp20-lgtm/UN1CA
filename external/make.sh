#!/bin/bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

BUILD() {
    local PDR="$(pwd)"
    local NAME="$1"; shift
    local DIR="$1"; shift
    local CMDS=("$@")
    echo "- Building $NAME..."
    cd "$DIR"
    for CMD in "${CMDS[@]}"; do
        if ! eval "$CMD"; then
            echo "BUILD FAILED: $CMD" >&2
            exit 1
        fi
    done
    cd "$PDR"
}

CHECK_TOOLS() {
    local EXECUTABLES=("$@")
    for i in "${EXECUTABLES[@]}"; do
        [ ! -f "$TOOLS_DIR/bin/$i" ] && return 1
    done
    return 0
}

SRC_DIR="$(pwd)"
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools"
mkdir -p "$TOOLS_DIR/bin"

ANDROID_TOOLS=true; APKTOOL=true; EROFS_UTILS=true; IMG2SDAT=true; SAMLOADER=true; SIGNAPK=true

CHECK_TOOLS "adb" && ANDROID_TOOLS=false
CHECK_TOOLS "apktool" && APKTOOL=false
CHECK_TOOLS "mkfs.erofs" && EROFS_UTILS=false
CHECK_TOOLS "img2sdat" && IMG2SDAT=false
[ -f "../venv/bin/samloader" ] && SAMLOADER=false
CHECK_TOOLS "signapk" && SIGNAPK=false

if $EROFS_UTILS; then
    EROFS_UTILS_CMDS=("./autogen.sh" "./configure --prefix=\"$TOOLS_DIR\" --bindir=\"$TOOLS_DIR/bin\"" "make -j\"$(nproc)\"" "make install")
    BUILD "erofs-utils" "$SRC_DIR/external/erofs-utils" "${EROFS_UTILS_CMDS[@]}"
fi

if $APKTOOL; then
    APKTOOL_CMDS=("./gradlew build shadowJar" "cp -a \"brut.apktool/apktool-cli/build/libs/apktool-cli.jar\" \"$TOOLS_DIR/bin/apktool.jar\"")
    BUILD "apktool" "$SRC_DIR/external/apktool" "${APKTOOL_CMDS[@]}"
fi

echo "All dependencies checked/built successfully."
