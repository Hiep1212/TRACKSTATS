local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Webhook Discord
local WEBHOOK_URL = "https://discord.com/api/webhooks/1408341281033158657/m9XMjG3Z_KOp7PdPpZYtIFyMmGiMQvt_V-maL4iywLoGCSsXflFwxawy_z8oEsO0aTD1"

-- Lấy thông tin account
local accountName = "Unknown"
if Players.LocalPlayer then
    accountName = Players.LocalPlayer.Name
end

-- Hàm gửi webhook an toàn
local function sendSafeWebhook(status)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Tạo dữ liệu webhook
    local webhookData = {
        ["content"] = status == "ONLINE" and "🟢 **ACCOUNT ONLINE**" or "🔴 **ACCOUNT OFFLINE**",
        ["embeds"] = {{
            ["title"] = "ROBLOX ACCOUNT STATUS",
            ["description"] = "**Account:** " .. accountName .. "\n**Status:** " .. status .. "\n**Time:** " .. timestamp,
            ["color"] = status == "ONLINE" and 65280 or 16711680,
            ["footer"] = {
                ["text"] = "Monitor System"
            }
        }}
    }
    
    -- Sử dụng RequestAsync cho an toàn
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(webhookData)
        })
    end)
    
    if success then
        print("✅ Webhook sent: " .. status)
    else
        warn("❌ Webhook error: " .. tostring(response))
    end
end

-- Gửi thông báo ONLINE
sendSafeWebhook("ONLINE")
print("🟢 Account Online: " .. accountName)

-- Hàm xử lý khi player rời game
local function onPlayerLeft(player)
    if player and player.Name == accountName then
        sendSafeWebhook("OFFLINE")
        print("🔴 Account Offline: " .. accountName)
    end
end

-- Kết nối sự kiện
Players.PlayerRemoving:Connect(onPlayerLeft)

-- Giữ script chạy
while true do
    wait(10)
end

