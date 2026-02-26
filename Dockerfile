#####
#
# Dockerfile for building Steampipe FDW on Linux
# Uses AlmaLinux 9 (glibc 2.34) to match the pg_lake runtime image.
#
# Build the image with:
#   docker build --pull -f Dockerfile -t steampipe_fdw_builder .
#
# Run with:
#   docker run -it --rm --name sp_fdw_builder \
#     -v $(pwd):/tmp/ext \
#     -v steampipe-gomod-cache:/home/postgres/go/pkg/mod \
#     -v steampipe-gobuild-cache:/home/postgres/.cache/go-build \
#     steampipe_fdw_builder
#
# Then inside the container:
#   cd /tmp/ext
#   YES=1 ./build.sh salesforce v1.4.0          # builds for PG 14-17
#   YES=1 ./build.sh salesforce v1.4.0 17       # builds for PG 17 only
#   YES=1 ./build-all.sh                        # builds all plugins
#
#####

FROM almalinux:9

# Install EPEL (for golang), enable CRB (for perl-IPC-Run), and add PGDG YUM repo
RUN dnf -y install epel-release \
  && dnf config-manager --enable crb \
  && dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install Go, build tools, and PostgreSQL dev headers for all supported versions
# --allowerasing: AlmaLinux 9 ships curl-minimal which conflicts with full curl
RUN dnf -y --allowerasing install \
  golang \
  perl-IPC-Run \
  postgresql14-server postgresql14-devel \
  postgresql15-server postgresql15-devel \
  postgresql16-server postgresql16-devel \
  postgresql17-server postgresql17-devel \
  gcc make git wget curl ca-certificates \
  redhat-rpm-config \
  gettext rsync which \
  glibc-langpack-en \
  && dnf clean all

# PGDG RPM installs pg_config at /usr/pgsql-XX/bin/pg_config.
# build.sh expects /usr/pgsql-XX/bin/pg_config (updated to match RPM layout).

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# postgres user is already created by postgresql*-server packages
RUN id postgres 2>/dev/null || useradd -m postgres

# Pre-create Go cache directories with correct ownership for volume mounts
RUN mkdir -p /home/postgres/go/pkg/mod /home/postgres/.cache/go-build \
  && chown -R postgres:postgres /home/postgres/go /home/postgres/.cache

WORKDIR /tmp/ext
USER postgres
