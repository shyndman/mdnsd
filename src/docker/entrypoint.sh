#!/bin/sh
set -eu

SOCK_PATH="${DOCKER_SOCK:-/var/run/docker.sock}"

if [ ! -S "${SOCK_PATH}" ]; then
  echo "Docker socket not found at ${SOCK_PATH}" >&2
  exit 1
fi

SOCK_GID="$(stat -c '%g' "${SOCK_PATH}")"

GROUP_NAME="$(getent group | while IFS=: read -r name _ gid _; do
  if [ "${gid}" = "${SOCK_GID}" ]; then
    printf '%s\n' "${name}"
    break
  fi
done)"

if [ -z "${GROUP_NAME}" ]; then
  GROUP_NAME="dockersock"
  if getent group "${GROUP_NAME}" >/dev/null 2>&1; then
    GROUP_NAME="dockersock_${SOCK_GID}"
  fi
  addgroup -g "${SOCK_GID}" "${GROUP_NAME}"
fi

if ! id -nG mdnsd | tr ' ' '\n' | grep -qx "${GROUP_NAME}"; then
  addgroup mdnsd "${GROUP_NAME}"
fi

exec su-exec mdnsd "$@"
