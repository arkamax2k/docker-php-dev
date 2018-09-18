#!/bin/bash

if [ "$DOCKER_HOST_UID" == "" ]; then
	exit 0
fi

if [ "$DOCKER_HOST_GID" == "" ]; then
        exit 0
fi

# Change www-data user and group to IDs of the user running on Docker host

usermod --non-unique --uid $DOCKER_HOST_UID www-data
groupmod --non-unique --gid $DOCKER_HOST_GID www-data
