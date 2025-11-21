# TankAlert (WoW 1.12)

A lightweight, configurable addon for Vanilla (1.12) clients that automatically announces failed tanking abilities and critical loss-of-control events.

## Features

* **Multi-Class Support:** Automatically detects your class (currently **Warrior** and **Druid**) and loads the correct abilities and settings.
* **Specific Failure Alerts:** Announces the *exact* failure type (e.g., `RESISTED`, `DODGED`, `PARRIED`, `MISSED`) for maximum clarity.
* **Smart CC & Disarm Alerts:** Proactively announces if you are STUNNED, FEARED, or DISARMED. Uses smart detection to prevent false-positives and includes an 8-second throttle to prevent spam.
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

## Global Alerts (All Classes)
* **Loss of Control (Stun/Fear):** Alerts when you try to use an ability while Stunned or Feared.
* **Disarm:** Intelligently alerts when you try to use an ability while Disarmed (and confirms you have a weapon equipped).

## New in v1.6: Threat Whispers (TWThreat Integration)
TankAlert now integrates with **TWThreat** to help you manage group threat without looking at a meter.

* **Smart Whispers:** If a DPS or Healer exceeds the threat threshold (default 90%) on your target, TankAlert will send them a private whisper warning them to watch their threat.
* **Passive "Spy" Mode:** This feature requires at least one person in your party/raid to be running the **TWThreat** addon. TankAlert listens to their broadcasts invisibly.
* **Tank Protection:** The addon intelligently detects who the current tank is and will *not* whisper them, even if they are high on threat.
* **Anti-Spam Throttle:** Whispers are throttled to occur at most once every 15 seconds per player.

### Threat Commands
* `/ta toggle whisper` - Enable/Disable the threat whisper system.
* `/ta toggle tankonly` - **(Smart Mode)** If enabled, TankAlert will ONLY send whispers if **YOU** are currently the tank. This prevents 5 people running TankAlert from spamming the poor mage at the same time.
* `/ta set threshold 90` - Sets the threat percentage at which to whisper (Range: 50-100).

## Slash Commands

All settings are controlled via the `/ta` command.

* `/ta`
    Displays the current status of the addon and a list of all commands *specific to your class*.

* `/ta on` | `off` | `toggle`
    The master switch. Enables or disables all announcements.

* `/ta force [auto | party | raid | say]`
    Overrides the channel logic. For example, `/ta force party` will make all announcements go to party chat, even if you are in a raid. Use `/ta force auto` to return to normal.

* `/ta toggle [ability | cc | disarm]`
    Toggles announcements for a specific ability (e.g., `sunder`) or a global alert (e.g., `cc` or `disarm`).

## Installation

1.  Go to the [Releases page](https://github.com/Azuriel-stream/TankAlert/releases) of this repository.
2.  Download the latest `.zip` file (e.g., `TankAlert-v1.6.zip`).
3.  Extract the folder inside the `.zip` file.
4.  Rename the folder inside to **`TankAlert`** (if it isn't already).
5.  Place the `TankAlert` folder into your `World of Warcraft\Interface\AddOns\` directory.
6.  Launch the game, go to "AddOns" on your character selection screen, and make sure **"TankAlert"** is enabled.

## Compatibility

This addon is built for the 1.12 client API and is extremely lightweight. It does not modify any UI elements.