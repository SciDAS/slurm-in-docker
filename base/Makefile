
SLURM_VERSION = 19.05.1
IMAGE = scidas/slurm.base

DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: all build clean test

all: build

build:
	cp -r "$(DIR)/../packages/centos-7/rpms" .
	docker build -t $(IMAGE):$(SLURM_VERSION) .

clean:
	@[ -z $(docker images -q $(IMAGE):$(SLURM_VERSION)) ] || docker rmi $(IMAGE):$(SLURM_VERSION)
	rm -rf rpms
