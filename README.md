# ZoneWho

Addon for **World of Warcraft 1.12.1** (Vanilla / VanillaPlus) — shows a live list of players currently in your zone.

## Features

- Automatic background `/who` for the current zone every 20 seconds
- Compact movable window with class-coloured names, levels and guilds
- Does **not** open or close the Social / Who window (FriendsFrame)
- Works alongside manual `/who` and the Social button

## Installation

Place the `ZoneWho` folder into:

```
Interface\AddOns\ZoneWho
```

Then `/reload` or restart the client.

Update via git (recommended):

```bat
cd /d c:\Vanillaplus\Interface\AddOns\ZoneWho
git pull
```

## Slash commands

| Command | Description |
|---------|-------------|
| `/zonewho` | Toggle the window |
| `/zonewho show` / `hide` | Show or hide the window |
| `/zonewho now` | Force an immediate who query |
| `/zonewho debug` | Print current zone and result count |
| `/zonewho version` | Show addon version |

## Version history

See [CHANGELOG.md](CHANGELOG.md).

Current version: **1.2**
