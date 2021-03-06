describe("block mode", function()
    local hs = require("resty.hs")
    describe("simple mode", function()
        it("single", function()
            local db, err = hs.simple_new(hs.HS_MODE_BLOCK, [[^[\d_a-z]+]], 0)
            assert.not_nil(db, err)
            local ret = db:scan("dsy8sahjd_das", {
                handler = function() return hs.HS_SCAN_TERMINATED end
            })
            assert.is_equal(ret, hs.HS_SCAN_TERMINATED)
        end)
        describe("multi", function()
            local db, err
            it("new", function()
                db, err = hs.simple_new(hs.HS_MODE_BLOCK, { [[[\da-z]+]], [[[_a-z]+]] }, { hs.HS_FLAG_SINGLEMATCH, hs.HS_FLAG_SINGLEMATCH }, { 1, 2 })
                assert.not_nil(db, err)
            end)
            it("scan all", function()
                local count = 0;
                local ret = db:scan("128e36_121_asfc",{
                    handler = function()
                        count = count + 1
                        return hs.HS_SUCCESS
                    end
                })
                assert.is_equal(ret, hs.HS_SUCCESS)
                assert.equal(count, 2)
            end)
            it("scan single", function()
                local count = 0;
                local ret = db:scan("128e36_121_asfc", {
                    handler = function()
                        count = count + 1
                        return hs.HS_SCAN_TERMINATED
                    end
                })
                assert.is_equal(ret, hs.HS_SCAN_TERMINATED)
                assert.equal(count, 1)
            end)
        end)
    end)
    describe("normal", function()
        it("single", function()
            local db, err = hs.new(hs.HS_MODE_BLOCK, [[^[\d_a-z]+]], 0)
            assert.not_nil(db, err)
            local scratch, err = hs.init_scratch(db)
            assert.not_nil(scratch, err)
            local ret = db:scan("dsy8sahjd_das", {
                handler = function() return hs.HS_SCAN_TERMINATED end
            }, scratch)
            assert.is_equal(ret, hs.HS_SCAN_TERMINATED)
        end)
    end)
end)
