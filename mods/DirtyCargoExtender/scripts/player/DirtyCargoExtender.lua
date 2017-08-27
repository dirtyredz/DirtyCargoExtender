package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";configs/?.lua"
require ("utility")
require ("goods")
require ("stationextensions")
require ("randomext")

-- this is so the script won't crash when executed in a context where there's no onServer() or onClient() function available -
-- naturally those functions should return false then
if not onServer then onServer = function() return false end end
if not onClient then onClient = function() return false end end
--This file isnt needed on the client to run.
if onClient() then return end

-- namespace DirtyCargoExtender
DirtyCargoExtender = {}

--For EXTERNAL configuration files
package.path = package.path .. ";mods/DirtyCargoExtender/config/?.lua"
DirtyCargoExtenderConfig = nil
exsist, DirtyCargoExtenderConfig = pcall(require, 'DirtyCargoExtenderConfig')

--Custom logging
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require("PrintLog")
local logLevels = require("LogLevels")

--Config Settings
DirtyCargoExtender.ModPrefix = DirtyCargoExtenderConfig.ModPrefix or "[Dirty Cargo Extender]";
DirtyCargoExtender.Version = DirtyCargoExtenderConfig.Version or "[1.0.0]";
DirtyCargoExtender.MaxGoodCount = DirtyCargoExtenderConfig.MaxGoodCount or 10000 --The max quantity of each good per station/mine

-- print command, puts mod name and version infront of each print
function DirtyCargoExtender.print(...)
  local args = table.pack(...)
  if args[1] ~= nil then
    args[1] = DirtyCargoExtender.ModPrefix .. DirtyCargoExtender.Version .. args[1]
    print(table.unpack(args))
  else
    print(DirtyCargoExtender.ModPrefix .. DirtyCargoExtender.Version .. " nil")
  end
end

if onServer() then

  function DirtyCargoExtender.initialize()
    DirtyCargoExtender.print('DirtyCargoExtender initialize',logLevels.trace)
    local Sector = Sector()
    local Player = Player()
    local playerIndex = Player.index
    local x, y = Sector:getCoordinates()

    Player:registerCallback("onSectorEntered", "DirtyCargoExtender_onSectorEntered")
    DirtyCargoExtender.DirtyCargoExtender_onSectorEntered(playerIndex,x,y)
  end

  function DirtyCargoExtender.EntityHasFactoryScript(entity,scripts)
  	for _,script in pairs(scripts) do
  		if entity:hasScript(script) then
  			return script
  		end
  	end
  	return false
  end

  function DirtyCargoExtender.DirtyCargoExtender_onSectorEntered(playerIndex, x, y)
    if Player().index ~= playerIndex then return end  --WTF, why is this function run against every player?
    DirtyCargoExtender.print('DirtyCargoExtender_onSectorEntered',logLevels.trace)

    local scripts = {
      "data/scripts/entity/merchants/factory.lua",
      "data/scripts/entity/merchants/basefactory.lua",
      "data/scripts/entity/merchants/lowfactory.lua",
      "data/scripts/entity/merchants/midfactory.lua",
      "data/scripts/entity/merchants/highfactory.lua"
    }
    local Sector = Sector()
    --Get all stations
    local stations = {Sector:getEntitiesByType(EntityType.Station)}

    for _,station in pairs(stations) do
      local faction = Faction(station.factionIndex)
      local DCE_Checked = station:getValue('DCE_Checked') or 0

      --No player stations please
      if faction == nil or not faction.isAIFaction then
        DirtyCargoExtender.print('Station is a player station or has no faction',logLevels.debug)
        continue = false
        goto continue
      end

      --Must be a factory
      if not DirtyCargoExtender.EntityHasFactoryScript(station, scripts) then
        DirtyCargoExtender.print('Station is not a producing station',logLevels.debug)
        continue = false
        goto continue
      end

      --Have we already checked this station?
      if DCE_Checked >= DirtyCargoExtender.MaxGoodCount then
        DirtyCargoExtender.print('Station has already been checked.',logLevels.debug)
        continue = false
        goto continue
      end

      --Time to process the station
      do--"${good} Mine"%_t % {good = goodName}
        DirtyCargoExtender.print('Processing Station: ' .. station.title .. " - " .. station.name,logLevels.debug)

        local SoldGoods = {station:invokeFunction(DirtyCargoExtender.EntityHasFactoryScript(station, scripts), "getSoldGoods")}
        local checkOne = table.remove(SoldGoods,1)
        local HasGoods = next(SoldGoods)

        --if station has goods to process
        if checkOne == 0 and HasGoods then
          local MinGoodsSize = 0

          --all the goods
          for _,goodName in pairs(SoldGoods) do
    				local good = goods[goodName]:good()
            local NeededGoodSpace = good["size"] * DirtyCargoExtender.MaxGoodCount
            MinGoodsSize = MinGoodsSize + NeededGoodSpace
            DirtyCargoExtender.print(goodName .. ': Space: ' .. good["size"] .. ', Needed space: ' .. NeededGoodSpace,logLevels.debug)
    			end --end SoldGoods loop
          local CurrentMaxCargoSpace = station.maxCargoSpace

          --Mark the station that weve checked it
          station:setValue('DCE_Checked',DirtyCargoExtender.MaxGoodCount)

          --Do we need to add storage?
          if station.maxCargoSpace < MinGoodsSize then
            DirtyCargoExtender.print('Station Needs its cargo extended',logLevels.info)
            local NeededCargoSpace = MinGoodsSize - station.maxCargoSpace
            DirtyCargoExtender.print('Needs Additinal Cargo Space: ' .. NeededCargoSpace,logLevels.info)

            --Calculate how many blocks to add to the station
            local StoragePerAttachment = NeededCargoSpace / 2
            local NeededBlocks = StoragePerAttachment / 468.5
            local BlocksX = ((NeededBlocks / 4) / 2) - 1
            local FinalBlocksX = math.max(1,math.ceil(BlocksX))

            --Add cargo
            addCargoStorage(station,2,FinalBlocksX,4)
            --Update crew/durability
            station.crew = station.minCrew
            station.shieldDurability = station.shieldMaxDurability
            local NewMaxCargoSpace = station.maxCargoSpace
            local DifferenceCargoSpace = NewMaxCargoSpace - CurrentMaxCargoSpace
            DirtyCargoExtender.print('Old: ' .. CurrentMaxCargoSpace .. ', New: ' .. NewMaxCargoSpace .. ', Differnce: ' .. DifferenceCargoSpace,logLevels.debug)
          end
        end
      end --end do
      DirtyCargoExtender.print('',logLevels.debug)
      ::continue::
    end --end stations loop
  end

end --end onServer()
