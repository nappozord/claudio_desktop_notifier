MODE ?= done
PROP ?=
ACCESSORY ?=
MASCOT ?=
TEXT ?=

build: build/claudio

build/claudio: $(wildcard src/*.swift)
	mkdir -p build
	swiftc -O src/*.swift -o build/claudio

install:
	./install.sh

uninstall:
	./uninstall.sh

# make preview [MODE=ask] [PROP=pizza] [ACCESSORY=crown|sunglasses|...] [MASCOT=yellow] [TEXT="..."]
# Runs the repo build, not the installed one. TEXT goes through Haiku like a real message.
# A prop, accessory or mascot-color name given as MODE is treated as PROP/ACCESSORY/MASCOT,
# since that mix-up is easy to make.
preview: build
	@mode="$(MODE)"; prop="$(PROP)"; accessory="$(ACCESSORY)"; mascot="$(MASCOT)"; \
	case "$$mode" in done|ask) ;; *) \
	  if build/claudio --props | grep -qx "$$mode"; then \
	    echo "'$$mode' is a prop, so showing it as PROP=$$mode (MODE is the mood: done or ask)"; prop="$$mode"; mode=done; \
	  elif build/claudio --accessories | grep -qx "$$mode"; then \
	    echo "'$$mode' is an accessory, so showing it as ACCESSORY=$$mode (MODE is the mood: done or ask)"; accessory="$$mode"; mode=done; \
	  elif build/claudio --mascots | grep -qx "$$mode"; then \
	    echo "'$$mode' is a mascot color, so showing it as MASCOT=$$mode (MODE is the mood: done or ask)"; mascot="$$mode"; mode=done; \
	  else echo "MODE must be done or ask, not '$$mode'. Props go in PROP, accessories in ACCESSORY, mascot colors in MASCOT, e.g. make preview PROP=pizza"; exit 1; fi;; \
	esac; \
	if [ -n "$$prop" ] && ! build/claudio --props | grep -qx "$$prop"; then \
	  echo "Unknown PROP '$$prop'. Props: $$(build/claudio --props | tr '\n' ' ')"; exit 1; fi; \
	if [ -n "$$accessory" ] && ! build/claudio --accessories | grep -qx "$$accessory"; then \
	  echo "Unknown ACCESSORY '$$accessory'. Accessories: $$(build/claudio --accessories | tr '\n' ' ')"; exit 1; fi; \
	if [ -n "$$mascot" ] && ! build/claudio --mascots | grep -qx "$$mascot"; then \
	  echo "Unknown MASCOT '$$mascot'. Mascot colors: $$(build/claudio --mascots | tr '\n' ' ')"; exit 1; fi; \
	jq -n --arg t "$(TEXT)" '{last_assistant_message: $$t, message: $$t}' \
	  | CLAUDIO_PROP="$$prop" CLAUDIO_ACCESSORY="$$accessory" CLAUDIO_MASCOT="$$mascot" ./scripts/notify.sh "$$mode"

props: build
	@build/claudio --props | tr '\n' ' '; echo

accessories: build
	@build/claudio --accessories | tr '\n' ' '; echo

mascots: build
	@build/claudio --mascots | tr '\n' ' '; echo

clean:
	rm -rf build

.PHONY: build install uninstall preview props accessories mascots clean
