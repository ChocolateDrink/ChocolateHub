local started = tick()

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Service = fetch('classes/Service')
local httpService = Service:Get('HttpService')

local games = httpService:JSONDecode(fetch('games', true))
local gameName = games[tostring(game.GameId)]

if not gameName then
	warn('[script] no script made for this game')
	return
end

-- // these games require signal fix
local shitGames = {'sls'}
_G.sigFix = table.find(shitGames, getShortName(gameName))

local library = fetch('ui')

do -- game loader
	library.title = library.title .. ' | ' .. formatStr(gameName:sub(1, 2) == '__' and gameName:sub(3) or gameName)
	library.gameName = gameName

	if gameName:sub(1, 2) == '__' then
		local func, err = loadstring(readfile('ChocolateHub/scripts/' .. gameName:sub(3) .. '.luau'))
		if not func then
			warn('[script] an error occured when loading private script:', err)
			return
		end

		func()
	else
		if isfile('ChocolateHub/scripts/' .. gameName .. '.luau') then
			local func, err = loadstring(readfile('ChocolateHub/scripts/' .. gameName .. '.luau'))
			if not func then
				warn('[script] an error occured when loading script:', err)
				return
			end

			func()
		else
			fetch('games/' .. gameName)
		end
	end
end

library:Init()

printf('[script] loaded in %.02f seconds', tick() - started)

_G.debug = false