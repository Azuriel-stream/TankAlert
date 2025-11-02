# TankAlert (WoW 1.12)

A lightweight addon for the Vanilla (1.12) client that automatically announces failed tanking abilities to the appropriate chat channel.

## Features

This addon monitors your combat log and provides critical alerts when one of your main tanking abilities fails to land.

* **Smart Announce:** Automatically detects if you are solo, in a party, or in a raid:
    * **Solo:** Announces to **/say**.
    * **Party:** Announces to **/party**.
    * **Raid:** Announces to **/raidwarning** (the big yellow text).
* **No Setup Required:** Just install it and it works. There are no settings or commands.

### Tracked Abilities

* **Taunt:** Announces when resisted.
* **Sunder Armor:** Announces on miss, dodge, or parry.
* **Shield Slam:** Announces on miss, dodge, or parry.
* **Revenge:** Announces on miss, dodge, or parry.

## Installation

1.  Go to the [Releases page](https://github.com/Azuriel-stream/TankAlert/releases) of this repository (or click "Code" > "Download ZIP").
2.  Download the `.zip` file.
3.  Extract the folder inside the `.zip` file.
4.  Rename the folder inside to **`TankAlert`** (if it isn't already).
5.  Place the `TankAlert` folder into your `World of Warcraft\Interface\AddOns\` directory.
6.  Launch the game, go to "AddOns" on your character selection screen, and make sure **"TankAlert"** is enabled.

## Compatibility

This addon is built for the 1.12 client API. It is extremely lightweight and does not modify any UI elements.

* **pfUI:** Confirmed to be **100% compatible** and works alongside `pfUI`.
