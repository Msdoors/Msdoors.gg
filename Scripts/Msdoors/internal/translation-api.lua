local TranslationAPI = {}
TranslationAPI.__index = TranslationAPI

_G.msdoors_language = _G.msdoors_language or "pt-br"
_G.msdoors_config = _G.msdoors_config or {}

local CONFIG = {
    GITHUB_BASE_URL = "https://raw.githubusercontent.com/msdoors-gg/msdoors-translations/main",
    GITHUB_API_URL = "https://api.github.com/repos/msdoors-gg/msdoors-translations/contents/Languages",
    LANGUAGES_FOLDER = "Languages",
    LOCAL_FILE = "language.txt",
    DEFAULT_LANGUAGE = "pt-br",
    CACHE_DURATION = 300,
    REQUEST_TIMEOUT = 10
}

local function safeHttpGet(url, timeout)
    timeout = timeout or CONFIG.REQUEST_TIMEOUT
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        return result
    else
        warn("[msdoors - translation api] Erro na requisição HTTP:", result)
        return nil
    end
end

local function parseJSON(jsonString)
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(jsonString)
    end)
    
    if success then
        return result
    else
        warn("[msdoors - translation api] Erro ao decodificar JSON:", result)
        return nil
    end
end

local function encodeJSON(table)
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONEncode(table)
    end)
    
    if success then
        return result
    else
        warn("[msdoors - translation api] Erro ao codificar JSON:", result)
        return "{}"
    end
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
    
    self.currentLanguage = _G.msdoors_language
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
    local success, savedLanguage = pcall(function()
        if isfile(CONFIG.LOCAL_FILE) then
            return readfile(CONFIG.LOCAL_FILE):gsub("%s+", "")
        else
            return nil
        end
    end)
    
    if success and savedLanguage and savedLanguage ~= "" then
        self.currentLanguage = savedLanguage
        _G.msdoors_language = savedLanguage
    else
        self.currentLanguage = CONFIG.DEFAULT_LANGUAGE
        _G.msdoors_language = CONFIG.DEFAULT_LANGUAGE
        self:saveCurrentLanguage()
    end
end

function TranslationAPI:saveCurrentLanguage()
    local success, error = pcall(function()
        writefile(CONFIG.LOCAL_FILE, self.currentLanguage)
    end)
    
    if success then
        _G.msdoors_language = self.currentLanguage
        print("[msdoors - translation api] Idioma salvo com sucesso:", self.currentLanguage)
        return true
    else
        warn("[msdoors - translation api] Erro ao salvar idioma no arquivo:", error)
        return false
    end
end

function TranslationAPI:discoverAvailableLanguages()
    if not Cache:isExpired() and #Cache.availableLanguages > 0 then
        return Cache.availableLanguages
    end
    
    local apiResponse = safeHttpGet(CONFIG.GITHUB_API_URL)
    if not apiResponse then
        warn("[msdoors - translation api] Falha ao acessar API do GitHub")
        return Cache.availableLanguages
    end
    
    local files = parseJSON(apiResponse)
    if not files then
        warn("[msdoors - translation api] Falha ao decodificar resposta da API")
        return Cache.availableLanguages
    end
    
    Cache.availableLanguages = {}
    
    for _, file in ipairs(files) do
        if file.name and file.name:match("%.json$") then
            local languageCode = file.name:gsub("%.json$", "")
            table.insert(Cache.availableLanguages, languageCode)
        end
    end
    
    Cache:updateTimestamp()
    
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
        ["pt-br"] = "Português (Brasil)",
        ["en"] = "English",
        ["es"] = "Español",
        ["fr"] = "Français",
        ["de"] = "Deutsch",
        ["it"] = "Italiano",
        ["ru"] = "Русский",
        ["ja"] = "日本語",
        ["ko"] = "한국어",
        ["zh-cn"] = "中文 (简体)",
        ["zh-tw"] = "中文 (繁體)",
        ["ar"] = "العربية",
        ["hi"] = "हिन्दी",
        ["tr"] = "Türkçe",
        ["pl"] = "Polski",
        ["nl"] = "Nederlands",
        ["sv"] = "Svenska",
        ["no"] = "Norsk",
        ["da"] = "Dansk",
        ["fi"] = "Suomi"
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
        warn("[msdoors - translation api] Falha ao carregar traduções para:", languageCode)
        return false
    end
    
    local translations = parseJSON(response)
    if not translations then
        warn("[msdoors - translation api] Falha ao decodificar traduções para:", languageCode)
        return false
    end
    
    Cache.translations[languageCode] = translations
    Cache:updateTimestamp()
    
    return true
end

function TranslationAPI:getTranslate(key, fallback)
    if not key or key == "" then
        return fallback or "MISSING_KEY"
    end
    
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
    
    print("[msdoors - translation api] Tentando alterar idioma para:", languageCode)
    
    if not self:loadLanguageTranslations(languageCode) then
        warn("[msdoors - translation api] Falha ao carregar idioma:", languageCode)
        return false
    end
    
    local oldLanguage = self.currentLanguage
    self.currentLanguage = languageCode
    _G.msdoors_language = languageCode
    
    local saveSuccess = self:saveCurrentLanguage()
    if not saveSuccess then
        warn("[msdoors - translation api] Falha ao salvar arquivo, revertendo mudança")
        self.currentLanguage = oldLanguage
        _G.msdoors_language = oldLanguage
        return false
    end
    
    print("[msdoors - translation api] Idioma alterado com sucesso de", oldLanguage, "para", languageCode)
    print("[msdoors - translation api] _G.msdoors_language agora é:", _G.msdoors_language)
    
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
        local success, error = pcall(callback, oldLanguage, newLanguage)
        if not success then
            warn("[msdoors - translation api] Erro em callback de mudança de idioma:", error)
        end
    end
end

function TranslationAPI:createLanguageDropdown(tab, options)
    options = options or {}
    
    local availableLanguages = self:getAvailableLanguages()
    local dropdownValues = {}
    local languageCodeMap = {} -- Mapa para converter nome de volta para código
    local defaultValue = nil
    
    -- Criar valores para o dropdown e mapa de conversão
    for _, code in ipairs(availableLanguages) do
        local displayName = self:getLanguageDisplayName(code)
        table.insert(dropdownValues, displayName)
        languageCodeMap[displayName] = code
        
        if code == self.currentLanguage then
            defaultValue = displayName
        end
    end
    
    -- Se não encontrou o idioma atual, usar o nome de exibição padrão
    if not defaultValue then
        defaultValue = self:getLanguageDisplayName(self.currentLanguage)
    end
    
    print("[msdoors - translation api] Criando dropdown com valores:", table.concat(dropdownValues, ", "))
    print("[msdoors - translation api] Valor padrão:", defaultValue)
    
    local dropdown = tab:AddDropdown("LanguageSelector", {
        Values = dropdownValues,
        Default = defaultValue,
        Multi = false,
        Text = self:getTranslate("LanguageSelector", "Language"),
        Tooltip = self:getTranslate("LanguageTooltip", "Select your preferred language"),
        Callback = function(selected)
            print("[msdoors - translation api] Dropdown selecionado:", selected)
            
            local languageCode = languageCodeMap[selected]
            if languageCode then
                print("[msdoors - translation api] Código do idioma:", languageCode)
                
                local success = self:setLanguage(languageCode)
                if success then
                    print("[msdoors - translation api] Mudança de idioma bem-sucedida!")
                    if options.Callback then
                        options.Callback(languageCode, selected)
                    end
                else
                    warn("[msdoors - translation api] Falha ao alterar idioma!")
                end
            else
                warn("[msdoors - translation api] Código de idioma não encontrado para:", selected)
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
        globalLanguage = _G.msdoors_language,
        availableLanguages = self:getAvailableLanguages(),
        cacheStatus = {
            lastUpdate = Cache.lastUpdate,
            isExpired = Cache:isExpired(),
            cachedLanguages = Cache.translations and table.concat(Cache.translations, ", ") or "Nenhum"
        },
        isInitialized = self.isInitialized,
        fileExists = isfile(CONFIG.LOCAL_FILE)
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
        if type(value) == "string" and value ~= "" then
            count = count + 1
        end
    end
    
    return true, string.format("Idioma %s possui %d traduções válidas", languageCode, count)
end

function TranslationAPI:forceCreateFile()
    local success = self:saveCurrentLanguage()
    return success
end

return TranslationAPI