Config = {}

Config.Debug = false

-- Admin authorization:
-- Grant this ACE in server.cfg:
-- add_ace group.admin bs-coca-supplies.admin allow
Config.AdminAce = 'bs-coca-supplies.admin'
Config.AllowRSGAdminPermission = true

Config.Commands = {
    place = 'cocaplace',
    edit = 'cocaedit',
    remove = 'cocaremove',
    list = 'cocalocations',
    reload = 'cocareload'
}

Config.InteractControl = 0xCEFD9220 -- INPUT_CONTEXT / E
Config.InteractKeyLabel = 'E'
Config.DefaultDistance = 2.0
Config.MaxInteractDistance = 5.0
Config.ServerDistanceTolerance = 3.0
Config.ProgressDuration = 4500
Config.ProgressCanCancel = true

-- Cooldown is shared by everyone at that point, preventing repeated harvesting.
Config.MinCooldown = 5
Config.MaxCooldown = 86400
Config.MaxLocations = 1000
Config.MaxRewardAmount = 100

Config.TypeLabels = {
    gathering = 'Gather',
    search = 'Search',
    loot = 'Search',
    custom = 'Interact'
}

Config.Animations = {
    gathering = { dict = 'amb_work@world_human_crouch_inspect@male_a@idle_a', clip = 'idle_a' },
    search = { dict = 'amb_work@world_human_crouch_inspect@male_a@idle_a', clip = 'idle_a' },
    loot = { dict = 'amb_work@world_human_crouch_inspect@male_a@idle_a', clip = 'idle_a' },
    custom = nil
}
