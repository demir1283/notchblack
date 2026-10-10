-- NotchBlack Hammerspoon entegrasyon ornegi
--
-- NotchBlack, ekran degisikliklerini zaten kendi basina dinler (monitor
-- tak/cikar, uyku/uyanma, Spaces gecisi). Bu kopru, Hammerspoon'daki kendi
-- gorev zincirine (ornegin duvar kagidi/Dock ayarlarini degistirdikten
-- sonra) NotchBlack'i de kesin sirayla dahil etmek istedigin zaman islevsel.

local NB = "local.notchblack"

-- NotchBlack'e komut gonder. Uygulama acik degilse URL scheme ile baslatir.
-- cmd: "refresh" | "on" | "off" | "toggle" | "status"
-- display: "all" | "builtin" | "<ekran UUID'si>" (hs.screen:getUUID())
local function notchblack(cmd, display)
    local running = hs.application.get("NotchBlack") ~= nil
    if running then
        hs.distributednotifications.post(NB .. ".command", nil, { cmd = cmd, display = display or "all" })
    else
        local url = string.format("notchblack://%s?display=%s", cmd, display or "all")
        hs.urlevent.openURL(url)
    end
end

-- NotchBlack bir komutu bitirince bu bildirimi yayinlar.
-- info.screens: su an seridi acik olan ekranlarin UUID listesi.
notchblackWatcher = hs.distributednotifications.new(function(name, object, info)
    print("NotchBlack didRefresh, ekranlar: " .. hs.inspect(info and info.screens))
end, NB .. ".didRefresh")
notchblackWatcher:start()

-- Ornek: ekran degisiminde once kendi ayarlarini yap, sonra NotchBlack'i yenile.
local debounceTimer
local function onScreenChange()
    if debounceTimer then debounceTimer:stop() end
    debounceTimer = hs.timer.doAfter(0.3, function()
        -- ... burada kendi Dock/duvar kagidi/vb. ayarlarin ...
        notchblack("refresh", "all")
    end)
end

screenWatcher = hs.screen.watcher.new(onScreenChange)
screenWatcher:start()

-- Belirli bir ekranda kapatmak istersen:
-- notchblack("off", hs.screen.find("Dell"):getUUID())
