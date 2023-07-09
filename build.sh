#!/bin/bash

set -xeuo pipefail

if [[ ${SINGULARITY_CONTAINER:-} == "" ]]; then
    SUDO=sudo
else
    SUDO=
fi

export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LC_ALL=C

$SUDO apt-get -y -qq update
$SUDO apt-get -y -qq install git curl xz-utils libunwind-dev

git clone -q --single-branch --depth 1 --branch "v$VERSION" https://github.com/elFarto/nvidia-vaapi-driver.git "nvidia-vaapi-driver-$VERSION"
git clone -q --single-branch --depth 1 https://github.com/NVIDIA/open-gpu-kernel-modules.git

pushd "nvidia-vaapi-driver-$VERSION"
./extract_headers.sh open-gpu-kernel-modules 
rm -f nvidia-include/nvidia-drm-ioctl.h.bak
rm -fr .git*
popd
tar zcf "nvidia-vaapi-driver_$VERSION.orig.tar.gz" "nvidia-vaapi-driver-$VERSION"

pushd "nvidia-vaapi-driver-$VERSION"
curl --silent http://archive.ubuntu.com/ubuntu/pool/universe/n/nvidia-vaapi-driver/nvidia-vaapi-driver_0.0.8-1.debian.tar.xz | tar Jxf -

cat <<EOF | tee /tmp/changelog
nvidia-vaapi-driver ($VERSION-1) UNRELEASED; urgency=low

  * Local packaging.

 -- kumattau <kumattau@gmail.com>  $(date -R)

EOF
cat debian/changelog | tee -a /tmp/changelog
mv --force /tmp/changelog debian/changelog

$SUDO apt-get -y -qq build-dep .
dpkg-buildpackage -us -uc
popd

rm -fr open-gpu-kernel-modules
rm -fr "nvidia-vaapi-driver-$VERSION"

exit 0
