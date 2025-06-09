-- CONFIG
Config = {
    Locale = "en",
    RespawnTime = 600,
}

Locales = {
    ["de"] = {
        ["wasted_title"] = "DU BIST GESTORBEN",
        ["respawn_text"] = "Automatischer Respawn in %s",
    },
    ["en"] = {
        ["wasted_title"] = "WASTED",
        ["respawn_text"] = "Auto respawn in %s",
    },
    ["pl"] = {
        ["wasted_title"] = "POLEGŁEŚ",
        ["respawn_text"] = "Automatyczne odrodzenie za %s",
    },
    ["fr"] = {
        ["wasted_title"] = "ÉCHOUÉ",
        ["respawn_text"] = "Réapparition automatique dans %s",
    },
    ["es"] = {
        ["wasted_title"] = "MUERTO",
        ["respawn_text"] = "Reaparición automática en %s",
    },
    ["it"] = {
        ["wasted_title"] = "MORTO",
        ["respawn_text"] = "Respawn automatico tra %s",
    },
    ["ru"] = {
        ["wasted_title"] = "УБИТ",
        ["respawn_text"] = "Автоматическое возрождение через %s",
    },
    ["tr"] = {
        ["wasted_title"] = "OLDUN",
        ["respawn_text"] = "Otomatik yeniden doğma %s içinde",
    },
    ["pt"] = {
        ["wasted_title"] = "MORREU",
        ["respawn_text"] = "Ressurgimento automático em %s",
    },
    ["nl"] = {
        ["wasted_title"] = "GEFAALD",
        ["respawn_text"] = "Automatisch respawnen in %s",
    },
    ["ja"] = {
        ["wasted_title"] = "死亡",
        ["respawn_text"] = "%s後に自動リスポーン",
    },
    ["ko"] = {
        ["wasted_title"] = "사망",
        ["respawn_text"] = "%s 후 자동 리스폰",
    },
    ["zh"] = {
        ["wasted_title"] = "死亡",
        ["respawn_text"] = "%s后自动重生",
    },
    ["ar"] = {
        ["wasted_title"] = "قتيل",
        ["respawn_text"] = "إعادة الظهور تلقائيًا خلال %s",
    },
    ["sv"] = {
        ["wasted_title"] = "DÖD",
        ["respawn_text"] = "Automatisk återuppståndelse om %s",
    }
}

function _U(key, ...)
    local lang = Config.Locale or "en"
    if Locales[lang] and Locales[lang][key] then
        return string.format(Locales[lang][key], ...)
    else
        return key
    end
end

-- DEATHSCREEN SCRIPT
local isDead = false
local scaleform = nil
local remainingTime = Config.RespawnTime
local hasRespawned = false

function updateScaleform()
    if scaleform then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        scaleform = nil
    end

    scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end

    PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    PushScaleformMovieFunctionParameterString(_U("wasted_title"))

    local min = math.floor(remainingTime / 60)
    local sec = remainingTime % 60
    local countdownText = string.format("%02d:%02d", min, sec)
    PushScaleformMovieFunctionParameterString(_U("respawn_text", countdownText))
    PopScaleformMovieFunctionVoid()
end

function showDeathScreen()
    if isDead then return end
    isDead = true
    hasRespawned = false
    remainingTime = Config.RespawnTime

    PlaySoundFrontend(-1, "Bed", "WastedSounds", true)

    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)

    updateScaleform()

    CreateThread(function()
        while isDead and remainingTime > 0 do
            Wait(1000)
            remainingTime = remainingTime - 1
            updateScaleform()
        end

        if isDead then
            autoRespawn()
        end
    end)

    CreateThread(function()
        while isDead do
            Wait(0)
            if not IsEntityDead(PlayerPedId()) then
                isDead = false
                if scaleform then
                    SetScaleformMovieAsNoLongerNeeded(scaleform)
                    scaleform = nil
                end
                break
            end
            if scaleform then
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
            end
        end
    end)
end

function autoRespawn()
    if hasRespawned then return end
    hasRespawned = true
    isDead = false

    DoScreenFadeOut(1000)
    Wait(2000)

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped, true)
    ClearPedBloodDamage(ped)

    Wait(1000)
    DoScreenFadeIn(1000)

    if scaleform then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        scaleform = nil
    end
end

AddEventHandler("baseevents:onPlayerDied", function()
    showDeathScreen()
end)

AddEventHandler("baseevents:onPlayerKilled", function()
    showDeathScreen()
end)
