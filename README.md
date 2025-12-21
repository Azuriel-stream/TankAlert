# TankAlert (WoW 1.12)

A lightweight, configurable addon for Vanilla (1.12) clients that automatically announces failed tanking abilities and critical loss-of-control events.

**Current Version:** v1.8.1

## Features

* **Multi-Class Support:** Supports **Warrior**, **Druid**, **Paladin**, and **Shaman**.
* **Smart Announce (v1.8.1):**
    * **Silence Filter:** If no non-tank player is above **50% threat**, the addon stays silent to prevent spam.
    * **Early Combat (0-10s):** Fails announced via **Raid Warning** (if promoted) to establish initial aggro.
    * **Mid Combat (>10s):** Fails only announced via Raid Warning if a **High Threat (80%+)** player is detected. Otherwise, uses standard Raid chat.
* **Threat Whispers (Spy Mode):** Integrates with **TWThreat** to whisper DPS/Healers who are close to pulling aggro.
* **Settings GUI:** A fully functional, drag-and-drop configuration window (`/ta`).
* **Specific Failure Alerts:** Announces the *exact* failure type (e.g., `RESISTED`, `DODGED`, `PARRIED`, `MISSED`).
* **Smart CC & Disarm Alerts:** Proactively announces if you are STUNNED, FEARED, or DISARMED.

## Tracked Abilities

### Warrior
* **Taunt** (RESISTED)
* **Sunder Armor** (MISSED, DODGED, PARRIED)
* **Shield Slam** (MISSED, DODGED, PARRIED)
* **Revenge** (MISSED, DODGED, PARRIED)
* **Mocking Blow** (MISSED, DODGED, PARRIED)

### Druid
* **Growl** (RESISTED)

### Paladin
* **Hand of Reckoning** (RESISTED)
* **Holy Strike** (MISSED, DODGED, PARRIED)

### Shaman
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
* **Debug Threat:** Type `/ta debug` to see what threat data the addon is currently tracking.

## Installation

1.  Download the latest release.
2.  Extract the **`TankAlert`** folder into `World of Warcraft\Interface\AddOns\`.
3.  Launch the game.

## Compatibility
Built for **Vanilla 1.12** (Turtle WoW compatible).