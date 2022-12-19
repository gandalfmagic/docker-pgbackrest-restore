#!/bin/bash

set -C
set -e
set -f
set -o pipefail
set -u

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Add known host ${PGBR_REPO_HOST}"
ssh_keyscan_count=12
while ! ssh-keyscan "${PGBR_REPO_HOST}" >>/var/lib/postgresql/.ssh/known_hosts 2>/dev/null; do
  if [ ${ssh_keyscan_count} -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- ERROR: the ssh-keyscan command failed after 1 minute of retries"
    exit 1
  fi
  ssh_keyscan_count=$((ssh_keyscan_count-1))
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- WARN: the ssh-keyscan command failed, retrying... ${ssh_keyscan_count}"
  sleep 5
done

PGBR_TIME=${PGBR_TIME:-}
PGBR_CLEAN_DATA=${PGBR_CLEAN_DATA:-}

if [ "${PGBR_CLEAN_DATA}" != "" ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Cleaning local postgres data directory"
  for entry in $(ls -1A /var/lib/postgresql/13/main); do
    rm -rf /var/lib/postgresql/12/main/${entry}
  done
fi

touch /tmp/pgbackrest_empty.conf
if [ "${PGBR_TYPE}" == "immediate" ] || [ "${PGBR_TYPE}" == "default" ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started, latest backup set will be used"
  pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=off --pg1-path=/var/lib/postgresql/13/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo"${PGBR_REPO_ID:-1}"-host="${PGBR_REPO_HOST}" --repo"${PGBR_REPO_ID:-1}"-host-user="${PGBR_SSH_USER:-pgbackrest}" --stanza="${PGBR_STANZA}" --type="${PGBR_TYPE}"
elif [ "${PGBR_TYPE}" == "time" ]; then
  if [ "${PGBR_TIME}" == "" ]; then
    >&2 echo "You must specify a valid PITR time with the PGBR_TIME variable"
    exit 1
  fi
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore from ${PGBR_REPO_HOST} started, PITR at ${PGBR_TIME} will be used"
  pgbackrest restore --config=/tmp/pgbackrest_empty.conf --delta --log-level-console=error --log-level-file=off --pg1-path=/var/lib/postgresql/13/main --process-max=${PGBR_PROCESS_MAX} --recovery-option=recovery_target_action=promote --repo"${PGBR_REPO_ID:-1}"-host="${PGBR_REPO_HOST}" --repo"${PGBR_REPO_ID:-1}"-host-user="${PGBR_SSH_USER:-pgbackrest}" --stanza="${PGBR_STANZA}" --type=time --target="${PGBR_TIME}"
fi
echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Restore ended"

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Configuring server"
sed -r -i "s/(#?)listen_addresses = (.*)$/listen_addresses = '*'/" /etc/postgresql/13/main/postgresql.conf
sed -r -i "s/(#?)max_connections = (.*)/max_connections = ${PGBR_PG_MAX_CONNECTIONS:-100}/" /etc/postgresql/13/main/postgresql.conf

if [[ -d /restore.d ]] && [[ "$(ls -1 /restore.d | wc -l)x" != "0x" ]]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting server (script execution)"
  touch /tmp/script_startup.log
  /usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main -c config_file=/etc/postgresql/13/main/postgresql.conf >>/tmp/script_startup.log 2>&1 &

  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to be ready (script execution)..."
  while [[ ! "$(tail -n 1 /tmp/script_startup.log)" =~ 'database system is ready to accept connections' ]]; do
    sleep 3
    echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to be ready (script execution)..."
  done

  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting execution of restore.d scripts"
  find /restore.d -type f -name *.sh -exec {} \;
  echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Ended execution of restore.d scripts"

  kill $(cat /var/run/postgresql/13-main.pid)
  while [[ -f /var/lib/postgresql/13/main/postmaster.pid ]]; do
    sleep 3
    echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Waiting for the database to shutdown (script execution)..."
  done
fi

echo "$(date +'%Y-%m-%d %H:%M:%S %Z') --- LOG: Starting server"
/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main -c config_file=/etc/postgresql/13/main/postgresql.conf
