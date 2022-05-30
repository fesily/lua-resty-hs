local ffi = require "ffi"
local libhs = require "resty.hs.libhs"
local _M = {
    _VERSION = require "resty.hs.base"._VERSION
}

local ffi_new = ffi.new
local ffi_string = ffi.string
local ffi_gc = ffi.gc
local ffi_cast = ffi.cast

ffi.cdef [[
struct hs_stream;
typedef struct hs_stream hs_stream_t;
struct hs_scratch;
typedef struct hs_scratch hs_scratch_t;
typedef int ( *match_event_handler)(unsigned int id,
                                            unsigned long long from,
                                            unsigned long long to,
                                            unsigned int flags,
                                            void *context);
hs_error_t  hs_open_stream(const hs_database_t *db, unsigned int flags,
                                   hs_stream_t **stream);
hs_error_t  hs_scan_stream(hs_stream_t *id, const char *data,
                                   unsigned int length, unsigned int flags,
                                   hs_scratch_t *scratch,
                                   match_event_handler onEvent, void *ctxt);
hs_error_t  hs_close_stream(hs_stream_t *id, hs_scratch_t *scratch,
                                    match_event_handler onEvent, void *ctxt);
hs_error_t  hs_reset_stream(hs_stream_t *id, unsigned int flags,
                                    hs_scratch_t *scratch,
                                    match_event_handler onEvent, void *context);
hs_error_t  hs_copy_stream(hs_stream_t **to_id,
                                   const hs_stream_t *from_id);
hs_error_t  hs_reset_and_copy_stream(hs_stream_t *to_id,
                                             const hs_stream_t *from_id,
                                             hs_scratch_t *scratch,
                                             match_event_handler onEvent,
                                             void *context);
hs_error_t  hs_compress_stream(const hs_stream_t *stream, char *buf,
                                       size_t buf_space, size_t *used_space);
hs_error_t  hs_expand_stream(const hs_database_t *db,
                                     hs_stream_t **stream, const char *buf,
                                     size_t buf_size);
hs_error_t  hs_reset_and_expand_stream(hs_stream_t *to_stream,
                                               const char *buf, size_t buf_size,
                                               hs_scratch_t *scratch,
                                               match_event_handler onEvent,
                                               void *context);
hs_error_t  hs_scan(const hs_database_t *db, const char *data,
                            unsigned int length, unsigned int flags,
                            hs_scratch_t *scratch, match_event_handler onEvent,
                            void *context);
hs_error_t  hs_scan_vector(const hs_database_t *db,
                                   const char *const *data,
                                   const unsigned int *length,
                                   unsigned int count, unsigned int flags,
                                   hs_scratch_t *scratch,
                                   match_event_handler onEvent, void *context);
hs_error_t  hs_alloc_scratch(const hs_database_t *db,
                                     hs_scratch_t **scratch);
hs_error_t  hs_clone_scratch(const hs_scratch_t *src,
                                     hs_scratch_t **dest);
hs_error_t  hs_scratch_size(const hs_scratch_t *scratch,
                                    size_t *scratch_size);
hs_error_t  hs_free_scratch(hs_scratch_t *scratch);
]]

local HS_SUCCESS = 0


---@param onEvent Hyperscan.Event
---@param context? any
function _M.hs_scan(db, data, scratch, onEvent, context)
    return libhs.hs_scan(db[0], data, #data, 0, scratch[0], onEvent, context)
end

function _M.hs_scan_vector()
    error("not implemented")
end
local function hs_free_scratch(scratch)
    libhs.hs_free_scratch(scratch[0])
end
local hs_scratch_t = ffi.typeof("hs_scratch_t*[1]")
---@param scratch? Hyperscan.scratch_t
---@return Hyperscan.scratch_t
function _M.hs_alloc_scratch(db, scratch)
    local need_attach_gc = not scratch
    if not scratch then
        scratch = ffi_new(hs_scratch_t)
    end
    local err = libhs.hs_alloc_scratch(db[0], scratch)
    if err ~= HS_SUCCESS then
        return nil, err
    end
    if need_attach_gc then
        ffi_gc(scratch, hs_free_scratch)
    end
    return scratch
end

return _M
