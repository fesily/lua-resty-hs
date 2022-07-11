local hs = require "resty.hs"
describe("serizlize", function()
    local buf
    it("to memory", function()
        local db, err = hs.simple_new(hs.HS_MODE_BLOCK, { "avc", "dfcws" }, { 0, 0 }, { 1, 2 }, true)
        assert.is_equal(hs.HS_SCAN_TERMINATED, db:scan("avc", {
            handler = function() return hs.HS_SCAN_TERMINATED end
        }), err)
        buf, err = hs.database_to_memory(db)
        assert(buf, err)
    end)
    it("from memory", function()
        local db, err = hs.new_from_memory(buf)
        assert(db, err)
        hs.init_scratch(db)
        assert.is_equal(hs.HS_SCAN_TERMINATED, db:scan("avc", {
            handler = function() return hs.HS_SCAN_TERMINATED end
        }), err)
    end)
end)
