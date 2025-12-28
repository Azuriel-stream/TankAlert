# TankAlert (Turtle WoW / Vanilla 1.12)

**TankAlert** is a lightweight, standalone addon for Vanilla WoW (1.12) designed to help tanks communicate critical failures and threat warnings to their group automatically.

## Key Features

### 1. Ability Failure Alerts
Automatically announces to **Say**, **Party**, or **Raid** when your critical tanking abilities fail (Dodge, Parry, Miss, Resist).
* **Warrior:** Taunt, Sunder Armor, Shield Slam, Revenge, Mocking Blow
* **Druid:** Growl
* **Paladin:** Hand of Reckoning, Holy Strike
* **Shaman:** Earthshaker Slam, Earth Shock, Lightning Strike, Stormstrike

### 2. Crowd Control (CC) Warning
Detects when you lose control of your character and alerts the group to watch their threat.
* **Stuns:** Iron Grenades, HoJ, Kidney Shot, War Stomp, etc.
* **Fears:** Psychic Scream, Intimidating Shout, etc.
* **Incapacitate:** Polymorph, Gouge, Sap (New in v1.8.2)
* **Disarm:** Weapon chain/shield checks.

### 3. Threat Whispers (Requires TWThreat)
Acts as a "Spy" module for the **TWThreat** library.
* Monitors threat data synced from other players.
* **Whisper Warnings:** Automatically whispers DPS/Healers when they exceed a threat threshold (default 90%) relative to the tank.
* **Smart Filtering:** Can be configured to only send whispers if YOU are the current tank.

## Installation

### Turtle WoW Launcher / GitAddonsManager
1.  Open either application.
2.  Click the **Add** button.
3.  Paste the url: `https://github.com/Azuriel-stream/TankAlert`
4.  Download and keep up to date.

### Manual Installation
1.  Download the latest **.zip** file from the Releases page.
2.  Extract the contents.
3.  Ensure the folder is named `TankAlert` (remove `-main` or version numbers if present).
4.  Move the folder to your `\World of Warcraft\Interface\AddOns\` directory.

## Usage
Type `/ta` to open the configuration GUI.

* **Toggle Alerts:** Enable/Disable specific alerts (CC, Disarm, Whispers).
* **Output Channels:** Auto-detect (Raid/Party) or force specific channels.
* **Thresholds:** Adjust the % threat level required to trigger a whisper warning.

## Slash Commands
* `/ta` - Open Settings GUI
* `/ta on` - Enable Addon
* `/ta off` - Disable Addon
* `/ta debug` - Dump current threat table (for debugging TWTv4 sync)

## Changelog
### v1.8.2
* **Improved CC Detection:** Now uses pattern matching to detect a wider range of loss-of-control effects (e.g., "Fleeing" vs "Feared").
* **New State:** Added detection for **Incapacitated** states (Polymorph, Gouge, Sap) and **Confused** states (Scatter Shot).

### v1.8
* Added support for **Paladin** and **Shaman** tanks (Turtle WoW class changes).
* Added GUI checkboxes for class-specific abilities.