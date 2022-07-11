local ffi = require "ffi"

ffi.cdef([[
struct hs_database;
typedef struct hs_database hs_database_t;
typedef int hs_error_t;
hs_error_t  hs_free_database(hs_database_t *db);
hs_error_t  hs_serialize_database(const hs_database_t *db, char **bytes,
                                          size_t *length);
hs_error_t  hs_deserialize_database(const char *bytes,
                                            const size_t length,
                                            hs_database_t **db);
hs_error_t  hs_deserialize_database_at(const char *bytes,
                                               const size_t length,
                                               hs_database_t *db);
hs_error_t  hs_stream_size(const hs_database_t *database,
                                   size_t *stream_size);
hs_error_t  hs_database_size(const hs_database_t *database,
                                     size_t *database_size);
hs_error_t  hs_serialized_database_size(const char *bytes,
                                                const size_t length,
                                                size_t *deserialized_size);
hs_error_t  hs_database_info(const hs_database_t *database,
                                     char **info);
hs_error_t  hs_serialized_database_info(const char *bytes,
                                                size_t length, char **info);
typedef void *( *hs_alloc_t)(size_t size);
typedef void ( *hs_free_t)(void *ptr);
hs_error_t  hs_set_allocator(hs_alloc_t alloc_func,
                                     hs_free_t free_func);
hs_error_t  hs_set_database_allocator(hs_alloc_t alloc_func,
                                              hs_free_t free_func);
hs_error_t  hs_set_misc_allocator(hs_alloc_t alloc_func,
                                          hs_free_t free_func);
hs_error_t  hs_set_scratch_allocator(hs_alloc_t alloc_func,
                                             hs_free_t free_func);
hs_error_t  hs_set_stream_allocator(hs_alloc_t alloc_func,
                                            hs_free_t free_func);
const char *  hs_version(void);
hs_error_t  hs_valid_platform(void);
]])

local hs
do
    local so_name = "libhs.so"
    local macos_name = "libhs.dylib"
    local HS_SUCCESS = 0

    local function exists(path)
        local f = io.open(path, "r")
        if f then
            f:close()
            return true
        end
        return false
    end

    -- load library
    for k, _ in string.gmatch(package.cpath, "[^;]+") do
        local so_path = string.match(k, "(.*/)")
        if so_path then
            if exists(so_path .. so_name) then
                hs = ffi.load(so_path .. so_name)
                break
            end
            if jit.os == "OSX" then
                if exists(so_path .. macos_name) then
                    hs = ffi.load(so_path .. macos_name)
                    break
                end
            end
        end
    end
    if not hs then
        hs = ffi.load("libhs")
    end

    if not hs then
        error("load shared library libhs failed")
    end

    if hs.hs_valid_platform() ~= HS_SUCCESS then
        error("This system not spport Hyperscan")
    end
end

return hs
