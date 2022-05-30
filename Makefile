.PHONY:all, init, test install clean
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


init: 
	git clone $(hyperscan_git_repo)

build: 
	cd hyperscan && cmake -DBUILD_STATIC_AND_SHARED=true && cmake --build .

lib/libhs.$(EXT): build
	cp hyperscan/lib/libhs.$(EXT) lib/libhs.$(EXT)

all: lib/libhs.$(EXT)
	
test:
	rebusted -p='.lua' -m="./lib/?.lua;./lib/?/?.lua;./lib/?/init.lua" --cpath='./lib/?.$(EXT)' t/

install:
	cp lib/resty/hs.lua /usr/local/openresty/lualib/resty/
	cp lib/resty/hs/* /usr/local/openresty/lualib/resty/hs/

clean:
	rm -rf lib/libhs.$(EXT)