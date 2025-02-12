local started = tick()

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Service = fetch('classes/Service')
local httpService = Service:Get('HttpService')

local games = httpService:JSONDecode(fetch('games', true))
local gameName = games[tostring(game.GameId)]

-- // these games require signal fix
local shitGames = {'sls'}
_G.sigFix = table.find(shitGames, getShortName(gameName or 'Universal'))

local library = fetch('ui')

local formatted = formatName(gameName and (gameName:sub(1, 2) == '__' and gameName:sub(3) or gameName) or 'Universal')
local title = gameName and (gameName:len() < 5 and gameName or formatted) or formatted

library.title = library.title .. ' | ' .. title
library.gameName = gameName

if gameName then
	local tab = library:AddTab(gameName, 1)
	library.sides = {
		tab:AddColumn(),
		tab:AddColumn()
	}

	if gameName:sub(1, 2) == '__' then
		printf('fetching private script')

		local func, err = loadstring(readfile('ChocolateHub/scripts/' .. gameName:sub(3) .. '.luau'))
		if not func then
			warn('[script] an error occured when loading private script:', err)
			return
		end

		func()
	else
		if isfile('ChocolateHub/scripts/' .. gameName .. '.luau') then
			printf('fetching public script from local file')

			local func, err = loadstring(readfile('ChocolateHub/scripts/' .. gameName .. '.luau'))
			if not func then
				warn('[script] an error occured when loading script:', err)
				return
			end

			func()
		else
			printf('fetching public script from server')
			fetch('games/' .. gameName)
		end
	end
end

library.funcs = {}
fetch('games/core/Visuals')
fetch('games/core/Universal')
fetch('games/core/Aiming')

library:Init()

printf('[script] loaded in %.02f seconds', tick() - started)

_G.debug = false