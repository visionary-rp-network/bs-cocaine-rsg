# Broken Spur Cocaine System for RSG / RedM

**Brand:** Visionary RP Network (VRP)  
**Project:** Broken Spur  
**Creator / project credit:** sovereign_rp  
**Public GitHub:** https://github.com/visionary-rp-network/bs-cocaine-rsg

Custom scripts and integrations are credited to VRP and sovereign_rp. RSG retains credit for its original framework and crafting base.

A standalone export of Broken Spur's fictional in-game coca harvesting, quality-tier processing and NPC bag sales. Includes the custom dependencies needed for its processing station and supply points without replacing the server's ordinary crafting resource.

**Status: installation candidate, not a verified one-click release.** Static and installer checks are provided. A recipient-server gameplay test is required. Existing server shop database records are not exported; supply availability and a brick buyer must be configured as described below.

## Included

| Resource | Purpose |
| --- | --- |
| `bs-cocaine` | Wild coca field, harvest cooldowns and ambient-NPC packaged-product sales |
| `bs-coca-crafting` | Separate processing UI, server-checked recipes, crafting XP and quality tiers; adapted from RSG crafting |
| `bs-coca-stations` | Third-eye processing workbench at the Bayou location |
| `bs-coca-supplies` | Three existing reagent gathering points and an administrator supply-location editor |

The installation folder contains **21 additive item definitions and 21 images**, including seeds, base products, tiered products, the brick and all recipe inputs. A coca crop addition is included for modern `rsg-farming` configurations using `Config.Crops`.

No database export, player records, passwords, webhook URLs, Discord identities, license keys or original repository history are included. Encounter guards/predators, unrelated businesses, black-market shops and other server content are not required or included.

## Requirements

- An existing working **RedM RSG** server with OneSync/networked entities.
- `rsg-core`, `rsg-inventory`, `rsg-target`, and `ox_lib`, started before this package.
- For planting: `rsg-farming` with the modern **`Config.Crops`** format. Older farming versions require a manual adapter. This package does not upgrade their database or replace their farming script.
- Python 3.10+ for the optional Windows/Linux installer. Manual installation does not need Python.
- RSG inventory server exports `GetItemCount`, `CanAddItem`, `AddItem`, `RemoveItem`; client `HasItem`; RSG target global-ped and sphere-zone APIs; core crafting reputation functions `GetRep`/`AddRep`.

Obtain the framework resources from [RSG Framework](https://github.com/Rexshack-RedM) and ox_lib from its maintained official distribution. Do not replace customized framework resources with defaults to install this package.

## Install with the helper

1. Back up the destination resources/configuration and database. Stop the destination server before applying changes.
2. Extract this repository/ZIP outside the server's resources directory.
3. Preview the installation:

```powershell
python .\install.py --resources 'C:\YourServer\resources'
```

4. Review the output, then apply:

```powershell
python .\install.py --resources 'C:\YourServer\resources' --apply
```

For wild-field harvesting without farming, add `--skip-farming` to both commands. **Seeds will not become plantable in that mode.**

The helper appends guarded item/crop definitions, copies missing images, and adds the four new resources. It preserves existing item/crop definitions and images. If an existing package file differs, or a dependency/config format is missing, it refuses the plan before writing anything. It does not run SQL, edit server.cfg, stop a server or restart anything. Originals it changes and an installation record are saved in `bs-coca-install-backups` next to the resources folder.

5. Copy the `ensure` lines from `startup.example.cfg` into your server startup after the listed prerequisites. Avoid duplicate group/explicit startup entries.
6. Perform a **scheduled full restart**, since core item definitions and farming seed registrations load at startup. Do not hot-restart core/inventory with players online.

## Manual installation

Copy each folder under `resources/` to a resource category of your choice. Append `installation/items.lua` to the end of `rsg-core/shared/items.lua`, after its item table. Do not paste it inside the table. Add the contents of `installation/crop.lua` at the end of `rsg-farming/shared/config.lua` if it uses `Config.Crops`. Copy missing `installation/images/*.png` to `rsg-inventory/html/images`. Add the startup lines and restart as above.

Existing definitions take priority. If your server already uses an item ID such as `resource_string`, confirm its meaning and weight match the recipe before installing.

## Gameplay and locations

- Wild field: center roughly **440, -1715, 43.24**. Approach a plant and use **G** to harvest. The exact 25 placements are editable in `bs-cocaine/config.lua`.
- Processing station: **2230.59, -769.93, 43.54**. Third eye the workbench area to open processing. The resource does not spawn a building/interior.
- Supply points: reagent collection near **2644.68, -1436.57, 51.35**, **-161.53, 646.04, 118.66**, and **2843.10, 1443.79, 74.20**. Approach and use the on-screen **E** interaction.
- Plantable item: `seedcoca`. The farming crop yields coca leaves and a chance of returning a seed. Default base growth time is 90 minutes, subject to the recipient's farming care/settings.
- Packaged bags: third eye an eligible **networked ambient NPC** and select **Offer packaged product**. Buyers can decline. Highest-priced tiers are offered first, up to 15 total bags. The default configured tier prices are $8 / $12 / $16 per bag; legacy bags use $5â€“$9. Existing weed-sales code is not replaced.

All locations and prices are server-owner configuration, not guaranteed to suit every map or economy. Inspect ground/interior access on the recipient server.

## Supplies, seeds and brick buyer: configure before inviting players

The original server distributes seeds through staff/its economy. This export does **not** silently add seeds to public stores or grant items to players. Use your normal authorized RSG give-item tool to test `seedcoca`, then add it to an appropriate shop or reward system.

The saved gathering records cover reagent only. Add routes for `bs_baking_soda`, `bs_empty_baggie`, `bs_wrapping_paper` and `resource_string` to your existing shop/gathering system. Alternatively use the included supply-location editor: authorize your administrator group with the commented ACE line, use `/cocaplace`, choose a gathering/search point and its reward item, then save. Editor commands are `/cocaplace`, `/cocaedit`, `/cocaremove`, `/cocalocations`, `/cocareload`; inspect the resource README for details. Restrict editor access to trusted administrators.

**Bricks are not sold through ambient-NPC bag sales.** Add `bs_coca_packed` to a server-side buyer in your existing shop/trader system and choose a payout appropriate to your economy. No live shop SQL, ownership, inventories or pricing records are included. Do not advertise a working brick sell-off until that buyer has been tested.

## Processing and configuration

The separate resource preserves the three fictional quality tiers (XP thresholds 0, 50, 100) and premium brick recipe (XP 150). Its recipes are in `bs-coca-crafting/server/recipes.lua`, the station/categories in `server/stations.lua`, and target placement in `bs-coca-stations/config.lua`. If moving the station, update **both** placement files. The existing RSG `crafting` reputation is shared; ordinary crafting events and books are isolated.

The `bs_coca_processingbook` item is a separately named reference book; processing still requires the station. No ordinary RSG crafting book is replaced. Webhook logging is disabled in the export. Any future logging URL belongs only in the server-side configuration.

Do not run both the original Broken Spur coca resources and their exported equivalents on the same server: duplicate supply zones, stations or NPC-sale handlers would result.

## Acceptance checklist

1. Start with no missing-dependency/item errors; ordinary RSG crafting still works.
2. Harvest a field plant, confirm inventory gain, regrowth cooldown and reconnect state.
3. Plant a seed; water, grow, harvest and reconnect using your farming system.
4. Collect reagent at each configured supply point; test other materials after configuring them.
5. At the station, check locked tiers, all ten recipes, ingredient deduction, XP and output; try missing ingredients, insufficient space, cancelling and walking away.
6. Confirm bag-sale payouts match configuration and a buyer cannot be repeatedly sold to during its cooldown. Try a player ped and a distant NPC: neither should be accepted.
7. Produce a brick and test your configured buyer. Check ordinary weed/other-drug sales still work.
8. Restart the server and repeat the station/farming checks with two players.

The installer/static checks do not prove animations, map terrain, target compatibility or all inventory edge cases. Test on a separate server before using with players.

## Troubleshooting

- **Seed does nothing:** confirm the farming crop addition, matching Config.Crops API, item registration and full restart. `--skip-farming` deliberately does not register a plantable seed.
- **Processing menu empty:** confirm all four resources start in order and recipes/items loaded. Inspect server and F8 errors.
- **No NPC selling:** use a living, networked ambient NPC, carry packaged bags and ensure rsg-target started first. A player or a non-networked ped is intentionally rejected.
- **Missing supply or no brick buyer:** configure the material routes/buyer described above; those are server economy choices.
- **Installer refuses an existing file:** back it up and manually merge. The helper will not overwrite an existing customization.
- **Missing model or buried plant:** check the configured world model and field Z coordinates against your server build/maps.

## Rollback / updates

Stop the destination server. Remove the four package ensure lines and newly installed resource folders. Restore changed core/farming files from the matching helper backup **only if no later edits would be lost**; otherwise remove just the marked `BEGIN/END BS COCA` blocks manually. Do not remove a crop definition while saved plants still reference it: harvest/remove those through your normal farming tools first. Keep item definitions/images while players still possess the items. No SQL rollback is supplied because the installer runs no SQL.

For updates, back up recipient changes and merge deliberately; this initial installer refuses different installed package files rather than overwriting them.

## Source and licensing

The original crafting base is credited to the RSG team. Its GPL license is preserved in `resources/bs-coca-crafting/LICENSE`; the adapted distribution is provided under that same license (see root LICENSE). Original upstream attribution/README is retained in that resource. `source-manifest.json` records the source snapshot and export scope. Images are the inventory assets used with these item definitions; do not claim exclusive ownership of third-party artwork.

This is a game resource, not real-world production instructions. No affiliation with Rockstar Games, Cfx.re or the RSG team is implied.
