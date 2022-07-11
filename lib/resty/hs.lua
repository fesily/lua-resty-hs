local ffi = require "ffi"
local libhs = require "resty.hs.libhs"
local compile = require "resty.hs.compile"
local runtime = require "resty.hs.runtime"
local hs = {
    _VERSION = 0.2
}

ffi.cdef[[
    void free(void*);
]]

local ffi_new = ffi.new
local ffi_string = ffi.string
local ffi_gc = ffi.gc
local ffi_cast = ffi.cast

hs.HS_SUCCESS = 0
hs.HS_INVALID = -1
hs.HS_NOMEM = -2
hs.HS_SCAN_TERMINATED = -3
hs.HS_COMPILER_ERROR = -4
hs.HS_DB_VERSION_ERROR = -5
hs.HS_DB_PLATFORM_ERROR = -6
hs.HS_DB_MODE_ERROR = -7
hs.HS_BAD_ALIGN = -8
hs.HS_BAD_ALLOC = -9
hs.HS_SCRATCH_IN_USE = -10
hs.HS_ARCH_ERROR = -11
hs.HS_INSUFFICIENT_SPACE = -12
hs.HS_UNKNOWN_ERROR = -13
hs.HS_EXT_FLAG_MIN_OFFSET = 1
hs.HS_EXT_FLAG_MAX_OFFSET = 2
hs.HS_EXT_FLAG_MIN_LENGTH = 4
hs.HS_EXT_FLAG_EDIT_DISTANCE = 8
hs.HS_EXT_FLAG_HAMMING_DISTANCE = 16
hs.HS_FLAG_CASELESS = 1
hs.HS_FLAG_DOTALL = 2
hs.HS_FLAG_MULTILINE = 4
hs.HS_FLAG_SINGLEMATCH = 8
hs.HS_FLAG_ALLOWEMPTY = 16
hs.HS_FLAG_UTF8 = 32
hs.HS_FLAG_UCP = 64
hs.HS_FLAG_PREFILTER = 128
hs.HS_FLAG_SOM_LEFTMOST = 256
hs.HS_FLAG_COMBINATION = 512
hs.HS_FLAG_QUIET = 1024
hs.HS_CPU_FEATURES_AVX2 = 4
hs.HS_CPU_FEATURES_AVX512 = 8
hs.HS_CPU_FEATURES_AVX512VBMI = 16
hs.HS_TUNE_FAMILY_GENERIC = 0
hs.HS_TUNE_FAMILY_SNB = 1
hs.HS_TUNE_FAMILY_IVB = 2
hs.HS_TUNE_FAMILY_HSW = 3
hs.HS_TUNE_FAMILY_SLM = 4
hs.HS_TUNE_FAMILY_BDW = 5
hs.HS_TUNE_FAMILY_SKL = 6
hs.HS_TUNE_FAMILY_SKX = 7
hs.HS_TUNE_FAMILY_GLM = 8
hs.HS_TUNE_FAMILY_ICL = 9
hs.HS_TUNE_FAMILY_ICX = 10
hs.HS_MODE_BLOCK = 1
hs.HS_MODE_NOSTREAM = 1
hs.HS_MODE_STREAM = 2
hs.HS_MODE_VECTORED = 4
hs.HS_MODE_SOM_HORIZON_LARGE = 16777216
hs.HS_MODE_SOM_HORIZON_MEDIUM = 33554432
hs.HS_MODE_SOM_HORIZON_SMALL = 67108864

local function error_to_string(err)
    if err == hs.HS_INVALID then
        return "Invalid"
    elseif err == hs.HS_NOMEM then
        return "NOMEM"
    elseif err == hs.HS_SCAN_TERMINATED then
        return "Scan terminated"
    elseif err == hs.HS_COMPILER_ERROR then
        return "Compiler error"
    elseif err == hs.HS_DB_VERSION_ERROR then
        return "Database version error"
    elseif err == hs.HS_DB_PLATFORM_ERROR then
        return "Database platform error"
    elseif err == hs.HS_DB_MODE_ERROR then
        return "Database mode error"
    elseif err == hs.HS_BAD_ALLOC then
        return "bad alloc"
    elseif err == hs.HS_BAD_ALIGN then
        return "bad alignment"
    elseif err == hs.HS_SCRATCH_IN_USE then
        return "scratch in use"
    elseif err == hs.HS_ARCH_ERROR then
        return "arch error"
    elseif err == hs.HS_INSUFFICIENT_SPACE then
        return "insufficient space"
    elseif err == hs.HS_UNKNOWN_ERROR then
        return "unknown error"
    else
        return ""
    end
end

local match_ctx = {}
local function default_match_event_handler(id, from, to, flags, context)
    if match_ctx == nil then
        return hs.HS_INVALID
    end
    return match_ctx:handler(id)
end

---@type ffi.cb*
local match_event_handler = ffi.cast("match_event_handler", default_match_event_handler)

local runtime_hs_scan = runtime.hs_scan
local function hs_scan(self, data, ctx, scratch)
    if not ctx or not ctx.handler then return hs.HS_UNKNOWN_ERROR end
    match_ctx = ctx
    scratch = scratch or self.scratch
    return runtime_hs_scan(self.handle, data, scratch, match_event_handler)
end

local mt_new = { __index = {
    scan = hs_scan,
} }

---@param mode Hyperscan.mode
---@param expression string|string[]
---@param flag integer|integer[]
---@param id? integer|integer[]
---@param pure_literal? boolean
---@return Hyperscan?,string?
function hs.new(mode, expression, flag, id, pure_literal)
    assert(mode == hs.HS_MODE_BLOCK)
    local db, err
    if type(expression) == "string" then
        if pure_literal then
            db, err = compile.hs_compile(expression, flag, mode)
        else
            db, err = compile.hs_compile(expression, flag, mode)
        end
    elseif type(expression) == "table" then
        assert(id ~= nil)
        if pure_literal then
            db, err = compile.hs_compile_lit_multi(expression, flag, id, mode)
        else
            db, err = compile.hs_compile_multi(expression, flag, id, mode)
        end
    else
        return nil, "expression must be a table or string"
    end
    if not db then return nil, err end

    return setmetatable({ handle = db }, mt_new)
end

---@param mode Hyperscan.mode
---@param expression string|string[]
---@param flag integer|integer[]
---@param id? integer|integer[]
---@param pure_literal? boolean
---@return Hyperscan?,string?
function hs.simple_new(mode, expression, flag, id, pure_literal)
    local db, err = hs.new(mode, expression, flag, id, pure_literal)
    if not db then return nil, err end
    local scratch, err = runtime.hs_alloc_scratch(db.handle, db.scratch)
    if not scratch then return nil, error_to_string(err) end
    db.scratch = scratch
    return db
end

function hs.new_from_memory(data)
    if not data then return nil, "data is nil" end
    local db = compile.new_database()
    local err = libhs.hs_deserialize_database(data, #data, db)
    if err ~= hs.HS_SUCCESS then
        return nil, error_to_string(err)
    end
    return setmetatable({ handle = db }, mt_new)
end
local function free_buf(buf)
    ffi.C.free(buf[0])
end

function hs.database_to_memory(db)
    local buf = ffi_new("char*[1]")
    local size = ffi_new("size_t[1]")
    local err = libhs.hs_serialize_database(db.handle[0], buf, size)
    if err ~= hs.HS_SUCCESS then
        return nil, error_to_string(err)
    end
    ffi_gc(buf, free_buf)
    return ffi_string(buf[0], size[0])
end

---@param scratch? Hyperscan.scratch_t
function hs.init_scratch(db, scratch)
    local scratch, err = runtime.hs_alloc_scratch(db.handle, scratch or db.scratch)
    if not scratch then return nil, error_to_string(err) end
    db.scratch = scratch
    return scratch
end

---@param cb Hyperscan.Event
function hs.set_match_event_function(cb)
    match_event_handler:set(cb)
end

hs.default_match_event_handler = default_match_event_handler

return hs
