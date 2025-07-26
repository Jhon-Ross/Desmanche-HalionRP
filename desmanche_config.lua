-- ================================================================
-- CONFIGURAÇÕES DO SISTEMA DE DESMANCHE
-- Arquivo: config.lua
-- ================================================================

Config = {}

-- ================================================================
-- CONFIGURAÇÕES GERAIS
-- ================================================================

-- Localização do desmanche (coordenadas)
Config.DesmancheLocation = {
    x = 2340.64,
    y = 3049.73,
    z = 48.15,
    heading = 0.0
}

-- Tempo para desmanchar um veículo (em milissegundos)
Config.DesmancheTime = 30000 -- 30 segundos

-- Distância máxima para interagir com o desmanche
Config.InteractDistance = 3.0

-- Distância para mostrar o marker
Config.MarkerDistance = 50.0

-- Tempo de cooldown entre desmanche (em segundos)
Config.CooldownTime = 300 -- 5 minutos

-- Número mínimo de policiais online para permitir desmanche
Config.MinPoliceOnline = 2

-- ================================================================
-- CONFIGURAÇÕES VISUAIS
-- ================================================================

-- Configurações do marker
Config.Marker = {
    type = 1,                    -- Tipo do marker
    size = {x = 3.0, y = 3.0, z = 1.0}, -- Tamanho
    color = {r = 255, g = 0, b = 0, a = 150}, -- Cor (RGBA)
    bob = true,                  -- Movimento de subir/descer
    face_camera = false,         -- Sempre olhar para a câmera
    rotate = true                -- Rotação
}

-- Configurações do blip
Config.Blip = {
    sprite = 446,                -- Ícone do blip
    color = 1,                   -- Cor do blip
    scale = 0.8,                 -- Tamanho do blip
    name = "Desmanche"           -- Nome do blip
}

-- ================================================================
-- VALORES DOS VEÍCULOS POR CLASSE
-- ================================================================

Config.VehicleValues = {
    -- Carros de alta performance
    ["super"] = {
        min = 12000,
        max = 20000,
        materials_multiplier = 2.0
    },
    
    ["sports"] = {
        min = 8000,
        max = 15000,
        materials_multiplier = 1.8
    },
    
    ["sportsclassics"] = {
        min = 10000,
        max = 17000,
        materials_multiplier = 1.9
    },
    
    -- Carros médios
    ["sedans"] = {
        min = 3000,
        max = 6000,
        materials_multiplier = 1.2
    },
    
    ["suvs"] = {
        min = 4000,
        max = 8