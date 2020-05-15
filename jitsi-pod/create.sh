#!/bin/bash


CONF_DIRS="/home/podman/data/jitsi/{web/letsencrypt,transcripts,prosody,jicofo,jvb,jigasi,jibri}"

cd $(dirname "$0")
PODNAME=$(basename $(pwd))

if podman pod exists "$PODNAME"; then
  echo "pod $PODNAME already exists" 1>&2
  exit 1
fi

# create container config dir
eval mkdir -p $CONF_DIRS

export SERVER_FQDN=$(hostname -f)
export SERVER_IP=$(hostname -i)

if [ -z "$JITSI_DOMAIN" ]; then
  echo "JITSI_DOMAIN must be set to the gitlab Domainname f.e. jitsi.example.ph.de" 1>&2
  exit 1
fi

export JITSI_DOMAIN

cd docker-jitsi-meet
cp env.example .env
cp ../docker-compose.yml .

./gen-passwords.sh

sed -i -e 's#CONFIG=.*#CONFIG=/home/podman/data/jitsi/#' .env

sed -i -e 's/HTTP_PORT=.*/HTTP_PORT=80/g' .env
sed -i -e 's/HTTPS_PORT=.*/HTTPS_PORT=443/g' .env
sed -i -e 's/TZ=.*/TZ=Europe\/Berlin/g' .env
sed -i -e "s#PUBLIC_URL=.*#PUBLIC_URL=https://$JITSI_DOMAIN#g" .env

echo "DOCKER_HOST_ADDRESS=${SERVER_IP}" >>.env

sed -i -e 's/TZ=.*/TZ=Europe\/Berlin/g' .env

sed -i -e 's/#DISABLE_HTTPS=.*/DISABLE_HTTPS=1/g' .env
sed -i -e 's/#ENABLE_HTTP_REDIRECT=.*/ENABLE_HTTP_REDIRECT=0/g' .env

podman-compose up -d
re=$?
if [ $re -eq 0 ]; then
  echo "pod and container successfully created."
  echo "on first run it might take up to 5 min until the container is up and running"
  echo "Container configuration can be found in $CONF_DIRS"

  cd ..
  cp nginx.conf nginx.conf.tmp
  sed -i -e "s/\\\$JITSI_DOMAIN\\\$/$JITSI_DOMAIN/g" nginx.conf.tmp
  podman unshare mv nginx.conf.tmp /home/podman/data/nginx-autoletsencrypt/nginx/site-confs/$PODNAME
  echo "restart nginx"
  podman pod restart nginx-autoletsencrypt-pod

else
  exit $re
fi
