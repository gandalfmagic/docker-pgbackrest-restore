#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

if [ ! -f /var/lib/postgresql/12/main/PG_VERSION ]; then
  mkdir -p /var/lib/postgresql/12/main
  chown -R postgres:postgres /var/lib/postgresql/12
fi

if [ -f /var/lib/postgresql/12/main/postmaster.pid ]; then
  rm /var/lib/postgresql/12/main/postmaster.pid
fi

su postgres -c ./restore.sh
