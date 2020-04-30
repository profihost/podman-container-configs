#!/bin/bash

CONF_DIRS="/home/podman/data/confluence"

cd $(dirname "$0")
PODNAME=$(basename $(pwd))

if podman pod exists "$PODNAME"; then
  echo "pod $PODNAME already exists" 1>&2
  exit 1
fi

# create container config dir
mkdir -p $CONF_DIRS

if [ -z "$CONFLUENCE_DOMAIN" ]; then
  echo "CONFLUENCE_DOMAIN must be set to the confluence Domainname f.e. confluence.example.ph.de" 1>&2
  exit 1
fi

export CONFLUENCE_DOMAIN

podman-compose up -d
re=$?
if [ $re -eq 0 ]; then
  echo "pod and container successfully created."
  echo "on first run it might take up to 5 min until the container is up and running"
  echo "Container configuration can be found in $CONF_DIRS"

  cp nginx.conf nginx.conf.tmp
  sed -i -e "s/\\\$CONFLUENCE_DOMAIN\\\$/$CONFLUENCE_DOMAIN/g" nginx.conf.tmp
  podman unshare mv nginx.conf.tmp /home/podman/data/nginx-autoletsencrypt/nginx/site-confs/$PODNAME
  echo "restart nginx"
  podman pod restart nginx-autoletsencrypt-pod

else
  exit $re
fi
