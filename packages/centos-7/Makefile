
SLURM_VERSION = 19.05.1
IMAGE = scidas/slurm.rpms

DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: all build clean test

all: build

build: rpms

rpms:
	docker build -t $(IMAGE):$(SLURM_VERSION) .
	docker run --rm \
			-e SLURM_VERSION=$(SLURM_VERSION) \
			-v "$(DIR)/rpms:/packages" $(IMAGE):$(SLURM_VERSION)

clean:
	@[ -z $(docker images -q $(IMAGE):$(SLURM_VERSION)) ] || docker rmi $(IMAGE):$(SLURM_VERSION)
	rm -rf rpms
