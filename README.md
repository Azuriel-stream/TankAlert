# TankAlert (WoW 1.12)

A lightweight, configurable addon for Vanilla (1.12) clients that automatically announces failed tanking abilities and critical loss-of-control events.

**Current Version:** v1.8

## Features

* **Multi-Class Support:** Supports **Warrior**, **Druid**, **Paladin**, and **Shaman** (New in v1.8!).
* **Settings GUI:** A fully functional, drag-and-drop configuration window (`/ta`).
* **Specific Failure Alerts:** Announces the *exact* failure type (e.g., `RESISTED`, `DODGED`, `PARRIED`, `MISSED`).
* **Smart CC & Disarm Alerts:** Proactively announces if you are STUNNED, FEARED, or DISARMED (throttled).
* **Smart Announce:** Automatically detects if you are solo, in a party, or in a raid, and sends messages to the correct channel.
* **Threat Whispers (Spy Mode):** Integrates with **TWThreat** to whisper DPS/Healers who are close to pulling aggro.

## Tracked Abilities

### Warrior
* **Taunt** (RESISTED)
* **Sunder Armor** (MISSED, DODGED, PARRIED)
* **Shield Slam** (MISSED, DODGED, PARRIED)
* **Revenge** (MISSED, DODGED, PARRIED)
* **Mocking Blow** (MISSED, DODGED, PARRIED)

### Druid
* **Growl** (RESISTED)

### Paladin (New!)
* **Hand of Reckoning** (RESISTED)
* **Holy Strike** (MISSED, DODGED, PARRIED)

### Shaman (New!)
* **Earthshaker Slam** (RESISTED)
* **Earth Shock** (RESISTED)
* **Lightning Strike** (MISSED, DODGED, PARRIED)
* **Stormstrike** (MISSED, DODGED, PARRIED)
* **Frost Shock** (RESISTED)

## Configuration

**Type `/ta` to open the Settings Window.**

From the GUI, you can:
* **Toggle Addon:** Enable/Disable the master switch.
* **Toggle Abilities:** Individually enable/disable alerts for specific spells.
* **Configure Threat Whispers:** Enable "Tank Only Mode" to ensure you only warn DPS if *you* are the current tank.

## Installation

1.  Download the latest release.
2.  Extract the **`TankAlert`** folder into `World of Warcraft\Interface\AddOns\`.
3.  Launch the game.

## Compatibility
Built for **Vanilla 1.12**.