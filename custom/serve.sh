#!/bin/bash

DEPS_DIR="$HOME/.dxr"

function start_elasticsearch() {
  docker run -d -p 9200:9200 -p 9300:9300 \
    --mount source=es_volume,target=/usr/share/elasticsearch/data elasticsearch:1.4 \
    >/dev/null 2>&1
  sleep 5
}

start_elasticsearch

source "$DEPS_DIR/dxr/venv/bin/activate"
dxr serve -t -c "$DEPS_DIR/.dxr.config"
