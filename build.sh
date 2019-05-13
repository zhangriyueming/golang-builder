#!/bin/bash -e

source /build_environment.sh

# Grab the last segment from the package name
name=${pkgName##*/}

#
# Optional OUTPUT env var to use the "-o" go build switch
# forces build to write the resulting executable or object
# to the named output file
#
output=""
outputFile="${name}"
if [[ ! -z "${OUTPUT}" ]];
then
  outputFile="${OUTPUT}"
  #
  # If OUTPUT env var ends with "/", assume an output directory
  # was specified, and we should append the executable name.
  #
  if [[ "$outputFile" == *"/" ]];
  then
    outputFile="${outputFile}${name}"
  fi
fi
output="-o ${outputFile}"

if [ ! -z "${MAIN_PATH}" ]; 
then
  cd ${MAIN_PATH}
fi

# Compile statically linked version of package
echo "Building $pkgName => ${outputFile}"
if [ ! -z "${BUILD_GOOS}" ];
then
  BUILD_GOARCH=${BUILD_GOARCH:-"amd64"}

  for goos in $BUILD_GOOS; do
    for goarch in $BUILD_GOARCH; do
      echo "Building $name for $goos-$goarch"
      # Why am I redefining the same variables that already existed?
      # Somehow they're not available just from the loop, unless I
      # either export them or do this. My theory is that it's somehow
      # building in another process that doesn't have access to the
      # loop variables. That caused everything to be built for linux.
      (
        GOOS=$goos GOARCH=$goarch CGO_ENABLED=${CGO_ENABLED:-0} go build \
              -a \
              `echo ${output}-$goos-$goarch` \
              --installsuffix cgo \
              --ldflags="${LDFLAGS:--s}"
        #      $pkgName
        # Or just simplely delete $pkgName line
      )
      rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
    done
  done
else
  (
    CGO_ENABLED=${CGO_ENABLED:-0} \
    go build \
    -a \
    ${output} \
    --installsuffix cgo \
    --ldflags="${LDFLAGS:--s}"
    # $pkgName
    # Or just simplely delete $pkgName line
  )
  if [[ "$COMPRESS_BINARY" == "true" ]];
  then
    if [[ ! -z "${outputFile}" ]];
    then
      goupx "${outputFile}"
    else
      goupx $name
    fi
  fi
fi

dockerContextPath="."
if [ ! -z "${DOCKER_BUILD_CONTEXT}" ];
then
  dockerContextPath="${DOCKER_BUILD_CONTEXT}"
fi

if [[ -e "/var/run/docker.sock"  &&  -e "${dockerContextPath}/Dockerfile" ]];
then
  # Default TAG_NAME to package name if not set explicitly
  tagName=${tagName:-"$name":latest}

  # Build the image from the Dockerfile in the package directory
  docker build -t $tagName "$dockerContextPath"
fi