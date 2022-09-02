GH_BASE_URI = 'https://api.github.com/'
REPOS_FORMAT_URI = GH_BASE_URI .. 'repos/%s/%s'
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

function string:startsWith(start)
	return self:sub(1, #start) == start
end

function string:endsWith(ending)
	return ending == "" or self:sub(-#ending) == ending
end

function table.build(iter)
	if type(iter) ~= 'function' then return nil end
	local t_k = {}
    local t_v = {}
	for i,v in iter do table.insert(t_k, i);table.insert(t_v, v) end
	return t_k, t_v
end

function Write(destination, raw, fail)
	if os.getenv('OS') == 'Windows_NT' then
		local path = destination:gsub('/', '\\')
		local directories = table.build(path:split('\\'))

		for i = 1, #directories - 1 do
			os.execute('mkdir "' .. table.concat(directories, '\\', 1, i) .. '"')
		end
		local file = io.open(path, 'wb')

		if file then
			file:write(raw)
			file:close()
		else
			print(file)
		end
	else
		local path = destination:gsub('/', '//'):gsub('////', '//')
		local directories = table.build(path:split('//'))

		for i = 1, #directories - 1 do
			os.execute('mkdir "' .. table.concat(directories, '//', 1, i) .. '"')
		end
		local file = io.open(path, 'wb')

		if file then
			file:write(raw)
			file:close()
		else
			print(file)
		end
	end
end

function Get(url)
	local p = promise:new()

	PerformHttpRequest(url, function(code, body, headers)
		if code == 200 then
			p:resolve(body)
		else
			print('GET (' .. url .. '):', code, body, headers)
			p:resolve(false, code, body, headers)
		end
	end, 'GET', '[]', headers or {
		['Content-Type'] = 'text/html;charset=UTF-8',
		['User-Agent'] = 'request',
		['Authorization'] = (Config.AuthKey ~= '' and 'token ' .. Config.AuthKey or nil)
	})
	return Citizen.Await(p)
end

function GitHub(url)
	url = url:gsub('https://', '')
	local components = table.build(url:split('/'))
	local responseRaw = Get(REPOS_FORMAT_URI:format(components[2], components[3]))

	if not responseRaw then
		return false
	end
	local response = json.decode(responseRaw)

	if response.message == 'Not Found' then
		print('Repository not found:', url)
		return false
	end

	return setmetatable(
		{
			response = response
		},
		{
			__index = {
				last = function(self, contents_url)
					local contentRaw = Get(contents_url or string.gsub(self.response.commits_url, '{/sha}', ''))
					local contents = json.decode(contentRaw)

					return contents[1]
				end,
				tree = function(self, contents_url)
					local contentRaw = Get(contents_url or string.gsub(self.response.contents_url, '{%+path}', ''))
					local contents = json.decode(contentRaw)
					local tree = {}

					for _, content in pairs(contents) do
						if content.type == 'file' then
							table.insert(tree, {
								name = content.name,
								path = content.path,
								raw = content.download_url
							})
						elseif content.type == 'dir' then
							local dir = self:tree(content.url)

							for _, v in pairs(dir) do
								table.insert(tree, v)
							end
						end
					end
					return tree
				end
			}
		}
	)
end