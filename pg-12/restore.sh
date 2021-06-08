#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Add known host"
ssh-keyscan ${PGBR_REPO_HOST} >> /var/lib/postgresql/.ssh/known_hosts 2>/dev/null

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started"
touch /tmp/pgbackrest_empty.conf
pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=error --pg1-path=/var/lib/postgresql/12/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo1-host="${PGBR_REPO_HOST}" --repo1-host-user="${PGBR_SSH_USER:-pgbackrest}" --repo1-path="${PGBR_REPO_PATH}" --stanza="${PGBR_STANZA}" --type=immediate
echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore ended"

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: PostgreSQL server started"
sed -r -i "s/(#?)listen_addresses = (.*)$/listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf
sed -r -i "s/(#?)max_connections = (.*)/max_connections = ${PGBR_PG_MAX_CONNECTIONS:-100}/" /etc/postgresql/12/main/postgresql.conf
/usr/lib/postgresql/12/bin/postgres -D /var/lib/postgresql/12/main -c config_file=/etc/postgresql/12/main/postgresql.conf
