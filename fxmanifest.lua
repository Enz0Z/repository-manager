fx_version 'cerulean'
game 'common'

lua54 'yes'
server_only 'yes'

server_scripts {
	'config.lua',
	'server/main.js',
	'server/utils.lua',
	'server/main.lua'
}

escrow_ignore {
	'server/base64.lua',
	'config.lua'
}