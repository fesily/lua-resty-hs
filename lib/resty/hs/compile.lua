local ffi = require "ffi"
local libhs = require "resty.hs.libhs"

local _M = {
    _VERSION = require "resty.hs.base"._VERSION
}

local ffi_new = ffi.new
local ffi_string = ffi.string
local ffi_gc = ffi.gc
local ffi_cast = ffi.cast

ffi.cdef([[

typedef struct hs_compile_error {
    char *message;
    int expression;
} hs_compile_error_t;
typedef struct hs_platform_info {
    unsigned int tune;
    unsigned long long cpu_features;
    unsigned long long reserved1;
    unsigned long long reserved2;
} hs_platform_info_t;

typedef struct hs_expr_info {
    unsigned int min_width;
    unsigned int max_width;
    char unordered_matches;
    char matches_at_eod;
    char matches_only_at_eod;
} hs_expr_info_t;

typedef struct hs_expr_ext {
    unsigned long long flags;
    unsigned long long min_offset;
    unsigned long long max_offset;
    unsigned long long min_length;
    unsigned edit_distance;
    unsigned hamming_distance;
} hs_expr_ext_t;
hs_error_t  hs_compile(const char *expression, unsigned int flags,
                               unsigned int mode,
                               const hs_platform_info_t *platform,
                               hs_database_t **db, hs_compile_error_t **error);
hs_error_t  hs_compile_multi(const char *const *expressions,
                                     const unsigned int *flags,
                                     const unsigned int *ids,
                                     unsigned int elements, unsigned int mode,
                                     const hs_platform_info_t *platform,
                                     hs_database_t **db,
                                     hs_compile_error_t **error);
hs_error_t  hs_compile_ext_multi(const char *const *expressions,
                                const unsigned int *flags,
                                const unsigned int *ids,
                                const hs_expr_ext_t *const *ext,
                                unsigned int elements, unsigned int mode,
                                const hs_platform_info_t *platform,
                                hs_database_t **db, hs_compile_error_t **error);
hs_error_t  hs_compile_lit(const char *expression, unsigned flags,
                                   const size_t len, unsigned mode,
                                   const hs_platform_info_t *platform,
                                   hs_database_t **db,
                                   hs_compile_error_t **error);
hs_error_t  hs_compile_lit_multi(const char * const *expressions,
                                         const unsigned *flags,
                                         const unsigned *ids,
                                         const size_t *lens,
                                         unsigned elements, unsigned mode,
                                         const hs_platform_info_t *platform,
                                         hs_database_t **db,
                                         hs_compile_error_t **error);
hs_error_t  hs_free_compile_error(hs_compile_error_t *error);
hs_error_t  hs_expression_info(const char *expression,
                                       unsigned int flags,
                                       hs_expr_info_t **info,
                                       hs_compile_error_t **error);
hs_error_t  hs_expression_ext_info(const char *expression,
                                           unsigned int flags,
                                           const hs_expr_ext_t *ext,
                                           hs_expr_info_t **info,
                                           hs_compile_error_t **error);
hs_error_t  hs_populate_platform(hs_platform_info_t *platform);
]])
local HS_SUCCESS = 0
local compile_error = ffi_new("hs_compile_error_t*[1]")
local hs_database_t = ffi.typeof("hs_database_t*[1]")
local function do_compile_error()
    local err = compile_error[0]
    if err ~= nil then
        local err_str = ffi_string(err.message)
        libhs.hs_free_compile_error(err)
        return err_str
    else
        return "unknown error"
    end
end

local function hs_free_database(db)
    libhs.hs_free_database(db[0])
end

---comment
---@param expression string
---@param flags integer
---@param mode integer
---@return any,string
function _M.hs_compile(expression, flags, mode)

    if type(expression) ~= "string" then
        return nil, "expression must be a string"
    end

    if type(flags) ~= "number" then
        return nil, "flags must be a number"
    end

    if type(mode) ~= "number" then
        return nil, "mode must be a number"
    end

    local db = ffi.new(hs_database_t)

    local ret = libhs.hs_compile(expression, flags, mode, nil, db, compile_error)
    if ret ~= HS_SUCCESS then
        return nil, do_compile_error()
    end
    ffi_gc(db, hs_free_database)
    return db
end

function _M.hs_compile_multi()
    error("not implemented")
end

---comment
---@param expressions string[]
---@param flags integer[]
---@param ids integer[]
---@param elements integer
---@param mode integer
---@return any
function _M.hs_compile_ext_multi(expressions, flags, ids, elements, mode)
    if type(expressions) ~= "table" then
        return nil, "expressions must be a table"
    end
    if type(flags) ~= "table" then
        return nil, "flags must be a table"
    end
    if type(ids) ~= "table" then
        return nil, "ids must be a table"
    end
    if type(elements) ~= "number" then
        return nil, "elements must be a number"
    end
    if type(mode) ~= "number" then
        return nil, "mode must be a number"
    end

    if elements ~= #expressions or elements ~= #flags or elements ~= #ids then
        return nil, "elements must be equal to the length of expressions, flags, ids"
    end

    local db = ffi_new(hs_database_t)

    local c_expressions = ffi_new('const  char*[?]', elements)
    local c_ids         = ffi_new('unsigned int[?]', elements)
    local c_flags       = ffi_new('unsigned int[?]', elements)

    for i = 1, elements do
        c_ids[i - 1]         = ids[i]
        c_flags[i - 1]       = flags[i]
        c_expressions[i - 1] = expressions[i]
    end

    local ret = libhs.hs_compile_ext_multi(c_expressions, c_flags, c_ids, nil, elements, mode, nil, db, compile_error)
    if ret ~= HS_SUCCESS then
        return nil, do_compile_error()
    end
    ffi_gc(db, hs_free_database)
    return db
end

function _M.hs_compile_lit()
    error("not implemented")
end

function _M.hs_compile_lit_multi()
    error("not implemented")
end

return _M
