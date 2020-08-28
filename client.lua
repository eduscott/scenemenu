--AddSpeedZoneForCoord(float x, float y, float z, float radius, float speed, BOOL p5);

local speedZoneActive = false
local blip
local speedZone
local speedzones = {}

_menuPool = NativeUI.CreatePool()
trafficmenu = NativeUI.CreateMenu("Scene Menu", "~b~(By Kye Jones)")
_menuPool:Add(trafficmenu)

function ShowNotification(text)
  SetNotificationTextEntry("STRING")
  AddTextComponentString(text)
  DrawNotification(false, false)
end

function ObjectsSubMenu(menu)
  local submenu = _menuPool:AddSubMenu(menu, "Menu de Objetos")

  local objects = { }

  for k,v in pairs(Config.Objects) do 
    for k,v in pairs(v) do 
        if k == "Displayname" then
          table.insert(objects, v)
        end
    end
  end

  local objectlist = NativeUI.CreateListItem("Objeto Colocado", objects, 1, "Pressione enter para colocar o objeto selecionado.")
  local deletebutton = NativeUI.CreateItem("Remover", "Remover o objeto mais próximo.")


  submenu:AddItem(deletebutton)
  deletebutton.Activated = function(sender, item, index)
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))

    for k,v in pairs(Config.Objects) do 
      
      local hash = GetHashKey(v.Object)
      if DoesObjectOfTypeExistAtCoords(x, y, z, 0.9, hash, true) then
        local object = GetClosestObjectOfType(x, y, z, 0.9, hash, false, false, false)
        DeleteObject(object)
      end

    end

  end


  submenu:AddItem(objectlist)
  objectlist.OnListSelected = function(sender, item, index)
    local Player = GetPlayerPed(-1)
    local heading = GetEntityHeading(Player)
    local x, y, z = table.unpack(GetEntityCoords(Player, true))
    local object = item:IndexToItem(index)

    for k,v in pairs(Config.Objects) do 
        if v.Displayname == object then
          print(v.Object)
          local objectname = v.Object
          RequestModel(objectname)
          while not HasModelLoaded(objectname) do
            Citizen.Wait(1)
          end
          local obj = CreateObject(GetHashKey(objectname), x, y, z, true, false);
          PlaceObjectOnGroundProperly(obj)
          SetEntityHeading(obj, heading)
          FreezeEntityPosition(obj, true)
        end
    end

  end
  

end

function SpeedZoneSubMenu(menu)
  local submenu = _menuPool:AddSubMenu(menu, "Zona de Redução de Velocidade")
  local radiusnum = { }

  local speednum = { }

  for k,v in pairs(Config.SpeedZone.Radius) do 
    table.insert(radiusnum, v)
  end

  for k,v in pairs(Config.SpeedZone.Speed) do 
    table.insert(speednum, v)
  end

  local zonecreate = NativeUI.CreateItem("Criar Zona", "Cria uma zona com o raio e a velocidade especificada.")
  local zoneradius = NativeUI.CreateSliderItem("Raio", radiusnum, 1, false)
  local zonespeed = NativeUI.CreateListItem("Velocidade", speednum, 1)
  local zonedelete = NativeUI.CreateItem("Remover Zona", "Remover a zona criada.")

  submenu:AddItem(zoneradius)
  submenu:AddItem(zonespeed)
  submenu:AddItem(zonecreate)
  submenu:AddItem(zonedelete)

  zonecreate:SetRightBadge(BadgeStyle.Tick)

  submenu.OnSliderChange = function(sender, item, index)
        radius = item:IndexToItem(index)
        ShowNotification("Alterando raio para ~r~" .. radius)
  end

  submenu.OnListChange = function(sender, item, index)
    speed = item:IndexToItem(index)
    ShowNotification("Alterando velocidade para ~r~" .. speed)
  end

  zonedelete.Activated = function(sender, item, index)
      TriggerServerEvent('Desativar')
      ShowNotification("Disativar zonas.")
  end

  zonecreate.Activated = function(sender, item, index)

      if not speed then
        speed = 0
      end

      if not radius then
        ShowNotification("~r~Por favor troque o raio!")
        return
      end

          speedZoneActive = true
          ShowNotification("Zona de Velocidade criada.")
          local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))
          radius = radius + 0.0
          speed = speed + 0.0
      
          local streetName, crossing = GetStreetNameAtCoord(x, y, z)
          streetName = GetStreetNameFromHashKey(streetName)

          local message = "^* ^1Anúncio de Tráfego: ^r^*^7A Polícia ordenou que o tráfego na ^2" .. streetName .. " ^7deverá ser de ^2" .. speed .. "km/h ^7devido a um incidente." 
          TriggerServerEvent('ZoneActivated', message, speed, radius, x, y, z)
  end

end

local GlobalData = ""

RegisterNetEvent('ReturnData')
AddEventHandler('ReturnData', function(data)

  GlobalData = data

end)

ObjectsSubMenu(trafficmenu)
SpeedZoneSubMenu(trafficmenu)

if Config.ActivationMode == "Key" then
Citizen.CreateThread(function()
  while true do
      Citizen.Wait(0)
      _menuPool:ProcessMenus()
      if IsControlJustPressed(0, Config.ActivationKey) and GetLastInputMethod( 0 ) then

        if Config.UsageMode == "Ped" then

          pmodel = GetEntityModel(PlayerPedId())
          if inArrayPed(pmodel, Config.WhitelistedPeds) then
            trafficmenu:Visible(not trafficmenu:Visible())
          else 
            print("You are not in the correct ped to use this menu.")
          end

        elseif Config.UsageMode == "IP" then

          TriggerServerEvent("GetData", "IP")
          Wait(100)
          if inArray(GlobalData, Config.WhitelistedIPs) then
            trafficmenu:Visible(not trafficmenu:Visible())
          else 
            print("Você não tem autorização para usar isto.")
          end

        elseif Config.UsageMode == "Steam" then

          TriggerServerEvent("GetData", "Steam")
          Wait(100)
          if inArraySteam(GlobalData, Config.WhitelistedSteam) then
            trafficmenu:Visible(not trafficmenu:Visible())
          else 
            print("Você não tem autorização para usar isto.")
          end

        elseif Config.UsageMode == "Everyone" then
            trafficmenu:Visible(not trafficmenu:Visible())
        end

      end
  end
end)

elseif Config.ActivationMode == "Command" then

Citizen.CreateThread(function()
  while true do
      Citizen.Wait(0)
      _menuPool:ProcessMenus()
  end
end)

RegisterCommand(Config.ActivationCommand, function(source, args, rawCommand)
    if Config.UsageMode == "Ped" then

    pmodel = GetEntityModel(PlayerPedId())
    if inArrayPed(pmodel, Config.WhitelistedPeds) then
      trafficmenu:Visible(not trafficmenu:Visible())
    else 
      print("You are not in the correct ped to use this menu.")
    end

  elseif Config.UsageMode == "IP" then

    TriggerServerEvent("GetData", "IP")
    Wait(100)
    if inArray(GlobalData, Config.WhitelistedIPs) then
      trafficmenu:Visible(not trafficmenu:Visible())
    else 
      print("You are not whitelisted to use this.")
    end

  elseif Config.UsageMode == "Steam" then

    TriggerServerEvent("GetData", "Steam")
    Wait(100)
    if inArraySteam(GlobalData, Config.WhitelistedSteam) then
      trafficmenu:Visible(not trafficmenu:Visible())
    else 
      print("You are not whitelisted to use this.")
    end

  elseif Config.UsageMode == "Everyone" then
      trafficmenu:Visible(not trafficmenu:Visible())
  end
end, false)

end


RegisterNetEvent('Zone')
AddEventHandler('Zone', function(speed, radius, x, y, z)

  blip = AddBlipForRadius(x, y, z, radius)
      SetBlipColour(blip,idcolor)
      SetBlipAlpha(blip,80)
      SetBlipSprite(blip,9)
  speedZone = AddSpeedZoneForCoord(x, y, z, radius, speed, false)

  table.insert(speedzones, {x, y, z, speedZone, blip})

end)

RegisterNetEvent('RemoveBlip')
AddEventHandler('RemoveBlip', function()

    if speedzones == nil then
      return
    end
    local playerPed = GetPlayerPed(-1)
    local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
    local closestSpeedZone = 0
    local closestDistance = 1000
    for i = 1, #speedzones, 1 do
        local distance = Vdist(speedzones[i][1], speedzones[i][2], speedzones[i][3], x, y, z)
        if distance < closestDistance then
            closestDistance = distance
            closestSpeedZone = i
        end
    end
    RemoveSpeedZone(speedzones[closestSpeedZone][4])
    RemoveBlip(speedzones[closestSpeedZone][5])
    table.remove(speedzones, closestSpeedZone)

end)

function inArrayPed(value, array)
  for _,v in pairs(array) do
    if GetHashKey(v) == value then
      return true
    end
  end
  return false
end

function inArray(value, array)
  for _,v in pairs(array) do
    if v == value then
      return true
    end
  end
  return false
end

  -- Returns TRUE if value is in array, FALSE otherwise
  function inArraySteam(value, array)
    for _,v in pairs(array) do
      v = getSteamId(v)
      if v == value then
        return true
      end
    end
    return false
  end

-- Returns TRUE if steamId start with "steam:", FALSE otherwise
function isNativeSteamId(steamId)
  if string.sub(steamId, 0, 6) == "steam:" then
    return true
  end
  return false
end

function getSteamId(steamId)
  if not isNativeSteamId(steamId) then -- FiveM SteamID conversion
    steamId = "steam:" .. string.format("%x", tonumber(steamId))
  else
    steamId = string.lower(steamId) -- Lowercase conversion
  end
  return steamId
end

_menuPool:MouseControlsEnabled(false)
_menuPool:ControlDisablingEnabled(false)
