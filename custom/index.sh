#!/bin/bash

set -eu

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2> /dev/null && pwd -P )"
DEPS_DIR="$HOME/.dxr" && mkdir -p "$DEPS_DIR"

function setup_deps() {
  export NODE_BINDIR="$DEPS_DIR/node-v6.17.1-darwin-x64/bin"
  export LLVM_BINDIR="$DEPS_DIR/clang+llvm-3.8.0-x86_64-apple-darwin/bin"

  test -f "$DEPS_DIR/.deps_installed" && return

  local node_v6_url="https://nodejs.org/dist/latest-v6.x/node-v6.17.1-darwin-x64.tar.gz"
  local clang_url="https://releases.llvm.org/3.8.0/clang+llvm-3.8.0-x86_64-apple-darwin.tar.xz"

  local node_archive="$DEPS_DIR/$(basename $node_v6_url)"
  local clang_archive="$DEPS_DIR/$(basename $clang_url)"

  curl -o "$node_archive" "$node_v6_url"
  curl -o "$clang_archive" "$clang_url"

  tar -x -C "$(dirname "$node_archive")" -f "$node_archive"
  tar -x -C "$(dirname "$clang_archive")" -f "$clang_archive"

  rm -f "$node_archive" "$clang_archive"

  touch "$DEPS_DIR/.deps_installed"
}

function setup_dxr() {
  local dxr_remote="https://github.com/vkalintiris/dxr.git"
  local dxr_dir="$DEPS_DIR/dxr"

  export DXR_BINDIR="$dxr_dir/tooling/binaries"

  if [ -f "$DEPS_DIR/.dxr_installed" ]; then
    set +u; source "$dxr_dir/venv/bin/activate"; set -u
    return
  fi

  git clone -b custom --depth 10 "$dxr_remote" "$dxr_dir"
  virtualenv -p /opt/uber/ios-devex/python-2.7.17/bin/python "$dxr_dir/venv"
  set +u; source "$dxr_dir/venv/bin/activate"; set -u

  # Set MACOSX_DEPLOYMENT_TARGET=10.9 at ~/.node-gyp/x.x.x/include/node/common.gypi
  env PATH="$NODE_BINDIR:$PATH" \
    make -C "$dxr_dir" V=1 static requirements .dxr_installed

  # clang plugin
  env PATH="$LLVM_BINDIR:$PATH" \
    "$dxr_dir/dxr/plugins/clang/build-clang-plugin.py"

  # ES image
  docker build "$dxr_dir/tooling/docker/es"

  touch "$DEPS_DIR/.dxr_installed"
}

function print_usage() {
  echo "Usage:"
  echo "./tools/dxr/index.sh --source-folder <dir> --compile-commands <file>"
  exit 1
}

function parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      "--source-folder")
        SOURCE_FOLDER=$2
        shift
        ;;
      "--compile-commands")
        COMPILE_COMMANDS=$2
        shift
        ;;
      *)
        echo "Usage:"
        echo "./tools/dxr/index.sh --source-folder <dir> --compile-commands <file>"
        exit 1
    esac

    shift
  done

  if [ -z "$SOURCE_FOLDER" ] || [ -z "$COMPILE_COMMANDS" ]; then
    print_usage
  fi

  if [ ! -d "$SOURCE_FOLDER" ] || [ ! -f "$COMPILE_COMMANDS" ]; then
    print_usage
  fi
}

function generate_dxr_config() {
  OBJECT_FOLDER="$(mktemp -d)"
  LOG_FOLDER="$(mktemp -d)/dxr-logs-{tree}"
  TEMP_FOLDER="$(mktemp -d)/dxr-temp-{tree}"

  m4 -DOBJECT_FOLDER="$OBJECT_FOLDER" \
     -DLOG_FOLDER="$LOG_FOLDER" \
     -DTEMP_FOLDER="$TEMP_FOLDER" \
     -DSOURCE_FOLDER="$SOURCE_FOLDER" \
     -DCOMPILE_COMMANDS="$COMPILE_COMMANDS" <"$THIS_DIR/dxr.config.template" | \
  tee "$DEPS_DIR/.dxr.config"
}

function start_elasticsearch() {
  ES_CONTAINER_ID=$(
    docker run -d -p 9200:9200 -p 9300:9300 \
      --mount source=es_volume,target=/usr/share/elasticsearch/data elasticsearch:1.4
  )
  sleep 30
}

function stop_elasticsearch() {
  docker stop "$ES_CONTAINER_ID" >/dev/null 2>&1
}

setup_deps && setup_dxr
export PATH="$DXR_BINDIR:$LLVM_BINDIR:$NODE_BINDIR:$PATH" && set +u

parse_arguments "$@"
generate_dxr_config

start_elasticsearch
dxr index -v -c "$DEPS_DIR/.dxr.config"
stop_elasticsearch

rm -rf "$OBJECT_FOLDER" "$LOG_FOLDER" "$TEMP_FOLDER"
