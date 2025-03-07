#!/bin/bash
# Purpose: Create a ZIP for an AWS Lambda layer on Amazon Linux 2023, ensuring
# that bin/, lib/, and fonts/ appear at the root of the ZIP.
#
# This script:
# 1. Installs wkhtmltopdf (built for CentOS 8) and system dependencies.
# 2. Copies the binary and libraries into /package/bin and /package/lib.
# 3. Copies a local fonts/ directory into /package/fonts.
# 4. cd's into /package and zips everything, ensuring the final ZIP has
#    bin/, lib/, and fonts/ at the root.
#
# Usage:
#  - Place a local 'fonts/' folder (and optional fonts.conf) next to this script.
#  - Run the script on Amazon Linux 2023 or in a Docker container.
#  - The resulting ZIP will be in /output/layer.zip.

set -e

echo "Updating system and installing base dependencies..."
dnf update -y
dnf install -y \
    fontconfig freetype libX11 libXext libXrender libXau libjpeg \
    xorg-x11-fonts-75dpi xorg-x11-fonts-Type1 urw-fonts \
    wget zip tar gzip perl

echo "Installing wkhtmltox (wkhtmltopdf 0.12.6-1 for CentOS 8)..."
ARCH=x86_64
dnf install -y "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.centos8.${ARCH}.rpm"

echo "Creating staging directories..."
mkdir -p /package/bin /package/lib /package/fonts

echo "Copying wkhtmltopdf binary..."
cp /usr/local/bin/wkhtmltopdf /package/bin/

wget https://www.openssl.org/source/openssl-1.1.1u.tar.gz
tar -xzf openssl-1.1.1u.tar.gz
cd openssl-1.1.1u

# Configure and compile; adjust --prefix as needed (e.g., a staging directory)
./config --prefix=/usr/local/openssl1.1 --openssldir=/usr/local/openssl1.1 shared
make
make install

# Now, the libraries will be in /usr/local/openssl1.1/lib
# Copy them into your package directory for the Lambda layer
cp /usr/local/openssl1.1/lib/libssl.so.1.1 /package/lib/ || true
cp /usr/local/openssl1.1/lib/libcrypto.so.1.1 /package/lib/ || true

echo "Copying required shared libraries..."
# You can tailor this to your actual ldd output.
cp /usr/lib64/libX11*.so.* /package/lib/ || true
cp /usr/lib64/libXext*.so.* /package/lib/ || true
cp /usr/lib64/libXrender*.so.* /package/lib/ || true
cp /usr/lib64/libXfixes*.so.* /package/lib/ || true
cp /usr/lib64/libfontconfig*.so.* /package/lib/ || true
cp /usr/lib64/libfreetype*.so.* /package/lib/ || true
cp /usr/lib64/libjpeg*.so.* /package/lib/ || true
cp /usr/lib64/libXau*.so.* /package/lib/ || true
cp /usr/lib64/libcrypto*.so.* /package/lib/ || true
cp /usr/lib64/libpng*.so.* /package/lib/ || true
cp /usr/lib64/libharfbuzz*.so.* /package/lib/ || true
cp /usr/lib64/libbrotlidec*.so.* /package/lib/ || true
cp /usr/lib64/libz*.so.* /package/lib/ || true
cp /usr/lib64/libxcb*.so.* /package/lib/ || true
cp /usr/lib64/libgraphite2*.so.* /package/lib/ || true
cp /usr/lib64/libbrotlicommon*.so.* /package/lib/ || true

echo "Copying local fonts..."
# If you have a local 'fonts' folder next to this script, copy it to /package/fonts
if [ -d "./fonts" ]; then
  cp -r ./fonts/* /package/fonts/
fi

# If you also have a fonts.conf, and you want it in the ZIP root:
if [ -f "./fonts.conf" ]; then
  cp ./fonts.conf /package/
fi

echo "Zipping the layer with bin/, lib/, and fonts/ at the root..."
mkdir -p /output
cd /package
zip -r /output/layer.zip .

echo "Done! The layer ZIP is at /output/layer.zip"
echo "Check its contents with: unzip -l /output/layer.zip"
exit 0
