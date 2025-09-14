local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Lấy thông tin account
local accountName = Players.LocalPlayer and Players.LocalPlayer.Name or "UnknownAccount"
local userId = Players.LocalPlayer and tostring(Players.LocalPlayer.UserId) or "0"

-- Biến để track trạng thái
local isOnline = true

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
    
    pcall(function()
        local jsonData = HttpService:JSONEncode(webhookData)
        HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
    end)
end

-- Gửi thông báo ONLINE ngay khi script chạy
sendDiscordWebhook("ONLINE")
print("🟢 Account Online: " .. accountName)

-- Hàm xử lý khi game sắp đóng
local function onGameClosing()
    if isOnline then
        isOnline = false
        sendDiscordWebhook("OFFLINE")
        print("🔴 Account Offline: " .. accountName)
        wait(1) -- Đợi gửi webhook trước khi tắt
    end
end

-- Sử dụng sự kiện khi game shutdown
game:BindToClose(onGameClosing)

-- Sử dụng sự kiện khi player rời game
Players.PlayerRemoving:Connect(function(player)
    if player.Name == accountName then
        onGameClosing()
    end
end)

-- Backup: Kiểm tra định kỳ nếu player còn trong game
coroutine.wrap(function()
    while isOnline do
        local playerStillHere = false
        for _, player in pairs(Players:GetPlayers()) do
            if player.Name == accountName then
                playerStillHere = true
                break
            end
        end
        
        if not playerStillHere then
            onGameClosing()
            break
        end
        
        wait(5) -- Kiểm tra mỗi 5 giây
    end
end)()

-- Giữ script chạy
while isOnline do
    RunService.Heartbeat:Wait()
end
