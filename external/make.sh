#!/bin/bash

# Define directories
SRC_DIR="$(pwd)"
TOOLS_DIR="$SRC_DIR/out/tools"

# Create target directory for binaries
mkdir -p "$TOOLS_DIR/bin"

echo "Building erofs-utils..."

# Enter directory and build
cd "$SRC_DIR/external/erofs-utils" || { echo "Directory not found"; exit 1; }

# Perform the standard Autotools build pipeline
# autogen: generates the configure script
# configure: prepares the Makefile
# make: compiles the code
# make install: moves binaries to your target folder
./autogen.sh
./configure --prefix="$TOOLS_DIR" --bindir="$TOOLS_DIR/bin"
make -j"$(nproc)"
make install

# Final check
if [ -f "$TOOLS_DIR/bin/mkfs.erofs" ]; then
    echo "Dependencies built successfully."
else
    echo "Build failed: Binary not found."
    exit 1
fi
