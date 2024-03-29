describe("runtime", function()
    local compile = require("resty.hs.compile")
    local hs = require("resty.hs")
    local runtime = require("resty.hs.runtime")
    describe("test mode", function()
        local db, scratch, err
        it("block", function()
            db, err = compile.hs_compile([[^[\d_a-z]+]], 0, hs.HS_MODE_BLOCK)
            assert.not_nil(db)
            assert.is_nil(err)
            scratch, err = runtime.hs_alloc_scratch(db)
            assert.not_nil(scratch)
            assert.is_nil(err)
            local ret = runtime.hs_scan(db, "dsy8sahjd_das", scratch, function(id)
                return hs.HS_SUCCESS
            end)
            assert.equal(ret, hs.HS_SUCCESS)
        end)
        it("free db and scratch", function()
            db = nil
            scratch = nil
            collectgarbage("collect")
        end)
    end)
    it('hs_expression_info', function()
        local info = compile.hs_expression_info([[(\d+)]], hs.HS_FLAG_CASELESS)
        assert.is_same(info, {
            matches_at_eod = 0,
            matches_only_at_eod = 0,
            max_width = 4294967295,
            min_width = 1,
            unordered_matches = 0,
        })
    end)
end)
