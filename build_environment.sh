#!/bin/bash

tagName=$1

if ( find /src -maxdepth 0 -empty | read v );
then
  echo "Error: Must mount Go source code into /src directory"
  exit 990
fi

# Construct Go package path
modFlag=""
if [ -e "/src/go.mod" ];
then
  if [ ! -z "${MAIN_PATH}" ]; 
  then
    echo "go.mod found, MAIN_PATH: ${MAIN_PATH}"
    export GO111MODULE=on
    modFlag="-mod=vendor"
    pkgBase="$(go list -mod=vendor 2>/dev/null || true)"
    path=$(cd /src && ls -d -1 ${MAIN_PATH})
    pkgName="$pkgBase/${MAIN_PATH}"
  else
    pkgName="$(go list -e -f '{{.ImportComment}}' 2>/dev/null || true)"
    pkgBase="$pkgName"
  fi
else
  if [ ! -z "${MAIN_PATH}" ]; 
  then
    echo "MAIN_PATH: ${MAIN_PATH}"
    # pkgName="$(cd ${MAIN_PATH} && go list -e -f '{{.ImportComment}}' ./... 2>/dev/null || true)"
    pkgName="$(go list -e -f '{{.ImportComment}}' ./... 2>/dev/null | grep ${MAIN_PATH} || true)"
    path=$(cd /src && ls -d -1 ${MAIN_PATH})
    pkgBase=${pkgName%/$path}
  else
    pkgName="$(go list -e -f '{{.ImportComment}}' 2>/dev/null || true)"
    pkgBase="$pkgName"
  fi
fi

echo "using pkgName: $pkgName, pkgBase: $pkgBase"

if [ -z "$pkgName" ];
then
  echo "Error: Must add canonical import path to root package, or specify the MAIN_PATH env var"
  exit 992
fi

# Grab just first path listed in GOPATH
goPath="${GOPATH%%:*}"

pkgPath="$goPath/src/$pkgBase"

# Set-up src directory tree in GOPATH
mkdir -p "$(dirname "$pkgPath")"

# Link source dir into GOPATH
ln -sf /src "$pkgPath"

cd "$pkgPath/$MAIN_PATH"

if [ -e "$pkgPath/vendor" ];
then
  # Enable vendor experiment
  export GO15VENDOREXPERIMENT=1
elif [ -e "$pkgPath/Godeps/_workspace" ];
then
  # Add local godeps dir to GOPATH
  GOPATH=$pkgPath/Godeps/_workspace:$GOPATH
else
  # Get all package dependencies
  if [ ! -z "${BUILD_GOOS}" ];
  then
    `GOOS=${BUILD_GOOS:-""} GOARCH=${BUILD_GOARCH:-""} go get -t -d -v ./...`
  else
    go get -t -d -v ./...
  fi
fi