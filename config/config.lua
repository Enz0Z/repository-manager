Config = {}

Config.AuthKey = ''
Config.Verbose = true

Config.Repositories = {
    --[[{
        name = 'fivem-github-manager', -- required
        url = 'https://github.com/Enz0Z/fivem-github-manager', -- required
        destination = '[test]', -- This is inside your resources folder (resources/[test]) -- required
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