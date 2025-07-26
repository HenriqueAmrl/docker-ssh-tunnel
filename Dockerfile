FROM alpine:3.21.2
MAINTAINER Jujhar Singh <jujhar+docker@jujhar.com>

LABEL org.label-schema.vcs-url="https://github.com/HenriqueAmrl/docker-ssh-tunnel"

RUN apk --no-cache add openssh-client

ADD run.sh /run.sh

# Security fix for CVE-2016-0777 and CVE-2016-0778
RUN echo -e 'Host *\nUseRoaming no' >> /etc/ssh/ssh_config

ENTRYPOINT ["/bin/sh", "-c", "/run.sh"]
