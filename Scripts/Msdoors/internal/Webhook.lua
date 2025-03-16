local HttpService = game:GetService("HttpService")

if not _G.bot_config or not _G.webhook_config then
    error("As configurações globais (_G.bot_config e _G.webhook_config) não foram definidas corretamente.")
end

local config = {
    webhookUrl = _G.bot_config.webhook_link or "",
    botName = _G.bot_config.NAME or "Webhook Bot",
    botAvatar = _G.bot_config.FotoPerfil or "https://cdn.discordapp.com/embed/avatars/4.png",
    rateLimitCooldown = 2 
}

local function sendWebhook()
    local embed = {
        title = _G.webhook_config.titulo or "Mensagem do Webhook",
        description = _G.webhook_config.descricao or "Nenhuma descrição fornecida.",
        color = _G.webhook_config.cor or 16711680, -- Padrão: vermelho
        fields = _G.webhook_config.campos or {},
        footer = {
            text = _G.webhook_config.rodape or "Enviado automaticamente.",
            icon_url = config.botAvatar
        }
    }

    local payload = {
        content = _G.webhook_config.mensagem or "**Aviso Automático**: Sistema Webhook Executado.",
        username = config.botName,
        avatar_url = config.botAvatar,
        embeds = { embed }
    }

    local request = (syn and syn.request or http_request) or request or http and http.request
    if not request then
        error("Nenhuma função de solicitação HTTP compatível foi encontrada.")
    end

    local response = request({
        Url = config.webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })

    if response and response.StatusCode == 204 then
        print("[Sucesso] Webhook enviado com sucesso!")
    else
        warn("[Erro] Falha ao enviar webhook. Detalhes:", response and response.StatusMessage or "Desconhecido")
    end
end

return { sendWebhook = sendWebhook }
