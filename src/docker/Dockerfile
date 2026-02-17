ARG NAME=mdnsd
# Build is done in ${INSTALL_DIR} rather than a temp dir to ensure
#  resultant files are correctly linked to target directories in
#  final image.
ARG INSTALL_DIR=/usr/local/share/${NAME}

# ----------------------[ Stage 1 ]---------------------------------
FROM alpine AS build
ARG INSTALL_DIR
ARG BUILD_DIR=${INSTALL_DIR}

# Build from GitHub repo
# ----------------------
# ARG REPO=https://github.com/shyndman/mdnsd.git
# ADD ${REPO} ${BUILD_DIR}
# ----------------------

# Build from local project
# ------------------------
# COPY <dir> copies the *contents* of <dir>, not <dir itself>, regardless
#  of <existing_dest> or <dest>/
COPY . ${BUILD_DIR}
# ------------------------

RUN ls -la ${BUILD_DIR}

RUN apk add --no-cache git python3 python3-dev linux-headers build-base
RUN make --directory ${BUILD_DIR}

RUN python -m venv --upgrade-deps ${BUILD_DIR}/venv
RUN ${BUILD_DIR}/venv/bin/pip install -r \
  ${BUILD_DIR}/src/python/requirements.txt

# ----------------------[ Stage 2 ]---------------------------------
FROM alpine AS image

ARG NAME
ARG INSTALL_DIR
ARG BIN_DIR=/usr/local/bin

RUN mkdir -p ${INSTALL_DIR}/venv
COPY --chmod=0751 src/python/* ${INSTALL_DIR}/
COPY --from=build --chmod=0751 ${INSTALL_DIR}/build/mdns-repeater ${BIN_DIR}/
COPY --from=build ${INSTALL_DIR}/venv ${INSTALL_DIR}/venv

RUN apk add --no-cache libcap-setcap python3

RUN setcap cap_net_raw=+ep ${BIN_DIR}/mdns-repeater

# Create non-root user
RUN addgroup -S mdnsd && adduser -S -G mdnsd -H -s /sbin/nologin mdnsd

USER mdnsd
# -u == unbuffered output
#  (otherwise entrypoint logs are masked by mdns-repeater replacing the process)
ENTRYPOINT ["/usr/local/share/mdnsd/venv/bin/python", "-u", "/usr/local/share/mdnsd/entrypoint.py"]
