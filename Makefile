subdir = packages base controller worker database

.PHONY: all build clean $(subdir)

all: build

build: $(subdir)

clean: $(subdir)

controller worker database: base

base: packages

$(subdir):
	$(MAKE) -C $@ $(MAKECMDGOALS)
