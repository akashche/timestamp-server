#!/bin/bash

set -e

BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_DIR="$BIN_DIR"/..

pushd "$SERVER_DIR"/work > /dev/null

python "$BIN_DIR"/server.py

popd > /dev/null