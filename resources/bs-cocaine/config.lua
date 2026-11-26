Config = {}
-- SAFE DEFAULT: enable only on staging after setting real in-world coordinates.
Config.Enabled = true
-- Change only after testing a native RDR2 model in game.
Config.PlantModel = 'rdr_bush_arec_aa_sim'
Config.InteractKey = 0x760A9C6F -- G
Config.InteractDistance = 2.0
Config.FieldRespawnSeconds = 60
Config.HarvestAmount = { min = 2, max = 4 }
Config.HarvestCooldownSeconds = 5
Config.CraftSeconds = 8
Config.SaleCooldownSeconds = 2
Config.BuyChance = 65
Config.PriceMin = 5
Config.PriceMax = 9
Config.SaleQuantityMin = 1
Config.SaleQuantityMax = 15
Config.NpcDistance = 3.0
Config.SaleMoneyType = 'cash'
Config.Items = {
  leaf = 'bs_coca_leaf', raw = 'bs_coca_raw', loose = 'bs_coca_loose',
  bag = 'bs_coca_bag', baggie = 'bs_empty_baggie',
  reagent = 'bs_fictional_reagent', soda = 'bs_baking_soda'
}
-- Set coordinates after selecting and verifying actual spots in-game.
-- Every field location is shared; server maintains its respawn timer.
Config.Plants = {
    { coords = vector3(472.95, -1724.11, 43.24) },
    { coords = vector3(469.12, -1719.48, 43.24) },
    { coords = vector3(463.37, -1728.64, 43.24) },
    { coords = vector3(458.91, -1715.23, 43.24) },
    { coords = vector3(475.42, -1731.06, 43.24) },
    { coords = vector3(451.26, -1722.78, 43.24) },
    { coords = vector3(445.83, -1711.45, 43.24) },
    { coords = vector3(460.74, -1704.29, 43.24) },
    { coords = vector3(470.18, -1707.63, 43.24) },
    { coords = vector3(438.52, -1727.14, 43.24) },
    { coords = vector3(432.67, -1718.39, 43.24) },
    { coords = vector3(449.61, -1698.82, 43.24) },
    { coords = vector3(455.93, -1692.54, 43.24) },
    { coords = vector3(441.17, -1690.76, 43.24) },
    { coords = vector3(428.24, -1686.2, 43.24) },
    { coords = vector3(434.83, -1696.43, 43.24) },
    { coords = vector3(423.91, -1702.78, 43.24) },
    { coords = vector3(418.72, -1691.36, 43.24) },
    { coords = vector3(425.64, -1712.91, 43.24) },
    { coords = vector3(438.95, -1705.27, 43.24) },
    { coords = vector3(466.21, -1736.18, 43.24) },
    { coords = vector3(453.84, -1734.62, 43.24) },
    { coords = vector3(445.27, -1738.51, 43.24) },
    { coords = vector3(416.83, -1719.44, 43.24) },
    { coords = vector3(479.31, -1714.57, 43.24) },
}
Config.Benches = {
  -- { coords = vector3(0.0, 0.0, 0.0), label = 'Prepare Leaves', stage = 1 },
  -- { coords = vector3(0.0, 0.0, 0.0), label = 'Refine Product', stage = 2 },
  -- { coords = vector3(0.0, 0.0, 0.0), label = 'Package Product', stage = 3 },
}
-- Abstract game recipes, not real-world production instructions.
Config.Recipes = {
  [1] = { inputs = { bs_coca_leaf = 3, bs_fictional_reagent = 1 }, output = 'bs_coca_raw', amount = 1 },
  [2] = { inputs = { bs_coca_raw = 1, bs_baking_soda = 1 }, output = 'bs_coca_loose', amount = 1 },
  [3] = { inputs = { bs_coca_loose = 1, bs_empty_baggie = 1 }, output = 'bs_coca_bag', amount = 1 },
}

-- Broken Spur TEST supply-gathering locations. No location cooldowns.
Config.GatherInteractDistance = 3.0
Config.GatherDurationSeconds = 10
Config.GatherLocations = {} -- Locations now created using bs-cityinteractions
-- Tiered street buyer: configurable per-grade NPC prices (cash per bag).
Config.TierSales = {
  { item = 'bs_coca_bag_t3', label = 'Pure Reserve', price = 16 },
  { item = 'bs_coca_bag_t2', label = 'Refined Cut', price = 12 },
  { item = 'bs_coca_bag_t1', label = 'Street Cut', price = 8 },
}
