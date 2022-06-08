# GreenArrow Docker Integration

[![](https://www.greenarrowemail.com/docs/assets/greenarrow-logo.5a0f5393b05e.png)](https://www.greenarrowemail.com)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Quick reference](#quick-reference)
- [GreenArrow](#greenarrow)
- [Prerequisites](#prerequisites)
- [Using GreenArrow in Docker](#using-greenarrow-in-docker)
  - [(1) Clone the GreenArrow Docker repository](#1-clone-the-greenarrow-docker-repository)
  - [(2) Select a Linux distribution](#2-select-a-linux-distribution)
  - [(3) Build the image](#3-build-the-image)
  - [(4) Initialize the persistent volume](#4-initialize-the-persistent-volume)
  - [(5) Start GreenArrow](#5-start-greenarrow)
  - [(6) Connecting to the running Docker container](#6-connecting-to-the-running-docker-container)
  - [(7) Finish installation](#7-finish-installation)
- [Image entrypoint](#image-entrypoint)
- [Stopping GreenArrow](#stopping-greenarrow)
- [Upgrading GreenArrow](#upgrading-greenarrow)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!--

  table of contents generated/updated with:

    doctoc --notitle README.markdown --maxlevel 3

-->


## Quick reference

* **Maintained by**: [GreenArrow Email](https://www.greenarrowemail.com)
* **Documentation**: [GreenArrow Documentation](https://www.greenarrowemail.com/docs/)
* **Support**: [GreenArrow Technical Support Contact Info](https://www.greenarrowemail.com/docs/greenarrow-engine/Technical-Support-Contact-Info)


## GreenArrow

GreenArrow is a high-powered Mail Transfer Agent and Marketing Studio.

Please see [GreenArrow Email](https://www.greenarrowemail.com) for more information.

The provided Dockerfile will work with GreenArrow versions 4.202.2 and above.


## Prerequisites

* Docker
* GreenArrow repository key
* GreenArrow license key

If you do not have a valid repository key and license key,
[contact GreenArrow](https://www.greenarrowemail.com/contact-us) to purchase one.


## Using GreenArrow in Docker

### (1) Clone the GreenArrow Docker repository

```
git clone https://github.com/drhinternet/greenarrow-docker.git
cd greenarrow-docker
```


<a id="build-image"/>

### (2) Select a Linux distribution

These instructions create a Docker container that runs CentOS 7 by default, but
Debian 10 Docker containers are also supported by GreenArrow 4.209.0 and later.

If you prefer Debian 10, replace `--file Dockerfile` with
`--file Dockerfile.debian10` in the `docker build` command below.

### (3) Build the image

GreenArrow is installed from packages in a private repository. In order to
create the image, you need to specify a valid repository key.

Select
[which version to install](https://www.greenarrowemail.com/docs/greenarrow-engine/Change-Log/)
and run the following. Replace `PROVIDED_BY_GREENARROW` with your actual repository key.


```
docker build \
  --tag greenarrow:4.258.0 \
  --build-arg GA_REPO_KEY=PROVIDED_BY_GREENARROW \
  --build-arg GA_VERSION=4.258.0 \
  --file Dockerfile \
  .
```


### (4) Initialize the persistent volume

The GreenArrow Docker image requires a persistent volume to be mounted at
`/opt/greenarrow-persistent`. Prior to running GreenArrow, this volume
must be initialized. During initialization, the persistent volume will
be populated with the data GreenArrow needs to function. That persistent
volume will then be used for actually running GreenArrow.

The filesystem where the volume is stored should be one of those
[supported by GreenArrow](https://www.greenarrowemail.com/docs/greenarrow-engine/Getting-Started/Installation-Guide#configure-filesystems)
(ext4 and XFS).

The following command will create a volume `greenarrow-vol1` (if it does not
already exist) and initialize it. These environment variables can be specified.

#### Environment variables

**`GA_HOSTNAME`** (required)

The hostname to use for this GreenArrow installation. This should be a fully
qualified domain name. A URL domain and bounce mailbox will be created using
this hostname.

**`GA_ADMIN_EMAIL`** (required)

The email address of the primary administrator to use. This will be the Marketing Studio username.

**`GA_ADMIN_PASSWORD`** (required)

The password for the primary administrator to use. This will be set for both the email address above in Marketing Studio and the "admin" user in Engine's user interface.

If you don't want to specify your production password as an environment variable, we recommend
setting a "dummy" password here then changing your password in both
[Engine](https://www.greenarrowemail.com/docs/greenarrow-engine/Configuration/General-Settings#web-interface-password) and
[Studio](https://www.greenarrowemail.com/docs/greenarrow-studio/Organizations/User-Management).

**`GA_LICENSE_KEY`** (optional)

The license key that will be written to `/var/hvmail/control/license_key`.

Specifying the license key during persistent volume initialization is optional.

The license key is updated periodically, as such some users may not want it as part of container initialization.

#### Example initialization command

The following command will create a volume `greenarrow-vol1` (if it does not
already exist) and initialize it.

```
docker run \
  --rm \
  --mount source=greenarrow-vol1,target=/opt/greenarrow-persistent \
  --env GA_HOSTNAME=greenarrow-testing.com \
  --env GA_ADMIN_EMAIL="user@greenarrowemail.com" \
  --env GA_ADMIN_PASSWORD=abc123 \
  greenarrow:4.258.0 \
  init
```

<a id="start-greenarrow"/>

### (5) Start GreenArrow

Once the persistent volume is initialized, it is now ready to startup
GreenArrow.

When the container starts up, all of GreenArrow's standard
user-data paths are rewritten as symbolic links pointing into the persistent
volume.

GreenArrow requires a license key to be fully operational.

The example below uses
[the default network driver _bridge_](https://docs.docker.com/network/)
and exposes ports to the host network. This does not provide GreenArrow with
any public IP addresses.  Most installations of GreenArrow should have at least
one public IP address from which to deliver email.  You may choose to use
the [_macvlan_ network driver](https://docs.docker.com/network/macvlan/) instead of the
default, in order to provide specific public IP addresses to containers.
In this case, the expose statements below do not apply.

#### Environment variables

**`GA_RAMDISK_SIZE`** (required)

The ramdisk size to use for this container.

This option is tightly coupled with the two `--tmpfs` arguments required to
start the container. If the `--tmpfs` arguments are missing, or are of
insufficient size, GreenArrow will not start.

Refer to our [RAM Queue Size](https://www.greenarrowemail.com/docs/greenarrow-engine/Configuration/General-Settings#ram-queue-size)
documentation for more information about the available size options.

The most common sizes are `xlarge_500mb_2000conn` (400MB RAM queue, 100MB bounce queue)
and `xxlarge_3300mb_12000conn` (3200MB RAM queue, 100MB bounce queue). The tmpfs filesystem
is stored in RAM, so this has a direct impact on RAM utilization.

Here's a list of what `--tmpfs` arguments you need for each of our supported RAM disk sizes:

* micro_30mb_100conn
  ```
  --env GA_RAMDISK_SIZE=micro_30mb_100conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=20m,nr_inodes=16000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=10m,nr_inodes=4000
  ```
* small_100mb_500conn
  ```
  --env GA_RAMDISK_SIZE=small_100mb_500conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=80m,nr_inodes=16000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=20m,nr_inodes=4000
  ```
* medium_160mb_1000conn
  ```
  --env GA_RAMDISK_SIZE=medium_160mb_1000conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=140m,nr_inodes=16000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=20m,nr_inodes=4000
  ```
* large_250mb_1000conn
  ```
  --env GA_RAMDISK_SIZE=large_250mb_1000conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=200m,nr_inodes=16000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=50m,nr_inodes=4000
  ```
* xlarge_1000mb_2000conn_multiqueue
  ```
  --env GA_RAMDISK_SIZE=xlarge_1000mb_2000conn_multiqueue
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=900m,nr_inodes=32000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m,nr_inodes=4000
  ```
* xlarge_500mb_2000conn
  ```
  --env GA_RAMDISK_SIZE=xlarge_500mb_2000conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=400m,nr_inodes=32000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m,nr_inodes=4000
  ```
* xxlarge_3300mb_12000conn_multiqueue
  ```
  --env GA_RAMDISK_SIZE=xxlarge_3300mb_12000conn_multiqueue
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=3200m,nr_inodes=16000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m,nr_inodes=4000
  ```
* xxlarge_3300mb_12000conn
  ```
  --env GA_RAMDISK_SIZE=xxlarge_3300mb_12000conn
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=3200m,nr_inodes=320000
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m,nr_inodes=4000
  ```

**`GA_LICENSE_KEY`** (optional)

The license key as provided by GreenArrow.

If you prefer to not specify the
license key in this way, see
[this document on setting the license key](https://www.greenarrowemail.com/docs/greenarrow-engine/Configuration/License-Key)
inside the running container.

```
  --env GA_LICENSE_KEY=abcdefghijklmnopqrstuvwxyz1234567890
```

#### Example GreenArrow start

```
docker run \
  --rm \
  --mount source=greenarrow-vol1,target=/opt/greenarrow-persistent \
  --publish 20080:80  \
  --publish 20443:443 \
  --publish 20025:25  \
  --publish 20587:587 \
  --publish 20110:110 \
  --env GA_LICENSE_KEY="abcdefghijklmnopqrstuvwxyz1234567890" \
  --env GA_RAMDISK_SIZE=xlarge_500mb_2000conn \
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=400m,nr_inodes=32000 \
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m,nr_inodes=4000 \
  greenarrow:4.258.0 \
  start
```


### (6) Connecting to the running Docker container

You can connect to your `greenarrow-name` container using `docker exec` with bash.

```
docker exec --interactive --tty greenarrow-name /bin/bash -l
```

### (7) Finish installation

There are some steps described in the
[GreenArrow Installation Guide](https://www.greenarrowemail.com/docs/greenarrow-engine/Getting-Started/Installation-Guide)
that haven't been completed above.

You can pick up at the [Configure HTTPS](https://www.greenarrowemail.com/docs/greenarrow-engine/Getting-Started/Installation-Guide#configure-https)
step and proceed from there. Skip the "Tune GreenArrow Engine" section.


## Image entrypoint

When starting up in the Docker image, GreenArrow launches the command `/var/hvmail/libexec/greenarrow-docker-entrypoint`.

This command accepts two possible parameters, `init` and `start`. The `init`
command initializes a previously-uninitialized Docker volume. The `start`
command starts GreenArrow's runtime services. This document describes the
behavior of both of these commands.


## Stopping GreenArrow

It's important to stop the GreenArrow container cleanly. This gives it an
opportunity to ensure its data is written to the persistent volume prior to
exiting.

There are several ways to stop your `greenarrow-name` container cleanly:

* Send `SIGINT` or `SIGTERM` to the container.
* Press control-c if your container is running in a terminal session.
* Docker's stop command: `docker stop greenarrow-name`

Once the container has exited, it's safe to remove it.


## Upgrading GreenArrow

Upgrades should be done by creating a new image with the new
[GreenArrow version number](https://www.greenarrowemail.com/docs/greenarrow-engine/Change-Log/).
Any data migrations that need to happen will be run automatically when the new
container running the new image starts up.

Upgrades are as simple as:

1. [Create a new Docker image for the new version](#build-image).
2. Stop the running container.
3. [Run a new container using the new image](#start-greenarrow).
