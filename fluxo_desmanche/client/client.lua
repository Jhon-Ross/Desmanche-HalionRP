local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local vSERVERd = Tunnel.getInterface("fluxo_desmanche")

local desmanchelog = "https://discord.com/api/webhooks/1363753288108867704/z2UmLkmXFr5mFmMGjAE-notio1aUsjfgO8WB3IHGQ0OFJLFBAkCTqyLVEVt1Tx7fA337"

-- =================================================================================
-- VARIAVEIS LOCAIS
-- =================================================================================
local etapa = 0
local PosVeh = {}
local PecasRemovidas = {}
local TipoVeh = ''
local qtdPecasRemovidas = 0
local PecasVeh = 0
local lepitopi = {}
local veh = nil
local idDesmanche = nil
local placa = ""
local nomeCarro = ""
local modeloCarro = ""
local cancelando = false

-- =================================================================================
-- FUNÇÕES
-- =================================================================================

function text3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
    if onScreen then
        SetTextFont(4)
        SetTextScale(0.35,0.35)
        SetTextColour(255,255,255,215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text))/370
        DrawRect(_x,_y+0.0125, 0.01+factor,0.03, 0,0,0, 100)
    end
end

function CheckVeiculo(x,y,z)
    local check = GetClosestVehicle(x,y,z,5.0,0,71)
    if DoesEntityExist(check) and GetPedInVehicleSeat(check, -1) == 0 then
        return check
    elseif DoesEntityExist(check) then
        TriggerEvent('Notify', 'negado', 'O veículo precisa estar vazio.')
        return false
    end
    return false
end

function DeletarVeiculo(entity)
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
    end
end

function CheckClasse(veh)
    local classe = GetVehicleClass(veh)
    if classe == 10 or classe >= 13 then
        return false, classe
    else
        return true, classe
    end
end

function CheckVehPermitido(nomeCarro)
    local vehs = vSERVERd.GetVehs()
    if not vehs or type(vehs) ~= 'table' or #vehs == 0 then
        return true
    end
    local upperNomeCarro = string.upper(nomeCarro)
    for _, v in pairs(vehs) do
        if type(v) == 'string' and upperNomeCarro == string.upper(v) then
            return true
        end
    end
    return true
end

function resetState()
    if DoesEntityExist(veh) then
        FreezeEntityPosition(veh, false)
        SetVehicleDoorsLocked(veh, 1)
    end
    etapa = 0
    PosVeh = {}
    PecasRemovidas = {}
    TipoVeh = ''
    qtdPecasRemovidas = 0
    PecasVeh = 0
    veh = nil
    idDesmanche = nil
    placa = ""
    nomeCarro = ""
    modeloCarro = ""
    cancelando = false
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
end

function iniciarCancelamento()
    cancelando = true
    Citizen.CreateThread(function()
        while cancelando do
            Wait(5)
            if IsControlJustPressed(0, 168) then -- F7
                TriggerEvent('Notify', 'aviso', 'DESMANCHE CANCELADO.')
                resetState()
                break
            end
        end
    end)
end

-- =================================================================================
-- THREAD PRINCIPAL
-- =================================================================================

Citizen.CreateThread(function()
    -- Espera o CFG ser carregado para evitar erros
    while cfg == nil or cfg.desmanche == nil do
        print("[Desmanche] Aguardando configuração (cfg.desmanche)...")
        Wait(2000)
    end

    print("[Desmanche] Configuração carregada. Criando laptops...")
    -- Cria os laptops uma vez
    for i, desmancheData in ipairs(cfg.desmanche) do
        if desmancheData.computador then
            local compData = desmancheData.computador
            local heading = compData[4] or 0.0
            lepitopi[i] = CreateObject(GetHashKey("prop_laptop_lester"), compData[1], compData[2], compData[3] - 0.97, true, true, true)
            SetEntityHeading(lepitopi[i], heading)
            print("[Desmanche] Laptop #"..i.." criado.")
        end
    end

    -- Loop principal
    while true do
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local sleep = 500

        if etapa == 0 then
            for k, v in pairs(cfg.desmanche) do
                local dist = Vdist(pedCoords, v.iniciar[1], v.iniciar[2], v.iniciar[3])
                if dist < 10 then
                    sleep = 5
                    DrawMarker(21, v.iniciar[1], v.iniciar[2], v.iniciar[3] - 0.5, 0, 0, 0, 0.0, 0, 0, 0.4, 0.4, 0.4, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)
                    if dist < 1.5 then
                        text3D(v.iniciar[1], v.iniciar[2], v.iniciar[3] - 0.5, '~r~[E] ~w~PARA INICIAR O DESMANCHE')
                        if IsControlJustPressed(0, 38) then
                            -- VERIFICA A PERMISSÃO APENAS UMA VEZ, AO PRESSIONAR 'E'
                            if vSERVERd.checkPerm(k) then
                                local foundVeh = CheckVeiculo(v.desmanchar[1], v.desmanchar[2], v.desmanchar[3])
                                if foundVeh then
                                    if vSERVERd.checkItem(k) then
                                        veh = foundVeh
                                        local VehPermitido, ClasseVeh = CheckClasse(veh)
                                        if VehPermitido then
                                            placa = GetVehicleNumberPlateText(veh)
                                            nomeCarro = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                                            modeloCarro = GetLabelText(nomeCarro)

                                            if CheckVehPermitido(nomeCarro) then
                                                TipoVeh = (ClasseVeh == 8) and 'moto' or 'carro'
                                                PecasVeh = (TipoVeh == 'moto') and 4 or 6

                                                -- Calcular posições
                                                PosVeh = {}
                                                if TipoVeh == 'carro' then
                                                    PosVeh['Porta_Direita'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"door_dside_f"))
                                                    PosVeh['Porta_Esquerda'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"door_pside_f"))
                                                    PosVeh['Roda_EsquerdaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lf"))
                                                    PosVeh['Roda_DireitaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rf"))
                                                    PosVeh['Roda_EsquerdaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lr"))
                                                    PosVeh['Roda_DireitaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rr"))
                                                else -- Moto
                                                    PosVeh['Roda_Frente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, "wheel_f"))
                                                    PosVeh['Roda_Tras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, "wheel_r"))
                                                    local vehCoords = GetEntityCoords(veh)
                                                    PosVeh['Guidão'] = vector3(vehCoords.x, vehCoords.y, vehCoords.z + 0.5)
                                                    PosVeh['Motor'] = vector3(vehCoords.x, vehCoords.y, vehCoords.z - 0.2)
                                                end

                                                PecasRemovidas = {}
                                                qtdPecasRemovidas = 0
                                                idDesmanche = k
                                                etapa = 1
                                                iniciarCancelamento()
                                                FreezeEntityPosition(veh, true)
                                                SetVehicleDoorsLocked(veh, 4)
                                                TriggerEvent('Notify','sucesso','Veículo identificado. Pegue as ferramentas.')
                                            else
                                                TriggerEvent('Notify', 'negado', 'Este modelo de veículo ('..modeloCarro..') não pode ser desmanchado.')
                                            end
                                        else
                                            TriggerEvent('Notify', 'negado', 'Apenas carros e motos podem ser desmanchados.')
                                        end
                                    else
                                        TriggerEvent('Notify', 'negado', 'Você não possui os itens necessários.')
                                    end
                                else
                                    TriggerEvent('Notify', 'negado', 'Nenhum veículo na área de desmanche.')
                                end
                            else
                                TriggerEvent('Notify', 'negado', 'Você não possui permissão para usar este local.')
                            end
                        end
                    end
                end
            end
        elseif etapa == 1 then -- Pegar Ferramentas
            sleep = 5
            local toolsPos = cfg.desmanche[idDesmanche].ferramentas
            local dist = Vdist(pedCoords, toolsPos[1], toolsPos[2], toolsPos[3])
            if dist < 10 then
                DrawMarker(21, toolsPos[1], toolsPos[2], toolsPos[3]-0.5, 0,0,0, 0,0,0, 0.4,0.4,0.4, 255,0,0,150, false, true, 2, false, nil, nil, false)
                if dist < 1.5 then
                    text3D(toolsPos[1], toolsPos[2], toolsPos[3]-0.5, '~r~[E] ~w~PARA PEGAR AS FERRAMENTAS')
                    if IsControlJustPressed(0,38) then
                        FreezeEntityPosition(ped, true)
                        vRP.playAnim(false, {{"amb@medic@standing@kneel@idle_a", "idle_a"}}, true)
                        TriggerEvent('progress', 5000, 'PEGANDO FERRAMENTAS')
                        Wait(5000)
                        ClearPedTasks(ped)
                        FreezeEntityPosition(ped, false)
                        etapa = 2
                        TriggerEvent('Notify', 'sucesso', 'Ferramentas pegas. Agora desmanche o veículo.')
                    end
                end
            end
        elseif etapa == 2 then -- Desmanchar Peças
            sleep = 5
            if not DoesEntityExist(veh) then
                TriggerEvent('Notify', 'negado', 'O veículo alvo desapareceu!')
                resetState()
            elseif qtdPecasRemovidas >= PecasVeh then
                etapa = 3
                TriggerEvent('Notify', 'sucesso', 'Veículo desmanchado. Vá até o computador para vender o chassi.')
            else
                local nearPart = false
                for nomePeca, posPecaCoords in pairs(PosVeh) do
                    if not PecasRemovidas[nomePeca] then
                        local x,y,z = table.unpack(posPecaCoords)
                        local dist = Vdist(pedCoords, x, y, z)
                        if dist < 5 then
                            nearPart = true
                            DrawMarker(20, x, y, z, 0, 0, 0, 0.0, 180.0, 0, 0.3, 0.3, 0.3, 255, 165, 0, 100, false, true, 2, false, nil, nil, false)
                            if dist < 1.5 then
                                text3D(x, y, z+0.3, '~r~[E] ~w~PARA DESMANCHAR '..nomePeca)
                                if IsControlJustPressed(0, 38) then
                                    FreezeEntityPosition(ped, true)
                                    vRP._playAnim(false,{task='WORLD_HUMAN_WELDING'},true)
                                    TriggerEvent('progress', 5000, 'DESMANCHANDO '..nomePeca)
                                    Wait(5000)
                                    ClearPedTasks(ped)
                                    FreezeEntityPosition(ped, false)
                                    if DoesEntityExist(veh) then
                                        PecasRemovidas[nomePeca] = true
                                        qtdPecasRemovidas = qtdPecasRemovidas + 1
                                        TriggerEvent('Notify', 'info', nomePeca .. ' removida ('..qtdPecasRemovidas..'/'..PecasVeh..')')
                                        -- Aplicar dano visual
                                        if TipoVeh == 'carro' then
                                            if nomePeca == 'Roda_EsquerdaFrente' then SetVehicleTyreBurst(veh, 0, true, 1000.0)
                                            elseif nomePeca == 'Roda_DireitaFrente' then SetVehicleTyreBurst(veh, 1, true, 1000.0)
                                            elseif nomePeca == 'Roda_EsquerdaTras' then SetVehicleTyreBurst(veh, 4, true, 1000.0)
                                            elseif nomePeca == 'Roda_DireitaTras' then SetVehicleTyreBurst(veh, 5, true, 1000.0)
                                            elseif nomePeca == 'Porta_Direita' then SetVehicleDoorBroken(veh, 1, true)
                                            elseif nomePeca == 'Porta_Esquerda' then SetVehicleDoorBroken(veh, 0, true)
                                            end
                                        else -- Moto
                                            if nomePeca == 'Roda_Frente' then SetVehicleTyreBurst(veh, 0, true, 1000.0)
                                            elseif nomePeca == 'Roda_Tras' then SetVehicleTyreBurst(veh, 4, true, 1000.0)
                                            end
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
                if not nearPart then
                    local vehCoords = GetEntityCoords(veh)
                    text3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.0, "Aproxime-se das peças para desmanchar")
                end
            end
        elseif etapa == 3 then -- Vender Chassi
            sleep = 5
            local anunciarPos = cfg.desmanche[idDesmanche].computador
            local dist = Vdist(pedCoords, anunciarPos[1], anunciarPos[2], anunciarPos[3])
            if dist < 10 then
                DrawMarker(21, anunciarPos[1], anunciarPos[2], anunciarPos[3]-0.5, 0,0,0, 0,0,0, 0.4,0.4,0.4, 0,255,0,150, false, true, 2, false, nil, nil, false)
                if dist < 1.5 then
                    text3D(anunciarPos[1], anunciarPos[2], anunciarPos[3]-0.5, '~g~[E] ~w~PARA VENDER O CHASSI')
                    if IsControlJustPressed(0,38) then
                        FreezeEntityPosition(ped, true)
                        vRP.playAnim(false, {{"amb@medic@standing@kneel@idle_a", "idle_a"}}, true)
                        TriggerEvent('progress', 5000, 'VENDENDO O CHASSI')
                        Wait(5000)
                        TriggerServerEvent("desmancheVehicles2", placa, modeloCarro, nomeCarro, desmanchelog)
                        DeletarVeiculo(veh)
                        resetState()
                        TriggerEvent("Notify","sucesso","Chassi vendido com sucesso!")
                    end
                end
            end
        end

        if etapa > 0 then
            sleep = 5
            text3D(pedCoords.x, pedCoords.y, pedCoords.z - 0.9, "Pressione [F7] para Cancelar")
        end

        Wait(sleep)
    end
end)
