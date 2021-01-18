#!/bin/bash
set -euo pipefail

BUILD_BY=${BUILD_BY:-"admin@ovirt.club"}
BUILD_TYPE=${BUILD_TYPE:-"beta"}
BUILD_VERSION=${BUILD_VERSION:-"1.3"}
IMAGE_NAME=${IMAGE_NAME:-"vyos/vyos-build"}
BUILD_SCRIPT_BRANCH=${BUILD_SCRIPT_BRANCH:-"equuleus"}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if ! [ -x "$(command -v unzip)" ]; then
  sudo apt-get install -y unzip
fi

! rm -rf "vyos-build"

# download scripts
git clone --branch ${BUILD_SCRIPT_BRANCH} https://github.com/vyos/vyos-build.git

# build image
pushd "vyos-build"
echo "configuring..."
docker run --rm --privileged -v $(pwd):/vyos -w /vyos "${IMAGE_NAME}:${BUILD_SCRIPT_BRANCH}" ./configure --build-by "${BUILD_BY}" --build-type "${BUILD_TYPE}" --version "${BUILD_VERSION}"

for var in "$@"
do
    echo "Building $var..."
    
    # do not set -j
    docker run --rm --privileged -v $(pwd):/vyos -w /vyos "${IMAGE_NAME}:${BUILD_SCRIPT_BRANCH}" make "${var}"
done

# collect artifacts
if [ -z ${BUILD_ARTIFACTSTAGINGDIRECTORY+x} ]; then 
   echo "Environment variable BUILD_ARTIFACTSTAGINGDIRECTORY is unset, skipping"
else
   ls -alh build/
   
   # recurse intentionally disabled
   ! cp -d build/* ${BUILD_ARTIFACTSTAGINGDIRECTORY}
fi

