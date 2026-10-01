MODE ?= done
ITEM ?=

build: build/claudio

build/claudio: $(wildcard src/*.swift)
	mkdir -p build
	swiftc -O src/*.swift -o build/claudio

install:
	./install.sh

uninstall:
	./uninstall.sh

# make preview [MODE=ask] [ITEM=pizza|crown|...]  (runs the repo build, not the installed one)
preview: build
	CLAUDIO_ITEM=$(ITEM) ./scripts/notify.sh $(MODE) < /dev/null

clean:
	rm -rf build

.PHONY: build install uninstall preview clean
