#!/bin/bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# shellcheck disable=SC1007,SC2164,SC2181,SC2291

BUILD()
{
    local PDR
    PDR="$(pwd)"

    local NAME="$1"; shift
    local DIR="$1"; shift
    local CMDS=("$@")

    LOG "- Building $NAME..."

    cd "$DIR"
    for CMD in "${CMDS[@]}"; do
        local OUT
        OUT="$(eval "$CMD" 2>&1)"
        if [ $? -ne 0 ]; then
            echo -e    '\033[1;31m'"BUILD FAILED!"'\033[0m\n' >&2
            echo -e    '\033[0;31m'"$CMD"'\033[0m\n' >&2
            echo -n -e '\033[0;33m' >&2
            echo -n    "$OUT" >&2
            echo -e    '\033[0m' >&2
            exit 1
        fi
    done
    cd "$PDR"

    return 0
}

CHECK_TOOLS()
{
    local EXECUTABLES=("$@")

    local EXISTS=true
    for i in "${EXECUTABLES[@]}"; do
        [ ! -f "$TOOLS_DIR/bin/$i" ] && EXISTS=false
    done

    $EXISTS
}

GET_CMAKE_FLAGS()
{
    local FLAGS

    FLAGS+="-DCMAKE_SYSTEM_NAME=\"$(uname -s)\" "
    FLAGS+="-DCMAKE_SYSTEM_PROCESSOR=\"$(uname -m)\" "
    FLAGS+="-DCMAKE_BUILD_TYPE=\"Release\" "
    if type ccache &> /dev/null; then
        FLAGS+="-DCMAKE_C_COMPILER_LAUNCHER=\"ccache\" "
        FLAGS+="-DCMAKE_CXX_COMPILER_LAUNCHER=\"ccache\" "
    fi
    FLAGS+="-DCMAKE_C_COMPILER=\"clang\" "
    FLAGS+="-DCMAKE_CXX_COMPILER=\"clang++\""

    echo "$FLAGS"
}

GET_SRC_DIR()
{
    local TOPFILE="unica/configs/version.sh"
    if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/$TOPFILE" ]; then
        (cd "$SRC_DIR"; PWD= /bin/pwd)
    else
        if [ -f "$TOPFILE" ]; then
            PWD= /bin/pwd
        else
            local HERE="$PWD"
            local T=
            while [ \( ! \( -f "$TOPFILE" \) \) ] && [ \( "$PWD" != "/" \) ]; do
                \cd ..
                T="$(PWD= /bin/pwd -P)"
            done
            \cd "$HERE"
            if [ -f "$T/$TOPFILE" ]; then
                echo "$T"
            fi
        fi
    fi
}

IS_WSL()
{
    if [ -e "/proc/sys/fs/binfmt_misc/WSLInterop" ] || [ -e "/run/WSL" ]; then
        echo "ON"
    else
        echo "OFF"
    fi
}

SRC_DIR="$(GET_SRC_DIR)"
if [ ! "$SRC_DIR" ]; then
    echo "Couldn't locate the top of the tree. Try setting SRC_DIR." >&2
    exit 1
else
    source "$SRC_DIR/scripts/utils/log_utils.sh" || exit 1
fi
OUT_DIR="$SRC_DIR/out"
TOOLS_DIR="$OUT_DIR/tools"

mkdir -p "$TOOLS_DIR/bin"

ANDROID_TOOLS=true
APKTOOL=true
EROFS_UTILS=true
IMG2SDAT=true
SAMLOADER=true
SIGNAPK=true

ANDROID_TOOLS_EXEC=("adb" "append2simg" "avbtool" "e2fsdroid" "ext2simg" "fastboot" "fec" "gki/generate_gki_certificate.py" "img2simg" "lpadd" "lpdump" "lpflash" "lpmake" "lpunpack" "make_f2fs" "mkbootfs" "mkbootimg" "mkdtboimg" "mke2fs" "mke2fs.android" "mke2fs.conf" "mkf2fsuserimg" "mkuserimg_mke2fs" "repack_bootimg" "simg2img" "sload_f2fs" "unpack_bootimg" "zipalign")
CHECK_TOOLS "${ANDROID_TOOLS_EXEC[@]}" && ANDROID_TOOLS=false
APKTOOL_EXEC=("apktool" "apktool.jar")
CHECK_TOOLS "${APKTOOL_EXEC[@]}" && APKTOOL=false
EROFS_UTILS_EXEC=("dump.erofs" "extract.erofs" "fsck.erofs" "fuse.erofs" "mkfs.erofs")
CHECK_TOOLS "${EROFS_UTILS_EXEC[@]}" && EROFS_UTILS=false
IMG2SDAT_EXEC=("blockimgdiff.py" "common.py" "images.py" "img2sdat" "rangelib.py" "sparse_img.py")
CHECK_TOOLS "${IMG2SDAT_EXEC[@]}" && IMG2SDAT=false
SAMLOADER_EXEC=("../venv/bin/samloader")
CHECK_TOOLS "${SAMLOADER_EXEC[@]}" && SAMLOADER=false
SIGNAPK_EXEC=("signapk" "signapk.jar")
CHECK_TOOLS "${SIGNAPK_EXEC[@]}" && SIGNAPK=false

if [[ "$1" == "--check-tools" ]]; then
    if ! $ANDROID_TOOLS && ! $APKTOOL && ! $EROFS_UTILS && ! $IMG2SDAT && ! $SAMLOADER && ! $SIGNAPK; then
        exit 0
    else
        exit 1
    fi
elif [ "$1" ]; then
    echo "Usage: $(basename "$0" | sed 's/build_dependencies.sh/build_dependencies/')" >&2
    exit 1
fi

if $ANDROID_TOOLS; then
    ANDROID_TOOLS_CMDS=("git submodule foreach --recursive \"git am --abort || true\"" "cmake -B \"build\" $(GET_CMAKE_FLAGS) -DANDROID_TOOLS_USE_BUNDLED_FMT=ON -DANDROID_TOOLS_USE_BUNDLED_LIBUSB=ON" "make -C \"build\" -j\"$(nproc)\"" "find \"build/vendor\" -maxdepth 1 -type f -exec test -x {} \; -exec cp -a {} \"$TOOLS_DIR/bin\" \;" "cp -a \"vendor/avb/avbtool.py\" \"$TOOLS_DIR/bin/avbtool\"" "cp -a \"vendor/mkbootimg/mkbootimg.py\" \"$TOOLS_DIR/bin/mkbootimg\"" "cp -a \"vendor/mkbootimg/repack_bootimg.py\" \"$TOOLS_DIR/bin/repack_bootimg\"" "cp -a \"vendor/mkbootimg/unpack_bootimg.py\" \"$TOOLS_DIR/bin/unpack_bootimg\"" "cp -a \"vendor/libufdt/utils/src/mkdtboimg.py\" \"$TOOLS_DIR/bin/mkdtboimg\"" "mkdir -p \"$TOOLS_DIR/bin/gki\"" "cp -a \"vendor/mkbootimg/gki/generate_gki_certificate.py\" \"$TOOLS_DIR/bin/gki/generate_gki_certificate.py\"" "ln -sf \"$TOOLS_DIR/bin/mke2fs.android\" \"$TOOLS_DIR/bin/mke2fs\"" "cp -a \"../ext4_utils/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/bin/mkuserimg_mke2fs.py\"" "ln -sf \"$TOOLS_DIR/bin/mkuserimg_mke2fs.py\" \"$TOOLS_DIR/bin/mkuserimg_mke2fs\"" "cp -a \"../ext4_utils/mke2fs.conf\" \"$TOOLS_DIR/bin/mke2fs.conf\"" "cp -a \"../f2fs_utils/mkf2fsuserimg.sh\" \"$TOOLS_DIR/bin/mkf2fsuserimg\"")
    BUILD "android-tools" "$SRC_DIR/external/android-tools" "${ANDROID_TOOLS_CMDS[@]}"
fi
if $APKTOOL; then
    APKTOOL_CMDS=("git reset --hard" "git apply \"$SRC_DIR/external/patches/apktool/0
