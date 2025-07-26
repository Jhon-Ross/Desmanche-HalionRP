-- ================================================================
-- SISTEMA DE DESMANCHE DE VEÍCULOS - VRP
-- Arquivo: server.lua
-- ================================================================

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vRP_desmanche")

-- Interface para comunicação com o cliente
desmanche_client = Tunnel.getInterface("desmanche_client", "vRP_desmanche")

-- Configurações do sistema
local config = {
    -- Localização do desmanche
    location = {
        x = 2340.64,
        y = 3049.73,
        z = 48.15
    },
    
    -- Tempo para desmanchar (em milissegundos)
    desmanche_time = 30000, -- 30 segundos
    
    -- Distância máxima para interagir
    max_distance = 10.0,
    
    -- Requisitos mínimos
    min_players_online = 2, -- Mínimo de policiais online
    cooldown_time = 300, -- 5 minutos de cooldown por player
}

-- Tabela de valores dos veículos por classe
local vehicle_values = {
    -- Carros de luxo/super
    ["super"] = {min = 8000, max = 15000},
    ["sports"] = {min = 6000, max = 12000},
    ["sportsclassics"] = {min = 7000, max = 13000},
    
    -- Carros comuns
    ["sedans"] = {min = 2000, max = 4000},
    ["suvs"] = {min = 3000, max = 6000},
    ["coupes"] = {min = 2500, max = 5000},
    ["compacts"] = {min = 1500, max = 3000},
    
    -- Motos
    ["motorcycles"] = {min = 1000, max = 4000},
    
    -- Outros
    ["vans"] = {min = 2000, max = 4000},
    ["trucks"] = {min = 3000, max = 7000},
    ["default"] = {min = 1000, max = 3000}
}

-- Tabela de materiais que podem ser obtidos
local materials = {
    "metal",
    "plastic", 
    "rubber",
    "glass",
    "fabric"
}

-- Tabela de cooldowns dos jogadores
local player_cooldowns = {}

-- Tabela de jogadores desmanchando
local players_dismantling = {}

-- ================================================================
-- FUNÇÕES AUXILIARES
-- ================================================================

-- Função para verificar se o jogador está em cooldown
local function isPlayerInCooldown(user_id)
    if player_cooldowns[user_id] then
        local current_time = os.time()
        if current_time < player_cooldowns[user_id] then
            return true, player_cooldowns[user_id] - current_time
        else
            player_cooldowns[user_id] = nil
        end
    end
    return false
end

-- Função para definir cooldown do jogador
local function setPlayerCooldown(user_id)
    player_cooldowns[user_id] = os.time() + config.cooldown_time
end

-- Função para calcular valor do veículo
local function calculateVehicleValue(vehicle_class, vehicle_hash)
    local class_values = vehicle_values[vehicle_class] or vehicle_values["default"]
    local base_value = math.random(class_values.min, class_values.max)
    
    -- Adicionar variação baseada no hash do veículo
    local hash_modifier = (vehicle_hash % 1000) / 1000
    local final_value = math.floor(base_value * (0.8 + hash_modifier * 0.4))
    
    return final_value
end

-- Função para gerar materiais aleatórios
local function generateMaterials(vehicle_value)
    local generated_materials = {}
    local material_count = math.random(2, 4)
    
    for i = 1, material_count do
        local material = materials[math.random(1, #materials)]
        local amount = math.random(1, math.ceil(vehicle_value / 1000))
        
        if generated_materials[material] then
            generated_materials[material] = generated_materials[material] + amount
        else
            generated_materials[material] = amount
        end
    end
    
    return generated_materials
end

-- Função para verificar se há policiais suficientes online
local function checkPoliceCops()
    local police_count = 0
    local users = vRP.getUsers()
    
    for k, v in pairs(users) do
        if vRP.hasPermission(k, "policia.permissao") then
            police_count = police_count + 1
        end
    end
    
    return police_count >= config.min_players_online
end

-- ================================================================
-- EVENTOS DO SERVIDOR
-- ================================================================

-- Evento para verificar se o jogador pode desmanchar
RegisterServerEvent("desmanche:checkCanDismantle")
AddEventHandler("desmanche:checkCanDismantle", function()
    local source = source
    local user_id = vRP.getUserId(source)
    
    if not user_id then return end
    
    -- Verificar cooldown
    local in_cooldown, remaining_time = isPlayerInCooldown(user_id)
    if in_cooldown then
        TriggerClientEvent("desmanche:notify", source, "Você deve aguardar " .. remaining_time .. " segundos para desmanchar novamente.", "error")
        return
    end
    
    -- Verificar se há policiais suficientes
    if not checkPoliceCops() then
        TriggerClientEvent("desmanche:notify", source, "Não há policiais suficientes na cidade.", "error")
        return
    end
    
    -- Verificar se o jogador já está desmanchando
    if players_dismantling[user_id] then
        TriggerClientEvent("desmanche:notify", source, "Você já está desmanchando um veículo.", "error")
        return
    end
    
    TriggerClientEvent("desmanche:canDismantle", source)
end)

-- Evento para iniciar o desmanche
RegisterServerEvent("desmanche:startDismantle")
AddEventHandler("desmanche:startDismantle", function(vehicle_data)
    local source = source
    local user_id = vRP.getUserId(source)
    
    if not user_id or not vehicle_data then return end
    
    -- Verificações de segurança
    local in_cooldown = isPlayerInCooldown(user_id)
    if in_cooldown or players_dismantling[user_id] then
        return
    end
    
    -- Marcar jogador como desmanchando
    players_dismantling[user_id] = true
    
    -- Notificar início do desmanche
    TriggerClientEvent("desmanche:notify", source, "Iniciando desmanche do veículo...", "info")
    TriggerClientEvent("desmanche:startProgress", source, config.desmanche_time)
    
    -- Aguardar tempo de desmanche
    SetTimeout(config.desmanche_time, function()
        if players_dismantling[user_id] then
            -- Calcular recompensas
            local vehicle_value = calculateVehicleValue(vehicle_data.class, vehicle_data.hash)
            local materials_reward = generateMaterials(vehicle_value)
            
            -- Dar dinheiro ao jogador
            vRP.giveMoney(user_id, vehicle_value)
            
            -- Dar materiais ao jogador
            for material, amount in pairs(materials_reward) do
                vRP.giveInventoryItem(user_id, material, amount, true)
            end
            
            -- Notificar jogador
            local message = string.format("Desmanche concluído! Você recebeu $%d e materiais.", vehicle_value)
            TriggerClientEvent("desmanche:notify", source, message, "success")
            TriggerClientEvent("desmanche:dismantleComplete", source)
            
            -- Definir cooldown e limpar status
            setPlayerCooldown(user_id)
            players_dismantling[user_id] = nil
            
            -- Alertar polícia
            local police_users = vRP.getUsersByPermission("policia.permissao")
            for k, v in pairs(police_users) do
                local police_source = vRP.getUserSource(v)
                if police_source then
                    TriggerClientEvent("desmanche:policeAlert", police_source, config.location)
                end
            end
        end
    end)
end)

-- Evento para cancelar desmanche
RegisterServerEvent("desmanche:cancelDismantle")
AddEventHandler("desmanche:cancelDismantle", function()
    local source = source
    local user_id = vRP.getUserId(source)
    
    if user_id and players_dismantling[user_id] then
        players_dismantling[user_id] = nil
        TriggerClientEvent("desmanche:notify", source, "Desmanche cancelado.", "warning")
    end
end)

-- ================================================================
-- COMANDOS
-- ================================================================

-- Comando para teleportar ao desmanche (admin)
RegisterCommand("desmanche", function(source, args, rawCommand)
    local user_id = vRP.getUserId(source)
    
    if user_id and vRP.hasPermission(user_id, "admin.permissao") then
        vRPclient.teleport(source, config.location.x, config.location.y, config.location.z)
        TriggerClientEvent("desmanche:notify", source, "Teleportado para o desmanche.", "info")
    end
end)

-- Comando para verificar cooldown
RegisterCommand("cooldowndesmanche", function(source, args, rawCommand)
    local user_id = vRP.getUserId(source)
    
    if user_id then
        local in_cooldown, remaining_time = isPlayerInCooldown(user_id)
        if in_cooldown then
            TriggerClientEvent("desmanche:notify", source, "Cooldown: " .. remaining_time .. " segundos restantes.", "info")
        else
            TriggerClientEvent("desmanche:notify", source, "Você pode desmanchar veículos.", "success")
        end
    end
end)

-- ================================================================
-- EVENTOS DE DESCONEXÃO
-- ================================================================

AddEventHandler("vRP:playerLeave", function(user_id, source)
    if players_dismantling[user_id] then
        players_dismantling[user_id] = nil
    end
end)

print("^2[DESMANCHE]^7 Sistema de desmanche carregado com sucesso!")