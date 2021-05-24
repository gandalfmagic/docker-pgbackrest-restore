FROM debian:10.9-slim

ARG PG_VERSION=13.3-1.pgdg100+1
ARG PGBR_VERSION=2.33-1.pgdg100+1
ARG LOCALE_OPT=it_IT.UTF-8

RUN apt-get update && apt-get -y install ssh wget lsb-release gnupg2 && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && apt-get -y install postgresql-13=${PG_VERSION} pgbackrest=${PGBR_VERSION} && \
    echo "host    all             all             0.0.0.0/0               md5" >>/etc/postgresql/13/main/pg_hba.conf && \
    sed -r -i 's/# en_US.UTF-8 (.*)/en_US.UTF-8 \1/' /etc/locale.gen && \
    sed -r -i "s/# ${LOCALE_OPT} (.*)/${LOCALE_OPT} \1/" /etc/locale.gen && \
    locale-gen && \
    apt autoclean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY restore.sh /restore.sh

ENTRYPOINT [ "/entrypoint.sh" ]