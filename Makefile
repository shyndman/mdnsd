# Makefile for mdnsd (https://github.com/shyndman/mdnsd)
# 
# mdnsd is a Docker wrapper for mdns-repeater by geekman
# (https://github.com/geekman/mdns-repeater)

NAME := mdnsd
MDNSD_VERSION := 0.1.0

SRC_DIR := src
VENV_DIR := venv
PYTHON_DIR := $(SRC_DIR)/python
DOCKER_DIR := $(SRC_DIR)/docker
DOCKER_IMAGE := ghcr.io/shyndman/$(NAME)

MR_NAME := mdns-repeater
MR_BUILD_DIR := build
MR_BUILD := $(MR_BUILD_DIR)/$(MR_NAME)
MR_SRC_DIR := lib/$(MR_NAME)
MR_SRC := $(MR_SRC_DIR)/$(MR_NAME).c
MR_OBJ := $(MR_BUILD).o

INSTALL_DIR := $(PREFIX)/bin

MR_GIT_VER_FILE := $(MR_BUILD_DIR)/gitversion
MR_GITVERSION := $(shell git rev-parse --short=8 HEAD 2>/dev/null || exit 1)

RELEASE_VERSION := $(MDNSD_VERSION)-$(MR_GITVERSION)

CFLAGS += -DHGVERSION="\"$(MR_GITVERSION)\"" -Wall -s
LDFLAGS += -s

# Detect Alpine (musl flags needed)
ALPINE := $(shell grep -si ID=alpine /etc/os-release 2>/dev/null)

# Alpine-specific flags
# Warning: Will not build if tab-indented
# (denotes recipe, invalid before first target)
ifdef ALPINE
  $(info 'Alpine detected  (⌐■_■)')
  CFLAGS += -D_GNU_SOURCE

  # find musl dynamic linker
  MUSL_DL := $(shell find /lib -name 'ld-musl-*.so.*' 2>/dev/null | head -n 1)

  ifneq ($(MUSL_DL),)
    $(info "Found musl dynamic linker $(MUSL_DL)")
    LDFLAGS += -Wl,--dynamic-linker=$(MUSL_DL)
  endif

endif

# Build targets
$(MR_BUILD): $(MR_OBJ)
	$(CC) $(LDFLAGS) $< -o $@

$(MR_OBJ): $(MR_SRC)
	$(CC) $(CFLAGS) -c $< -o $@

$(MR_SRC): $(MR_GIT_VER_FILE) | submodule

# | $(MR_BUILD_DIR) ignores timestamp; only runs mkdir once
$(MR_GIT_VER_FILE): | $(MR_BUILD_DIR)
	cmp -s $(cat $@) $(MR_GITVERSION) || echo $(MR_GITVERSION) > $@

$(MR_BUILD_DIR):
	mkdir -p $@

$(VENV_DIR):
	python -m venv --upgrade-deps $@
	$@/bin/pip install -r $(PYTHON_DIR)/requirements.txt

.PHONY: all \
	      clean \
				install \
				docker-dev-build \
				docker-dev-push \
				docker-rel-build \
				docker-rel-push \
				submodule

all: $(MR_BUILD)

clean:
	-rm -rf $(MR_BUILD_DIR) $(VENV_DIR)
	docker image ls | \
		grep $(DOCKER_IMAGE) | \
			awk '{system("docker rmi " $$1 ":" $$2)}' 2>/dev/null

install: $(MR_BUILD)
	install -m 0751 -t $(INSTALL_DIR) $<

docker-dev-build: $(MR_BUILD)
	docker build \
		--progress=plain \
		-f $(DOCKER_DIR)/Dockerfile \
		-t $(DOCKER_IMAGE):dev \
		.

docker-dev-push: docker-dev-build
	docker push $(DOCKER_IMAGE):dev

docker-rel-build: $(MR_BUILD)
	docker build \
		--progress=plain \
		-f $(DOCKER_DIR)/Dockerfile \
		-t $(DOCKER_IMAGE):$(RELEASE_VERSION) \
		.
	
	docker image tag $(DOCKER_IMAGE):$(RELEASE_VERSION) $(DOCKER_IMAGE):latest

docker-rel-push: docker-rel-build
	docker push $(DOCKER_IMAGE):latest $(DOCKER_IMAGE):$(RELEASE_VERSION)

submodule:
	[ -f $(MR_SRC) ] || git submodule update --init --force --checkout