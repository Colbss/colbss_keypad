fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

description 'Keypad Interact'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts{
    '@qbx_core/modules/lib.lua',
    'client.lua'
} 

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/*.*'
}
