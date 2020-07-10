# GreenArrow Docker Integration


## Quick reference

* **Maintained by**: [GreenArrow Email](https://www.greenarrowemail.com)


## GreenArrow

GreenArrow is a high-powered Mail Transfer Agent and Marketing Studio.

Please see [GreenArrow Email](https://www.greenarrowemail.com) for more information.

The provided Dockerfile will work with GreenArrow versions 4.202.1 and above.


<a id="build-image"/>

## Building the image

GreenArrow is installed from packages in a private yum repository. In order to
create the image, you need to have a repository key. If you have not yet
obtained a repository key, [contact GreenArrow](https://www.greenarrowemail.com/contact-us)
to purchase one.

Once you have a repo key, all you need to do is select
[which version to install](https://www.greenarrowemail.com/docs/greenarrow-engine/Change-Log/)
and run the following.

```
docker build \
  --tag greenarrow:4.202.1 \
  --build-arg GA_REPO_KEY=PROVIDED_BY_GREENARROW \
  --build-arg GA_VERSION=4.202.1 \
  .
```


## Initialization

The GreenArrow docker image assumes a persistent volume will be mounted at
`/opt/greenarrow-persistent`. Prior to running GreenArrow, this volume
must be initialized. During initialization, the persistent volume will
be populated with the data GreenArrow needs to function. That persistent
volume will then be used for actually running GreenArrow.

The following command will create a volume `greenarrow-vol1` (if it does not
already exist) and initialize it. These environment variables must be specified.

**`GA_HOSTNAME`**

The hostname to use for this GreenArrow installation. A URL domain and bounce mailbox will be created using this hostname.

**`GA_ADMIN_EMAIL`**

The email address of the primary administrator to use. This address will be used to sign into Marketing Studio.

**`GA_ADMIN_PASSWORD`**

The password for the primary administrator to use. This will be set for both the email address above in Marketing Studio and the "admin" user in Engine's user interface.

```
docker run \
  --rm \
  --mount source=greenarrow-vol1,target=/opt/greenarrow-persistent \
  --env GA_HOSTNAME=greenarrow-testing.com \
  --env GA_ADMIN_EMAIL="user@greenarrowemail.com" \
  --env GA_ADMIN_PASSWORD=abc123 \
  greenarrow:4.202.1 \
  init
```


## Startup

Once the persistent volume is initialized, it is now ready to startup
GreenArrow.

When the container starts up, all of GreenArrow's standard
user-data paths are rewritten as symbolic links pointing into the persistent
volume.

GreenArrow requires a license key to be fully operational.
If you have not yet
obtained a license key, [contact GreenArrow](https://www.greenarrowemail.com/contact-us)
to purchase one.

```
docker run \
  --rm \
  --mount source=greenarrow-vol1,target=/opt/greenarrow-persistent \
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=400m \
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m \
  --expose 10080:80  \ # http
  --expose 10443:443 \ # https
  --expose 10025:25  \ # smtp
  --expose 10587:587 \ # smtp submission
  --expose 10110:110 \ # pop3
  --env GA_LICENSE_KEY="abcdefghijklmnopqrstuvwxyz1234567890" \
  greenarrow:4.202.1 \
  start
```

**This command is doing a lot of heavy lifting, so we'll break it down below.**

```
  --rm \
```

Destroy the container after it exits. GreenArrow stores all of its data that
needs to be saved in the persistent volume. The container can be destroyed
without losing meaningful data.

```
  --mount source=greenarrow-vol1,target=/opt/greenarrow-persistent \
```

Mount the named persistent volume `greenarrow-vol1` at the correct path. The
name of this mount is up to you - but it must be mounted at `/opt/greenarrow-persistent`.

```
  --tmpfs /var/hvmail/qmail-ram/queue:rw,noexec,nosuid,size=400m \
  --tmpfs /var/hvmail/qmail-bounce/queue:rw,noexec,nosuid,size=100m \
```

Give the RAM queue a 400MB tmpfs filesystem, and the bounce queue 100MB. This is
required and GreenArrow will not start if these tmpfs paths have not been configured.
See the section below [Tuning the RAM and bounce queues](#tuning-queues) for more information on
how to select the right size values.

```
  --expose 10080:80  \ # http
  --expose 10443:443 \ # https
  --expose 10025:25  \ # smtp
  --expose 10587:587 \ # smtp submission
  --expose 10110:110 \ # pop3
```

Expose the most common ports on the host network. You may choose to use
a [macvlan network](https://docs.docker.com/network/macvlan/) instead of the
default network driver, in order to provide specific public IP addresses to containers.
In this case, the expose statements do not apply.

```
  --env GA_LICENSE_KEY="abcdefghijklmnopqrstuvwxyz1234567890" \
```

The license key as provided by GreenArrow.

```
  greenarrow:4.202.1 \
```

The Docker image tag to use, as you've defined in the [Building the image](#build-image) section above.

```
  start
```

Pass the "start" command to GreenArrow's docker entrypoint.


## Connecting to the running Docker container

You can connect to the running GreenArrow Docker container using `docker exec` with bash.

```
docker exec --interactive --tty CONTAINER-ID /bin/bash -l
```


<a id="tuning-queues"/>

## Tuning the RAM and bounce queues

See the [GreenArrow Concepts documentation](https://www.greenarrowemail.com/docs/greenarrow-engine/Getting-Started/GreenArrow-Concepts/#queues)
for details on the roles of each of GreenArrow's queues.

Our [Installation Guide](https://www.greenarrowemail.com/docs/greenarrow-engine/Getting-Started/Installation-Guide#tune-greenarrow-engine)
also discusses tuning these values.

We recommend starting with a value of `400m` for the RAM queue and `100m` for
the bounce queue. You can tune these values at a later date if your performance
is being limited by the size of the queues.
