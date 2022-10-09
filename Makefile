.PHONY:all, init, test install clean no-build install-no-build
default: all
ARCH := $(shell uname -m)
OS := $(shell uname -s)
ifeq ($(ARCH), aarch64)
	ARCH = arm64
endif
hyperscan_git_repo = "https://github.com/intel/hyperscan.git"
ifeq ($(ARCH), arm64)
hyperscan_git_repo = "https://github.com/VectorCamp/vectorscan.git" hyperscan
endif

EXT = so
ifeq ($(OS), Darwin)
	EXT = dylib
endif

OPENRESTY_PREFIX ?= /usr/local/openresty
INST_LUADIR      ?= $(OPENRESTY_PREFIX)/site/lualib
INST_LIBDIR      ?= $(OPENRESTY_PREFIX)/site/lualib
INSTALL ?= install

init:
ifeq (,$(wildcard hyperscan))
	git clone $(hyperscan_git_repo)
endif

build: init
ifeq (, $(wildcard CMakeFiles))
	cd hyperscan && cmake -G Ninja -DBUILD_STATIC_AND_SHARED=true
endif
	cd hyperscan && cmake --build . -- -j$(shell nproc)

lib/libhs.$(EXT): build
	cp hyperscan/lib/libhs.$(EXT) lib/libhs.$(EXT)

all: lib/libhs.$(EXT)

no-build:

test:
	rebusted -p='.lua' -m="./lib/?.lua;./lib/?/?.lua;./lib/?/init.lua" --cpath='./lib/?.$(EXT)' t/

install: install-no-build
	$(INSTALL) -m 644 lib/libhs.$(EXT) $(INST_LIBDIR)

install-no-build:
	$(INSTALL) -d $(INST_LUADIR)/resty/hs/
	$(INSTALL) -m 644 lib/resty/hs.lua $(INST_LUADIR)/resty/
	$(INSTALL) -m 644 lib/resty/hs/* $(INST_LUADIR)/resty/hs/

clean:
	rm -rf lib/libhs.$(EXT)
