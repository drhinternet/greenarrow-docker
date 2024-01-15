FROM almalinux:9

ARG GA_REPO_KEY
ARG GA_VERSION

RUN echo "[greenarrow]" > /etc/yum.repos.d/greenarrow.repo \
 && echo "name=GreenArrow Software Repository" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "baseurl=https://git.drh.net/key/$GA_REPO_KEY/yum/el\$releasever/production/\$basearch" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "enabled=True" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "gpgcheck=True" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "repo_gpgcheck=True" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "gpgkey=https://git.drh.net/pub/greenarrow.gpg.key" >> /etc/yum.repos.d/greenarrow.repo \
 && dnf -y install epel-release \
 && dnf config-manager --set-enabled crb \
 && dnf -y install greenarrow-$GA_VERSION xfsprogs \
 && dnf clean all \
 && /bin/rm -rf /var/cache/yum \
 && rm /etc/yum.repos.d/greenarrow.repo

RUN echo 1 > /var/hvmail/control/opt.ramdisk_use_tmpfs
RUN touch /var/hvmail/studio/public/custom.css
RUN ln -s /var/hvmail/postgres/16 /var/hvmail/postgres/default

ENTRYPOINT ["/var/hvmail/libexec/greenarrow-docker-entrypoint"]
