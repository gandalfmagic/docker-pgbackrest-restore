#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

if [ ! -f /var/lib/postgresql/13/main/PG_VERSION ]; then
  mkdir -p /var/lib/postgresql/13/main
  chown -R postgres:postgres /var/lib/postgresql/13
fi

if [ -f /var/lib/postgresql/13/main/postmaster.pid ]; then
  rm /var/lib/postgresql/13/main/postmaster.pid
fi

if [ -f ${SSH_DIR}/id_rsa ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Change id_rsa file permissions"
  chmod 644 ${SSH_DIR}/id_rsa
fi

su postgres -c ./restore.sh
