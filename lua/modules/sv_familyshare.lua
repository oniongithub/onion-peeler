if (SERVER) then
    gameevent.Listen("player_activate")
    hook.Add("player_activate", "sv_familyshare", function(args)
        if (onion.warn_on_familyshare or onion.kick_on_familyshare) then
            local ply = Player(args.userid)
            if (ply and (not ply:IsPlayer() or ply:IsBot() or ply:SteamID() == "STEAM_0:0:0")) then return end

            if (ply:SteamID64() ~= ply:OwnerSteamID64()) then
                if (onion.warn_on_familyshare) then print("Peeler - Family-Share Detected for " .. ply:Name() .. ", steamid: " .. ply:SteamID()) end
                if (onion.kick_on_familyshare) then if (not onion.familyshare_superadmin or ply:GetUserGroup() ~= "superadmin") then ply:Kick(onion.familyshare_kick_msg) end end
            end
        end
    end)
end