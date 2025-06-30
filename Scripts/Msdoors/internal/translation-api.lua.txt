local TranslationAPI = {}
TranslationAPI.__index = TranslationAPI

local CONFIG = {
    GITHUB_BASE_URL = "https://raw.githubusercontent.com/msdoors-gg/msdoors-translations/main",
    GITHUB_API_URL = "https://api.github.com/repos/msdoors-gg/msdoors-translations/contents/Languages",
    LANGUAGES_FOLDER = "Languages",
    LOCAL_FOLDER = "msdoors/language",
    LOCAL_FILE = "language.txt",
    DEFAULT_LANGUAGE = "en",
    CACHE_DURATION = 300,
    REQUEST_TIMEOUT = 10
}

local function createFolder(path)
    if not isfolder(path) then
        makefolder(path)
        return true
    end
    return false
end

local function safeHttpGet(url, timeout)
    timeout = timeout or CONFIG.REQUEST_TIMEOUT
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        return result
    else
        warn("[TranslationAPI] Erro na requisição HTTP:", result)
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
        warn("[TranslationAPI] Erro ao decodificar JSON:", result)
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
        warn("[TranslationAPI] Erro ao codificar JSON:", result)
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
    
    self.currentLanguage = CONFIG.DEFAULT_LANGUAGE
    self.isInitialized = false
    self.languageChangedCallbacks = {}
    
    self:initialize()
    
    return self
end

function TranslationAPI:initialize()
    print("[TranslationAPI] Inicializando sistema de tradução...")
    
    createFolder(CONFIG.LOCAL_FOLDER)
    
    self:loadSavedLanguage()
    
    self:discoverAvailableLanguages()
    
    self:loadLanguageTranslations(self.currentLanguage)
    
    self.isInitialized = true
    print("[TranslationAPI] Sistema inicializado com sucesso! Idioma atual:", self.currentLanguage)
end

function TranslationAPI:loadSavedLanguage()
    local filePath = CONFIG.LOCAL_FOLDER .. "/" .. CONFIG.LOCAL_FILE
    
    if isfile(filePath) then
        local savedLanguage = readfile(filePath):gsub("%s+", "")
        if savedLanguage and savedLanguage ~= "" then
            self.currentLanguage = savedLanguage
            print("[TranslationAPI] Idioma carregado do arquivo local:", savedLanguage)
        end
    else
        print("[TranslationAPI] Nenhum idioma salvo encontrado, usando padrão:", CONFIG.DEFAULT_LANGUAGE)
    end
end

function TranslationAPI:saveCurrentLanguage()
    local filePath = CONFIG.LOCAL_FOLDER .. "/" .. CONFIG.LOCAL_FILE
    
    local success, error = pcall(function()
        writefile(filePath, self.currentLanguage)
    end)
    
    if success then
        print("[TranslationAPI] Idioma salvo localmente:", self.currentLanguage)
    else
        warn("[TranslationAPI] Erro ao salvar idioma:", error)
    end
end

function TranslationAPI:discoverAvailableLanguages()
    if not Cache:isExpired() and #Cache.availableLanguages > 0 then
        print("[TranslationAPI] Usando cache de idiomas disponíveis")
        return Cache.availableLanguages
    end
    
    print("[TranslationAPI] Descobrindo idiomas disponíveis...")
    
    local apiResponse = safeHttpGet(CONFIG.GITHUB_API_URL)
    if not apiResponse then
        warn("[TranslationAPI] Falha ao acessar API do GitHub, usando idiomas em cache")
        return Cache.availableLanguages
    end
    
    local files = parseJSON(apiResponse)
    if not files then
        warn("[TranslationAPI] Falha ao decodificar resposta da API do GitHub")
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
    
    print("[TranslationAPI] Idiomas descobertos:", table.concat(Cache.availableLanguages, ", "))
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
        print("[TranslationAPI] Usando traduções em cache para:", languageCode)
        return true
    end
    
    print("[TranslationAPI] Carregando traduções para:", languageCode)
    
    local url = CONFIG.GITHUB_BASE_URL .. "/" .. CONFIG.LANGUAGES_FOLDER .. "/" .. languageCode .. ".json"
    local response = safeHttpGet(url)
    
    if not response then
        warn("[TranslationAPI] Falha ao carregar traduções para:", languageCode)
        return false
    end
    
    local translations = parseJSON(response)
    if not translations then
        warn("[TranslationAPI] Falha ao decodificar traduções para:", languageCode)
        return false
    end
    
    Cache.translations[languageCode] = translations
    Cache:updateTimestamp()
    
    print("[TranslationAPI] Traduções carregadas com sucesso para:", languageCode)
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
        warn("[TranslationAPI] Código de idioma inválido")
        return false
    end
    
    if languageCode == self.currentLanguage then
        print("[TranslationAPI] Idioma já está definido como:", languageCode)
        return true
    end
    
    print("[TranslationAPI] Alterando idioma para:", languageCode)
    
    if not self:loadLanguageTranslations(languageCode) then
        warn("[TranslationAPI] Falha ao carregar idioma:", languageCode)
        return false
    end
    
    local oldLanguage = self.currentLanguage
    self.currentLanguage = languageCode
    
    self:saveCurrentLanguage()
    
    self:executeLanguageChangedCallbacks(oldLanguage, languageCode)
    
    print("[TranslationAPI] Idioma alterado com sucesso para:", languageCode)
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
            warn("[TranslationAPI] Erro em callback de mudança de idioma:", error)
        end
    end
end

function TranslationAPI:createLanguageDropdown(tab, options)
    options = options or {}
    
    local availableLanguages = self:getAvailableLanguages()
    local languageOptions = {}
    
    for _, code in ipairs(availableLanguages) do
        languageOptions[self:getLanguageDisplayName(code)] = code
    end
    
    local dropdown = tab:AddDropdown("LanguageSelector", {
        Values = languageOptions,
        Default = self:getLanguageDisplayName(self.currentLanguage),
        Multi = false,
        Text = self:getTranslate("LanguageSelector", "Language"),
        Tooltip = self:getTranslate("LanguageTooltip", "Select your preferred language"),
        Callback = function(selected)
            local languageCode = languageOptions[selected]
            if languageCode then
                self:setLanguage(languageCode)
                
                if options.Callback then
                    options.Callback(languageCode, selected)
                end
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
    print("[TranslationAPI] Cache limpo")
end

function TranslationAPI:getSystemInfo()
    return {
        currentLanguage = self.currentLanguage,
        availableLanguages = self:getAvailableLanguages(),
        cacheStatus = {
            lastUpdate = Cache.lastUpdate,
            isExpired = Cache:isExpired(),
            cachedLanguages = Cache.translations and table.concat(Cache.translations, ", ") or "Nenhum"
        },
        isInitialized = self.isInitialized
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

return TranslationAPI
