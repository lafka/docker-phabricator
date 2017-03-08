#!/bin/sh

/usr/bin/docker run \
   -i \
   -t \
   -d \
   --name source.tiny-mesh.com
   -h source.tiny-mesh.com \
   -p 172.16.40.254:80:80 \
   -p 172.16.40.254:443:443 \
   -p 172.16.40.254:22:2222 \
   -v /data/phabricator/certs:/certs \
   -v /data/phabricator/db:/var/lib/mysql \
   -v /data/phabricator/repo:/var/repo \
   -v /data/phabricator/conf:/opt/phabricator/conf \
   tinymesh/phabricator

