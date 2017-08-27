if onServer() then
  function execute(sender, commandName, one, ...)
      local args = {...}
      local Server = Server()
      local Player = Player(sender)
      local script = Player:hasScript("mods/DirtyCargoExtender/scripts/player/DirtyCargoExtender.lua")
      if script == true then
        Player:removeScript("mods/DirtyCargoExtender/scripts/player/DirtyCargoExtender.lua")
      end
      Player:addScript("mods/DirtyCargoExtender/scripts/player/DirtyCargoExtender.lua")
      Player:sendChatMessage('DirtyCargoExtender', 0, "DirtyCargoExtender Added")

      return 0, "", ""
  end

  function getDescription()
      return "Dirty Cargo Extender, will add DCE to the player, and force initiliztion."
  end

  function getHelp()
      return "Dirty Cargo Extender, will add DCE to the player, and force initiliztion. Usage /dce"
  end
end
