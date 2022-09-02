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

CreateThread(function()
	for _, repository in ipairs(Config.Repositories) do
		if repository.auto_start == nil then
			repository.auto_start = true
		end
		if repository.auto_update == nil then
			repository.auto_update = true
		end
		local github = GitHub(repository.url)
		local updated = false

		if github and repository.auto_update then
			local commit = github:last()
			local destination = RESOURCES_PATH .. '/' .. repository.destination .. '/' .. repository.name

			if commit['sha'] ~= cache[repository.name] then
				print(repository.name .. ' is outdated (^1' .. (cache[repository.name] or 'unknown') .. ' ^7-> ^2' .. commit['sha'] .. '^7), updating...')
				if os.getenv('OS') == 'Windows_NT' then
					os.execute(('rmdir %s /s /q'):format(destination:gsub('/', '\\')))
				else
					os.execute(('rm -rf %s'):format(destination))
				end
				local files = github:tree()

				for __, file in ipairs(files) do
					local write = true

					for ___, name in ipairs(repository.ignore or {}) do
						if name:endsWith('/') and file.path:startsWith(name) then
							write = false
							break
						end
						if file.path == name then
							write = false
							break
						end
					end
					if write then
						local raw = Get(file.raw)

						if repository.replace and repository.replace[file.path] then
							if type(repository.replace[file.path]) == 'table' then
								for ____, replace in ipairs(repository.replace[file.path]) do
									raw = string.gsub(raw, replace[1], replace[2])
								end
							else
								raw = repository.replace[file.path]
							end
						end
						Write(destination .. '/' .. file.path, raw)
						if Config.Verbose then
							print(repository.name .. ' saved ' .. file.path .. ' [' .. __ .. '/' .. #files .. '].')
						end
						Wait(50)
					else
						if Config.Verbose then
							print(repository.name .. ' skipped ' .. file.path .. ' [' .. __ .. '/' .. #files .. '].')
						end
					end
				end
				print(repository.name .. ' updated to commit ^2' .. commit['sha'] .. '^7.')
				cache[repository.name] = commit['sha']
				updated = true
			else
				print(repository.name .. ' is up to date.')
			end
		end
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
end)