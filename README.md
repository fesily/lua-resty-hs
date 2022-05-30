# lua-resty-hs

hyperscan for openresty

## future

1. Pure lua ffi, specify the callback is lua function, not a c function.  vs [lua-resty-hyperscan](https://github.com/fesily/lua-resty-hyperscan)
2. Support save/load api for distribute compilation results
3. shared scratch object to reduce memory occupation

## roadmap

- [ ] use tinycc to compile dynamic callback instead of lua callback

## why create a new library fro hyperscan

Because we need more degrees of freedom to flexibly handle the callback.If you don't have the require ,Not use this library
