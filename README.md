# pgbackrest-restore docker container

This container permit to execure a PostgreSQL server instance, recovering the data from a remote pgbackrest repository.

## Execute the container

The container clones the PostgreSQL database from a remote pgbackrest repository, using the following environment variables:

| Name                      | Description                                                                                 |
|---------------------------|---------------------------------------------------------------------------------------------|
| `PGBR_REPO_HOST`          | hostname or IP address of theremote pgbackrest repository                                   |
| `PGBR_REPO_PATH`          | path where the backup is stored on the pgbackrest repository                                |
| `PGBR_STANZA`             | defines the pgbackrest stanza to restore                                                    |
| `PGBR_PROCESS_MAX`        | maximum number of processes used by pgbackrest                                              |
| `PGBR_PG_MAX_CONNECTIONS` | max_connections parameters used on the postgresql server (default: 100)                     |
| `PGBR_SSH_USER`           | pgbackrest user connecting to the remote pgbackrest repository in SSH (default: pgbackrest) |
| `PGBR_SSH_USER_KEY`       | private SSH key used to connect the remote pgbackrest repository                            |
