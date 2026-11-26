# bs-coca-supplies

Standalone admin-placed gathering, searching, loot, and custom interaction points for Broken Spur (RedM / RSGCore).

## Dependencies

- `rsg-core`
- `ox_lib`

This resource deliberately does not modify existing gathering, crafting, processing, selling, or database resources. It grants the configured item directly through `Player.Functions.AddItem`.

## Installation

1. Copy `bs-coca-supplies` into `resources/[community]/`.
2. Ensure `ox_lib` and `rsg-core` start before this resource.
3. Add this ACE permission to `server.cfg` for the admin group:

```cfg
add_ace group.admin bs-coca-supplies.admin allow
```

4. Add this after RSGCore and ox_lib:

```cfg
ensure bs-coca-supplies
```

5. Restart the staging server.

If your admin group is not named `group.admin`, grant the ACE to the correct group. RSGCore admin permission is also checked when `Config.AllowRSGAdminPermission = true`.

## In-game commands

| Command | Description |
|---|---|
| `/cocaplace` | Place a new interaction at your current position |
| `/cocaedit` | Edit the nearest interaction within 8 metres; saves at your current position |
| `/cocaremove` | Remove the nearest interaction within 8 metres |
| `/cocalocations` | Show the saved location list |
| `/cocareload` | Reload locations from JSON |

The server also registers `bs-coca-supplies-reload` for console/admin reloads.

## Creating a point

Run `/cocaplace`, select a type, enter a label and an exact RSGCore item ID, set quantity bounds, cooldown, and interaction radius. The point is saved in `data/locations.json`.

Supported types:
- `gathering`
- `search`
- `loot`
- `custom`

`propModel` is currently stored as an optional reference label. Interaction is coordinate-based; this first version does not dynamically bind to or spawn world props.

## Security and behavior

- All create, edit, remove, and collect operations are validated server-side.
- The server checks admin permission, item existence, reward bounds, coordinates, and player proximity.
- Rewards are granted server-side only.
- Each location has a shared cooldown for all players.
- Locations persist in `data/locations.json`.
- No recipe, gathering script, processing script, database, or existing item definition is modified.

## Important test notes

- Verify the target RSGCore build supports `Player.Functions.AddItem(item, amount)`.
- Verify your server's inventory UI displays the configured item icon.
- Confirm the admin ACE group matches your server's actual admin group.
- Test with a disposable character and one low-value item first.
- The resource does not currently implement per-player cooldowns, multi-reward tables, prop entity detection, or inventory-full return semantics beyond the standard `AddItem` false result.

## Release status

Version 1.0.0 - staging test build. Validate on the OfficePC staging server before copying to public LIVE.
