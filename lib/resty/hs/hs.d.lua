
---@class Hyperscan
---@field handle Hyperscan.database_t
---@field scratch Hyperscan.scratch_t
local hs = {}

---@class Hyperscan.scratch_t
---@class Hyperscan.database_t

---@alias Hyperscan.error_t integer
---@alias Hyperscan.Event fun(id,from,to,flags,context):Hyperscan.error_t


---comment
---@param data string
---@param onEvent Hyperscan.Event
---@param scratch? Hyperscan.scratch_t
---@return Hyperscan.error_t
function hs:scan(data, onEvent, scratch)
end

---@alias Hyperscan.mode
---|hs.HS_MODE_BLOCK
---|hs.HS_MODE_NOSTREAM
---|hs.HS_MODE_STREAM
---|hs.HS_MODE_VECTORED