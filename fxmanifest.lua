fx_version 'cerulean'
game 'common'

lua54 'yes'
server_only 'yes'

server_scripts {
	'config/config.lua',
	'server/utils.lua',
	'server/main.lua'
}

escrow_ignore {
	'config/config.lua'
}