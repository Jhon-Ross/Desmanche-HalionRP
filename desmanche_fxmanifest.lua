-- ================================================================
-- FXMANIFEST - SISTEMA DE DESMANCHE VRP
-- ================================================================

fx_version 'cerulean'
game 'gta5'

author 'Seu Nome'
description 'Sistema de Desmanche de Veículos para VRP'
version '1.0.0'

-- Dependências
dependencies {
    'vrp'
}

-- Arquivos do servidor
server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua'
}

-- Arquivos do cliente
client_scripts {
    '@vrp/lib/utils.lua',
    'client.lua'
}

-- Configurações
lua54 'yes'