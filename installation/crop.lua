-- BEGIN BS COCA CROP v1
assert(Config.Crops, 'Coca needs the Config.Crops farming API')
if not Config.Crops.coca then Config.Crops.coca = {
        label = 'Coca Plant', seed = 'seedcoca', growTime = 90,
        -- Match the existing bs-cocaine field plant; reuse its leaf item.
        stages = {
            { from = 0,   prop = 'rdr_bush_arec_aa_sim', zOffset = -0.5 },
            { from = 50,  prop = 'rdr_bush_arec_aa_sim', zOffset = -0.25 },
            { from = 100, prop = 'rdr_bush_arec_aa_sim', zOffset = 0.0 },
        },
        harvest = { { item = 'bs_coca_leaf', min = 2, max = 4 }, { item = 'seedcoca', min = 0, max = 1 } },
    }
end
-- END BS COCA CROP v1
