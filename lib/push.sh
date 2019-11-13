#!/bin/bash
set -eou pipefail

# shellcheck source=functions.sh source=lib/functions.sh disable=SC1091
source "$(dirname "$(realpath -s "$0")")/functions.sh"

if [[ $# == 0 ]]; then
  set -- --help
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    "-h" | "--help")
      echo "Usage:"
      echo "../lib/build.sh [-h|--help] [-b|--binary docker|podman] [-d|--delay N] [-n|--dry-run] [--hook URL] [-i|--image supersandro2000/base-alpine|base-alpine] [-m|--manifest] [-t|--tag edge|stable|1.0.0] [--tag-suffix alpine-] [--variant amd64|arm64|armhf] [-v|--verbose]"
      echo "--help         Show this help."
      echo "--binary       Binary which runs the build commands."
      echo "--delay        How many seconds should be waited between pushes."
      echo "--dry-run      Show commands which would be run."
      echo "--hook         URL to send POST request after sucessful push."
      echo "--manifest     Push manifests. Need to be created with manifest.sh before."
      echo "--image        Image being pushed"
      echo "--tag          Tags added to the image."
      echo "--tag-suffix   Suffix added infront of each tag."
      echo "--variant      Variants which should be included seperated by comma. Defaults to amd64,arm64,armhf."
      echo "--verbose      Be more verbose."
      echo
      show_exit_codes
      exit 0
      ;;
    "-b" | "--binary")
      binary="$2"
      shift
      ;;
    "-d" | "--delay")
      delay="$2"
      shift
      ;;
    "-n" | "--dry-run")
      dry_run=true
      ;;
    "-i" | "--image")
      image="$2"
      shift
      ;;
    "--hook")
      hook="$2"
      shift
      ;;
    "-m" | "--manifest")
      export DOCKER_CLI_EXPERIMENTAL=enabled
      manifest=manifest
      ;;
    "-t" | "--tag")
      tag="$2"
      shift
      ;;
    "--tag-suffix")
      tag_suffix="$2"
      shift
      ;;
    "--variant")
      variant="$2"
      shift
      ;;
    "-v" | "--verbose")
      verbose=true
      ;;
    "--version")
      version="$2"
      shift
      ;;
    *)
      echo "Argument $1 is not understood."
      exit 2
      ;;
  esac
  shift
done

if [[ -n ${verbose:-} ]]; then
  set -x
fi

binary="${binary:-docker}"
if [[ -n ${dry_run:-} ]]; then
  binary="echo $binary"
fi

check_tool "$binary --version" docker
check_tool "curl --version" curl

delay=${delay:-3}
if ! [[ $delay =~ ^[0-9]+$ ]]; then
  echo "$delay is not a number. Delay only takes whole numbers."
  exit 2
fi

if [[ -z ${image:-} ]]; then
  echo "You need to supply --image NAME."
  exit 2
else
  if [[ ! $image =~ "/" ]]; then
    image="supersandro2000/$image"
  fi
fi

if [[ -z ${variant:-} ]]; then
  variant="amd64,arm64,armhf"
fi

if [[ -z ${tag:-} && -z ${version:-} ]]; then
  echo "You need to supply either --tag edge|stable|1.0.0 or --version 1.0.0.."
  exit 1
fi

function check_manifest() {
  if $binary inspect "$image:$version" && $binary inspect "$image:latest"; then
    return
  fi
  exit 2
}

function push() {
  arch=$1
  image_variant="$image:${tag_suffix:-}${arch:-}"

  if [[ -n ${tag:-} ]]; then
    retry "$binary ${manifest:-} push $image_variant-$tag"
    sleep 3
  fi

  if [[ -n ${version:-} ]]; then
    retry "$binary ${manifest:-} push $image_variant-$version"
    sleep 3
    retry "$binary ${manifest:-} push $image_variant-latest"
  fi
}

IFS=","
for arch in $variant; do
  case $arch in
    "amd64" | "arm64" | "armhf")
      push "$arch"
      ;;
    *)
      echo "Variant $arch is not supported. See --help for supported variants."
      exit 2
      ;;
  esac
done

if [[ -n ${hook:-} ]]; then
  curl -X POST "$hook"
fi
