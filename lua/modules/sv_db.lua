if (SERVER) then
    onion_db = {} onion_db.__index = {}

    onion_db.refresh_table = function()
        if (not sql.TableExists(onion.db_table_name)) then
            sql.Query("CREATE TABLE " .. onion.db_table_name .. "( id INTEGER, steamid TEXT, ip TEXT, banned INTEGER, familyshared INTEGER, PRIMARY KEY(id AUTOINCREMENT) )")
        end
    end

    onion_db.get_table = function()
        if (sql.TableExists(onion.db_table_name)) then
            return sql.Query("SELECT * FROM " .. onion.db_table_name)
        end
    end

    onion_db.clear_table = function()
        if (sql.TableExists(onion.db_table_name)) then
            sql.Query("DROP TABLE " .. onion.db_table_name)
        end

        onion_db.refresh_table()
    end

    onion_db.update_info = function(ply, steamid, banned, familyshared)
        local id
        if (ply) then id = ply:SteamID() end
        if (steamid) then id = steamid end

        if (id) then
            if (banned) then sql.Query("UPDATE "  .. onion.db_table_name .. " SET banned=" .. banned .. " WHERE steamid='" .. tostring(id) .. "';") end
            if (familyshared) then sql.Query("UPDATE "  .. onion.db_table_name .. " SET familyshared=" .. familyshared .. " WHERE steamid='" .. tostring(id) .. "';") end
        end
    end

    onion_db.check_player = function(ply, steamid)
        local id
        if (ply) then id = ply:SteamID() end
        if (steamid) then id = steamid end

        if (id) then
            return sql.Query("SELECT * FROM "  .. onion.db_table_name .. " WHERE steamid='" .. tostring(id) .. "';")
        end
    end

    onion_db.add_player = function(ply)
        local id = ply:SteamID()

        local port_ind, address
        if (ply) then port_ind = string.find(ply:IPAddress(), ":") end
        if (ply and port_ind) then address = string.sub(ply:IPAddress(), 1, port_ind - 1) end
        if (address == nil) then address = "0.0.0.0" end
        
        local familyshare = (ply:SteamID64() ~= ply:OwnerSteamID64())

        if (id) then
            if (not onion_db.check_player(ply)) then
                sql.Query("INSERT INTO "  .. onion.db_table_name .. " (steamid, ip, banned, familyshared) VALUES ('" .. tostring(id) .. "', '" .. address .. "', 0, " .. (familyshare == true and '1' or '0') .. ");")
            else
                onion_db.update_info(ply, nil, nil, (familyshare == true and '1' or '0'))
            end
        end
    end

    concommand.Add( "onion_db_checkplayer", function( ply, cmd, args, arg_str )
        if (onion.db_check_cmd and ply:GetUserGroup() == "superadmin") then
            pcall(function()
                PrintTable(onion_db.check_player(nil, arg_str))
            end)
        end
    end)

    gameevent.Listen("server_addban")
    gameevent.Listen("server_addban")
    gameevent.Listen("player_activate")

    hook.Add("server_addban", "sv_db_addban", function(args)
        local port_ind, address
        if (args.ip) then port_ind = string.find(args.ip, ":") end
        if (args.ip and port_ind) then address = string.sub(args.ip, 1, port_ind - 1) end
        if (address == nil) then address = "0.0.0.0" end

        if (onion_db.check_player(nil, args.networkid)) then
            onion_db.update_info(nil, args.networkid, "1")
        else
            sql.Query("INSERT INTO "  .. onion.db_table_name .. " (steamid, ip, banned, familyshared) VALUES ('" .. args.networkid .. "', '" .. address .. "', 1, 0);")
        end     
    end)

    hook.Add("ULibPlayerBanned", "sv_db_addban2", function(steamid)
        if (onion_db.check_player(nil, steamid)) then
            onion_db.update_info(nil, steamid, "1")
        else
            sql.Query("INSERT INTO "  .. onion.db_table_name .. " (steamid, ip, banned, familyshared) VALUES ('" .. steamid .. "', '0.0.0.0', 1, 0);")
        end   
    end)

    hook.Add("server_removeban", "sv_db_removeban", function(args)
        if (onion_db.check_player(nil, args.networkid)) then
            onion_db.update_info(nil, args.networkid, "0")
        else
            sql.Query("INSERT INTO "  .. onion.db_table_name .. " (steamid, ip, banned, familyshared) VALUES ('" .. args.networkid .. "', '0.0.0.0', 0, 0);")
        end
    end)

    hook.Add("ULibPlayerUnBanned", "sv_db_removeban2", function(steamid)
        if (onion_db.check_player(nil, steamid)) then
            onion_db.update_info(nil, steamid, "0")
        else
            sql.Query("INSERT INTO "  .. onion.db_table_name .. " (steamid, ip, banned, familyshared) VALUES ('" .. steamid .. "', '0.0.0.0', 0, 0);")
        end   
    end)

    hook.Add("player_activate", "sv_db_activate", function(args)
        local ply = Player(args.userid)
        if (ply and (not ply:IsPlayer() or ply:IsBot() or ply:SteamID() == "STEAM_0:0:0")) then return end
        
        onion_db.add_player(ply)

        local familyshare = (ply:SteamID64() ~= ply:OwnerSteamID64())

        if (familyshare) then
            local owner_check = onion_db.check_player(nil, util.SteamIDFrom64(ply:OwnerSteamID64()))
            if (owner_check and type(owner_check[1]) == "table" and owner_check[1].banned == "1") then
                onion_db.update_info(nil, ply:SteamID(), "1", "1")
                game.ConsoleCommand("ulx banid " .. ply:SteamID() .. " 0 \"" .. onion.alt_ban_reason .. "\"\n")
            end
        end

        local port_ind, address
        if (ply) then port_ind = string.find(ply:IPAddress(), ":") end
        if (ply and port_ind) then address = string.sub(ply:IPAddress(), 1, port_ind - 1) end
        if (address == nil) then address = "0.0.0.0" end
        
        if (address ~= "0.0.0.0") then
            local tbl = sql.Query("SELECT * FROM "  .. onion.db_table_name .. " WHERE ip='" .. address .. "';")

            if (tbl) then
                for i, v in pairs(tbl) do
                    if (type(v) == "table") then
                        if (v.ip == address and v.banned == "1") then
                            onion_db.update_info(nil, ply:SteamID(), "1", "1")
                            game.ConsoleCommand("ulx banid " .. ply:SteamID() .. " 0 \"" .. onion.alt_ban_reason .. "\"\n")
                        end
                    end
                end
            end
        end
    end)
end