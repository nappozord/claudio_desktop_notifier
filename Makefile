MODE ?= done
ITEM ?=
TEXT ?=

build: build/claudio

build/claudio: $(wildcard src/*.swift)
	mkdir -p build
	swiftc -O src/*.swift -o build/claudio

install:
	./install.sh

uninstall:
	./uninstall.sh

# make preview [MODE=ask] [ITEM=pizza|crown|...] [TEXT="All 24 tests pass"]
# Runs the repo build, not the installed one. TEXT goes through Haiku like a real message.
# A prop name given as MODE (MODE=crown) is treated as ITEM, since that mix-up is easy to make.
preview: build
	@mode="$(MODE)"; item="$(ITEM)"; \
	case "$$mode" in done|ask) ;; *) \
	  if build/claudio --props | grep -qx "$$mode"; then \
	    echo "'$$mode' is a prop, so showing it as ITEM=$$mode (MODE is the mood: done or ask)"; item="$$mode"; mode=done; \
	  else echo "MODE must be done or ask, not '$$mode'. Props go in ITEM, e.g. make preview ITEM=pizza"; exit 1; fi;; \
	esac; \
	if [ -n "$$item" ] && ! build/claudio --props | grep -qx "$$item"; then \
	  echo "Unknown ITEM '$$item'. Props: $$(build/claudio --props | tr '\n' ' ')"; exit 1; fi; \
	jq -n --arg t "$(TEXT)" '{last_assistant_message: $$t, message: $$t}' \
	  | CLAUDIO_ITEM="$$item" ./scripts/notify.sh "$$mode"

props: build
	@build/claudio --props | tr '\n' ' '; echo

clean:
	rm -rf build

.PHONY: build install uninstall preview props clean
