# TankAlert (WoW 1.12)

A lightweight, configurable addon for Vanilla (1.12) clients that automatically announces failed tanking abilities for multiple classes.

## Features

* **Multi-Class Support:** Automatically detects your class (currently **Warrior** and **Druid**) and loads the correct abilities and settings.
* **Specific Alerts:** Announces the *exact* failure type (e.g., `RESISTED`, `DODGED`, `PARRIED`, `MISSED`) for maximum clarity.
* **Smart Announce:** Automatically detects if you are solo, in a party, or in a raid, and sends messages to the correct channel.
* **Intelligent Raid Logic:** Announces to `/raidwarning` if you are a raid leader or assist. Announces to `/raid` if you are a regular member, keeping raid warnings clean.
* **Raid Icon Priority:** Automatically includes the target's raid icon (e.g., `[Skull]`) in the message. If no icon is present, it uses the target's name instead.
* **Fully Configurable:** Use simple slash commands to toggle the addon on/off, change the output channel, or disable alerts for specific abilities.
* **Persistent:** All your settings are saved between sessions.
* **Extremely Lightweight:** No UI, no setup. Just install and go.

## Tracked Abilities

### Warrior
* **Taunt** (RESISTED)
* **Sunder Armor** (MISSED, DODGED, PARRIED)
* **Shield Slam** (MISSED, DODGED, PARRIED)
* **Revenge** (MISSED, DODGED, PARRIED)
* **Mocking Blow** (MISSED, DODGED, PARRIED)

### Druid
* **Growl** (RESISTED)
*(More Druid abilities will be added in future versions!)*

## Slash Commands

All settings are controlled via the `/ta` command.

* `/ta`
    Displays the current status of the addon and a list of all commands *specific to your class*.

* `/ta on` | `off` | `toggle`
    The master switch. Enables or disables all announcements.

* `/ta force [auto | party | raid | say]`
    Overrides the channel logic. For example, `/ta force party` will make all announcements go to party chat, even if you are in a raid. Use `/ta force auto` to return to normal.

* `/ta toggle [ability]`
    Toggles announcements for a specific ability for your class (e.g., `/ta toggle sunder` or `/ta toggle growl`).

## Installation

1.  Go to the [Releases page](https://github.com/Azuriel-stream/TankAlert/releases) of this repository.
2.  Download the latest `.zip` file (e.g., `TankAlert-v1.4.zip`).
3.  Extract the folder inside the `.zip` file.
4.  Rename the folder inside to **`TankAlert`** (if it isn't already).
5.  Place the `TankAlert` folder into your `World of Warcraft\Interface\AddOns\` directory.
6.  Launch the game, go to "AddOns" on your character selection screen, and make sure **"TankAlert"** is enabled.

## Compatibility

This addon is built for the 1.12 client API. It is extremely lightweight and does not modify any UI elements.
