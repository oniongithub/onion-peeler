if (SERVER) then
    -- Not very elaborate and will not work with ipv6 or many VPNs 
    vpn = {} vpn.__index = {} vpn.file, vpn.file_contents = nil, nil
    vpn.masks = {
        { 127, 255, 255, 255 }, { 63, 255, 255, 255 }, { 31, 255, 255, 255 },
	    { 15, 255, 255, 255 }, { 7, 255, 255, 255 }, { 3, 255, 255, 255 },
	    { 1, 255, 255, 255 }, { 0, 255, 255, 255 }, { 0, 127, 255, 255 },
	    { 0, 63, 255, 255 }, { 0, 31, 255, 255 }, { 0, 15, 255, 255 },
	    { 0, 7, 255, 255 }, { 0, 3, 255, 255 }, { 0, 1, 255, 255 },
	    { 0, 0, 255, 255 }, { 0, 0, 127, 255 }, { 0, 0, 63, 255 },
	    { 0, 0, 31, 255 }, { 0, 0, 15, 255 }, { 0, 0, 7, 255 },
	    { 0, 0, 3, 255 }, { 0, 0, 1, 255 }, { 0, 0, 0, 255 },
	    { 0, 0, 0, 127 }, { 0, 0, 0, 63 }, { 0, 0, 0, 31 },
	    { 0, 0, 0, 15 }, { 0, 0, 0, 7 }, { 0, 0, 0, 3 }, { 0, 0, 0, 1 }
    }

    vpn.get_mask = function(str)
        local ind = string.find(str, '/')

        if (ind) then
            local mask_number
            pcall(function()
                mask_number = tonumber(string.sub(str, ind + 1, string.len(str)))
            end)

            return mask_number
        end
    end

    vpn.check_ip = function(ip)
        ipv4 = {}
        ip:gsub('%d+', function(sub) table.insert(ipv4, tonumber(sub)) end)

        if (vpn.file_contents) then
            for i, mask in pairs(vpn.file_contents) do
                ipv4_mask = {}
                local ind = string.find(mask, "/")
                string.gsub(string.sub(mask, 1, ind), '%d+', function(sub) table.insert(ipv4_mask, tonumber(sub)) end)

                local range = vpn.get_mask(mask)
                local current_mask = vpn.masks[tonumber(range)]

                if (current_mask) then -- no goto or continue :cringe:
                    if (ipv4[1] >= ipv4_mask[1] - current_mask[1] and ipv4[1] <= ipv4_mask[1] + current_mask[1]) then
                        if (ipv4[2] >= ipv4_mask[2] - current_mask[2] and ipv4[2] <= ipv4_mask[2] + current_mask[2]) then
                            if (ipv4[3] >= ipv4_mask[3] - current_mask[3] and ipv4[3] <= ipv4_mask[3] + current_mask[3]) then
                                if (ipv4[4] >= ipv4_mask[4] - current_mask[4] and ipv4[4] <= ipv4_mask[4] + current_mask[4]) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end

        return false
    end

    vpn.split_by_char = function(str, char)
        return_table = {}

        for s in str:gmatch("[^\r\n]+") do
            table.insert(return_table, s)
        end

        return return_table
    end

    vpn.refresh_contents = function()
        if (vpn.file) then
            vpn.file_contents = vpn.file:Read()
            vpn.file_contents = vpn.split_by_char(vpn.file_contents, "\n")

            return true
        end

        return false
    end

    vpn.refresh_cache = function()
        if (not file.Exists("peeledfiles", "DATA")) then
            file.CreateDir("peeledfiles", "DATA")
        end

        http.Fetch("https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt", function(body)
            if (vpn.file) then vpn.file:Close() end
            file.Write("peeledfiles/vpn.txt", body)
        end)

        vpn.file = file.Open("peeledfiles/vpn.txt", "r", "DATA")
        vpn.refresh_contents()
    end

    concommand.Add( "onion_vpn_refresh", function( ply, cmd, args )
        if (onion.vpn_refresh_cmd and ply:GetUserGroup() == "superadmin") then
            vpn.refresh_cache()
            print("Refreshed the VPN detection list.")
        end
    end)

    concommand.Add( "onion_vpn_checkip", function( ply, cmd, args, arg_str )
        if (onion.vpn_check_cmd and ply:GetUserGroup() == "superadmin") then
            pcall(function() 
                ply:PrintMessage(HUD_PRINTCONSOLE, tostring(vpn.check_ip(arg_str))) 
            end)
        end
    end)

    gameevent.Listen("player_activate")
    hook.Add("player_activate", "sv_vpn", function(args)
        if (onion.warn_on_vpn or onion.kick_on_vpn) then
            local ply = Player(args.userid)
            if (ply and (not ply:IsPlayer() or ply:IsBot() or ply:SteamID() == "STEAM_0:0:0")) then return end
            local address = ply:IPAddress()
            if (address ~= "loopback" and address ~= "none") then
                local port_ind = string.find(address, ":")
                address = string.sub(address, 1, port_ind - 1)

                if (vpn.check_ip(address)) then
                    if (onion.warn_on_vpn) then print("Peeler - VPN Detected for " .. ply:Name() .. ", steamid: " .. ply:SteamID() .. ", ip: " .. address) end
                    if (onion.kick_on_vpn) then if (not onion.vpn_superadmin or ply:GetUserGroup() ~= "superadmin") then ply:Kick(onion.vpn_kick_msg) end end
                end
            end
        end
    end)
end