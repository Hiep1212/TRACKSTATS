local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Lấy thông tin account
local accountName = "UnknownAccount"
local userId = "0"

if Players.LocalPlayer then
    accountName = Players.LocalPlayer.Name
    userId = tostring(Players.LocalPlayer.UserId)
end

-- Hàm gửi webhook an toàn
local function sendDiscordWebhook(status)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    local embedData = {
        {
            title = "🔔 ROBLOX ACCOUNT STATUS",
            color = status == "ONLINE" and 65280 or 16711680,
            fields = {
                {
                    name = "📝 Account",
                    value = accountName,
                    inline = true
                },
                {
                    name = "🆔 User ID",
                    value = userId,
                    inline = true
                },
                {
                    name = "🔄 Status",
                    value = status,
                    inline = true
                },
                {
                    name = "⏰ Time",
                    value = timestamp,
                    inline = false
                }
            },
            footer = {
                text = "Roblox Account Monitor"
            }
        }
    }
    
    local webhookData = {
        embeds = embedData,
        username = "Account Tracker",
        content = status == "ONLINE" and "🟢 **ACCOUNT ONLINE**" or "🔴 **ACCOUNT OFFLINE**"
    }
    
    -- Sử dụng RequestAsync an toàn
    local success, result = pcall(function()
        local jsonData = HttpService:JSONEncode(webhookData)
        
        return HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
    end)
    
    if success then
        print("✅ Webhook sent: " .. status)
    else
        warn("❌ Webhook error: " .. tostring(result))
    end
end

-- Gửi thông báo ONLINE
sendDiscordWebhook("ONLINE")
print("🟢 Account Online: " .. accountName)

-- Hàm xử lý khi offline
local function handleOffline()
    sendDiscordWebhook("OFFLINE")
    print("🔴 Account Offline: " .. accountName)
end

-- Method 1: Detect khi player rời game
Players.PlayerRemoving:Connect(function(player)
    if player.Name == accountName then
        handleOffline()
    end
end)

-- Method 2: Kiểm tra định kỳ
coroutine.wrap(function()
    while true do
        local playerFound = false
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name == accountName then
                playerFound = true
                break
            end
        end
        
        if not playerFound then
            handleOffline()
            break
        end
        
        wait(15) -- Kiểm tra mỗi 15 giây
    end
end)()

-- Giữ script chạy
while true do
    RunService.Heartbeat:Wait()
end
