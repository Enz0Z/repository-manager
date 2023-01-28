-- ███████ ████████ ████████ ███████ ███    ██ ████████ ██  ██████  ███    ██
-- ██   ██    ██       ██    ██      ████   ██    ██    ██ ██    ██ ████   ██
-- ███████    ██       ██    █████   ██ ██  ██    ██    ██ ██    ██ ██ ██  ██
-- ██   ██    ██       ██    ██      ██  ██ ██    ██    ██ ██    ██ ██  ██ ██
-- ██   ██    ██       ██    ███████ ██   ████    ██    ██  ██████  ██   ████
--
-- Remember to add these permissions to your server.cfg
-- add_ace resource.SCRIPT_NAME command.stop allow
-- add_ace resource.SCRIPT_NAME command.start allow
-- add_ace resource.SCRIPT_NAME command.restart allow
-- add_ace resource.SCRIPT_NAME command.refresh allow
-- add_ace resource.SCRIPT_NAME command.quit allow
--

Config = {}

Config.Verbose = true

Config.Artifact = {
    -- Check if the server artifact is outdated
    check = false
}

Config.Repositories = {
    --[[{
        name = 'REPO', -- (required)
        url = 'https://github.com/NAME/REPO', -- (required)
        branch = 'master', -- the branch to get the files (optional, default is "master")
        destination = '[test]', -- this is inside your resources folder (resources/[test]) (required)
        token = '', -- Github/Gitlab token (optional but recommended)
        ignore = { -- Files to ignore (optional but recommended)
            'README.md', -- ignore only the file
            '.github/' -- ignore the entire folder
        },
        replace = { -- Replace files content with other things
            ['LICENSE'] = {
                {'MIT License', 'esneciL TIM', true} -- replace "MIT License" with "esneciL TIM" in "LICENSE" file, true or false at the last argument will escape all characters automatically
            },
            ['LICENSE2'] = function()
                return 'text2' -- replace all the file with the result of this function
            end,
            ['LICENSE3'] = 'text3' -- replace all the file with this text
        },
        inject = { -- inject more files (optional)
            ['LICENSE'] = function()
                return 'text'
            end,
            ['LICENSE2'] = 'text2'
        },
        force_sha = '728a7897b897c98798792837' -- force an specific "commit" (optional)
        auto_start = false, -- start the script when updated (optional, default is false)
        restart_server = false, -- restart the server when updated (optional, default is false)
    }]]
}