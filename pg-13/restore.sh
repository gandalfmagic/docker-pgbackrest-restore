#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Preparing the SSH environment"
mkdir -p ${HOME}/.ssh && chmod 700 ${HOME}/.ssh
ssh-keyscan ${PGBR_REPO_HOST} > ${HOME}/.ssh/known_hosts 2>/dev/null && chmod 600 ${HOME}/.ssh/known_hosts
echo "${PGBR_SSH_USER_KEY}" > ${HOME}/.ssh/id_rsa && chmod 600 ${HOME}/.ssh/id_rsa

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started"
touch /tmp/pgbackrest_empty.conf
pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=error --pg1-path=/var/lib/postgresql/13/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo1-host="${PGBR_REPO_HOST}" --repo1-host-user="${PGBR_SSH_USER:-pgbackrest}" --repo1-path="${PGBR_REPO_PATH}" --stanza="${PGBR_STANZA}" --type=immediate
echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore ended"

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: PostgreSQL server started"
sed -r -i "s/(#?)listen_addresses = (.*)$/listen_addresses = '*'/" /etc/postgresql/13/main/postgresql.conf
sed -r -i "s/(#?)max_connections = (.*)/max_connections = ${PGBR_PG_MAX_CONNECTIONS:-100}/" /etc/postgresql/13/main/postgresql.conf
/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main -c config_file=/etc/postgresql/13/main/postgresql.conf
