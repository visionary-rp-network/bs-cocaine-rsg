Config.Crafting = {
    -- Broken Spur fictional coca processing: one station, shared crafting XP.
    -- Each stage preserves its quality tier; generic legacy items are not produced.
    -- Tier 1: XP 0; fictional gameplay conversion ratios.
    { category = 'Tier 1 - Street Cut', receive = 'bs_coca_raw_t1', giveamount = 5,
      crafttime = 8000, requiredxp = 0, xpreward = 1,
      ingredients = { { item = 'bs_coca_leaf', amount = 3 }, { item = 'bs_fictional_reagent', amount = 2 } } },
    { category = 'Tier 1 - Street Cut', receive = 'bs_coca_loose_t1', giveamount = 5,
      crafttime = 8000, requiredxp = 0, xpreward = 1,
      ingredients = { { item = 'bs_coca_raw_t1', amount = 5 }, { item = 'bs_baking_soda', amount = 2 } } },
    { category = 'Tier 1 - Street Cut', receive = 'bs_coca_bag_t1', giveamount = 10,
      crafttime = 8000, requiredxp = 0, xpreward = 1,
      ingredients = { { item = 'bs_coca_loose_t1', amount = 1 }, { item = 'bs_empty_baggie', amount = 1 } } },

    -- Tier 2: XP 50; fictional gameplay conversion ratios.
    { category = 'Tier 2 - Refined Cut', receive = 'bs_coca_raw_t2', giveamount = 4,
      crafttime = 8000, requiredxp = 50, xpreward = 2,
      ingredients = { { item = 'bs_coca_leaf', amount = 2 }, { item = 'bs_fictional_reagent', amount = 2 } } },
    { category = 'Tier 2 - Refined Cut', receive = 'bs_coca_loose_t2', giveamount = 8,
      crafttime = 8000, requiredxp = 50, xpreward = 2,
      ingredients = { { item = 'bs_coca_raw_t2', amount = 4 }, { item = 'bs_baking_soda', amount = 2 } } },
    { category = 'Tier 2 - Refined Cut', receive = 'bs_coca_bag_t2', giveamount = 15,
      crafttime = 8000, requiredxp = 50, xpreward = 2,
      ingredients = { { item = 'bs_coca_loose_t2', amount = 1 }, { item = 'bs_empty_baggie', amount = 1 } } },

    -- Tier 3: XP 100; fictional gameplay conversion ratios.
    { category = 'Tier 3 - Pure Reserve', receive = 'bs_coca_raw_t3', giveamount = 4,
      crafttime = 8000, requiredxp = 100, xpreward = 3,
      ingredients = { { item = 'bs_coca_leaf', amount = 1 }, { item = 'bs_fictional_reagent', amount = 1 } } },
    { category = 'Tier 3 - Pure Reserve', receive = 'bs_coca_loose_t3', giveamount = 12,
      crafttime = 8000, requiredxp = 100, xpreward = 3,
      ingredients = { { item = 'bs_coca_raw_t3', amount = 4 }, { item = 'bs_baking_soda', amount = 1 } } },
    { category = 'Tier 3 - Pure Reserve', receive = 'bs_coca_bag_t3', giveamount = 20,
      crafttime = 8000, requiredxp = 100, xpreward = 3,
      ingredients = { { item = 'bs_coca_loose_t3', amount = 1 }, { item = 'bs_empty_baggie', amount = 1 } } },

    -- Premium brick: XP 150, tier 3 bags only.
    { category = 'Brick Production', receive = 'bs_coca_packed', giveamount = 1,
      crafttime = 12000, requiredxp = 150, xpreward = 5,
      ingredients = { { item = 'bs_coca_bag_t3', amount = 10 }, { item = 'bs_fictional_reagent', amount = 2 },
                      { item = 'bs_baking_soda', amount = 2 }, { item = 'bs_wrapping_paper', amount = 3 },
                      { item = 'resource_string', amount = 2 } } },
}
