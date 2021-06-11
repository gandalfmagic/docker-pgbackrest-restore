# pgbackrest-restore docker container

This container permit to execure a PostgreSQL server instance, recovering the data from a remote pgbackrest repository.

## Execute the container

The container clones the PostgreSQL database from a remote pgbackrest repository, using the following environment variables:

| Name                      | Description                                                                                   |
|---------------------------|-----------------------------------------------------------------------------------------------|
| `PGBR_REPO_HOST`          | hostname or IP address of theremote pgbackrest repository                                     |
| `PGBR_REPO_PATH`          | path where the backup is stored on the pgbackrest repository                                  |
| `PGBR_STANZA`             | defines the pgbackrest stanza to restore                                                      |
| `PGBR_PROCESS_MAX`        | maximum number of processes used by pgbackrest                                                |
| `PGBR_PG_MAX_CONNECTIONS` | max_connections parameters used on the postgresql server (default: 100)                       |
| `PGBR_SSH_USER`           | pgbackrest user connecting to the remote pgbackrest repository in SSH (default: `pgbackrest`) |
| `PGBR_TYPE`               | type of restore (valid values: `immediate`, `time`)                                           |
| `PGBR_TIME`               | time for PITR, used only when `PGBR_TYPE` is `time`                                           |
| `PGBR_CLEAN_DATA`         | clean the local postgres data before the pgbackrest restore (`true` when defined)             |

To access the remote backup serve, you **must** provide a valid ssh key, mountig it as a volume in `/var/lib/postgresql/.ssh/id_rsa`.

> **NOTE**: pgbackrest time format must be YYYY-MM-DD HH:MM:SS with optional msec and optional timezone (+/- HH or HHMM or HH:MM) - if timezone is omitted, local time is assumed (for UTC use +00)
## Examples

### Formatting time for pgbackrest using the linux `date` command:

Current time, using New York timezone:

```bash
$ TZ=America/New_York date '+%Y-%m-%d %H:%M:%S.%6N%z'
2021-06-09 05:37:12.113838-0400
```

Yesterday, right before midnight, using New York timezone:

```bash
$ TZ=America/New_York date -d '-1 day' '+%Y-%m-%d 23:59:59.999999%z'
2021-06-08 23:59:59.999999-0400
```

### Testing the container locally

Restore a server using the latest backup set:

```bash
$ docker run -ti --rm \
    -e PGBR_STANZA=test_stanza \
    -e PGBR_REPO_HOST=10.10.10.1 \
    -e PGBR_REPO_PATH=/var/lib/pgbackrest \
    -e PGBR_PROCESS_MAX=4 \
    -e PGBR_PG_MAX_CONNECTIONS=200 \
    -e PGBR_TYPE=immediate \
    -v /home/user/.ssh/id_rsa:/var/lib/postgresql/.ssh/id_rsa \
    gandalfmagic/pgbackrest-restore-pg11:0.7
```

Restore a server using point-in-time restore:

```bash
$ docker run -ti --rm \
    -e PGBR_STANZA=test_stanza \
    -e PGBR_REPO_HOST=10.10.10.1 \
    -e PGBR_REPO_PATH=/var/lib/pgbackrest \
    -e PGBR_PROCESS_MAX=4 \
    -e PGBR_PG_MAX_CONNECTIONS=200 \
    -e PGBR_TYPE=time \
    -e PGBR_TIME="$(TZ=America/New_York date -d '-1 day' '+%Y-%m-%d 23:59:59.999999%z')" \
    -v /home/user/.ssh/id_rsa:/var/lib/postgresql/.ssh/id_rsa \
    gandalfmagic/pgbackrest-restore-pg11:0.7
```

Restore a server using the latest backup set, forcing a full restore:

```bash
$ docker run -ti --rm \
    -e PGBR_STANZA=test_stanza \
    -e PGBR_REPO_HOST=10.10.10.1 \
    -e PGBR_REPO_PATH=/var/lib/pgbackrest \
    -e PGBR_PROCESS_MAX=4 \
    -e PGBR_PG_MAX_CONNECTIONS=200 \
    -e PGBR_TYPE=immediate \
    -e PGBR_CLEAN_DATA=true \
    -v /home/user/.ssh/id_rsa:/var/lib/postgresql/.ssh/id_rsa \
    gandalfmagic/pgbackrest-restore-pg11:0.7
```
