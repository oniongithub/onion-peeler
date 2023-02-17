# Onion Peeler
## Alt/VPN/Family Share detection

## Features
* **Alt Detection** - Detect alts from server-side.
* **Family-Share Detection** - Detect family shared users and check their main account for bans.
* **Banned IP Detection** - Detect an alt using the IP of a banned user.
* **VPN Detection** - Warn and kick if a VPN is detected (detection is free and somewhat spotty).
* **Configuration** - Customize your detection messages, commands, and more.
* **ULX Integration** - Runs off of ULX, required unless you want to convert it to another system.

## Commands
* **onion_db_checkplayer** - Print a player's database entry using their SteamID to the server console.
* **onion_vpn_refresh** - Refresh and redownload the latest VPN entries.
* **onion_vpn_checkip** - Check an IP to see if it's a VPN.

## Configuration
* **lua/sv_config.lua** - Configuration file path.


## Credits
* **X4BNet** - List of common VPN provider's IP ranges.
