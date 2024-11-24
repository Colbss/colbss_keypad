fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

description 'DUI Based Keypad'
author 'Colbss'
version '1.0.0'

dependencies {
    'ox_lib',
}

shared_script '@ox_lib/init.lua'

client_script 'client.lua' 

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/*.*'
}
