#!/bin/bash

CONF_DIRS="/home/podman/data/nginx-autoletsencrypt"

cd $(dirname "$0")
PODNAME=$(basename $(pwd))

if podman pod exists "$PODNAME"; then
  echo "pod $PODNAME already exists" 1>&2
  exit 1
fi

# create container config dir
mkdir -p $CONF_DIRS

export SERVER_FQDN=$(hostname -f)

if [ -z "$SSL_DOMAINS" ]; then
  echo "SSL_DOMAINS must be set to all domains service ssl seperated by ," 1>&2
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "EMAIL must be set to a valid email adress. Let's encrypt will inform you if there is any problem with your ssl cert." 1>&2
  exit 1
fi

export EMAIL
export SSL_DOMAINS

podman-compose up -d
re=$?
if [ $re -eq 0 ]; then
  echo "pod and container successfully created."
  echo "on first run it might take up to 2 min until the container is up and running"
  echo "Container configuration can be found in $CONF_DIRS"
else
  exit $re
fi
