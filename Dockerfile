FROM debian:10.9-slim

RUN apt-get update && apt-get -y install ssh wget lsb-release gnupg2 && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && apt-get -y install postgresql-11 pgbackrest && \
    apt autoclean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

USER postgres

ENTRYPOINT [ "/entrypoint.sh" ]
