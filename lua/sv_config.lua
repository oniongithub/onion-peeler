if (SERVER) then
    onion = {} onion.__index = {}

    -- VPN Detection
    onion.warn_on_vpn =          true  -- Warning in the console about players who use VPNs
    onion.kick_on_vpn =          true  -- Automatically kicks players who are connected with a VPN
    onion.vpn_kick_msg =         "VPN Detected - Disable it to connect" -- The message players get when kicked
    onion.vpn_superadmin =       true  -- Won't kick superadmins who use VPNs

    -- Commands
    onion.vpn_check_cmd =   true  -- Allows superadmins to manually check a player's ip
    onion.vpn_refresh_cmd = false -- Allows superadmins to manually refresh the VPN check list

    -- Family-Sharing
    onion.warn_on_familyshare =    true  -- Warning in the console about players using family share
    onion.kick_on_familyshare =    false -- Automatically kicks players who are using family share
    onion.familyshare_kick_msg =           "Family-Shared Account Detected" -- The message players get when kicked
    onion.familyshare_superadmin = true  -- Won't kick superadmins who are using family share
end