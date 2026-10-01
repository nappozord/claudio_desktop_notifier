MODE ?= done
PROP ?=
ACCESSORY ?=
TEXT ?=

build: build/claudio

build/claudio: $(wildcard src/*.swift)
	mkdir -p build
	swiftc -O src/*.swift -o build/claudio

install:
	./install.sh

uninstall:
	./uninstall.sh

# make preview [MODE=ask] [PROP=pizza] [ACCESSORY=crown|sunglasses|...] [TEXT="All 24 tests pass"]
# Runs the repo build, not the installed one. TEXT goes through Haiku like a real message.
# A prop or accessory name given as MODE is treated as PROP/ACCESSORY, since that mix-up is easy to make.
preview: build
	@mode="$(MODE)"; prop="$(PROP)"; accessory="$(ACCESSORY)"; \
	case "$$mode" in done|ask) ;; *) \
	  if build/claudio --props | grep -qx "$$mode"; then \
	    echo "'$$mode' is a prop, so showing it as PROP=$$mode (MODE is the mood: done or ask)"; prop="$$mode"; mode=done; \
	  elif build/claudio --accessories | grep -qx "$$mode"; then \
	    echo "'$$mode' is an accessory, so showing it as ACCESSORY=$$mode (MODE is the mood: done or ask)"; accessory="$$mode"; mode=done; \
	  else echo "MODE must be done or ask, not '$$mode'. Props go in PROP, accessories in ACCESSORY, e.g. make preview PROP=pizza"; exit 1; fi;; \
	esac; \
	if [ -n "$$prop" ] && ! build/claudio --props | grep -qx "$$prop"; then \
	  echo "Unknown PROP '$$prop'. Props: $$(build/claudio --props | tr '\n' ' ')"; exit 1; fi; \
	if [ -n "$$accessory" ] && ! build/claudio --accessories | grep -qx "$$accessory"; then \
	  echo "Unknown ACCESSORY '$$accessory'. Accessories: $$(build/claudio --accessories | tr '\n' ' ')"; exit 1; fi; \
	jq -n --arg t "$(TEXT)" '{last_assistant_message: $$t, message: $$t}' \
	  | CLAUDIO_PROP="$$prop" CLAUDIO_ACCESSORY="$$accessory" ./scripts/notify.sh "$$mode"

props: build
	@build/claudio --props | tr '\n' ' '; echo

accessories: build
	@build/claudio --accessories | tr '\n' ' '; echo

clean:
	rm -rf build

.PHONY: build install uninstall preview props accessories clean
