#!/bin/bash

CONF_DIRS="/home/podman/data/rocketchat/{uploads,scripts,db}"

cd $(dirname "$0")
PODNAME=$(basename $(pwd))

if podman pod exists "$PODNAME"; then
  echo "pod $PODNAME already exists" 1>&2
  exit 1
fi

# create container config dir
eval mkdir -p $CONF_DIRS

export SERVER_FQDN=$(hostname -f)

if [ -z "$ROCKETCHAT_DOMAIN" ]; then
  echo "ROCKETCHAT_DOMAIN must be set to the rocketchat Domainname f.e. rocketchat.example.ph.de" 1>&2
  exit 1
fi

export ROCKETCHAT_DOMAIN

podman-compose up -d
re=$?
if [ $re -eq 0 ]; then
  echo "pod and container successfully created."
  echo "on first run it might take up to 2 min until the container is up and running"
  echo "Container configuration can be found in $CONF_DIRS"

  cp nginx.conf nginx.conf.tmp
  sed -i -e "s/\\\$ROCKETCHAT_DOMAIN\\\$/$ROCKETCHAT_DOMAIN/g" nginx.conf.tmp
  podman unshare mv nginx.conf.tmp /home/podman/data/nginx-autoletsencrypt/nginx/site-confs/$PODNAME
  podman restart nginx-autoletsencrypt

else
  exit $re
fi
