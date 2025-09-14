local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Lấy thông tin account
local function getAccountInfo()
    local player = Players.LocalPlayer
    if not player then
        return "UnknownAccount", "0"
    end
    return player.Name, tostring(player.UserId)
end

local accountName, userId = getAccountInfo()

-- Hàm gửi webhook an toàn
local function sendDiscordWebhook(status)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    local embed = {
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
                    name = "🔄 Status",
                    value = status,
                    inline = true
                },
                {
                    name = "🕐 Time",
                    value = timestamp,
                    inline = false
                }
            }
        }
    }
    
    local data = {
        embeds = embed,
        username = "Account Monitor",
        content = status == "ONLINE" and "🟢 Account Online!" or "🔴 Account Offline!"
    }
    
    -- Sử dụng pcall để bắt lỗi an toàn
    local success, errorMessage = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
    
    if not success then
        warn("Webhook error: " .. tostring(errorMessage))
    end
end

-- Gửi thông báo ONLINE
sendDiscordWebhook("ONLINE")
print("🟢 Account Online: " .. accountName)

-- Xử lý sự kiện khi player rời game (thay cho BindToClose)
local function onPlayerRemoving(player)
    if player == Players.LocalPlayer then
        sendDiscordWebhook("OFFLINE")
        print("🔴 Account Offline: " .. accountName)
    end
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Giữ script chạy
while true do
    wait(60) -- Chờ 1 phút
    -- Có thể thêm kiểm tra định kỳ ở đây nếu cần
end
