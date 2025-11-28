# TankAlert (WoW 1.12)

A lightweight, configurable addon for Vanilla (1.12) clients that automatically announces failed tanking abilities and critical loss-of-control events.

**Current Version:** v1.7

## Features

* **Multi-Class Support:** Automatically detects your class (currently **Warrior** and **Druid**) and loads the correct abilities and settings.
* **NEW! Settings GUI:** A fully functional, drag-and-drop configuration window. Type `/ta` to open.
* **Specific Failure Alerts:** Announces the *exact* failure type (e.g., `RESISTED`, `DODGED`, `PARRIED`, `MISSED`) for maximum clarity.
* **Smart CC & Disarm Alerts:** Proactively announces if you are STUNNED, FEARED, or DISARMED. Uses smart detection and an 8-second throttle to prevent spam.
* **Smart Announce:** Automatically detects if you are solo, in a party, or in a raid, and sends messages to the correct channel.
* **Intelligent Raid Logic:** Announces to `/raidwarning` if you are a raid leader or assist. Announces to `/raid` if you are a regular member.
* **Threat Whispers (Spy Mode):** Integrates with **TWThreat** to whisper DPS/Healers who are close to pulling aggro (default >90%).
* **Extremely Lightweight:** No XML, single Lua file, zero dependencies.

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

## Configuration (New in v1.7)

**Type `/ta` to open the Settings Window.**

From the GUI, you can:
* **Toggle Addon:** Enable/Disable the master switch.
* **Force Channel:** Override smart logic (e.g., force output to `SAY` or `PARTY`).
* **Toggle Abilities:** Individually enable/disable alerts for specific spells (e.g., turn off Sunder alerts but keep Taunt).
* **Configure Threat Whispers:**
    * **Enable/Disable:** Turn the module on or off.
    * **Tank Only Mode:** Ensure you only send warnings if *you* are the active tank.
    * **Threshold:** Set the threat percentage (50%-100%) for warnings.

*Note: Old slash commands are still supported for macro usage.*

## Threat Whispers (TWThreat Integration)

TankAlert listens to `TWThreat` addon broadcasts invisibly.
* **Smart Whispers:** Warns DPS/Healers exceeding the threat threshold.
* **Tank Protection:** Ignores the current tank (you won't whisper the Main Tank).
* **Anti-Spam:** Limits whispers to once every 15 seconds per player.

## Installation

1.  Go to the [Releases page](https://github.com/Azuriel-stream/TankAlert/releases) of this repository.
2.  Download the latest `.zip` file (e.g., `TankAlert-v1.7.zip`).
3.  Extract the folder inside the `.zip` file.
4.  Rename the folder inside to **`TankAlert`** (if it isn't already).
5.  Place the `TankAlert` folder into your `World of Warcraft\Interface\AddOns\` directory.
6.  Launch the game.

## Compatibility
Built strictly for the **1.12 client API**. Does not rely on modern WoW functions.