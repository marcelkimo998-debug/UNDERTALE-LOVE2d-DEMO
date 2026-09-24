local settings = {}

local FILE = "restart_fullscreen.flag"

-- Nur unmittelbar vor einem Restart aufrufen
function settings.markFullscreenForRestart(isFullscreen)
    if isFullscreen then
        love.filesystem.write(FILE, "1")
    else
        -- kein Fullscreen -> gar keine Datei schreiben/liegen lassen
        if love.filesystem.getInfo(FILE) then
            love.filesystem.remove(FILE)
        end
    end
end

-- Wird beim Start EINMAL aufgerufen und verbraucht die Markierung
function settings.consumeRestartFullscreen()
    if not love.filesystem.getInfo(FILE) then
        return false
    end

    love.filesystem.remove(FILE) -- sofort löschen, damit's beim nächsten normalen Start weg ist
    return true
end

return settings