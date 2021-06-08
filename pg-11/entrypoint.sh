#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

if [ ! -f /var/lib/postgresql/11/main/PG_VERSION ]; then
  mkdir -p /var/lib/postgresql/11/main
  chown -R postgres:postgres /var/lib/postgresql/11
fi

if [ -f /var/lib/postgresql/11/main/postmaster.pid ]; then
  rm /var/lib/postgresql/11/main/postmaster.pid
fi

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Preparing the SSH environment"
SSH_DIR=/var/lib/postgresql/.ssh
(mkdir -p ${SSH_DIR} && chmod 700 ${SSH_DIR} && chown postgres:postgres ${SSH_DIR}) || true
echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Add known host"
ssh-keyscan ${PGBR_REPO_HOST} > ${SSH_DIR}/known_hosts 2>/dev/null
chmod 600 ${SSH_DIR}/known_hosts
chown postgres:postgres ${SSH_DIR}/known_hosts
if [ -f ${SSH_DIR}/id_rsa ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Change id_rsa file permissions"
  chmod 644 ${SSH_DIR}/id_rsa
fi

su postgres -c ./restore.sh
