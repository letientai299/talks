#!/usr/bin/env bash

# Source the common.sh script
# shellcheck source=./common.sh
. "$(git rev-parse --show-toplevel || echo ".")/scripts/common.sh"

cd "$PROJECT_DIR" || exit 1

if ! has reveal-md; then
  if has yarn; then
    yarn global add reveal-md
  elif has npm; then
    npm i -g reveal-md
  else
    echo_error "Yarn and npm not found, can't install reveal-md"
    exit 1
  fi
fi

if ! has nodemon; then
  if has yarn; then
    yarn global add nodemon
  elif has npm; then
    npm i -g nodemon
  else
    echo_warn "Nodemon not found, make watch won't work"
  fi
fi


cd "$WORKING_DIR" || exit 1
