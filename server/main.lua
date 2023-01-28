local update = function(repository)
	local service = GetService(repository)
	local updated = false

	if service then
		local destination = RESOURCES_PATH .. '/' .. repository.destination

		if service.last_commit ~= CACHE[repository.name] then
			print('^7' .. repository.name .. ' is outdated (^1' .. (CACHE[repository.name] or 'unknown') .. ' ^7-> ^2' .. service.last_commit .. '^7), updating...')
			print('^5> ' .. repository.url .. '/compare/' .. (CACHE[repository.name] or 'unknown') .. '..' .. service.last_commit .. '^7')
			if os.getenv('OS') == 'Windows_NT' then
				os.execute(('rmdir %s /s /q'):format(destination:gsub('/', '\\')))
			else
				os.execute(('rm -rf %s'):format(destination))
			end

			for line in io.lines(service:archive()) do
				Wait(50)
				local result = json.decode(line)
				local path = result[1]
				local write = true

				for _, name in ipairs(repository.ignore or {}) do
					if name:endsWith('/') and path:startsWith(name) then
						write = false
						break
					end
					if path == name then
						write = false
						break
					end
				end
				if write then
					local raw = BASE_64.decode(result[2])

					if repository.replace and repository.replace[path] then
						if type(repository.replace[path]) == 'table' then
							for ____, replace in ipairs(repository.replace[path]) do
								raw = string.gsub(raw, (replace[3] and string.gsub(replace[1], '([^%w])', '%%%1') or replace[1]), replace[2])
							end
						elseif type(repository.replace[path]) == 'function' then
							raw = repository.replace[path](raw)
						else
							raw = repository.replace[path]
						end
					end
					Write(destination .. '/' .. path, raw)
					if Config.Verbose then
						print('^7' .. repository.name .. ' saved ' .. path .. '.')
					end
				end
			end

			for path, action in pairs(repository.inject or {}) do
				Wait(50)
				Write(destination .. '/' .. path, (type(action) == 'function' and action() or action))
				if Config.Verbose then
					print('^7' .. repository.name .. ' injected ' .. path .. '.')
				end
			end

			print('^7' .. repository.name .. ' updated to commit ^2' .. service.last_commit .. '^7.')
			CACHE[repository.name] = service.last_commit
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
	exports[GetCurrentResourceName()]:CreatePath(GetResourcePath(GetCurrentResourceName()) .. '/.dumps/')
	if Config.Artifact.check then
		print('^7Checking artifact versions...')
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
		local current = exports[GetCurrentResourceName()]:GetBuild()
		local last = changelog.latest

		if tonumber(current) ~= tonumber(last) then
			print('^7Server artifact is outdated (^1' .. current .. ' ^7-> ^2' .. last .. '^7).')
			print('^5> ' .. changelog.latest_download .. '^7')
		end
	end
	print('^7Checking repositories...')

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
		if repository.restart_server and updated then
			print('^7' .. repository.name .. ' it is configured to restart the server when it is updated.')
			ExecuteCommand('quit "' .. repository.name .. ' it is configured to restart the server when it is updated.' .. '"')
			break
		end
	end
	print('^7All repositories up to date.')
end)

RegisterCommand('manager_refresh', function(source, args, raw)
	if args[1] then
		load(LoadResourceFile(GetCurrentResourceName(), 'config.lua'))()
		local repository = table.find(Config.Repositories, function(repository) return repository.name == args[1] end)

		if repository then
			CACHE[repository.name] = 'FORCED'

			update(repository)
		else
			print(args[1] .. ' could not be found.')
		end
	end
end, true)