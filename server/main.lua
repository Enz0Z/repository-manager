local cache = setmetatable({}, {
	__index = function(object, key)
		local raw = json.decode(LoadResourceFile(GetCurrentResourceName(), '.cache') or '{}')

		if not key then
			return raw
		end
		return raw[key]
	end,
	__newindex = function(object, key, value)
		local raw = json.decode(LoadResourceFile(GetCurrentResourceName(), '.cache') or '{}')
		raw[key] = value

		SaveResourceFile(GetCurrentResourceName(), '.cache', json.encode(raw), -1)
	end
})
local update = function(repository)
	local service = GetService(repository)
	local updated = false

	if service then
		local destination = RESOURCES_PATH .. '/' .. repository.destination

		if service.last_commit ~= cache[repository.name] then
			print('^7' .. repository.name .. ' is outdated (^1' .. (cache[repository.name] or 'unknown') .. ' ^7-> ^2' .. service.last_commit .. '^7), updating...')
			print('^5> ' .. repository.url .. '/compare/' .. (cache[repository.name] or 'unknown') .. '..' .. service.last_commit .. '^7')
			if os.getenv('OS') == 'Windows_NT' then
				os.execute(('rmdir %s /s /q'):format(destination:gsub('/', '\\')))
			else
				os.execute(('rm -rf %s'):format(destination))
			end
			local files = service:archive()

			for __, file in ipairs(files) do
				file.raw = base64.decode(file.raw)

				if repository.replace and repository.replace[file.path] then
					if type(repository.replace[file.path]) == 'table' then
						for ____, replace in ipairs(repository.replace[file.path]) do
							file.raw = string.gsub(file.raw, (replace[3] and string.gsub(replace[1], '([^%w])', '%%%1') or replace[1]), replace[2])
						end
					elseif type(repository.replace[file.path]) == 'function' then
						file.raw = repository.replace[file.path](file.raw)
					else
						file.raw = repository.replace[file.path]
					end
				end
				Write(destination .. '/' .. file.path, file.raw)
				if Config.Verbose then
					print('^7' .. repository.name .. ' saved ' .. file.path .. ' [' .. __ .. '/' .. #files .. '].')
				end
				Wait(50)
			end
			local count = 1

			for path, action in pairs(repository.inject or {}) do
				Write(destination .. '/' .. path, (type(action) == 'function' and action() or action))
				if Config.Verbose then
					print('^7' .. repository.name .. ' injected ' .. path .. ' [' .. count .. '/' .. table.size(repository.inject) .. '].')
				end
				count = count + 1
			end
			print('^7' .. repository.name .. ' updated to commit ^2' .. service.last_commit .. '^7.')
			cache[repository.name] = service.last_commit
			updated = true
		else
			if Config.Verbose then
				print('^7' .. repository.name .. ' is up to date.')
			end
		end
	end
	return updated
end

CreateThread(function()
	if Config.Artifact.check then
		local raw = Get('https://changelogs-live.fivem.net/api/changelog/versions/' .. (os.getenv('OS') == 'Windows_NT' and 'windows' or 'linux') .. '/server')

		if not raw then
			print('^7Cannot retrieve artifact version from fivem endpoint.')
			return
		end
		local changelog = json.decode(raw)

		if not changelog then
			print('^7Cannot retrieve artifact version from fivem endpoint.')
			return
		end
		local current = exports[GetCurrentResourceName()]:getBuild()
		local last = changelog.latest

		if tonumber(current) ~= tonumber(last) then
			print('^7Server artifact is outdated (^1' .. current .. ' ^7-> ^2' .. last .. '^7).')
			print('^5> ' .. changelog.latest_download .. '^7')
		end
	end
	for _, repository in ipairs(Config.Repositories) do
		if repository.auto_start == nil then
			repository.auto_start = true
		end
		local updated = update(repository)

		if repository.auto_start then
			if updated then
				ExecuteCommand('refresh')
			end
			if GetResourceState(repository.name) == 'started' and updated then
				ExecuteCommand('restart ' .. repository.name)
			else
				ExecuteCommand('start ' .. repository.name)
			end
		end
	end
	print('^7All repositories up to date.')
end)

RegisterCommand('manager_refresh', function(source, args, raw)
	if args[1] then
		load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
		local repository = table.find(Config.Repositories, function(repository) return repository.name == args[1] end)

		if repository then
			cache[repository.name] = 'FORCED'

			update(repository, true)
		else
			print(args[1] .. ' could not be found.')
		end
	end
end, true)