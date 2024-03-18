-- local logger = hs.logger.new('init','debug')
-- logger:d("Launching or focusing: " .. appName)

hs.hotkey.bind({"ctrl"}, "i", function()
  local appName = "Alacritty"
  local app = hs.application.get(appName)

  if app == nil then
    hs.application.launchOrFocus(appName)
  elseif app.isFrontmost and app:isFrontmost() then
    app:hide()
  else
    hs.application.launchOrFocus(appName)
  end
end)
