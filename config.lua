Config = {}

Config.Verbose = true

Config.Artifact = {
	-- Check if the server artifact is outdated
	check = true
}

Config.Repositories = {
	--[[{
		name = 'REPO', -- required
		url = 'https://github.com/NAME/REPO', -- required
		branch = 'master', -- optional, by default is "master"
		destination = '[test]', -- This is inside your resources folder (resources/[test]) -- required
		token = '', -- optional
		ignore = { -- optional
			'README.md', -- ignore only the file
			'.github/' -- ignore the entire folder
		},
		replace = { -- optional
			['LICENSE'] = {
				{'MIT License', 'esneciL TIM'} -- replace "MIT License" with "esneciL TIM" in "LICENSE" file
			}
		},
		auto_start = false, -- optional, default: true
		auto_update = false -- optional, default: true
	}]]
}