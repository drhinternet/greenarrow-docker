FROM centos:7

ARG GA_REPO_KEY
ARG GA_VERSION

RUN echo "[greenarrow]" > /etc/yum.repos.d/greenarrow.repo \
 && echo "name=GreenArrow Software Repository" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "baseurl=https://git.drh.net/key/$GA_REPO_KEY/yum/el\$releasever/production/\$basearch" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "enabled=False" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "gpgcheck=True" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "repo_gpgcheck=True" >> /etc/yum.repos.d/greenarrow.repo \
 && echo "gpgkey=https://git.drh.net/pub/greenarrow.gpg.key" >> /etc/yum.repos.d/greenarrow.repo \
 && yum --enablerepo=greenarrow -y install greenarrow-$GA_VERSION \
 && rm /etc/yum.repos.d/greenarrow.repo

RUN echo 1 > /var/hvmail/control/opt.ramdisk_use_tmpfs

ENTRYPOINT /var/hvmail/libexec/greenarrow-docker-entrypoint
