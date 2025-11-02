# TankAlert (WoW 1.12)

A lightweight, configurable addon for the Vanilla (1.12) client that automatically announces failed tanking abilities to the appropriate chat channel.

## Features

* **Smart Announce:** Automatically detects if you are solo, in a party, or in a raid, and sends messages to the correct channel.
* **Intelligent Raid Logic:** Announces to `/raidwarning` (the big yellow text) if you are a raid leader or assist. Announces to `/raid` if you are a regular member, keeping raid warnings clean.
* **Clear Callouts:** Announces the failed ability and its target (e.g., `Sunder Armor FAILED on [Skull] Mana Stalker. Watch threat!`).
* **Raid Icon Priority:** Automatically includes the target's raid icon in the message. If no icon is present, it uses the target's name instead.
* **Fully Configurable:** Use simple slash commands to toggle the addon on/off, change the output channel, or disable alerts for specific abilities.
* **Persistent:** All your settings are saved between sessions.
* **Extremely Lightweight:** No UI, no setup. Just install and go.

## Tracked Abilities

* Taunt (Resist)
* Sunder Armor (Miss, Dodge, Parry)
* Shield Slam (Miss, Dodge, Parry)
* Revenge (Miss, Dodge, Parry)

## Slash Commands

All settings are controlled via the `/ta` command.

* `/ta`
    Displays the current status of the addon and a list of all commands.

* `/ta on` | `off` | `toggle`
    The master switch. Enables or disables all announcements.

* `/ta force [auto | party | raid | say]`
    Overrides the channel logic. For example, `/ta force party` will make all announcements go to party chat, even if you are in a raid. Use `/ta force auto` to return to normal.

* `/ta toggle [taunt | sunder | slam | revenge]`
    Toggles announcements for a specific ability. For example, `/ta toggle sunder` will stop announcing failed Sunder Armors.

## Installation

1.  Go to the [Releases page](https://github.com/Azuriel-stream/TankAlert/releases) of this repository.
2.  Download the latest `.zip` file.
3.  Extract the folder inside the `.zip` file.
4.  Rename the folder inside to **`TankAlert`** (if it isn't already).
5.  Place the `TankAlert` folder into your `World of Warcraft\Interface\AddOns\` directory.
6.  Launch the game, go to "AddOns" on your character selection screen, and make sure **"TankAlert"** is enabled.

## Compatibility

This addon is built for the 1.12 client API. It is extremely lightweight and does not modify any UI elements.
