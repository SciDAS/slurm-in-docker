subdir = packages base controller worker database

.PHONY: all build clean test $(subdir)

all: build

build: $(subdir)

clean: $(subdir)

test:
	$(MAKE) -C $@

controller worker database: base

base: packages

$(subdir):
	$(MAKE) -C $@ $(MAKECMDGOALS)
