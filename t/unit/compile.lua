describe("compile", function()
    local compile = require("resty.hs.compile")
    local hs = require("resty.hs")
    local runtime = require("resty.hs.runtime")
    describe("test mode", function()
        describe("block", function()
            local db, scratch, err
            it("success", function()
                db, err = compile.hs_compile([[^[\d_a-z]+]], 0, hs.HS_MODE_BLOCK)
                assert.not_nil(db)
                assert.is_nil(err)
            end)
            it("error param", function()

            end)
            it("scan", function()
                scratch, err = runtime.hs_alloc_scratch(db)
                assert.not_nil(scratch)
                assert.is_nil(err)
                local ret = runtime.hs_scan(db, "dsy8sahjd_das", scratch, function(id)
                    return hs.HS_SUCCESS
                end)
                assert.equal(ret, hs.HS_SUCCESS)
            end)
        end)
    end)
    describe("test multi", function()
        local db, scratch, err
        it("success", function()
            db, err = compile.hs_compile_ext_multi({ [[[\da-z]+]], [[[_a-z]+]] }, { hs.HS_FLAG_SINGLEMATCH, hs.HS_FLAG_SINGLEMATCH }, { 1, 2 }, 2, hs.HS_MODE_BLOCK)
            assert.not_nil(db)
            assert.is_nil(err)
        end)
        it("error param", function()

        end)
        it("scan", function()
            scratch, err = runtime.hs_alloc_scratch(db)
            assert.not_nil(scratch)
            assert.is_nil(err)

            local count = 0;
            local ret = runtime.hs_scan(db, "128e36_121_asfc", scratch, function(id)
                count = count + 1
                return hs.HS_SUCCESS
            end)
            assert.equal(ret, hs.HS_SUCCESS)
            assert.equal(count, 2)
        end)

    end)
end)
