RESOURCES_PATH = ''

CreateThread(function()
	local path = ''

	if os.getenv('OS') == 'Windows_NT' then
		path = GetResourcePath(GetCurrentResourceName()):gsub('/', '\\')
	else
		path = GetResourcePath(GetCurrentResourceName()):gsub('/', '//'):gsub('////', '//')
	end
	local startIndex, endIndex = string.find(path, 'resources')
	RESOURCES_PATH = string.sub(path, 0, endIndex)
end)

function string:split(pat)
	pat = pat or '%s+'
	local st, g = 1, self:gmatch("()("..pat..")")
	local function getter(segs, seps, sep, cap1, ...)
	st = sep and seps + #sep
	return self:sub(segs, (seps or 0) - 1), cap1 or sep, ...
	end
	return function() if st then return getter(st, g()) end end
end

function table.build(iter)
	if type(iter) ~= 'function' then return nil end
	local t_k = {}
    local t_v = {}
	for i,v in iter do table.insert(t_k, i);table.insert(t_v, v) end
	return t_k, t_v
end

function Write(destination, raw)
	if os.getenv('OS') == 'Windows_NT' then
		exports[GetCurrentResourceName()]:createPath(destination)
		local file = io.open(destination:gsub('/', '\\'), 'wb')

		if file then
			file:write(raw)
			file:close()
		end
	else
		exports[GetCurrentResourceName()]:createPath(destination)
		local file = io.open(destination:gsub('/', '//'):gsub('////', '//'), 'wb')

		if file then
			file:write(raw)
			file:close()
		end
	end
end

function Get(url, headers)
	local p = promise:new()

	PerformHttpRequest(url, function(code, body, _headers)
		if code == 200 then
			p:resolve(body)
		else
			print('^7GET (' .. url .. '):', code, body, json.encode(_headers))
			p:resolve(false)
		end
	end, 'GET', '[]', headers)
	return Citizen.Await(p)
end

function GetService(repository)
	local components = table.build(string.gsub(repository.url, 'https://', ''):split('/'))
	local last_commit = '000000000'

	if string.find(repository.url, 'github') then
		if repository.token and repository.token ~= '' then
			repository.token = 'token ' .. repository.token
		end
		local response = Get('https://api.github.com/repos/' .. components[2] .. '/' .. components[3] .. '/commits/' .. (repository.branch or 'master'), {
			['Authorization'] = repository.token
		})

		if not response then
			print('^7Could not retrieve last commit from ' .. repository.url .. ' (' .. repository.branch .. '): ' .. response .. '.')
			return false
		end
		local contents = json.decode(response)
		last_commit = contents.sha
	elseif string.find(repository.url, 'gitlab') then
		if repository.token and repository.token ~= '' then
			repository.token = 'Bearer ' .. repository.token
		end
		local response = Get('https://gitlab.com/api/v4/projects/' .. components[2] .. '%2F' .. components[3] .. '/repository/commits?ref_name=' .. (repository.branch or 'master'), {
			['Authorization'] = repository.token
		})

		if not response then
			print('^7Could not retrieve last commit from ' .. repository.url .. ' (' .. repository.branch .. '): ' .. response .. '.')
			return false
		end
		local contents = json.decode(response)
		last_commit = contents[1].id
	end

	return setmetatable(
		{
			repository = repository,
			components = components,
			last_commit = last_commit
		},
		{
			__index = {
				archive = function(self)
					local url = ''

					if string.find(self.repository.url, 'github') then
						url = 'https://github.com/' .. self.components[2] .. '/' .. self.components[3] .. '/archive/' .. self.last_commit .. '.zip'
					elseif string.find(self.repository.url, 'gitlab') then
						url = 'https://gitlab.com/api/v4/projects/' .. self.components[2] .. '%2F' .. self.components[3] .. '/repository/archive.zip?sha=' .. self.last_commit
					end
					Write(GetResourcePath(GetCurrentResourceName()) .. '/.dump', Get(url, {
						['Authorization'] = self.repository.token
					}))
					return exports[GetCurrentResourceName()]:getFilesInZip(GetResourcePath(GetCurrentResourceName()) .. '/.dump', self.repository.ignore or {})
				end
			}
		}
	)
end