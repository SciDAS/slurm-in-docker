subdir = centos-7

.PHONY: all build clean $(subdir)

all: build

build: $(subdir)

clean: $(subdir)

$(subdir):
	$(MAKE) -C $@ $(MAKECMDGOALS)
