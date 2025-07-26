-- ================================================================
-- SISTEMA DE DESMANCHE DE VEÍCULOS - VRP (Cliente)
-- Arquivo: client.lua
-- ================================================================

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")

-- Interface do servidor
desmanche_server = Tunnel.getInterface("desmanche_server", "desmanche_client")

-- Configurações do cliente
local config = {
    -- Localização do desmanche
    location = {
        x = 2340.64,
        y = 3049.73,
        z = 48.15
    },
    
    -- Distância para mostrar marker
    marker_distance = 50.0,
    
    -- Distância para interagir
    interact_distance = 3.0,
    
    -- Configurações do marker
    marker = {
        type = 1,
        size = {x = 3.0, y = 3.0, z = 1.0},
        color = {r = 255, g = 0, b = 0, a = 150},
        bob = true,
        face_camera = false,
        rotate = true
    },
    
    -- Configurações do blip
    blip = {
        sprite = 446,
        color = 1,
        scale = 0.8,
        name = "Desmanche"
    }
}

-- Variáveis do sistema
local is_dismantling = false
local current_vehicle = nil
local progress_bar_active = false
local blip_created = false

-- ================================================================
-- FUNÇÕES AUXILIARES
-- ================================================================

-- Função para criar notificação
local function showNotification(message, type)
    if type == "error" then
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~" .. message)
        DrawNotification(false, false)
    elseif type == "success" then
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~g~" .. message)
        DrawNotification(false, false)
    elseif type == "warning" then
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~y~" .. message)
        DrawNotification(false, false)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~b~" .. message)
        DrawNotification(false, false)
    end
end

-- Função para desenhar texto 3D
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Função para obter informações do veículo
local function getVehicleInfo(vehicle)
    if not DoesEntityExist(vehicle) then
        return nil
    end
    
    local model = GetEntityModel(vehicle)
    local class = GetVehicleClass(vehicle)
    local class_name = GetVehicleClassFromName(model)
    
    local class_names = {
        [0] = "compacts",
        [1] = "sedans",
        [2] = "suvs",
        [3] = "coupes",
        [4] = "muscle",
        [5] = "sportsclassics",
        [6] = "sports",
        [7] = "super",
        [8] = "motorcycles",
        [9] = "offroad",
        [10] = "industrial",
        [11] = "utility",
        [12] = "vans",
        [13] = "cycles",
        [14] = "boats",
        [15] = "helicopters",
        [16] = "planes",
        [17] = "service",
        [18] = "emergency",
        [19] = "military",
        [20] = "commercial",
        [21] = "trains",
        [22] = "trucks"
    }
    
    return {
        model = model,
        hash = model,
        class = class_names[class] or "default",
        entity = vehicle
    }
end

-- Função para verificar se o veículo pode ser desmanchado
local function canDismantleVehicle(vehicle)
    if not DoesEntityExist(vehicle) then
        return false, "Veículo não encontrado"
    end
    
    -- Verificar se é um veículo válido
    if not IsEntityAVehicle(vehicle) then
        return false, "Não é um veículo válido"
    end
    
    -- Verificar se não é um veículo de emergência
    local vehicle_class = GetVehicleClass(vehicle)
    if vehicle_class == 18 or vehicle_class == 19 then -- Emergency, Military
        return false, "Não é possível desmanchar veículos de emergência"
    end
    
    -- Verificar se não há jogadores no veículo
    local max_passengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for i = -1, max_passengers do
        if not IsVehicleSeatFree(vehicle, i) then
            return false, "Há pessoas no veículo"
        end
    end
    
    -- Verificar se o veículo não está muito danificado
    local engine_health = GetVehicleEngineHealth(vehicle)
    if engine_health < 100 then
        return false, "Veículo muito danificado para desmanche"
    end
    
    return true, "OK"
end

-- Função para criar o blip
local function createBlip()
    if not blip_created then
        local blip = AddBlipForCoord(config.location.x, config.location.y, config.location.z)
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, config.blip.scale)
        SetBlipColour(blip, config.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(config.blip.name)
        EndTextCommandSetBlipName(blip)
        blip_created = true
    end
end

-- ================================================================
-- THREAD PRINCIPAL
-- ================================================================

Citizen.CreateThread(function()
    -- Criar blip
    createBlip()
    
    while true do
        Citizen.Wait(0)
        
        local player_ped = PlayerPedId()
        local player_coords = GetEntityCoords(player_ped)
        local distance = GetDistanceBetweenCoords(player_coords, config.location.x, config.location.y, config.location.z, true)
        
        -- Mostrar marker se estiver próximo
        if distance <= config.marker_distance then
            DrawMarker(
                config.marker.type,
                config.location.x, config.location.y, config.location.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                config.marker.size.x, config.marker.size.y, config.marker.size.z,
                config.marker.color.r, config.marker.color.g, config.marker.color.b, config.marker.color.a,
                config.marker.bob, config.marker.face_camera, 2, config.marker.rotate, nil, nil, false
            )
            
            -- Mostrar texto de interação se estiver muito próximo
            if distance <= config.interact_distance then
                if not is_dismantling then
                    DrawText3D(config.location.x, config.location.y, config.location.z + 1.5, 
                              "Pressione ~g~E~w~ para desmanchar veículo")
                    
                    -- Verificar input
                    if IsControlJustPressed(0, 38) then -- E key
                        -- Verificar se está em um veículo
                        if IsPedInAnyVehicle(player_ped, false) then
                            local vehicle = GetVehiclePedIsIn(player_ped, false)
                            local can_dismantle, reason = canDismantleVehicle(vehicle)
                            
                            if can_dismantle then
                                current_vehicle = getVehicleInfo(vehicle)
                                if current_vehicle then
                                    TriggerServerEvent("desmanche:checkCanDismantle")
                                end
                            else
                                showNotification(reason, "error")
                            end
                        else
                            showNotification("Você precisa estar em um veículo para desmanchá-lo", "error")
                        end
                    end
                else
                    DrawText3D(config.location.x, config.location.y, config.location.z + 1.5, 
                              "Desmanchando veículo... Pressione ~r~X~w~ para cancelar")
                    
                    -- Verificar cancelamento
                    if IsControlJustPressed(0, 73) then -- X key
                        TriggerServerEvent("desmanche:cancelDismantle")
                    end
                end
            end
        else
            Citizen.Wait(1000) -- Aumentar delay quando longe
        end
    end
end)

-- ================================================================
-- BARRA DE PROGRESSO
-- ================================================================

local function drawProgressBar(progress, text)
    local res_x, res_y = GetActiveScreenResolution()
    local x = res_x * 0.5
    local y = res_y * 0.85
    
    -- Fundo da barra
    DrawRect(x, y, 0.25, 0.05, 0, 0, 0, 150)
    
    -- Barra de progresso
    local bar_width = 0.23 * (progress / 100)
    DrawRect(x - 0.115 + (bar_width / 2), y, bar_width, 0.03, 0, 255, 0, 200)
    
    -- Texto
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.0, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y - 0.025)
end

-- Thread da barra de progresso
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if progress_bar_active then
            local progress = ((GetGameTimer() - progress_start_time) / progress_duration) * 100
            
            if progress >= 100 then
                progress = 100
                progress_bar_active = false
            end
            
            drawProgressBar(progress, "Desmanchando veículo...")
            
            -- Verificar se o jogador saiu do veículo
            local player_ped = PlayerPedId()
            if not IsPedInAnyVehicle(player_ped, false) and progress < 100 then
                progress_bar_active = false
                TriggerServerEvent("desmanche:cancelDismantle")
                showNotification("Desmanche cancelado - você saiu do veículo", "warning")
            end
        else
            Citizen.Wait(100)
        end
    end
end)

-- ================================================================
-- EVENTOS DO SERVIDOR
-- ================================================================

-- Evento de notificação
RegisterNetEvent("desmanche:notify")
AddEventHandler("desmanche:notify", function(message, type)
    showNotification(message, type)
end)

-- Evento quando pode desmanchar
RegisterNetEvent("desmanche:canDismantle")
AddEventHandler("desmanche:canDismantle", function()
    if current_vehicle and DoesEntityExist(current_vehicle.entity) then
        TriggerServerEvent("desmanche:startDismantle", current_vehicle)
    end
end)

-- Evento para iniciar barra de progresso
RegisterNetEvent("desmanche:startProgress")
AddEventHandler("desmanche:startProgress", function(duration)
    is_dismantling = true
    progress_bar_active = true
    progress_start_time = GetGameTimer()
    progress_duration = duration
    
    -- Impedir que o jogador saia do veículo
    local player_ped = PlayerPedId()
    if IsPedInAnyVehicle(player_ped, false) then
        local vehicle = GetVehiclePedIsIn(player_ped, false)
        SetVehicleDoorsLocked(vehicle, 4) -- Trancar portas
    end
end)

-- Evento quando desmanche é completo
RegisterNetEvent("desmanche:dismantleComplete")
AddEventHandler("desmanche:dismantleComplete", function()
    is_dismantling = false
    progress_bar_active = false
    
    -- Deletar o veículo
    if current_vehicle and DoesEntityExist(current_vehicle.entity) then
        DeleteVehicle(current_vehicle.entity)
    end
    
    current_vehicle = nil
end)

-- Evento de alerta para polícia
RegisterNetEvent("desmanche:policeAlert")
AddEventHandler("desmanche:policeAlert", function(location)
    -- Criar blip temporário para polícia
    local alert_blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(alert_blip, 161)
    SetBlipScale(alert_blip, 1.0)
    SetBlipColour(alert_blip, 1)
    SetBlipFlashes(alert_blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Desmanche em Andamento")
    EndTextCommandSetBlipName(alert_blip)
    
    -- Remover blip após 2 minutos
    SetTimeout(120000, function()
        RemoveBlip(alert_blip)
    end)
    
    showNotification("ALERTA: Atividade suspeita detectada no desmanche!", "error")
end)

print("^2[DESMANCHE]^7 Cliente do sistema de desmanche carregado!")