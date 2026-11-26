Config = {}

---------------------------------------------
-- general
---------------------------------------------
Config.BookItem    = 'bs_coca_processingbook'
Config.XPType      = 'crafting'
Config.Image       = 'rsg-inventory/html/images/'
Config.MaxBatch    = 10
Config.ShowLocked  = true

-- Recipes offered at fixed stations. Coordinates are also validated server-side.

Config.Anim = {
    dict = 'mech_inventory@crafting@fallbacks',
    clip = 'full_craft_and_stow',
    flag = 27,
}

-- Ingredients are existing RSG inventory items sourced from farming, herbalist,
-- lumberjack, mining, smelting, hunting, and moonshine activities.

-- Optional upstream 3.2 shared progression. Existing recipes and rep remain authoritative.
Config.Skills={Enabled=false,Skill='crafting',XPScale=5,SaveChance=false}
