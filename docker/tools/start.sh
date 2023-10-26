#!/bin/bash

# This script is to be run on Docker host to start Docker cluster

DOCKER_DIR=$(dirname $(cd $(dirname $BASH_SOURCE) && pwd))

DOCKER_PHP_VERSION="81"
DOCKER_DB_VERSION="mariadb103"

while [ "$1" != "" ]; do
    case $1 in
        --php )
            shift
            DOCKER_PHP_VERSION="`echo $1 | tr -d '.'`"
            ;;

        --db )
            shift
            DOCKER_DB_VERSION="`echo $1 | tr -d '.'`"
            ;;

        --build )
            shift
            REBUILD_CONTAINERS="1"
            ;;

        --reset )
            shift
            RESET_CONTAINERS="1"
            ;;
    esac
    shift
done


export DOCKER_HOST_UID=$(id -u)
export DOCKER_HOST_GID=$(id -g)

# Set up version environment variables

# ... for PHP

DOCKERFILE_WEB="${DOCKER_DIR}/dockerfiles/Dockerfile.php${DOCKER_PHP_VERSION}.web"

if [ ! -f "${DOCKERFILE_WEB}" ]; then
    echo "No Dockerfile was found for PHP ${DOCKER_PHP_VERSION}: ${DOCKERFILE_WEB}"
    exit 1
fi

# ... for DB

DOCKERFILE_DB="${DOCKER_DIR}/dockerfiles/Dockerfile.${DOCKER_DB_VERSION}.db"

if [ ! -f "${DOCKERFILE_DB}" ]; then
    echo "No Dockerfile was found for DB ${DOCKER_DB_VERSION}: ${DOCKERFILE_DB}"
    exit 1
fi

echo "Starting with PHP ${DOCKER_PHP_VERSION}..."
echo "Starting with DB ${DOCKER_DB_VERSION}..."

export DOCKER_PHP_VERSION
export DOCKER_DB_VERSION

# Check if container rebuild / reset is needed to support the new versions

PHP_VERSION_FILE="${DOCKER_DIR}/run/last_php_version"
DB_VERSION_FILE="${DOCKER_DIR}/run/last_db_version"

if [ -f "${PHP_VERSION_FILE}" ]; then
    if [ "${DOCKER_PHP_VERSION}" != "$(cat ${PHP_VERSION_FILE})" ]; then
        # PHP version change requires a container rebuild
        echo "PHP version requested is different from last run"
        REBUILD_CONTAINERS="1"
    fi
fi

if [ -f "${DB_VERSION_FILE}" ]; then
    if [ "${DOCKER_DB_VERSION}" != "$(cat ${DB_VERSION_FILE})" ]; then
        # DB version change may require a complete container reset due to data file differences
        echo "DB version requested is different from last run"
        RESET_CONTAINERS="1"
    fi
fi

OS_NAME=$(uname -s)

if [ "${OS_NAME}" == "Darwin" ]; then
    DOCKER_HOST_PLATFORM="macos"
else
    DOCKER_HOST_PLATFORM="generic"
fi

export DOCKER_HOST_PLATFORM

# Rebuild containers, if requested

CONTAINERS=$(cat <<'LIST'
docker_test_db
docker_test_web
docker_test_selenium
docker_test_mailcatcher
LIST
)

if [ ! -z "${RESET_CONTAINERS}" ]; then
    # In case previous shutdown was incomplete
    docker-compose -f ${DOCKER_DIR}/docker-compose.yml down

    echo "Resetting containers..."

    for CONTAINER in ${CONTAINERS}; do
        CONTAINER_ID=$(docker ps -a | grep ${CONTAINER} | awk '{ print $1 }')

        if [ ! -z "${CONTAINER_ID}" ]; then
            echo "Erasing ${CONTAINER} container ($CONTAINER_ID)..."
            docker rm ${CONTAINER_ID} > /dev/null
        fi
    done

    if ! docker-compose -f ${DOCKER_DIR}/docker-compose.yml build; then
        exit 1
    fi
elif [ ! -z "${REBUILD_CONTAINERS}" ]; then
    # In case previous shutdown was incomplete
    docker-compose -f ${DOCKER_DIR}/docker-compose.yml down

    echo "Rebuilding containers..."

    if ! docker-compose -f ${DOCKER_DIR}/docker-compose.yml build; then
        exit 1
    fi
fi

echo "${DOCKER_PHP_VERSION}" > "${PHP_VERSION_FILE}"
echo "${DOCKER_DB_VERSION}" > "${DB_VERSION_FILE}"

docker-compose -f ${DOCKER_DIR}/docker-compose.yml up

# If desired, replace the above line with one that has one or more override files like this:
# docker-compose -f ${DOCKER_DIR}/docker-compose.yml -f ${DOCKER_DIR}/docker-compose.example-override.yml up
