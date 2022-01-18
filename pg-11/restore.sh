#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Add known host"
ssh-keyscan ${PGBR_REPO_HOST} >> /var/lib/postgresql/.ssh/known_hosts 2>/dev/null

PGBR_TIME=${PGBR_TIME:-}
PGBR_CLEAN_DATA=${PGBR_CLEAN_DATA:-}

if [ "${PGBR_CLEAN_DATA}" != "" ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Cleaning local postgres data directory"
  for entry in $(ls -1A /var/lib/postgresql/11/main); do
    rm -rf /var/lib/postgresql/11/main/${entry}
  done
fi

touch /tmp/pgbackrest_empty.conf
if [ "${PGBR_TYPE}" == "immediate" ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started, latest backup set will be used"
  pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=off --pg1-path=/var/lib/postgresql/11/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo1-host="${PGBR_REPO_HOST}" --repo1-host-user="${PGBR_SSH_USER:-pgbackrest}" --repo1-path="${PGBR_REPO_PATH}" --stanza="${PGBR_STANZA}" --type=immediate
elif [ "${PGBR_TYPE}" == "time" ]; then
  if [ "${PGBR_TIME}" == "" ]; then
    >&2 echo "You must specify a valid PITR time with the PGBR_TIME variable"
    exit 1
  fi
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started, PITR at ${PGBR_TIME} will be used"
  pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=off --pg1-path=/var/lib/postgresql/11/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo1-host="${PGBR_REPO_HOST}" --repo1-host-user="${PGBR_SSH_USER:-pgbackrest}" --repo1-path="${PGBR_REPO_PATH}" --stanza="${PGBR_STANZA}" --type=time --target="${PGBR_TIME}"
fi
echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore ended"

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Configuring server"
sed -r -i "s/(#?)listen_addresses = (.*)$/listen_addresses = '*'/" /etc/postgresql/11/main/postgresql.conf
sed -r -i "s/(#?)max_connections = (.*)/max_connections = ${PGBR_PG_MAX_CONNECTIONS:-100}/" /etc/postgresql/11/main/postgresql.conf

if [[ -d /restore.d ]] && [[ "$(ls -1 /restore.d | wc -l)x" != "0x" ]]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting server (script execution)"
  touch /tmp/script_startup.log
  /usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf >>/tmp/script_startup.log 2>&1 &

  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to be ready (script execution)..."
  while [[ ! "$(tail -n 1 /tmp/script_startup.log)" =~ 'database system is ready to accept connections' ]]; do
    sleep 3
    echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to be ready (script execution)..."
  done

  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting execution of restore.d scripts"
  find /restore.d -type f -name *.sh -exec {} \;
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Ended execution of restore.d scripts"

  kill $(cat /var/run/postgresql/11-main.pid)
  while [[ -f /var/lib/postgresql/11/main/postmaster.pid ]]; do
    sleep 3
    echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to shutdown (script execution)..."
  done
fi

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting server"
/usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf
