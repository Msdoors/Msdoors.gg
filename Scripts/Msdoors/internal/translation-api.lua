local TranslationAPI = {}
TranslationAPI.__index = TranslationAPI

shared.msdoors_language = shared.msdoors_language or "pt-br"
shared.msdoors_config = shared.msdoors_config or {}

local CONFIG = {
    GITHUB_BASE_URL = "https://raw.githubusercontent.com/msdoors-gg/msdoors-translations/main",
    GITHUB_API_URL = "https://api.github.com/repos/msdoors-gg/msdoors-translations/contents/Languages",
    LANGUAGES_FOLDER = "Languages",
    LOCAL_FILE = "msdoors/language.txt",
    DEFAULT_LANGUAGE = "pt-br",
    CACHE_DURATION = 300,
    REQUEST_TIMEOUT = 10
}

local ROBLOX_LANGUAGE_MAP = {
    ["en-us"] = "en", ["en-gb"] = "en", ["pt-br"] = "pt-br", ["es-es"] = "es",
    ["es-mx"] = "es", ["fr-fr"] = "fr", ["de-de"] = "de", ["it-it"] = "it",
    ["ru-ru"] = "ru", ["ja-jp"] = "ja", ["ko-kr"] = "ko", ["zh-cn"] = "zh-cn",
    ["zh-tw"] = "zh-tw", ["ar-sa"] = "ar", ["hi-in"] = "hi", ["tr-tr"] = "tr",
    ["pl-pl"] = "pl", ["nl-nl"] = "nl", ["sv-se"] = "sv", ["no-no"] = "no",
    ["da-dk"] = "da", ["fi-fi"] = "fi", ["th-th"] = "en", ["vi-vn"] = "en", ["id-id"] = "en",
}

local FALLBACK_LANGUAGES = {"pt-br", "en", "es", "fr", "de", "it", "ru", "ja", "ko", "zh-cn", "zh-tw", "ar", "hi", "tr", "pl", "nl", "sv", "no", "da", "fi"}

local HttpService = game:GetService("HttpService")

local function safeHttpGet(url)
    local methods = {
        function() return game:HttpGet(url) end,
        function() return HttpService:GetAsync(url) end,
        function()
            if syn and syn.request then
                local res = syn.request({ Url = url, Method = "GET" })
                if res and res.Body then return res.Body end
            end
            return nil
        end,
        function()
            if request then
                local res = request({ Url = url, Method = "GET" })
                if res and res.Body then return res.Body end
            end
            return nil
        end,
        function()
            if http and http.request then
                local res = http.request({ Url = url, Method = "GET" })
                if res and res.Body then return res.Body end
            end
            return nil
        end,
        function()
            if http_request then
                local res = http_request({ Url = url, Method = "GET" })
                if res and res.Body then return res.Body end
            end
            return nil
        end,
    }

    for i, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result and result ~= "" then
            return result
        elseif not ok then
            warn("[msdoors - translation api] Método de request " .. i .. " falhou para " .. url .. ": " .. tostring(result))
        end
    end

    warn("[msdoors - translation api] Todos os métodos de request falharam para: " .. url)
    return nil
end

local function safeIsFile(path)
    local ok, result = pcall(isfile, path)
    if not ok then
        warn("[msdoors - translation api] isfile não suportado neste executor: " .. tostring(result))
        return false
    end
    return result
end

local function safeReadFile(path)
    local ok, result = pcall(readfile, path)
    if not ok then
        warn("[msdoors - translation api] readfile não suportado neste executor: " .. tostring(result))
        return nil
    end
    return result
end

local function safeWriteFile(path, content)
    local ok, err = pcall(writefile, path, content)
    if not ok then
        warn("[msdoors - translation api] writefile não suportado neste executor: " .. tostring(err))
        return false
    end
    return true
end

local function parseJSON(jsonString)
    local success, result = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    if not success then
        warn("[msdoors - translation api] Erro ao decodificar JSON: " .. tostring(result))
        return nil
    end
    return result
end

local function encodeJSON(t)
    local success, result = pcall(function()
        return HttpService:JSONEncode(t)
    end)
    if not success then
        warn("[msdoors - translation api] Erro ao codificar JSON: " .. tostring(result))
        return "{}"
    end
    return result
end

local function detectUserLanguage()
    local success, localizationService = pcall(function()
        return game:GetService("LocalizationService")
    end)
    if success and localizationService then
        local ok, robloxLocaleId = pcall(function()
            return localizationService.RobloxLocaleId
        end)
        if ok and robloxLocaleId then
            local mapped = ROBLOX_LANGUAGE_MAP[robloxLocaleId:lower()]
            if mapped then return mapped end
        end
    end
    return CONFIG.DEFAULT_LANGUAGE
end

local Cache = {
    languages = {},
    translations = {},
    lastUpdate = 0,
    availableLanguages = {}
}

function Cache:isExpired()
    return tick() - self.lastUpdate > CONFIG.CACHE_DURATION
end

function Cache:updateTimestamp()
    self.lastUpdate = tick()
end

function Cache:clear()
    self.languages = {}
    self.translations = {}
    self.availableLanguages = {}
    self.lastUpdate = 0
end

function TranslationAPI.new()
    local self = setmetatable({}, TranslationAPI)
    self.currentLanguage = shared.msdoors_language
    self.isInitialized = false
    self.languageChangedCallbacks = {}
    self:initialize()
    return self
end

function TranslationAPI:initialize()
    self:loadSavedLanguage()
    self:discoverAvailableLanguages()
    self:loadLanguageTranslations(self.currentLanguage)
    self.isInitialized = true
end

function TranslationAPI:loadSavedLanguage()
    local savedLanguage = nil

    if safeIsFile(CONFIG.LOCAL_FILE) then
        local content = safeReadFile(CONFIG.LOCAL_FILE)
        if content and content ~= "" then
            savedLanguage = content:gsub("%s+", "")
        end
    end

    if savedLanguage and savedLanguage ~= "" then
        self.currentLanguage = savedLanguage
        shared.msdoors_language = savedLanguage
    else
        local detectedLanguage = detectUserLanguage()
        self:discoverAvailableLanguages()
        local isAvailable = false
        for _, lang in ipairs(Cache.availableLanguages) do
            if lang == detectedLanguage then isAvailable = true break end
        end
        self.currentLanguage = isAvailable and detectedLanguage or CONFIG.DEFAULT_LANGUAGE
        shared.msdoors_language = self.currentLanguage
        self:saveCurrentLanguage()
    end
end

function TranslationAPI:saveCurrentLanguage()
    local success = safeWriteFile(CONFIG.LOCAL_FILE, self.currentLanguage)
    if success then
        shared.msdoors_language = self.currentLanguage
        return true
    else
        warn("[msdoors - translation api] Falha ao salvar idioma no arquivo, continuando apenas em memória.")
        shared.msdoors_language = self.currentLanguage
        return false
    end
end

function TranslationAPI:discoverAvailableLanguages()
    if not Cache:isExpired() and #Cache.availableLanguages > 0 then
        return Cache.availableLanguages
    end

    local apiResponse = safeHttpGet(CONFIG.GITHUB_API_URL)

    if apiResponse then
        local files = parseJSON(apiResponse)
        if files and type(files) == "table" and #files > 0 then
            Cache.availableLanguages = {}
            for _, file in ipairs(files) do
                if file.name and file.name:match("%.json$") then
                    local code = file.name:gsub("%.json$", "")
                    table.insert(Cache.availableLanguages, code)
                end
            end
            if #Cache.availableLanguages > 0 then
                Cache:updateTimestamp()
                return Cache.availableLanguages
            end
        end
        warn("[msdoors - translation api] Resposta da API inválida ou vazia, usando fallback")
    else
        warn("[msdoors - translation api] Falha ao acessar API do GitHub, usando lista de fallback")
    end

    if #Cache.availableLanguages == 0 then
        Cache.availableLanguages = FALLBACK_LANGUAGES
        Cache:updateTimestamp()
    end

    return Cache.availableLanguages
end

function TranslationAPI:getAvailableLanguages()
    if #Cache.availableLanguages == 0 then
        self:discoverAvailableLanguages()
    end
    return Cache.availableLanguages
end

function TranslationAPI:getLanguageDisplayName(languageCode)
    local displayNames = {
        ["pt-br"] = "Português (Brasil)", ["en"] = "English", ["es"] = "Español",
        ["fr"] = "Français", ["de"] = "Deutsch", ["it"] = "Italiano",
        ["ru"] = "Русский", ["ja"] = "日本語", ["ko"] = "한국어",
        ["zh-cn"] = "中文 (简体)", ["zh-tw"] = "中文 (繁體)", ["ar"] = "العربية",
        ["hi"] = "हिन्दी", ["tr"] = "Türkçe", ["pl"] = "Polski",
        ["nl"] = "Nederlands", ["sv"] = "Svenska", ["no"] = "Norsk",
        ["da"] = "Dansk", ["fi"] = "Suomi", ["jp"] = "日本語"
    }
    return displayNames[languageCode] or languageCode:upper()
end

function TranslationAPI:loadLanguageTranslations(languageCode)
    if Cache.translations[languageCode] and not Cache:isExpired() then
        return true
    end

    local url = CONFIG.GITHUB_BASE_URL .. "/" .. CONFIG.LANGUAGES_FOLDER .. "/" .. languageCode .. ".json"
    local response = safeHttpGet(url)

    if not response then
        warn("[msdoors - translation api] Falha ao carregar traduções para: " .. languageCode)
        return false
    end

    local translations = parseJSON(response)
    if not translations then
        warn("[msdoors - translation api] Falha ao decodificar traduções para: " .. languageCode)
        return false
    end

    Cache.translations[languageCode] = translations
    Cache:updateTimestamp()
    return true
end

function TranslationAPI:getTranslate(key, fallback)
    if not key or key == "" then return fallback or "MISSING_KEY" end

    if not Cache.translations[self.currentLanguage] then
        if not self:loadLanguageTranslations(self.currentLanguage) then
            if self.currentLanguage ~= CONFIG.DEFAULT_LANGUAGE then
                if not self:loadLanguageTranslations(CONFIG.DEFAULT_LANGUAGE) then
                    return fallback or key
                end
                return Cache.translations[CONFIG.DEFAULT_LANGUAGE][key] or fallback or key
            end
            return fallback or key
        end
    end

    local translation = Cache.translations[self.currentLanguage][key]

    if not translation and self.currentLanguage ~= CONFIG.DEFAULT_LANGUAGE then
        if not Cache.translations[CONFIG.DEFAULT_LANGUAGE] then
            self:loadLanguageTranslations(CONFIG.DEFAULT_LANGUAGE)
        end
        if Cache.translations[CONFIG.DEFAULT_LANGUAGE] then
            translation = Cache.translations[CONFIG.DEFAULT_LANGUAGE][key]
        end
    end

    return translation or fallback or key
end

function TranslationAPI:getCurrentLanguage()
    return self.currentLanguage
end

function TranslationAPI:setLanguage(languageCode)
    if not languageCode or languageCode == "" then
        warn("[msdoors - translation api] Código de idioma inválido")
        return false
    end

    if not self:loadLanguageTranslations(languageCode) then
        warn("[msdoors - translation api] Falha ao carregar idioma: " .. languageCode)
        return false
    end

    local oldLanguage = self.currentLanguage
    self.currentLanguage = languageCode
    shared.msdoors_language = languageCode

    local saveSuccess = self:saveCurrentLanguage()
    if not saveSuccess then
        warn("[msdoors - translation api] Falha ao salvar arquivo, continuando com o idioma em memória: " .. languageCode)
    end

    self:executeLanguageChangedCallbacks(oldLanguage, languageCode)
    return true
end

function TranslationAPI:onLanguageChanged(callback)
    if type(callback) == "function" then
        table.insert(self.languageChangedCallbacks, callback)
    end
end

function TranslationAPI:executeLanguageChangedCallbacks(oldLanguage, newLanguage)
    for _, callback in ipairs(self.languageChangedCallbacks) do
        local success, err = pcall(callback, oldLanguage, newLanguage)
        if not success then
            warn("[msdoors - translation api] Erro em callback de mudança de idioma: " .. tostring(err))
        end
    end
end

function TranslationAPI:createLanguageDropdown(tab, options)
    options = options or {}

    local availableLanguages = self:getAvailableLanguages()
    local dropdownValues = {"Select language"}
    local languageCodeMap = {}

    for _, code in ipairs(availableLanguages) do
        local displayName = self:getLanguageDisplayName(code)
        table.insert(dropdownValues, displayName)
        languageCodeMap[displayName] = code
    end

    if #dropdownValues <= 1 then
        warn("[msdoors - translation api] Nenhum idioma disponível para o dropdown, tentando redescobrir...")
        Cache:clear()
        availableLanguages = self:discoverAvailableLanguages()
        dropdownValues = {"Select language"}
        languageCodeMap = {}
        for _, code in ipairs(availableLanguages) do
            local displayName = self:getLanguageDisplayName(code)
            table.insert(dropdownValues, displayName)
            languageCodeMap[displayName] = code
        end
    end

    local dropdown = tab:AddDropdown("LanguageSelector", {
        Values = dropdownValues,
        Default = "Select language",
        Multi = false,
        Text = self:getTranslate("LanguageSelector", "Language"),
        Tooltip = self:getTranslate("LanguageTooltip", "Select your preferred language"),
        Callback = function(selected)
            if selected == "Select language" then return end
            local languageCode = languageCodeMap[selected]
            if languageCode then
                local success = self:setLanguage(languageCode)
                if not success then
                    warn("[msdoors - translation api] Falha ao alterar idioma para: " .. languageCode)
                elseif options.Callback then
                    options.Callback(languageCode, selected)
                end
            else
                warn("[msdoors - translation api] Código de idioma não encontrado para: " .. tostring(selected))
            end
        end
    })

    return dropdown
end

function TranslationAPI:preloadLanguage(languageCode)
    return self:loadLanguageTranslations(languageCode)
end

function TranslationAPI:clearCache()
    Cache:clear()
end

function TranslationAPI:getSystemInfo()
    return {
        currentLanguage = self.currentLanguage,
        globalLanguage = shared.msdoors_language,
        availableLanguages = self:getAvailableLanguages(),
        cacheStatus = {
            lastUpdate = Cache.lastUpdate,
            isExpired = Cache:isExpired(),
            cachedLanguages = Cache.translations and table.concat(Cache.translations, ", ") or "Nenhum"
        },
        isInitialized = self.isInitialized,
        fileExists = safeIsFile(CONFIG.LOCAL_FILE)
    }
end

function TranslationAPI:validateTranslations(languageCode)
    languageCode = languageCode or self.currentLanguage
    if not Cache.translations[languageCode] then
        if not self:loadLanguageTranslations(languageCode) then
            return false, "Falha ao carregar traduções"
        end
    end
    local translations = Cache.translations[languageCode]
    local count = 0
    for key, value in pairs(translations) do
        if type(value) == "string" and value ~= "" then count = count + 1 end
    end
    return true, string.format("Idioma %s possui %d traduções válidas", languageCode, count)
end

function TranslationAPI:forceCreateFile()
    return self:saveCurrentLanguage()
end

return TranslationAPI
